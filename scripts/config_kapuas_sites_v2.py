"""
config_kapuas_sites_v2.py

Project configuration for the Kapuas validation workflow.

Inputs:
  - Per-zone reference lines:
        Kapuas_Z0N_Refline.shp

  - Merged VedgeSat vegetation-edge lines:
        Kapuas_<season>_veglines_QC.shp

  - PlanetScope validation lines:
        <Season>_PS_ValidationLines_QC.shp

  - MapBiomas land-cover raster:
        Kapuas_LandCover_Clipped.tif
"""

import os

# ---------------------------------------------------------------------------
# Paths
# ---------------------------------------------------------------------------

BASE_DIR = "/Users/iniiastrii_/Desktop/MSC Project"

VALIDATION_DIR = os.path.join(BASE_DIR, "06_Validation")
INPUT_DIR = os.path.join(VALIDATION_DIR, "01_Inputs")
OUTPUT_DIR = os.path.join(VALIDATION_DIR, "03_Outputs")

os.makedirs(OUTPUT_DIR, exist_ok=True)

ZONES = ["Z01", "Z02", "Z03", "Z04", "Z05", "Z06"]

REFLINE_PATTERN = os.path.join(
    INPUT_DIR,
    "Kapuas_{zone}_Refline.shp"
)

SEASONS = [
    {
        "key": "wet",
        "ve_label": "wet",
        "vl_label": "Wet",
    },
    {
        "key": "transwetdry",
        "ve_label": "TransWetDry",
        "vl_label": "TransWetDry",
    },
    {
        "key": "dry",
        "ve_label": "dry",
        "vl_label": "Dry",
    },
    {
        "key": "transdrywet",
        "ve_label": "TransDryWet",
        "vl_label": "TransDryWet",
    },
]

VE_PATTERN = os.path.join(
    INPUT_DIR,
    "Kapuas_{ve_label}_veglines_QC.shp"
)

VL_PATTERN = os.path.join(
    INPUT_DIR,
    "{vl_label}_PS_ValidationLines_QC.shp"
)

LANDCOVER_RASTER = os.path.join(
    INPUT_DIR,
    "Kapuas_LandCover_Clipped.tif"
)

TRANSECTS_DIR = os.path.join(
    OUTPUT_DIR,
    "MasterTransects"
)

os.makedirs(TRANSECTS_DIR, exist_ok=True)

TRANSECTS_SHP = os.path.join(
    TRANSECTS_DIR,
    "Kapuas_MasterTransects.shp"
)

# ---------------------------------------------------------------------------
# CRS / transect settings
# ---------------------------------------------------------------------------

OUTPUT_EPSG = 32749
TRANSECT_SPACING = 10
TRANSECT_LENGTH = 200  # preserve the previously validated transect length

# ---------------------------------------------------------------------------
# Land-cover classes
# ---------------------------------------------------------------------------

CLASS_VALUE_MAP = {
    0: "NoData",

    3: "Forest Formation",
    5: "Mangrove",
    13: "Non-Forest Natural Vegetation",
    76: "Peat Swamp Forest",

    9: "Pulpwood Plantation",
    21: "Other Agriculture",
    35: "Oil Palm",
    40: "Rice Paddy",

    24: "Settlement",
    25: "Other Non-Vegetation",
    31: "Aquaculture",
    33: "River, Lake, Ocean",
}

CLASS_GROUP_MAP = {
    "Mangrove": "mangrove",

    "Forest Formation": "mixed_vegetation",
    "Peat Swamp Forest": "mixed_vegetation",
    "Non-Forest Natural Vegetation": "mixed_vegetation",

    "Oil Palm": "agriculture",
    "Rice Paddy": "agriculture",
    "Pulpwood Plantation": "agriculture",
    "Other Agriculture": "agriculture",

    "Settlement": "exclude",
    "Other Non-Vegetation": "exclude",
    "Aquaculture": "exclude",
    "River, Lake, Ocean": "exclude",

    "NoData": "nodata",
}