# ==============================================================================
# 05b_futuristic-fiction_report.R
#
# PURPOSE
#   Turns the exploratory findings from 05a_futuristic-fiction_exploratory.qmd
#   into a standalone, interactive HTML report.
#
# HOW IT WORKS
#   R does all the statistics; JavaScript does all the drawing. This script:
#     1. prepares the data (using the same shared functions as the notebook)
#     2. computes every summary table the report needs
#     3. converts each table to JSON
#     4. pastes that JSON into an HTML template that contains the charts
#
#   The result is ONE self-contained .html file with no dependencies -- it can
#   be emailed, put on a website, or opened offline, and the charts still work.
#
# COMPANION FILES (all beside this script, under code/experimental/)
#   R/futuristic_fiction_utils.R              shared data-prep functions
#   templates/futuristic-fiction-report.html  the page, with data placeholders
#
# HOW TO RUN
#   From the project root, either:
#     source("code/experimental/05b_futuristic-fiction_report.R")
#   or from a terminal:
#     Rscript code/experimental/05b_futuristic-fiction_report.R
#
# OUTPUT
#   output/futuristic-fiction-report.html
# ==============================================================================

library(tidyverse)
library(here)


# ==============================================================================
# 1. SETTINGS
#    Everything adjustable is in this one block. These match the notebook's
#    settings so the report says the same thing the exploration found.
# ==============================================================================

# Folder holding this script and its companion files (R/ and templates/).
# If you move this script, this is the only path you need to change.
code_dir <- here("code", "experimental")

settings <- list(

  # ---- Paths ---------------------------------------------------------------
  data_path     = here("data", "post45_books", "original", "futuristic_fiction.csv"),
  template_path = file.path(code_dir, "templates", "futuristic-fiction-report.html"),
  output_path   = here("output", "futuristic-fiction-report.html"),

  # ---- Analysis choices (must match 05a) -----------------------------------
  first_decade = 1950,   # earliest release decade to include
  min_medium_n = 50,     # a medium needs this many works to be included
  min_cell_n   = 10,     # a decade x medium cell needs this many for a median
  min_slope_n  = 60,     # a medium needs this many works to get a trend line
  current_year = 2026,   # "now", for deciding which futures have expired

  # ---- Report presentation -------------------------------------------------
  # How much of each work's "predictions" note to show in a tooltip.
  tooltip_chars = 220,

  # The calendar chart plots every work, but imagined years run from 1950 to
  # 100 trillion, so a single linear axis is impossible. The axis is linear up
  # to `calendar_break` and logarithmically compressed beyond it, with a visible
  # break. This is the point at which the switch happens.
  calendar_from  = 1950,
  calendar_break = 2150,

  # One colour per medium. Defined here so that R and the HTML template can
  # never disagree about which colour means which medium -- the script passes
  # this palette straight into the page.
  palette = c(
    "prose fiction" = "#2f5c8f",   # ink blue
    "film"          = "#c4761f",   # ochre
    "television"    = "#3f8f7f",   # teal
    "video game"    = "#a8386b",   # magenta
    "comics"        = "#7a8f3a"    # olive
  )
)

# The shared helper functions. Sourced after `settings` so that the folder
# location is defined in exactly one place, above.
source(file.path(code_dir, "R", "futuristic_fiction_utils.R"))


# ==============================================================================
# 2. PREPARE THE DATA
#    Identical pipeline to the notebook, because it calls the same functions.
# ==============================================================================

message("\n--- Preparing data ---")

ff_all <- ff_load_raw(settings$data_path) |>
  ff_add_horizon()

ff_analysis <- ff_build_analysis_set(
  ff_all,
  first_decade = settings$first_decade,
  min_medium_n = settings$min_medium_n
)

# Recover the drop counts that ff_build_analysis_set() recorded, so the report
# can state plainly what was excluded rather than quietly hiding it.
drops <- attr(ff_analysis, "ff_drops")


# ==============================================================================
# 3. COMPUTE THE SUMMARY TABLES
#    One block per chart, so it is obvious which numbers feed which graphic.
# ==============================================================================

message("--- Computing summaries ---")

