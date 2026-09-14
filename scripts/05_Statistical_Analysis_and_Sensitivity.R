# =========================================================
# STATISTICAL ANALYSIS AND VALIDATION-REFERENCE SENSITIVITY
# =========================================================
#
# Purpose:
# - Read manual and automated PlanetScope validation outputs
# - Summarise seasonal, vegetation-group, and zone-level results
# - Compare validation-reference definitions using common paired samples
# - Calculate RMSE, MAE, MedAE, bias, and median signed error
# - Generate sensitivity tables and figures
#
# Author:
# Sulastri Prihandini
# University of Glasgow
# =========================================================

# -----------------------------
# Output folders for dual-validation workflow
# -----------------------------
# Repository/project root
# IMPORTANT: run this script with the repository root as the working directory.
PROJECT_ROOT <- normalizePath(
  ".",
  winslash = "/",
  mustWork = TRUE
)

# Main results directory
BASE_OUT <- file.path(
  PROJECT_ROOT,
  "results"
)

# Put one complete positional-validation output set in each folder:
#   Manual/              = manually digitised PlanetScope validation lines
#   Automated_NDVI030/   = automated PlanetScope NDVI >= 0.30 validation lines
MANUAL_DIR <- file.path(BASE_OUT, "Manual")
AUTO_DIR   <- file.path(BASE_OUT, "Automated_NDVI030")

# Main figures use the MANUAL validation as the primary reference.
FIG_DIR     <- file.path(BASE_OUT, "Figures")
COMPARE_DIR <- file.path(BASE_OUT, "Comparison")

dir.create(FIG_DIR, recursive = TRUE, showWarnings = FALSE)
dir.create(COMPARE_DIR, recursive = TRUE, showWarnings = FALSE)

if (!dir.exists(MANUAL_DIR)) stop("Manual output folder not found: ", MANUAL_DIR)
if (!dir.exists(AUTO_DIR)) stop("Automated output folder not found: ", AUTO_DIR)


# -----------------------------
# Packages
# -----------------------------
library(readr)
library(dplyr)
library(ggplot2)
library(tidyr)
library(forcats)
library(stringr)

# -----------------------------
# Read data
# -----------------------------
per_transect <- read_csv(file.path(MANUAL_DIR, "per_transect_distances_all_seasons.csv"))
zone_season  <- read_csv(file.path(MANUAL_DIR, "zone_season_metrics.csv"))
vclass_season <- read_csv(file.path(MANUAL_DIR, "vclass_season_metrics.csv"))
season_metrics <- read_csv(file.path(MANUAL_DIR, "season_metrics.csv"))

# Main figures are written explicitly to FIG_DIR; the working directory is not changed.

# -----------------------------
# Order factors
# -----------------------------
season_levels <- c("wet", "transwetdry", "dry", "transdrywet")
season_labels <- c("Wet", "Trans. Wet-Dry", "Dry", "Trans. Dry-Wet")

per_transect <- per_transect %>%
  mutate(
    season = factor(season, levels = season_levels, labels = season_labels),
    zone = factor(zone, levels = c("Z01", "Z02", "Z03", "Z04", "Z05", "Z06")),
    vgroup = factor(vgroup,
                    levels = c("mangrove", "agriculture", "mixed_vegetation"),
                    labels = c("Mangrove", "Agriculture", "Mixed vegetation"))
  )

zone_season <- zone_season %>%
  mutate(
    season = factor(season, levels = season_levels, labels = season_labels),
    zone = factor(zone, levels = c("Z01", "Z02", "Z03", "Z04", "Z05", "Z06"))
  )

vclass_season <- vclass_season %>%
  mutate(
    season = factor(season, levels = season_levels, labels = season_labels),
    vgroup = factor(vgroup,
                    levels = c("mangrove", "agriculture", "mixed_vegetation"),
                    labels = c("Mangrove", "Agriculture", "Mixed vegetation"))
  )

season_metrics <- season_metrics %>%
  mutate(
    season = factor(season, levels = season_levels, labels = season_labels)
  )

# -----------------------------
# Custom colours
# -----------------------------
season_cols <- c(
  "Wet" = "#1f78b4",
  "Trans. Wet-Dry" = "#33a02c",
  "Dry" = "#ff7f00",
  "Trans. Dry-Wet" = "#6a3d9a"
)

veg_cols <- c(
  "Mangrove" = "#1b9e77",
  "Agriculture" = "#d95f02",
  "Mixed vegetation" = "#7570b3"
)

# =========================================================
# FIGURE 1 — Scatter plot: overall agreement by season
# Manual PlanetScope validation = primary reference
# =========================================================

# ---------------------------------------------------------
# Prepare annotation statistics
# ---------------------------------------------------------
scatter_stats <- season_metrics %>%
  mutate(
    label = paste0(
      "RMSE = ", sprintf("%.1f", rmse), " m\n",
      "Bias = ", ifelse(bias > 0, "+", ""),
      sprintf("%.1f", bias), " m\n",
      "R² = ", sprintf("%.2f", r2_pearson), "\n",
      "n = ", format(n, big.mark = ",", scientific = FALSE)
    )
  )

