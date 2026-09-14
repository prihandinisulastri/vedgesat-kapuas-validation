# VedgeSat Kapuas Validation

Code and supplementary outputs for validation of VedgeSat-derived vegetation edges in the Lower Kapuas Delta, West Kalimantan, Indonesia.

This repository supports the MSc dissertation:

**Validation of VedgeSat Performance in Tropical Delta Environments of Indonesia Using Sentinel-2 Imagery and Manual Vegetation-Edge References**

**Author:** Sulastri Prihandini  
**Institution:** University of Glasgow  
**Programme:** MSc Sustainable Water Environments

---

## Project Overview

This study evaluates the positional performance of VedgeSat vegetation-edge extraction in a heterogeneous tropical delta environment.

VedgeSat-derived vegetation edges from Sentinel-2 imagery were validated against vegetation boundaries derived from higher-resolution PlanetScope imagery.

The analysis examines performance across:

- four seasonal conditions;
- three vegetation groups;
- six operational processing zones; and
- two validation-reference definitions.

The manually interpreted PlanetScope vegetation boundary was used as the **primary validation reference**, while an automated PlanetScope NDVI-derived boundary using a threshold of 0.30 was used as a **secondary sensitivity reference**.

---

## Study Area

The study was conducted in the **Lower Kapuas Delta, Kubu Raya Regency, West Kalimantan, Indonesia**.

The delta contains heterogeneous vegetation, distributary channels, wet sediment, agricultural areas, mangrove vegetation, and transitional vegetation–substrate boundaries, providing a challenging environment for automated vegetation-edge extraction.

All spatial analysis was conducted in:

**WGS 84 / UTM Zone 49S (EPSG:32749)**

---

## Seasonal Framework

Four seasonal periods were analysed:

1. Wet
2. Transition Wet–Dry
3. Dry
4. Transition Dry–Wet

Sentinel-2 imagery was prepared in Google Earth Engine and exported at 10 m spatial resolution for subsequent VedgeSat processing.

---

## Validation Framework

A fixed master-transect network containing **7,619 unique transects** was used throughout the validation analysis.

- Transect spacing: **10 m**
- Number of operational processing zones: **6**
- Number of seasonal periods: **4**
- Total VedgeSat extraction runs: **24**

The same master-transect framework was retained across all seasons and both validation-reference methods.

For each valid transect, the distance from the transect origin to the VedgeSat-derived vegetation edge (VE) and the PlanetScope validation line (VL) was measured.

Positional error was calculated as:

```text
error = VE distance - VL distance
```

Positive values indicate that the VE intersection is farther from the transect origin than the VL intersection.

Negative values indicate that the VE intersection is closer to the transect origin.

The sign of the error should not automatically be interpreted as seaward or landward displacement.

---

## Validation References

### Manual PlanetScope Validation

The primary validation reference was manually interpreted from PlanetScope imagery using the outer boundary of continuous vegetation canopy.

### Automated NDVI-Derived PlanetScope Validation

A secondary PlanetScope validation line was generated using an NDVI threshold of **0.30**.

This automated reference was used to assess the sensitivity of VedgeSat validation results to vegetation-boundary definition. It was treated as a **secondary sensitivity reference**, rather than an alternative ground truth.

Direct comparison between the manual and automated validation references was conducted using common transect–season observations containing valid measurements under both reference definitions.

---

## Vegetation Groups

MapBiomas Indonesia Collection 4 land-cover classes were sampled at the midpoint of the fixed transects and reclassified into the following analytical groups:

- Mangrove
- Agriculture
- Mixed vegetation
- Excluded
- NoData

---

## Repository Structure

```text
vedgesat-kapuas-validation/
│
├── scripts/
│   ├── 01_Image_Selection_and_QA.js
│   ├── 02_Sentinel2_Image_Export.js
│   ├── 03_Master_Transect_Generation.py
│   ├── 04_VE_VL_Positional_Validation.py
│   ├── 05_Statistical_Analysis_and_Sensitivity.R
│   └── config_kapuas_sites_v2.py
│
├── results/
│   ├── Manual/
│   ├── Automated_NDVI030/
│   └── Comparison/
│
├── metadata/
│   └── README_data.md
│
├── .gitignore
└── README.md
```

The analytical workflow follows the sequence:

**Sentinel-2 image selection → image export → master-transect generation → positional validation → statistical analysis and validation-reference sensitivity**

---

## Script Workflow

The analytical workflow is organised into five main scripts.

### Script 1 — Image Selection and Quality Assessment

`01_Image_Selection_and_QA.js`

**Platform:** Google Earth Engine  
**Language:** JavaScript

Used to:

