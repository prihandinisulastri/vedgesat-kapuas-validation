"""
04_generate_master_transects.py

Generates cross-shore transects ONCE, from each zone's own reference line
(Kapuas_Z0N_Refline.shp), at fixed 10 m spacing. These transects are reused
for every season -- they are NOT regenerated per season -- so that all four
seasonal comparisons happen at exactly the same cross-shore locations
(see validation-planning discussion: transects must be fixed to compare
seasons fairly).

Each transect gets a "zone" attribute (Z01..Z06) so later steps can group
results by zone. Vegetation class is attached separately in script 05, since
that comes from the MapBiomas raster, not the reflines.

Output: one merged shapefile, config.TRANSECTS_SHP, with fields:
    TransectID (str, e.g. "Z01_0001")
    zone       (str, e.g. "Z01")
    geometry   (LineString, shore-normal transect)
"""

import os
import geopandas as gpd
import numpy as np
from shapely.geometry import LineString, Point

import config_kapuas_sites_v2 as cfg


def generate_transects_for_line(line, spacing, length, zone_id):
    """
    Walk along `line` at fixed `spacing` (m), and at each station draw a
    shore-normal transect of total length `length` (m), centred on the
    reference line (i.e. extending length/2 on each side).

    Returns a GeoDataFrame of LineString transects with a TransectID and
    zone attribute.
    """
    total_length = line.length
    n_stations = int(total_length // spacing)
    records = []

    for i in range(n_stations + 1):
        dist = i * spacing
        if dist > total_length:
            dist = total_length

        point = line.interpolate(dist)

        # Estimate local tangent direction using a small forward/backward
        # step, then rotate 90 degrees to get the shore-normal direction.
        eps = 1.0  # metres, small step for tangent estimation
        d0 = max(dist - eps, 0)
        d1 = min(dist + eps, total_length)
        p0 = line.interpolate(d0)
        p1 = line.interpolate(d1)

        dx, dy = (p1.x - p0.x), (p1.y - p0.y)
        norm = np.hypot(dx, dy)
        if norm == 0:
            continue
        dx, dy = dx / norm, dy / norm

        # Perpendicular (normal) direction
        nx, ny = -dy, dx

        half_len = length / 2
        start = Point(point.x - nx * half_len, point.y - ny * half_len)
        end = Point(point.x + nx * half_len, point.y + ny * half_len)
        transect_line = LineString([start, end])

        records.append({
            "TransectID": f"{zone_id}_{i:04d}",
            "zone": zone_id,
            "geometry": transect_line,
        })

    return gpd.GeoDataFrame(records, crs=line.crs if hasattr(line, "crs") else None)


def main():
    all_transects = []

    for zone in cfg.ZONES:
        refline_path = cfg.REFLINE_PATTERN.format(zone=zone)
        if not os.path.exists(refline_path):
            print(f"[SKIP] {zone}: refline not found at {refline_path}")
            continue

        refline_gdf = gpd.read_file(refline_path).to_crs(epsg=cfg.OUTPUT_EPSG)

        # Merge all features in the refline file into a single line (in case
        # it's split into multiple parts/segments in the shapefile)
        merged_line = refline_gdf.unary_union
        if merged_line.geom_type == "MultiLineString":
            # Stitch parts in file order -- check visually afterwards that
            # this produces a sensible single continuous line per zone;
            # complex multi-part reflines (e.g. Zone01 with its creek-mouth
            # detour) may need manual merging in QGIS first if this naive
            # concatenation produces a jumbled line.
            from shapely.ops import linemerge
            merged_line = linemerge(merged_line)

        zone_transects = generate_transects_for_line(
            merged_line, cfg.TRANSECT_SPACING, cfg.TRANSECT_LENGTH, zone
        )
        zone_transects = zone_transects.set_crs(epsg=cfg.OUTPUT_EPSG)
        all_transects.append(zone_transects)
        print(f"{zone}: generated {len(zone_transects)} transects")

    if not all_transects:
        print("No transects generated -- check refline paths in config.")
        return

    master = gpd.GeoDataFrame(
        pd_concat(all_transects), crs=f"EPSG:{cfg.OUTPUT_EPSG}"
    )
    master.to_file(cfg.TRANSECTS_SHP)
    print(f"\nSaved {len(master)} total transects to {cfg.TRANSECTS_SHP}")


def pd_concat(gdf_list):
    import pandas as pd
    return pd.concat(gdf_list, ignore_index=True)


if __name__ == "__main__":
    main()