# ---------------------------------------------------------
# Main scatter plot
# ---------------------------------------------------------
fig1 <- per_transect %>%
  filter(
    !is.na(ve_dist),
    !is.na(vl_dist)
  ) %>%
  ggplot(
    aes(
      x = vl_dist,
      y = ve_dist,
      colour = season
    )
  ) +
  
  # Transect observations
  geom_point(
    alpha = 0.30,
    size = 1.2
  ) +
  
  # Perfect agreement line
  geom_abline(
    slope = 1,
    intercept = 0,
    linetype = "dashed",
    linewidth = 0.8,
    colour = "black"
  ) +
  
  # One panel per season
  facet_wrap(
    ~season,
    ncol = 2
  ) +
  
  # Metric box in each panel
  geom_label(
    data = scatter_stats,
    aes(
      x = 7,
      y = 203,
      label = label
    ),
    inherit.aes = FALSE,
    hjust = 0,
    vjust = 1,
    size = 3.8,
    label.size = 0.25,
    label.padding = grid::unit(0.20, "lines"),
    fill = "white",
    colour = "black"
  ) +
  
  # Keep x/y scales identical
  coord_equal(
    xlim = c(0, 210),
    ylim = c(0, 210),
    expand = FALSE
  ) +
  
  # Use your existing season colour definitions
  scale_colour_manual(
    values = season_cols
  ) +
  
  labs(
    title =
      "Agreement between PlanetScope validation lines and VedgeSat vegetation edges",
    
    subtitle =
      "Points on the dashed line indicate perfect agreement; greater distance from the line indicates greater positional error",
    
    x =
      "Validated vegetation-edge distance along transect (m)",
    
    y =
      "VedgeSat vegetation-edge distance along transect (m)",
    
    caption =
      "RMSE represents overall positional error. Positive bias indicates that VedgeSat distances were generally larger than validation distances."
  ) +
  
  theme_bw(base_size = 12) +
  
  theme(
    # Facet header
    strip.background = element_rect(
      fill = "grey90",
      colour = "grey50"
    ),
    
    strip.text = element_text(
      face = "bold",
      size = 12
    ),
    
    # Figure text
    plot.title = element_text(
      face = "bold",
      size = 17
    ),
    
    plot.subtitle = element_text(
      size = 10.5,
      margin = margin(b = 8)
    ),
    
    plot.caption = element_text(
      size = 9.5,
      hjust = 0,
      margin = margin(t = 8)
    ),
    
    axis.title = element_text(
      size = 12
    ),
    
    axis.text = element_text(
      size = 10
    ),
    
    # Grid
    panel.grid.major = element_line(
      colour = "grey88",
      linewidth = 0.4
    ),
    
    panel.grid.minor = element_blank(),
    
    # Season already identified by facet labels
    legend.position = "none",
    
    plot.margin = margin(
      t = 10,
      r = 12,
      b = 10,
      l = 10
    )
  )


print(fig1)


ggsave(
  file.path(FIG_DIR, "Fig1_scatter_agreement_by_season_FINAL.png"),
  fig1,
  width = 11,
  height = 10,
  dpi = 300,
  bg = "white"
)

# =========================================================
# FIGURE 2 — Level 3: Season overall
# =========================================================

season_long <- season_metrics %>%
  select(season, rmse, mae, median_abs_error, bias) %>%
  pivot_longer(
    cols = c(rmse, mae, median_abs_error, bias),
    names_to = "metric",
    values_to = "value"
  ) %>%
  mutate(
    metric = factor(
      metric,
      levels = c("rmse", "mae", "median_abs_error", "bias"),
      labels = c("RMSE", "MAE", "MedAE", "Bias")
    )
  )

season_bar <- ggplot(season_long, aes(x = season, y = value, fill = season)) +
  geom_col(width = 0.7) +
  facet_wrap(~metric, scales = "free_y", nrow = 1) +
  scale_fill_manual(values = season_cols) +
  labs(
    title = "Overall validation performance by season",
    x = "Season",
    y = "Metric value (m)"
  ) +
  theme_minimal(base_size = 12) +
  theme(
    legend.position = "none",
    panel.grid.minor = element_blank(),
    plot.title = element_text(face = "bold")
  )

print(season_bar)

ggsave(file.path(FIG_DIR, "Fig2_overall_season_metrics.png"), season_bar,
       width = 13, height = 4.5, dpi = 300)

# =========================================================
# FIGURE 3 — Level 2: Vegetation group × Season
# =========================================================

vgroup_rmse <- ggplot(vclass_season, aes(x = season, y = rmse, fill = vgroup)) +
  geom_col(position = position_dodge(width = 0.8), width = 0.7) +
  scale_fill_manual(values = veg_cols) +
  labs(
    title = "RMSE by vegetation group and season",
    x = "Season",
    y = "RMSE (m)",
    fill = "Vegetation group"
  ) +
  theme_minimal(base_size = 12) +
  theme(
    legend.position = "bottom",
    panel.grid.minor = element_blank(),
    plot.title = element_text(face = "bold")
  )

print(vgroup_rmse)

ggsave(file.path(FIG_DIR, "Fig3_vgroup_season_rmse.png"), vgroup_rmse,
       width = 10, height = 6, dpi = 300)

vgroup_mae <- ggplot(vclass_season, aes(x = season, y = mae, fill = vgroup)) +
  geom_col(position = position_dodge(width = 0.8), width = 0.7) +
  scale_fill_manual(values = veg_cols) +
  labs(
    title = "MAE by vegetation group and season",
    x = "Season",
    y = "MAE (m)",
    fill = "Vegetation group"
  ) +
  theme_minimal(base_size = 12) +
  theme(
    legend.position = "bottom",
    panel.grid.minor = element_blank(),
    plot.title = element_text(face = "bold")
  )