- search candidate Sentinel-2 imagery;
- inspect Sentinel-2 tile coverage;
- retrieve image metadata;
- assess scene-level cloud information; and
- support seasonal image selection.

---

### Script 2 — Sentinel-2 Image Export

`02_Sentinel2_Image_Export.js`

**Platform:** Google Earth Engine  
**Language:** JavaScript

Used to:

- load the final selected Sentinel-2 imagery;
- mosaic intersecting scenes where required;
- clip imagery to the study area; and
- export seasonal datasets at 10 m spatial resolution in EPSG:32749.

---

### Script 3 — Master-Transect Generation

`03_Master_Transect_Generation.py`

**Language:** Python

Used to generate the fixed master-transect framework at 10 m spacing.

The final network contains **7,619 unique transects** and was reused throughout the validation analysis.

---

### Script 4 — VE–VL Positional Validation

`04_VE_VL_Positional_Validation.py`

**Language:** Python

Used to:

- identify intersections between VedgeSat-derived vegetation edges (VE) and PlanetScope validation lines (VL);
- measure VE and VL distances along the fixed transects;
- resolve multiple-intersection cases;
- assign vegetation-group attributes;
- calculate signed positional error; and
- generate seasonal, vegetation-group, and zone-level validation outputs.

This script uses the supporting configuration file:

`config_kapuas_sites_v2.py`

for project-specific site and file-path configuration.

---

### Script 5 — Statistical Analysis and Validation-Reference Sensitivity

`05_Statistical_Analysis_and_Sensitivity.R`

**Language:** R

Used to:

- summarise overall seasonal performance;
- analyse performance by vegetation group;
- analyse spatial variability across processing zones;
- compare manual and automated validation references;
- construct common paired samples; and
- calculate validation-reference sensitivity metrics.

---

## Validation Metrics

The principal validation metrics include:

- Root Mean Square Error (RMSE)
- Mean Absolute Error (MAE)
- Median Absolute Error (MedAE)
- Mean bias
- Median signed error
- Pearson coefficient of determination (R²)
- Sample size (`n`)

RMSE, MAE, MedAE, bias, and median signed error are reported in metres.

Pearson R² is used to describe spatial correspondence between VE and VL distances and should not be interpreted as a measure of absolute positional accuracy.

---

## Results Directory

### `results/Manual/`

Contains validation outputs generated using the manually interpreted PlanetScope validation reference.

Main outputs include:

- `per_transect_distances_all_seasons.csv`
- `season_metrics.csv`
- `zone_season_metrics.csv`
- `vclass_season_metrics.csv`

### `results/Automated_NDVI030/`

Contains equivalent validation outputs generated using the automated PlanetScope NDVI-derived reference with a threshold of 0.30.

Main outputs include:

- `per_transect_distances_all_seasons.csv`
- `season_metrics.csv`
- `zone_season_metrics.csv`
- `vclass_season_metrics.csv`

### `results/Comparison/`

Contains direct comparisons between the manual and automated validation-reference methods.

Paired comparisons use only transect–season observations containing valid measurements under both reference definitions.

Main paired outputs include:

- `comparison_PAIRED_common_transects.csv`
- `comparison_PAIRED_season_metrics.csv`
- `comparison_PAIRED_zone_season_metrics.csv`
- `comparison_PAIRED_vgroup_season_metrics.csv`
- `comparison_PAIRED_n_by_season.csv`
- `comparison_PAIRED_season_deltas_auto_minus_manual.csv`
- `comparison_PAIRED_zone_deltas_auto_minus_manual.csv`
- `comparison_PAIRED_vgroup_deltas_auto_minus_manual.csv`

Further information about the result files is provided in:

`metadata/README_data.md`

---

## Software

The workflow uses:

- Google Earth Engine
- Python
- R
- QGIS
- VedgeSat

Key Python packages include:

- GeoPandas
- pandas
- NumPy
- Rasterio
- Shapely

Key R packages include:

- readr
- dplyr
- tidyr
- ggplot2
- forcats
- stringr

---

## Data Availability

Raw Sentinel-2 imagery is not redistributed in this repository because it is available through public satellite-data services.

PlanetScope imagery is not redistributed because of licensing restrictions.

This repository contains the analytical scripts and derived validation outputs used to support the dissertation workflow.

---

## Reproducibility Notes

Some scripts require project-specific file paths and spatial input datasets that are not distributed through this repository.

Users should update the configuration file:

`scripts/config_kapuas_sites_v2.py`

to match their local data structure before running the positional-validation workflow.

For Script 5, the repository root should be used as the R working directory so that the relative `results/` paths resolve correctly.

---

## Author

**Sulastri Prihandini**  
MSc Sustainable Water Environments  
School of Geographical and Earth Sciences  
University of Glasgow  

2026
