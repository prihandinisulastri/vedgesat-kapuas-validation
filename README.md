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