print(vgroup_mae)

ggsave(file.path(FIG_DIR, "Fig4_vgroup_season_mae.png"), vgroup_mae,
       width = 10, height = 6, dpi = 300)

# ---------------------------------------------------------
# FIGURE 4b — Median absolute error by vegetation group × season
# ---------------------------------------------------------
vgroup_medae <- ggplot(
  vclass_season,
  aes(x = season, y = median_abs_error, fill = vgroup)
) +
  geom_col(position = position_dodge(width = 0.8), width = 0.7) +
  scale_fill_manual(values = veg_cols) +
  labs(
    title = "Median absolute error by vegetation group and season",
    x = "Season",
    y = "Median absolute error (m)",
    fill = "Vegetation group"
  ) +
  theme_minimal(base_size = 12) +
  theme(
    legend.position = "bottom",
    panel.grid.minor = element_blank(),
    plot.title = element_text(face = "bold")
  )

print(vgroup_medae)

ggsave(
  file.path(FIG_DIR, "Fig4b_vgroup_season_median_absolute_error.png"),
  vgroup_medae,
  width = 10,
  height = 6,
  dpi = 300
)

vgroup_bias <- ggplot(vclass_season, aes(x = season, y = bias, fill = vgroup)) +
  geom_col(position = position_dodge(width = 0.8), width = 0.7) +
  geom_hline(yintercept = 0, linetype = "dashed") +
  scale_fill_manual(values = veg_cols) +
  labs(
    title = "Bias by vegetation group and season",
    x = "Season",
    y = "Bias (m)",
    fill = "Vegetation group"
  ) +
  theme_minimal(base_size = 12) +
  theme(
    legend.position = "bottom",
    panel.grid.minor = element_blank(),
    plot.title = element_text(face = "bold")
  )

print(vgroup_bias)

ggsave(file.path(FIG_DIR, "Fig5_vgroup_season_bias.png"), vgroup_bias,
       width = 10, height = 6, dpi = 300)

# Optional line plot for trend
vgroup_line <- ggplot(vclass_season, aes(x = season, y = rmse, group = vgroup, colour = vgroup)) +
  geom_line(linewidth = 1) +
  geom_point(size = 3) +
  scale_colour_manual(values = veg_cols) +
  labs(
    title = "Seasonal RMSE trend by vegetation group",
    x = "Season",
    y = "RMSE (m)",
    colour = "Vegetation group"
  ) +
  theme_minimal(base_size = 12) +
  theme(
    legend.position = "bottom",
    panel.grid.minor = element_blank(),
    plot.title = element_text(face = "bold")
  )

print(vgroup_line)

ggsave(file.path(FIG_DIR, "Fig6_vgroup_season_rmse_line.png"), vgroup_line,
       width = 9, height = 5.5, dpi = 300)

# =========================================================
# FIGURE 7 — Level 1: Zone × Season
# =========================================================

zone_rmse_heat <- ggplot(zone_season, aes(x = season, y = zone, fill = rmse)) +
  geom_tile(color = "white") +
  geom_text(aes(label = round(rmse, 1)), size = 3) +
  scale_fill_gradient(low = "#deebf7", high = "#08519c") +
  labs(
    title = "RMSE by zone and season",
    x = "Season",
    y = "Zone",
    fill = "RMSE (m)"
  ) +
  theme_minimal(base_size = 12) +
  theme(
    panel.grid = element_blank(),
    plot.title = element_text(face = "bold")
  )

print(zone_rmse_heat)

ggsave(file.path(FIG_DIR, "Fig7_zone_season_rmse_heatmap.png"), zone_rmse_heat,
       width = 8, height = 5, dpi = 300)

zone_mae_heat <- ggplot(zone_season, aes(x = season, y = zone, fill = mae)) +
  geom_tile(color = "white") +
  geom_text(aes(label = round(mae, 1)), size = 3) +
  scale_fill_gradient(low = "#fee8c8", high = "#e34a33") +
  labs(
    title = "MAE by zone and season",
    x = "Season",
    y = "Zone",
    fill = "MAE (m)"
  ) +
  theme_minimal(base_size = 12) +
  theme(
    panel.grid = element_blank(),
    plot.title = element_text(face = "bold")
  )

print(zone_mae_heat)

ggsave(file.path(FIG_DIR, "Fig8_zone_season_mae_heatmap.png"), zone_mae_heat,
       width = 8, height = 5, dpi = 300)

# ---------------------------------------------------------
# FIGURE 8b — Median absolute error by zone × season
# ---------------------------------------------------------
zone_medae_heat <- ggplot(
  zone_season,
  aes(x = season, y = zone, fill = median_abs_error)
) +
  geom_tile(color = "white") +
  geom_text(aes(label = round(median_abs_error, 1)), size = 3) +
  scale_fill_gradient(low = "#f7fcf5", high = "#238b45") +
  labs(
    title = "Median absolute error by zone and season",
    x = "Season",
    y = "Zone",
    fill = "MedAE (m)"
  ) +
  theme_minimal(base_size = 12) +
  theme(
    panel.grid = element_blank(),
    plot.title = element_text(face = "bold")
  )

print(zone_medae_heat)