# ---- 3a. Every individual work (Chart 1: The Reach, Chart 4: The Calendar) --
# The Data Humanism principle at work: the report does not send the reader a
# set of averages, it sends every one of the 2,325 works so each can be
# hovered, read, and recognised as a specific thing somebody made.
works_payload <- ff_analysis |>
  transmute(
    ti = title,
    cr = coalesce(creator, "unknown"),
    rl = released,
    ys = year_set,
    hz = horizon,
    md = medium,
    gn = coalesce(genre, ""),
    # Truncate the annotation text so the HTML file stays a reasonable size.
    pr = str_trunc(coalesce(predictions, notes, ""), settings$tooltip_chars)
  ) |>
  arrange(rl)

# ---- 3b. Median horizon by decade, pooled and per medium (Charts 1 and 2) ---
decade_all <- ff_median_horizon(ff_analysis, release_decade) |>
  rename(dec = release_decade)

decade_medium <- ff_median_horizon(
  ff_analysis, medium, release_decade,
  min_n = settings$min_cell_n
) |>
  rename(dec = release_decade, md = medium) |>
  # Drop the cells that were too small to earn a median, rather than sending
  # nulls the chart would have to special-case.
  filter(!is.na(median_horizon))

# ---- 3c. Per-medium trend lines (Chart 2: Five Verdicts) -------------------
slopes <- ff_slopes_by_medium(ff_analysis, min_n = settings$min_slope_n) |>
  rename(md = medium) |>
  mutate(
    # A short human verdict for each medium, derived from the confidence
    # interval rather than from a p-value threshold.
    verdict = case_when(
      ci_high < 0 ~ "contracting",
      ci_low  > 0 ~ "expanding",
      TRUE        ~ "no change detected"
    )
  ) |>
  arrange(pct_per_year)

# ---- 3d. Medium composition by decade (Chart 3: Who Was Dreaming) ----------
composition <- ff_composition(ff_analysis) |>
  rename(dec = release_decade, md = medium)

# ---- 3e. The two pooled models (stated in the text) -----------------------
pooled_models <- ff_pooled_models(ff_analysis)

pooled <- bind_rows(
  ff_slope_row(pooled_models$pooled,      "no control"),
  ff_slope_row(pooled_models$with_medium, "controlling for medium")
)

# ---- 3f. Expired futures (Chart 4: The Calendar) --------------------------
expired_summary <- ff_analysis |>
  summarise(
    n           = n(),
    n_expired   = sum(year_set <= settings$current_year),
    pct_expired = 100 * mean(year_set <= settings$current_year),
    median_lead = median(horizon[year_set <= settings$current_year])
  )

# How many works sit beyond the calendar chart's linear section? Every work is
# still drawn -- these land in the compressed tail -- but the chart should be
# able to say how many readers are looking at on a squeezed scale.
calendar_beyond <- sum(ff_analysis$year_set > settings$calendar_break)

# ---- 3g. Round-number clustering (stated on Chart 4) ---------------------
round_numbers <- ff_analysis |>
  summarise(
    pct_ends_0  = 100 * mean(year_set %% 10  == 0),
    pct_ends_00 = 100 * mean(year_set %% 100 == 0)
  )

# ---- 3h. Named deep-future works, for annotation on Chart 1 ---------------
# These are the works our exploration confirmed are real rather than errors.
# Labelling them by name is the point: they are the corpus's most ambitious
# imaginations, and an analysis that deleted them would have deleted its
# own best evidence.
deep_future <- ff_analysis |>
  slice_max(horizon, n = 3) |>
  transmute(ti = title, cr = creator, rl = released, hz = horizon, md = medium)


# ==============================================================================
# 4. ASSEMBLE THE JSON PAYLOAD
#    ff_to_json() converts a flat data frame to a JSON array of objects.
#    Every name here matches a {{TOKEN}} in the HTML template.
# ==============================================================================

message("--- Serialising to JSON ---")

# The palette needs to travel as a lookup object, not a table.
palette_json <- ff_to_json_object(as.list(settings$palette))

