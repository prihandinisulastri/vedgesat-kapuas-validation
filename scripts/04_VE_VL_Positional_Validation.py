"""
S02_validation_by_zone_season_class.py

Runs the full Kapuas validation workflow:

  1. Load the fixed master transects.
  2. Sample MapBiomas land cover at each transect midpoint.
  3. For every configured season, intersect the VedgeSat vegetation-edge
     line and PlanetScope validation line with the same fixed transects.
  4. Calculate RMSE, MAE, median absolute error (MedAE), mean bias, median signed error, identity-line R²,
     Pearson R², and sample size at three levels:
       - zone × season
       - vegetation group × season
       - season overall
  5. Save the complete per-transect table and metric tables.

Requires:
  - config_kapuas_sites_v2.py
  - an existing master-transect shapefile at cfg.TRANSECTS_SHP
  - rasterio, geopandas, pandas, numpy, and shapely
"""

import os

import geopandas as gpd
import numpy as np
import pandas as pd
import rasterio
import shapely

import config_kapuas_sites_v2 as cfg


# ---------------------------------------------------------------------------
# Step 1–2: load transects and sample land-cover class
# ---------------------------------------------------------------------------
def load_transects_with_class():
    if not os.path.exists(cfg.TRANSECTS_SHP):
        raise FileNotFoundError(
            f"Master transects not found: {cfg.TRANSECTS_SHP}"
        )

    if not os.path.exists(cfg.LANDCOVER_RASTER):
        raise FileNotFoundError(
            f"Land-cover raster not found: {cfg.LANDCOVER_RASTER}"
        )

    transects = gpd.read_file(cfg.TRANSECTS_SHP)

    required_columns = {"TransectID", "zone", "geometry"}
    missing_columns = required_columns - set(transects.columns)

    if missing_columns:
        raise ValueError(
            "Master transects are missing columns: "
            f"{sorted(missing_columns)}"
        )

    if transects.empty:
        raise ValueError("The master-transect layer is empty.")

    if transects.crs is None:
        raise ValueError("The master-transect layer has no CRS.")

    if transects.geometry.isna().any() or transects.geometry.is_empty.any():
        raise ValueError(
            "The master-transect layer contains null or empty geometries."
        )

    if transects["TransectID"].duplicated().any():
        duplicates = (
            transects.loc[
                transects["TransectID"].duplicated(),
                "TransectID",
            ]
            .astype(str)
            .tolist()
        )
        raise ValueError(
            f"Duplicate TransectID values found: {duplicates[:10]}"
        )

    transects = transects.to_crs(epsg=cfg.OUTPUT_EPSG)

    # Validation is planar; remove hidden Z or M coordinate dimensions.
    transects["geometry"] = transects.geometry.apply(
        shapely.force_2d
    )

    if not transects.geom_type.eq("LineString").all():
        raise ValueError(
            "All master transects must be LineString geometries."
        )

    with rasterio.open(cfg.LANDCOVER_RASTER) as src:
        if src.crs is None:
            raise ValueError("The land-cover raster has no CRS.")

        transects_raster_crs = transects.to_crs(src.crs)

        midpoints = [
            geom.interpolate(0.5, normalized=True)
            for geom in transects_raster_crs.geometry
        ]
        coordinates = [(point.x, point.y) for point in midpoints]

        samples = src.sample(
            coordinates,
            indexes=1,
            masked=True,
        )

        classes = []

        for sample in samples:
            is_masked = (
                np.ma.isMaskedArray(sample)
                and np.ma.getmaskarray(sample).any()
            )

            if is_masked:
                classes.append(0)
                continue

            value = sample[0]

            if src.nodata is not None and value == src.nodata:
                classes.append(0)
            else:
                classes.append(int(value))

    transects["class_val"] = classes
    transects["vclass"] = transects["class_val"].map(
        cfg.CLASS_VALUE_MAP
    )
    transects["vgroup"] = transects["vclass"].map(
        cfg.CLASS_GROUP_MAP
    )

    unknown_values = sorted(
        set(
            transects.loc[
                transects["vclass"].isna(),
                "class_val",
            ].dropna()
        )
    )

    if unknown_values:
        print(
            "[WARNING] Raster values missing from CLASS_VALUE_MAP: "
            f"{unknown_values}"
        )

    print("\nLand-cover assignment by vegetation group:")
    print(
        transects["vgroup"]
        .value_counts(dropna=False)
        .to_string()
    )

    return transects


# ---------------------------------------------------------------------------
# Step 3: intersection helpers
# ---------------------------------------------------------------------------
def extract_intersection_candidates(geometry):
    """Return representative point candidates from an intersection."""

    if geometry is None or geometry.is_empty:
        return []

    if geometry.geom_type == "Point":
        return [geometry]

    if geometry.geom_type == "MultiPoint":
        return list(geometry.geoms)

    if geometry.geom_type == "LineString":
        return [geometry.interpolate(0.5, normalized=True)]

    if geometry.geom_type == "MultiLineString":
        return [
            part.interpolate(0.5, normalized=True)
            for part in geometry.geoms
            if not part.is_empty
        ]

    if geometry.geom_type == "GeometryCollection":
        candidates = []
        for part in geometry.geoms:
            candidates.extend(
                extract_intersection_candidates(part)
            )
        return candidates

    return []