ggsave(
  file.path(FIG_DIR, "Fig8b_zone_season_median_absolute_error_heatmap.png"),
  zone_medae_heat,
  width = 8,
  height = 5,
  dpi = 300
)
#==============================================================================
# FIGURE 9 — Zone × Season Bias
#==============================================================================
bias_limit <- max(
  abs(zone_season$bias),
  na.rm = TRUE
)

zone_bias_heat <- ggplot(
  zone_season,
  aes(
    x = season,
    y = zone,
    fill = bias
  )
) +
  geom_tile(
    color = "white"
  ) +
  geom_text(
    aes(
      label = round(bias, 1)
    ),
    size = 3
  ) +
  scale_fill_gradient2(
    low = "#2166ac",
    mid = "white",
    high = "#b2182b",
    midpoint = 0,
    limits = c(
      -bias_limit,
      bias_limit
    ),
    name = "Bias (m)"
  ) +
  labs(
    title = "Bias by zone and season",
    x = "Season",
    y = "Zone"
  ) +
  theme_minimal(base_size = 12) +
  theme(
    panel.grid = element_blank(),
    plot.title = element_text(
      face = "bold"
    )
  )

print(zone_bias_heat)

ggsave(file.path(FIG_DIR, "Fig9_zone_season_bias_heatmap.png"), zone_bias_heat,
       width = 8, height = 5, dpi = 300)

# =========================================================
# OPTIONAL — Sample size by vegetation group
# =========================================================

sample_size <- per_transect %>%
  filter(!is.na(ve_dist), !is.na(vl_dist)) %>%
  filter(vgroup %in% c("Mangrove", "Agriculture", "Mixed vegetation")) %>%
  group_by(vgroup) %>%
  summarise(n = n(), .groups = "drop")

sample_bar <- ggplot(sample_size, aes(x = vgroup, y = n, fill = vgroup)) +
  geom_col(width = 0.7) +
  geom_text(aes(label = n), vjust = -0.3) +
  scale_fill_manual(values = veg_cols) +
  labs(
    title = "Final sample size by vegetation group",
    x = "Vegetation group",
    y = "Number of valid VE–VL pairs"
  ) +
  theme_minimal(base_size = 12) +
  theme(
    legend.position = "none",
    panel.grid.minor = element_blank(),
    plot.title = element_text(face = "bold")
  )

print(sample_bar)

ggsave(file.path(FIG_DIR, "Fig10_sample_size_by_vgroup.png"), sample_bar,
       width = 7, height = 5, dpi = 300)

#FINDING ERROR IN WET SEASON (outliers)
wet_outliers <- per_transect %>%
  filter(
    valid_pair,
    season == "Wet"
  ) %>%
  mutate(
    abs_error = abs(error)
  ) %>%
  filter(
    abs_error >= quantile(
      abs_error,
      0.95,
      na.rm = TRUE
    )
  )

wet_outliers %>%
  count(zone, sort = TRUE)

wet_zone_plot <- per_transect %>%
  filter(
    valid_pair,
    season == "Wet"
  ) %>%
  ggplot(
    aes(
      x = vl_dist,
      y = ve_dist,
      colour = zone
    )
  ) +
  geom_point(
    alpha = 0.4,
    size = 1
  ) +
  geom_abline(
    slope = 1,
    intercept = 0,
    linetype = "dashed",
    colour = "black"
  ) +
  coord_equal(
    xlim = c(0, 210),
    ylim = c(0, 210),
    expand = FALSE
  ) +
  labs(
    title = "Final Wet-season agreement by zone",
    x = "Validated distance along transect (m)",
    y = "VedgeSat distance along transect (m)",
    colour = "Zone"
  ) +
  theme_minimal(base_size = 12)

wet_zone_plot

#identify the Z01 transects creating that structure.
wet_z01_arc <- per_transect %>%
  filter(
    valid_pair,
    season == "Wet",
    zone == "Z01",
    vl_dist >= 55,
    vl_dist <= 155,
    ve_dist <= 65,
    error <= -20
  ) %>%
  select(
    TransectID,
    zone,
    vl_dist,
    ve_dist,
    error
  ) %>%
  arrange(TransectID)

wet_z01_arc

nrow(wet_z01_arc)
#see whether most of them form one continuous transect sequence.
wet_z01_arc_runs <- wet_z01_arc %>%
  mutate(
    transect_num = as.integer(
      sub("Z01_", "", TransectID)
    )
  ) %>%
  arrange(transect_num) %>%
  mutate(
    run_id = cumsum(
      c(TRUE, diff(transect_num) != 1)
    )
  ) %>%
  group_by(run_id) %>%
  summarise(
    start_transect = first(TransectID),
    end_transect = last(TransectID),
    n = n(),
    mean_error = mean(error),
    min_error = min(error),
    .groups = "drop"
  ) %>%
  arrange(desc(n))

wet_z01_arc_runs



# =========================================================
# DUAL-VALIDATION COMPARISON
# Manual PlanetScope vs automated NDVI >= 0.30 PlanetScope
# =========================================================
# Interpretation rule:
#   Manual PlanetScope = PRIMARY validation reference.
#   Automated NDVI 0.30 = SECONDARY sensitivity / robustness reference.
#
# For the fairest direct comparison, the PAIRED figures below use only
# transect-season observations that have a valid VE-VL pair under BOTH
# validation methods. This keeps the comparison sample identical, so
# differences reflect validation-line definition rather than changing n.

