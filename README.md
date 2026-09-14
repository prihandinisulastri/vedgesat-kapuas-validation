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


before and after things like `NDVI >= 0.30`, filenames, and `metadata/README_data.md`.

Those empty triple-backtick blocks should be deleted. For short items such as filenames or equations, use **inline code with single backticks**. Keep triple backticks only for the repository tree.

Here is the cleaned version of the section you pasted:

````markdown
Positive values indicate that the VE intersection is farther from the transect origin than the VL intersection.

Negative values indicate that the VE intersection is closer to the transect origin.

The sign of the error should not automatically be interpreted as seaward or landward displacement.

---

## Validation References

### Manual PlanetScope validation

The primary validation reference was manually interpreted from PlanetScope imagery using the outer boundary of continuous vegetation canopy.

### Automated NDVI-derived validation

A secondary PlanetScope validation line was generated using an NDVI threshold of `NDVI >= 0.30`.

This reference was used to evaluate the sensitivity of validation results to vegetation-boundary definition.

It was not treated as an alternative ground truth.

---

## Vegetation Groups

MapBiomas Indonesia Collection 4 land-cover classes were sampled at the midpoint of the fixed transects and reclassified into broader analytical groups:

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