def get_intersection_distances(transects_gdf, line_gdf):
    """
    Return along-transect distances from the transect start to the selected
    line intersection.

    If multiple intersections occur, select the candidate nearest the
    transect midpoint. The same origin and rule are used for VE and VL.
    """

    if line_gdf.empty:
        raise ValueError("The input line layer is empty.")

    line_gdf = line_gdf[
        line_gdf.geometry.notna()
        & ~line_gdf.geometry.is_empty
    ].copy()

    if line_gdf.empty:
        raise ValueError(
            "The input line layer contains no usable geometry."
        )

    line_gdf["geometry"] = line_gdf.geometry.apply(
        shapely.force_2d
    )

    merged_line = line_gdf.geometry.union_all()

    if merged_line.is_empty:
        raise ValueError("Union of the line geometries is empty.")

    results = {}

    for _, row in transects_gdf.iterrows():
        transect_id = row["TransectID"]
        transect = row.geometry

        if not transect.intersects(merged_line):
            results[transect_id] = np.nan
            continue

        intersection = transect.intersection(merged_line)
        candidates = extract_intersection_candidates(intersection)

        if not candidates:
            results[transect_id] = np.nan
            continue

        transect_mid_distance = transect.length / 2

        best_point = min(
            candidates,
            key=lambda point: abs(
                transect.project(point) - transect_mid_distance
            ),
        )

        results[transect_id] = transect.project(best_point)

    return results


# ---------------------------------------------------------------------------
# Metrics
# ---------------------------------------------------------------------------
def compute_metrics(ve_dist, vl_dist):
    ve = np.asarray(ve_dist, dtype=float)
    vl = np.asarray(vl_dist, dtype=float)

    mask = np.isfinite(ve) & np.isfinite(vl)
    ve = ve[mask]
    vl = vl[mask]

    n = len(ve)

    if n == 0:
        return {
            "rmse": np.nan,
            "mae": np.nan,
            "median_abs_error": np.nan,
            "bias": np.nan,
            "median_error": np.nan,
            "r2_identity": np.nan,
            "r2_pearson": np.nan,
            "n": 0,
        }

    diff = ve - vl

    rmse = np.sqrt(np.mean(diff ** 2))
    mae = np.mean(np.abs(diff))
    median_abs_error = np.median(np.abs(diff))
    bias = np.mean(diff)
    median_error = np.median(diff)

    ss_res = np.sum((vl - ve) ** 2)
    ss_tot = np.sum((vl - np.mean(vl)) ** 2)
    r2_identity = 1 - ss_res / ss_tot if ss_tot > 0 else np.nan

    if n >= 2 and np.std(ve) > 0 and np.std(vl) > 0:
        correlation = np.corrcoef(ve, vl)[0, 1]
        r2_pearson = correlation ** 2
    else:
        r2_pearson = np.nan

    return {
        "rmse": rmse,
        "mae": mae,
        "median_abs_error": median_abs_error,
        "bias": bias,
        "median_error": median_error,
        "r2_identity": r2_identity,
        "r2_pearson": r2_pearson,
        "n": n,
    }