# -----------------------------
# Read automated-validation outputs
# -----------------------------
auto_per_transect <- read_csv(file.path(AUTO_DIR, "per_transect_distances_all_seasons.csv"))
auto_zone_season <- read_csv(file.path(AUTO_DIR, "zone_season_metrics.csv"))
auto_vclass_season <- read_csv(file.path(AUTO_DIR, "vclass_season_metrics.csv"))
auto_season_metrics <- read_csv(file.path(AUTO_DIR, "season_metrics.csv"))

# Apply the same labels/factor order as the primary/manual dataset
auto_per_transect <- auto_per_transect %>%
  mutate(
    season = factor(season, levels = season_levels, labels = season_labels),
    zone = factor(zone, levels = c("Z01", "Z02", "Z03", "Z04", "Z05", "Z06")),
    vgroup = factor(
      vgroup,
      levels = c("mangrove", "agriculture", "mixed_vegetation"),
      labels = c("Mangrove", "Agriculture", "Mixed vegetation")
    )
  )

auto_zone_season <- auto_zone_season %>%
  mutate(
    season = factor(season, levels = season_levels, labels = season_labels),
    zone = factor(zone, levels = c("Z01", "Z02", "Z03", "Z04", "Z05", "Z06"))
  )

auto_vclass_season <- auto_vclass_season %>%
  mutate(
    season = factor(season, levels = season_levels, labels = season_labels),
    vgroup = factor(
      vgroup,
      levels = c("mangrove", "agriculture", "mixed_vegetation"),
      labels = c("Mangrove", "Agriculture", "Mixed vegetation")
    )
  )

auto_season_metrics <- auto_season_metrics %>%
  mutate(season = factor(season, levels = season_levels, labels = season_labels))

method_cols <- c(
  "Manual PlanetScope" = "#333333",
  "Automated NDVI 0.30" = "#E69F00"
)

# =========================================================
# A. FULL-SET comparison (each method uses its own valid-pair sample)
# Useful for descriptive reporting, but n may differ between methods.
# =========================================================
season_full_compare <- bind_rows(
  season_metrics %>% mutate(validation_method = "Manual PlanetScope"),
  auto_season_metrics %>% mutate(validation_method = "Automated NDVI 0.30")
) %>%
  mutate(
    validation_method = factor(
      validation_method,
      levels = c("Manual PlanetScope", "Automated NDVI 0.30")
    )
  )

write_csv(
  season_full_compare,
  file.path(COMPARE_DIR, "comparison_FULL_season_metrics_by_method.csv")
)

season_full_long <- season_full_compare %>%
  select(season, validation_method, rmse, mae, median_abs_error, bias, n) %>%
  pivot_longer(
    cols = c(rmse, mae, median_abs_error, bias),
    names_to = "metric",
    values_to = "value"
  ) %>%
  mutate(
    metric = factor(metric,
                    levels = c("rmse", "mae", "median_abs_error", "bias"),
                    labels = c("RMSE", "MAE", "MedAE", "Bias"))
  )

comp_full_season <- ggplot(
  season_full_long,
  aes(x = season, y = value, colour = validation_method, group = validation_method)
) +
  geom_line(linewidth = 0.9) +
  geom_point(size = 3) +
  geom_hline(
    data = data.frame(metric = factor("Bias", levels = c("RMSE", "MAE", "MedAE", "Bias")), y = 0),
    aes(yintercept = y),
    inherit.aes = FALSE,
    linetype = "dashed",
    colour = "grey40"
  ) +
  facet_wrap(~metric, scales = "free_y", nrow = 1) +
  scale_colour_manual(values = method_cols) +
  labs(
    title = "Validation-method comparison by season (full available samples)",
    subtitle = "Each validation method uses its own available VE–VL pairs",
    x = "Season",
    y = "Metric value (m)",
    colour = "Validation method"
  ) +
  theme_minimal(base_size = 12) +
  theme(
    legend.position = "bottom",
    panel.grid.minor = element_blank(),
    plot.title = element_text(face = "bold")
  )

print(comp_full_season)

ggsave(
  file.path(COMPARE_DIR, "Comp_FULL_season_metrics_manual_vs_auto.png"),
  comp_full_season,
  width = 11,
  height = 4.8,
  dpi = 300
)

# Full-set n table: important because the two VL methods may intersect
# different numbers of transects.
full_n_compare <- season_full_compare %>%
  select(season, validation_method, n)

write_csv(
  full_n_compare,
  file.path(COMPARE_DIR, "comparison_FULL_valid_pairs_by_season.csv")
)

# =========================================================
# B. PAIRED COMMON-SAMPLE comparison (recommended for thesis comparison)
# =========================================================
manual_pair <- per_transect %>%
  transmute(
    TransectID,
    season = as.character(season),
    zone = as.character(zone),
    vgroup = as.character(vgroup),
    ve_dist_manual = ve_dist,
    vl_dist_manual = vl_dist,
    error_manual = error,
    valid_pair_manual = valid_pair
  )

auto_pair <- auto_per_transect %>%
  transmute(
    TransectID,
    season = as.character(season),
    ve_dist_auto = ve_dist,
    vl_dist_auto = vl_dist,
    error_auto = error,
    valid_pair_auto = valid_pair
  )

paired_all <- manual_pair %>%
  inner_join(auto_pair, by = c("TransectID", "season"))

# Diagnostic: VE distance should be effectively identical because only the
# validation-line method should change between the two runs.
max_ve_difference <- max(
  abs(paired_all$ve_dist_manual - paired_all$ve_dist_auto),
  na.rm = TRUE
)
message("Maximum absolute VE-distance difference between runs: ", max_ve_difference, " m")

