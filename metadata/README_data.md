# Data README

## Project

Validation of VedgeSat performance in a tropical delta environment of Indonesia using Sentinel-2 imagery and PlanetScope vegetation-edge references.

**Author:** Sulastri Prihandini  
**Institution:** University of Glasgow  
**Study area:** Lower Kapuas Delta, West Kalimantan, Indonesia

## Validation framework

A fixed master-transect network containing 7,619 unique transects was used throughout the validation analysis.

- Transect spacing: 10 m
- CRS: WGS 84 / UTM Zone 49S
- EPSG: 32749

The same master-transect framework was retained across all seasons and validation-reference methods.

## Validation references

Two PlanetScope-derived vegetation-boundary references were used:

1. **Manual PlanetScope validation line**
   - Primary validation reference
   - Manually interpreted outer boundary of continuous vegetation canopy

2. **Automated NDVI-derived PlanetScope validation line**
   - Secondary sensitivity reference
   - Derived using an NDVI threshold of 0.30

The automated reference was used to assess sensitivity to vegetation-boundary definition and was not treated as an alternative ground truth.

## Positional error

Positional error was calculated as:

`error = VE distance - VL distance`

where:

- `VE distance` = distance from the transect origin to the VedgeSat-derived vegetation-edge intersection
- `VL distance` = distance from the same transect origin to the PlanetScope validation-line intersection

Positive values indicate that the VE intersection lies farther from the transect origin than the VL intersection. Negative values indicate that the VE intersection lies closer to the transect origin.

Error sign should not automatically be interpreted as seaward or landward displacement.

## Seasonal categories

- Wet
- Transition Wet-Dry
- Dry
- Transition Dry-Wet

## Results folders

### `results/Manual/`

Contains validation outputs generated using the manually digitised PlanetScope reference.

Main files:

- `per_transect_distances_all_seasons.csv`
- `season_metrics.csv`
- `zone_season_metrics.csv`
- `vclass_season_metrics.csv`

### `results/Automated_NDVI030/`

Contains equivalent outputs generated using the automated PlanetScope NDVI >= 0.30 reference.

### `results/Comparison/`

Contains direct comparisons between the manual and automated validation-reference methods.

Paired comparisons use only transect-season observations containing valid measurements under both reference definitions.

Main paired outputs include:

- `comparison_PAIRED_common_transects.csv`
- `comparison_PAIRED_season_metrics.csv`
- `comparison_PAIRED_zone_season_metrics.csv`
- `comparison_PAIRED_vgroup_season_metrics.csv`
- `comparison_PAIRED_n_by_season.csv`
- `comparison_PAIRED_season_deltas_auto_minus_manual.csv`
- `comparison_PAIRED_zone_deltas_auto_minus_manual.csv`
- `comparison_PAIRED_vgroup_deltas_auto_minus_manual.csv`

## Validation metrics

The main metrics include:

- RMSE
- MAE
- MedAE
- Mean bias
- Median signed error
- Pearson R²
- Sample size (`n`)

## Data availability

Raw Sentinel-2 imagery is not included because it can be retrieved from public satellite-data services.

PlanetScope imagery is not redistributed in this repository.

This repository contains analysis scripts and derived validation outputs used to document and reproduce the analytical workflow.