# ---------------------------------------------------------------------------
# Main pipeline
# ---------------------------------------------------------------------------
def main():
    transects = load_transects_with_class()
    all_rows = []

    missing_inputs = []

    for season in cfg.SEASONS:
        ve_path = cfg.VE_PATTERN.format(
            ve_label=season["ve_label"]
        )
        vl_path = cfg.VL_PATTERN.format(
            vl_label=season["vl_label"]
        )

        if not os.path.exists(ve_path):
            missing_inputs.append(ve_path)
        if not os.path.exists(vl_path):
            missing_inputs.append(vl_path)

    if missing_inputs:
        raise FileNotFoundError(
            "Missing seasonal inputs:\n" + "\n".join(missing_inputs)
        )

    for season in cfg.SEASONS:
        season_key = season["key"]

        ve_path = cfg.VE_PATTERN.format(
            ve_label=season["ve_label"]
        )
        vl_path = cfg.VL_PATTERN.format(
            vl_label=season["vl_label"]
        )

        ve_gdf = gpd.read_file(ve_path)
        vl_gdf = gpd.read_file(vl_path)

        if ve_gdf.crs is None:
            raise ValueError(f"VE layer has no CRS: {ve_path}")
        if vl_gdf.crs is None:
            raise ValueError(f"Validation layer has no CRS: {vl_path}")

        ve_gdf = ve_gdf.to_crs(epsg=cfg.OUTPUT_EPSG)
        vl_gdf = vl_gdf.to_crs(epsg=cfg.OUTPUT_EPSG)

        ve_distances = get_intersection_distances(transects, ve_gdf)
        vl_distances = get_intersection_distances(transects, vl_gdf)

        for _, row in transects.iterrows():
            transect_id = row["TransectID"]

            all_rows.append({
                "TransectID": transect_id,
                "zone": row["zone"],
                "class_val": row["class_val"],
                "vclass": row["vclass"],
                "vgroup": row["vgroup"],
                "season": season_key,
                "ve_dist": ve_distances.get(transect_id, np.nan),
                "vl_dist": vl_distances.get(transect_id, np.nan),
            })

        ve_count = sum(np.isfinite(list(ve_distances.values())))
        vl_count = sum(np.isfinite(list(vl_distances.values())))

        print(
            f"{season_key}: {ve_count} VE intersections; "
            f"{vl_count} VL intersections."
        )

    if not all_rows:
        raise RuntimeError("No validation records were generated.")

    master_df = pd.DataFrame(all_rows)

    if master_df.duplicated(["TransectID", "season"]).any():
        raise ValueError(
            "Duplicate TransectID × season records were generated."
        )

    master_df["error"] = master_df["ve_dist"] - master_df["vl_dist"]
    master_df["abs_error"] = master_df["error"].abs()
    master_df["valid_pair"] = (
        master_df["ve_dist"].notna()
        & master_df["vl_dist"].notna()
    )

    master_out = os.path.join(
        cfg.OUTPUT_DIR,
        "per_transect_distances_all_seasons.csv",
    )
    master_df.to_csv(master_out, index=False)

    print(f"\nSaved full per-transect table to:\n{master_out}")

    intersection_summary = (
        master_df.groupby("season", as_index=False)
        .agg(
            total_rows=("TransectID", "size"),
            ve_intersections=("ve_dist", "count"),
            vl_intersections=("vl_dist", "count"),
            valid_pairs=("valid_pair", "sum"),
        )
    )

    print("\nIntersection summary:")
    print(intersection_summary.to_string(index=False))

    # Overall and zone metrics use every valid VE–VL pair, regardless of
    # whether MapBiomas could assign a vegetation class.
    overall_df = master_df.copy()

    # Vegetation-specific metrics require a reliable vegetation group.
    vegetation_df = master_df[
        master_df["vgroup"].notna()
        & ~master_df["vgroup"].isin(["exclude", "nodata"])
    ].copy()

    print(
        "\nValid VE–VL pairs available for zone and overall metrics: "
        f"{int(overall_df['valid_pair'].sum())}"
    )
    print(
        "Valid VE–VL pairs available for vegetation-group metrics: "
        f"{int(vegetation_df['valid_pair'].sum())}"
    )

    # Zone × season
    zone_rows = []
    for (zone, season), group in overall_df.groupby(["zone", "season"]):
        zone_rows.append({
            "zone": zone,
            "season": season,
            **compute_metrics(group["ve_dist"], group["vl_dist"]),
        })

    zone_season_df = pd.DataFrame(zone_rows)
    zone_season_df.to_csv(
        os.path.join(cfg.OUTPUT_DIR, "zone_season_metrics.csv"),
        index=False,
    )

    # Vegetation group × season
    vegetation_rows = []
    for (vgroup, season), group in vegetation_df.groupby(
        ["vgroup", "season"]
    ):
        vegetation_rows.append({
            "vgroup": vgroup,
            "season": season,
            **compute_metrics(group["ve_dist"], group["vl_dist"]),
        })

    vclass_season_df = pd.DataFrame(vegetation_rows)
    vclass_season_df.to_csv(
        os.path.join(cfg.OUTPUT_DIR, "vclass_season_metrics.csv"),
        index=False,
    )

    # Overall season
    season_rows = []
    for season, group in overall_df.groupby("season"):
        season_rows.append({
            "season": season,
            **compute_metrics(group["ve_dist"], group["vl_dist"]),
        })

    season_df = pd.DataFrame(season_rows)
    season_df.to_csv(
        os.path.join(cfg.OUTPUT_DIR, "season_metrics.csv"),
        index=False,
    )

    print("\n=== Season-level summary ===")
    print(season_df.to_string(index=False))

    print("\n=== Vegetation-group × season summary ===")
    print(vclass_season_df.to_string(index=False))

    print("\nSaved metric tables:")
    print(os.path.join(cfg.OUTPUT_DIR, "zone_season_metrics.csv"))
    print(os.path.join(cfg.OUTPUT_DIR, "vclass_season_metrics.csv"))
    print(os.path.join(cfg.OUTPUT_DIR, "season_metrics.csv"))
    print(f"\nAll outputs saved in:\n{cfg.OUTPUT_DIR}")


if __name__ == "__main__":
    main()