if (is.finite(max_ve_difference) && max_ve_difference > 1e-6) {
  warning(
    "VE distances differ between manual and automated runs. Check that the same ",
    "VedgeSat layers and master transects were used in both runs."
  )
}

paired_common <- paired_all %>%
  filter(
    valid_pair_manual,
    valid_pair_auto,
    !is.na(error_manual),
    !is.na(error_auto)
  ) %>%
  mutate(
    season = factor(season, levels = season_labels),
    zone = factor(zone, levels = c("Z01", "Z02", "Z03", "Z04", "Z05", "Z06")),
    vgroup = factor(
      vgroup,
      levels = c("Mangrove", "Agriculture", "Mixed vegetation")
    )
  )

write_csv(
  paired_common,
  file.path(COMPARE_DIR, "comparison_PAIRED_common_transects.csv")
)

paired_errors <- bind_rows(
  paired_common %>%
    transmute(
      TransectID, season, zone, vgroup,
      method_key = "manual",
      validation_method = "Manual PlanetScope",
      error = error_manual
    ),
  paired_common %>%
    transmute(
      TransectID, season, zone, vgroup,
      method_key = "auto",
      validation_method = "Automated NDVI 0.30",
      error = error_auto
    )
) %>%
  mutate(
    validation_method = factor(
      validation_method,
      levels = c("Manual PlanetScope", "Automated NDVI 0.30")
    )
  )

summarise_validation_metrics <- function(data, grouping_vars) {
  data %>%
    group_by(across(all_of(grouping_vars)), method_key, validation_method) %>%
    summarise(
      rmse = sqrt(mean(error^2, na.rm = TRUE)),
      mae = mean(abs(error), na.rm = TRUE),
      median_abs_error = median(abs(error), na.rm = TRUE),
      bias = mean(error, na.rm = TRUE),
      median_error = median(error, na.rm = TRUE),
      n = sum(!is.na(error)),
      .groups = "drop"
    )
}

paired_season_metrics <- summarise_validation_metrics(
  paired_errors,
  c("season")
)

paired_zone_metrics <- summarise_validation_metrics(
  paired_errors,
  c("zone", "season")
)

paired_vgroup_metrics <- paired_errors %>%
  filter(!is.na(vgroup)) %>%
  summarise_validation_metrics(c("vgroup", "season"))

write_csv(
  paired_season_metrics,
  file.path(COMPARE_DIR, "comparison_PAIRED_season_metrics.csv")
)
write_csv(
  paired_zone_metrics,
  file.path(COMPARE_DIR, "comparison_PAIRED_zone_season_metrics.csv")
)
write_csv(
  paired_vgroup_metrics,
  file.path(COMPARE_DIR, "comparison_PAIRED_vgroup_season_metrics.csv")
)

# Common-sample n by season (same n for both methods by construction)
paired_n_by_season <- paired_common %>%
  count(season, name = "n_common_pairs")
write_csv(
  paired_n_by_season,
  file.path(COMPARE_DIR, "comparison_PAIRED_n_by_season.csv")
)

# =========================================================
# COMP 1 — PAIRED season-level RMSE / MAE / Bias
# =========================================================
paired_season_long <- paired_season_metrics %>%
  select(season, validation_method, rmse, mae, median_abs_error, bias) %>%
  pivot_longer(
    cols = c(rmse, mae, median_abs_error, bias),
    names_to = "metric",
    values_to = "value"
  ) %>%
  mutate(
    metric = factor(metric,
                    levels = c("rmse", "mae", "median_abs_error", "bias"),
                    labels = c("RMSE", "MAE", "MedAE", "Bias"))
  )

comp1_paired_season <- ggplot(
  paired_season_long,
  aes(x = season, y = value, colour = validation_method, group = validation_method)
) +
  geom_line(linewidth = 1) +
  geom_point(size = 3) +
  facet_wrap(~metric, scales = "free_y", nrow = 1) +
  scale_colour_manual(values = method_cols) +
  labs(
    title = "Sensitivity of seasonal VedgeSat metrics to validation method",
    subtitle = "Common transect-season pairs only",
    x = "Season",
    y = "Metric value (m)",
    colour = "Validation method"
  ) +
  theme_minimal(base_size = 12) +
  theme(
    legend.position = "bottom",
    panel.grid.minor = element_blank(),
    plot.title = element_text(face = "bold")
  )

print(comp1_paired_season)
ggsave(
  file.path(COMPARE_DIR, "Comp1_PAIRED_season_metrics_manual_vs_auto.png"),
  comp1_paired_season,
  width = 11,
  height = 4.8,
  dpi = 300
)

# =========================================================
# COMP 2 — PAIRED vegetation-group RMSE
# =========================================================
comp2_vgroup_rmse <- ggplot(
  paired_vgroup_metrics,
  aes(x = season, y = rmse, colour = validation_method, group = validation_method)
) +
  geom_line(linewidth = 0.9) +
  geom_point(size = 2.8) +
  facet_wrap(~vgroup, nrow = 1) +
  scale_colour_manual(values = method_cols) +
  labs(
    title = "RMSE sensitivity to validation method by vegetation group",
    subtitle = "Common transect-season pairs only",
    x = "Season",
    y = "RMSE (m)",
    colour = "Validation method"
  ) +
  theme_minimal(base_size = 12) +
  theme(
    legend.position = "bottom",
    panel.grid.minor = element_blank(),
    plot.title = element_text(face = "bold")
  )