# Metadata: the numbers the report uses in its own prose, so no figure in the
# finished page is typed by hand.
meta <- list(
  n_file          = drops$n_start,
  n_analysis      = nrow(ff_analysis),
  n_no_year       = drops$n_no_year,
  n_too_old       = drops$n_too_old,
  n_rare_medium   = drops$n_rare_med,
  media_kept      = paste(drops$media_kept, collapse = ", "),
  first_decade    = settings$first_decade,
  current_year    = settings$current_year,
  min_cell_n      = settings$min_cell_n,
  calendar_from   = settings$calendar_from,
  calendar_break  = settings$calendar_break,
  cal_beyond      = calendar_beyond,
  n_expired       = expired_summary$n_expired,
  pct_expired     = round(expired_summary$pct_expired, 1),
  median_lead     = expired_summary$median_lead,
  pct_ends_0      = round(round_numbers$pct_ends_0, 1),
  pct_ends_00     = round(round_numbers$pct_ends_00, 1),
  pooled_pct      = round(pooled$pct_per_year[1], 2),
  control_pct     = round(pooled$pct_per_year[2], 2),
  pooled_r2       = round(pooled$r_squared[2] * 100, 1),
  med_1960        = decade_all$median_horizon[decade_all$dec == 1960],
  med_2020        = decade_all$median_horizon[decade_all$dec == 2020],
  prose_1950s     = round(100 * composition$share[composition$dec == 1950 &
                                                  composition$md == "prose fiction"]),
  prose_2020s     = round(100 * composition$share[composition$dec == 2020 &
                                                  composition$md == "prose fiction"]),
  film_1950s      = round(100 * composition$share[composition$dec == 1950 &
                                                  composition$md == "film"]),
  film_2020s      = round(100 * composition$share[composition$dec == 2020 &
                                                  composition$md == "film"]),
  generated       = format(Sys.Date(), "%d %B %Y")
)

payload <- list(
  WORKS         = ff_to_json(works_payload, digits = 0),
  DECADE_ALL    = ff_to_json(decade_all,    digits = 1),
  DECADE_MEDIUM = ff_to_json(decade_medium, digits = 1),
  SLOPES        = ff_to_json(slopes,        digits = 4),
  COMPOSITION   = ff_to_json(composition,   digits = 4),
  POOLED        = ff_to_json(pooled,        digits = 5),
  DEEP_FUTURE   = ff_to_json(deep_future,   digits = 0),
  PALETTE       = palette_json,
  META          = ff_to_json_object(meta)
)


# ==============================================================================
# 5. RENDER
# ==============================================================================

message("--- Rendering report ---")

ff_render_report(
  template_path = settings$template_path,
  output_path   = settings$output_path,
  payload       = payload
)


# ==============================================================================
# 6. CONSOLE SUMMARY
#    Print the headline results so running the script tells you what it found,
#    not just that it finished.
# ==============================================================================

cat("\n", strrep("=", 74), "\n", sep = "")
cat("IS THE IMAGINED FUTURE GETTING CLOSER?\n")
cat(strrep("=", 74), "\n\n", sep = "")

cat("Works analysed: ", meta$n_analysis, " of ", meta$n_file,
    " in the file (", meta$first_decade, " onward, ", meta$media_kept, ")\n\n", sep = "")

cat("Pooled trend, no control        : ", sprintf("%+.2f%% per year", meta$pooled_pct), "\n", sep = "")
cat("Pooled trend, medium controlled : ", sprintf("%+.2f%% per year", meta$control_pct), "\n", sep = "")
cat("  -> ", round(100 * (1 - meta$control_pct / meta$pooled_pct)),
    "% of the apparent decline is the changing mix of media\n\n", sep = "")

cat("Per medium:\n")
slopes |>
  mutate(line = sprintf("  %-14s n=%4d  %+6.2f%%/yr  [%+.2f, %+.2f]  %s",
                        md, n, pct_per_year, pct_per_year_low,
                        pct_per_year_high, verdict)) |>
  pull(line) |>
  cat(sep = "\n")

cat("\n\nComposition shift: prose fiction ", meta$prose_1950s, "% -> ", meta$prose_2020s,
    "% of works; film ", meta$film_1950s, "% -> ", meta$film_2020s, "%\n", sep = "")
cat("Expired futures  : ", meta$n_expired, " works (", meta$pct_expired,
    "%) are set in a year that has already passed\n", sep = "")
cat("\nReport written to: ", settings$output_path, "\n", sep = "")