print(comp2_vgroup_rmse)
ggsave(
  file.path(COMPARE_DIR, "Comp2_PAIRED_vgroup_RMSE_manual_vs_auto.png"),
  comp2_vgroup_rmse,
  width = 11,
  height = 4.8,
  dpi = 300
)

# =========================================================
# COMP 2b — PAIRED vegetation-group Median Absolute Error
# =========================================================
comp2b_vgroup_medae <- ggplot(
  paired_vgroup_metrics,
  aes(
    x = season,
    y = median_abs_error,
    colour = validation_method,
    group = validation_method
  )
) +
  geom_line(linewidth = 0.9) +
  geom_point(size = 2.8) +
  facet_wrap(~vgroup, nrow = 1) +
  scale_colour_manual(values = method_cols) +
  labs(
    title = "Median absolute error sensitivity to validation method by vegetation group",
    subtitle = "Common transect-season pairs only",
    x = "Season",
    y = "Median absolute error (m)",
    colour = "Validation method"
  ) +
  theme_minimal(base_size = 12) +
  theme(
    legend.position = "bottom",
    panel.grid.minor = element_blank(),
    plot.title = element_text(face = "bold")
  )

print(comp2b_vgroup_medae)

ggsave(
  file.path(COMPARE_DIR, "Comp2b_PAIRED_vgroup_MedAE_manual_vs_auto.png"),
  comp2b_vgroup_medae,
  width = 11,
  height = 4.8,
  dpi = 300
)

# =========================================================
# COMP 3 — PAIRED vegetation-group Bias
# =========================================================
comp3_vgroup_bias <- ggplot(
  paired_vgroup_metrics,
  aes(x = season, y = bias, colour = validation_method, group = validation_method)
) +
  geom_hline(yintercept = 0, linetype = "dashed", colour = "grey40") +
  geom_line(linewidth = 0.9) +
  geom_point(size = 2.8) +
  facet_wrap(~vgroup, nrow = 1) +
  scale_colour_manual(values = method_cols) +
  labs(
    title = "Bias sensitivity to validation method by vegetation group",
    subtitle = "Common transect-season pairs only",
    x = "Season",
    y = "Bias (m)",
    colour = "Validation method"
  ) +
  theme_minimal(base_size = 12) +
  theme(
    legend.position = "bottom",
    panel.grid.minor = element_blank(),
    plot.title = element_text(face = "bold")
  )

print(comp3_vgroup_bias)
ggsave(
  file.path(COMPARE_DIR, "Comp3_PAIRED_vgroup_Bias_manual_vs_auto.png"),
  comp3_vgroup_bias,
  width = 11,
  height = 4.8,
  dpi = 300
)

# =========================================================
# COMP 4 — PAIRED zone RMSE, absolute values for both methods
# =========================================================
rmse_limits <- range(paired_zone_metrics$rmse, na.rm = TRUE)

comp4_zone_rmse_methods <- ggplot(
  paired_zone_metrics,
  aes(x = season, y = zone, fill = rmse)
) +
  geom_tile(colour = "white") +
  geom_text(aes(label = round(rmse, 1)), size = 3) +
  facet_wrap(~validation_method, ncol = 1) +
  scale_fill_gradient(
    low = "#deebf7",
    high = "#08519c",
    limits = rmse_limits
  ) +
  labs(
    title = "Zone-level RMSE under manual and automated validation",
    subtitle = "Common transect-season pairs; identical colour scale",
    x = "Season",
    y = "Zone",
    fill = "RMSE (m)"
  ) +
  theme_minimal(base_size = 12) +
  theme(
    panel.grid = element_blank(),
    plot.title = element_text(face = "bold")
  )

print(comp4_zone_rmse_methods)
ggsave(
  file.path(COMPARE_DIR, "Comp4_PAIRED_zone_RMSE_manual_vs_auto.png"),
  comp4_zone_rmse_methods,
  width = 8.5,
  height = 8.5,
  dpi = 300
)

# =========================================================
# Difference tables: Automated minus Manual
# Positive delta RMSE/MAE = automated reference gives larger apparent error.
# Positive delta Bias = automated reference shifts bias in the positive direction.
# =========================================================
paired_zone_delta <- paired_zone_metrics %>%
  select(zone, season, method_key, rmse, mae, median_abs_error, bias, n) %>%
  pivot_wider(
    names_from = method_key,
    values_from = c(rmse, mae, median_abs_error, bias, n)
  ) %>%
  mutate(
    delta_rmse = rmse_auto - rmse_manual,
    delta_mae = mae_auto - mae_manual,
    delta_medae = median_abs_error_auto - median_abs_error_manual,
    delta_bias = bias_auto - bias_manual
  )

paired_season_delta <- paired_season_metrics %>%
  select(season, method_key, rmse, mae, median_abs_error, bias, n) %>%
  pivot_wider(
    names_from = method_key,
    values_from = c(rmse, mae, median_abs_error, bias, n)
  ) %>%
  mutate(
    delta_rmse = rmse_auto - rmse_manual,
    delta_mae = mae_auto - mae_manual,
    delta_medae = median_abs_error_auto - median_abs_error_manual,
    delta_bias = bias_auto - bias_manual
  )

paired_vgroup_delta <- paired_vgroup_metrics %>%
  select(vgroup, season, method_key, rmse, mae, median_abs_error, bias, n) %>%
  pivot_wider(
    names_from = method_key,
    values_from = c(rmse, mae, median_abs_error, bias, n)
  ) %>%
  mutate(
    delta_rmse = rmse_auto - rmse_manual,
    delta_mae = mae_auto - mae_manual,
    delta_medae = median_abs_error_auto - median_abs_error_manual,
    delta_bias = bias_auto - bias_manual
  )

write_csv(
  paired_zone_delta,
  file.path(COMPARE_DIR, "comparison_PAIRED_zone_deltas_auto_minus_manual.csv")
)
write_csv(
  paired_season_delta,
  file.path(COMPARE_DIR, "comparison_PAIRED_season_deltas_auto_minus_manual.csv")
)
write_csv(
  paired_vgroup_delta,
  file.path(COMPARE_DIR, "comparison_PAIRED_vgroup_deltas_auto_minus_manual.csv")
)

# =========================================================
# COMP 5 — Delta RMSE heatmap (Automated - Manual)
# =========================================================
delta_rmse_limit <- max(abs(paired_zone_delta$delta_rmse), na.rm = TRUE)

comp5_delta_rmse <- ggplot(
  paired_zone_delta,
  aes(x = season, y = zone, fill = delta_rmse)
) +
  geom_tile(colour = "white") +
  geom_text(aes(label = round(delta_rmse, 1)), size = 3) +
  scale_fill_gradient2(
    low = "#2166ac",
    mid = "white",
    high = "#b2182b",
    midpoint = 0,
    limits = c(-delta_rmse_limit, delta_rmse_limit),
    name = expression(Delta * "RMSE (m)")
  ) +
  labs(
    title = "Change in RMSE under automated validation",
    subtitle = "Automated NDVI 0.30 minus manual PlanetScope; common pairs only",
    x = "Season",
    y = "Zone"
  ) +
  theme_minimal(base_size = 12) +
  theme(
    panel.grid = element_blank(),
    plot.title = element_text(face = "bold")
  )

print(comp5_delta_rmse)
ggsave(
  file.path(COMPARE_DIR, "Comp5_PAIRED_delta_RMSE_auto_minus_manual.png"),
  comp5_delta_rmse,
  width = 8,
  height = 5,
  dpi = 300
)

# =========================================================
# COMP 5b — Delta MedAE heatmap (Automated - Manual)
# =========================================================
delta_medae_limit <- max(
  abs(paired_zone_delta$delta_medae),
  na.rm = TRUE
)

comp5b_delta_medae <- ggplot(
  paired_zone_delta,
  aes(x = season, y = zone, fill = delta_medae)
) +
  geom_tile(colour = "white") +
  geom_text(aes(label = round(delta_medae, 1)), size = 3) +
  scale_fill_gradient2(
    low = "#2166ac",
    mid = "white",
    high = "#b2182b",
    midpoint = 0,
    limits = c(-delta_medae_limit, delta_medae_limit),
    name = expression(Delta * "MedAE (m)")
  ) +
  labs(
    title = "Change in median absolute error under automated validation",
    subtitle = "Automated NDVI 0.30 minus manual PlanetScope; common pairs only",
    x = "Season",
    y = "Zone"
  ) +
  theme_minimal(base_size = 12) +
  theme(
    panel.grid = element_blank(),
    plot.title = element_text(face = "bold")
  )

print(comp5b_delta_medae)

ggsave(
  file.path(COMPARE_DIR, "Comp5b_PAIRED_delta_MedAE_auto_minus_manual.png"),
  comp5b_delta_medae,
  width = 8,
  height = 5,
  dpi = 300
)

# =========================================================
# COMP 6 — Delta Bias heatmap (Automated - Manual)
# =========================================================
delta_bias_limit <- max(abs(paired_zone_delta$delta_bias), na.rm = TRUE)

comp6_delta_bias <- ggplot(
  paired_zone_delta,
  aes(x = season, y = zone, fill = delta_bias)
) +
  geom_tile(colour = "white") +
  geom_text(aes(label = round(delta_bias, 1)), size = 3) +
  scale_fill_gradient2(
    low = "#2166ac",
    mid = "white",
    high = "#b2182b",
    midpoint = 0,
    limits = c(-delta_bias_limit, delta_bias_limit),
    name = expression(Delta * "Bias (m)")
  ) +
  labs(
    title = "Change in bias under automated validation",
    subtitle = "Automated NDVI 0.30 minus manual PlanetScope; common pairs only",
    x = "Season",
    y = "Zone"
  ) +
  theme_minimal(base_size = 12) +
  theme(
    panel.grid = element_blank(),
    plot.title = element_text(face = "bold")
  )

print(comp6_delta_bias)
ggsave(
  file.path(COMPARE_DIR, "Comp6_PAIRED_delta_Bias_auto_minus_manual.png"),
  comp6_delta_bias,
  width = 8,
  height = 5,
  dpi = 300
)

# =========================================================
# Optional console summaries for Results writing
# =========================================================
cat("\n=== PAIRED seasonal validation-method comparison ===\n")
print(paired_season_metrics)

cat("\n=== PAIRED seasonal deltas: automated minus manual ===\n")
print(paired_season_delta)

cat("\n=== Common paired sample size by season ===\n")
print(paired_n_by_season)

cat("\nComparison figures and tables saved in:\n", COMPARE_DIR, "\n")

