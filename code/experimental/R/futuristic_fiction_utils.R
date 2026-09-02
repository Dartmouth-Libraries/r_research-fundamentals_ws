# ==============================================================================
# futuristic_fiction_utils.R
#
# Shared helper functions for the "Is the imagined future getting closer?"
# analysis of data/post45_books/original/futuristic_fiction.csv
#
# WHY THIS FILE EXISTS
#   Two things need the same data-preparation logic:
#     - code/experimental/05a_futuristic-fiction_exploratory.qmd  (the notebook)
#     - code/experimental/05b_futuristic-fiction_report.R         (the report)
#   Rather than copy-paste the cleaning steps into both, we define them once
#   here and `source()` this file from each. If we later change how "horizon"
#   is calculated, we change it in exactly one place.
#
# HOW TO READ THIS FILE
#   Every function has a comment block above it saying what goes in, what comes
#   out, and why it exists. Functions do one thing each. None of them modify
#   anything outside themselves -- you hand a data frame in, you get a data
#   frame back.
#
# CONVENTIONS
#   - `ff_` prefix = "futuristic fiction", so these names never collide with
#     function names from tidyverse or other packages.
#   - `df` is always a data frame / tibble.
#   - We never delete rows silently. Any function that drops rows tells you
#     how many it dropped, via message().
# ==============================================================================

library(tidyverse)


# ------------------------------------------------------------------------------
# SECTION 1: LOADING
# ------------------------------------------------------------------------------

#' Read the raw futuristic fiction CSV
#'
#' The CSV was exported from Python (pandas), which writes the row number as an
#' unnamed first column. readr calls that column `...1`. It carries no
#' information, so we drop it -- and it actively causes trouble later, because a
#' column with an empty or auto-generated name breaks model formulas.
#'
#' @param path  Character. Full path to futuristic_fiction.csv.
#' @return A tibble of the raw data, one row per work, nothing cleaned yet.
ff_load_raw <- function(path) {

  raw <- readr::read_csv(
    path,
    show_col_types = FALSE,     # keeps the console quiet; we inspect types ourselves
    na = c("", "NA")            # treat empty cells as missing, not as ""
  )

  # Drop the leftover pandas index column if it is present.
  # `any_of()` means "drop these if they exist, don't error if they don't".
  raw <- dplyr::select(raw, -dplyr::any_of(c("...1", "X", "")))

  message("Loaded ", nrow(raw), " rows x ", ncol(raw), " columns from ", basename(path))

  raw
}


# ------------------------------------------------------------------------------
# SECTION 2: DERIVED COLUMNS
# ------------------------------------------------------------------------------

#' Add the two columns the whole analysis rests on
#'
#' `horizon` is the heart of this project: how many years into its own future
#' did this work look? A 1968 film set in 2001 has a horizon of 33 years.
#'
#' `release_decade` buckets works into 10-year groups so we can compare eras.
#' The `%/%` operator is integer division: 1968 %/% 10 = 196, then * 10 = 1960.
#'
#' Note: the file already ships a `years_distant` column that should equal our
#' `horizon`. We compute our own anyway and check them against each other in
#' the notebook -- never trust a derived column you did not derive.
#'
#' @param df  Data frame with `released` and `year_set` columns.
#' @return The same data frame plus `horizon` and `release_decade`.
ff_add_horizon <- function(df) {
  df |>
    dplyr::mutate(
      horizon        = year_set - released,
      release_decade = (released %/% 10) * 10
    )
}


# ------------------------------------------------------------------------------
# SECTION 3: BUILDING THE ANALYSIS UNIVERSE
# ------------------------------------------------------------------------------

#' Filter the raw data down to the rows the analysis can actually use
#'
#' This function makes exactly three decisions, and they are the only rows we
#' ever remove. Each one is reported so nothing disappears quietly.
#'
#'   1. Drop rows with no `year_set`. Without an imagined year there is no
#'      horizon to measure. (~10 rows)
#'   2. Keep only release decades from `first_decade` onward. Before 1950 there
#'      are only a handful of works per decade, too few for a stable median.
#'   3. Keep only media with at least `min_medium_n` works overall. "ride"
#'      (2 works) and "illustration" (1 work) cannot support a trend line.
#'
#' WHAT WE DELIBERATELY DO *NOT* DO: we do not remove works with enormous
#' horizons. Doctor Who's "Utopia" really is set in the year 100 trillion;
#' Stapledon's `Last and First Men` really does run ten million years out.
#' Those are correct data, not typos. We handle them with log scales and
#' medians (both immune to a long tail) rather than by deleting them.
#'
#' @param df            Data frame that has already been through ff_add_horizon().
#' @param first_decade  Numeric. Earliest release decade to keep, e.g. 1950.
#' @param min_medium_n  Numeric. Minimum works in a medium for it to be kept.
#' @return A filtered tibble, plus an attribute "ff_drops" recording what went.
ff_build_analysis_set <- function(df, first_decade = 1950, min_medium_n = 50) {

  n_start <- nrow(df)

  # --- Decision 1: a work with no imagined year cannot have a horizon --------
  step1     <- dplyr::filter(df, !is.na(year_set))
  n_no_year <- n_start - nrow(step1)

  # --- Decision 2: restrict to decades with enough works to be meaningful ---
  step2    <- dplyr::filter(step1, release_decade >= first_decade)
  n_too_old <- nrow(step1) - nrow(step2)

  # --- Decision 3: restrict to media with enough works to fit a trend -------
  # First count works per medium, then keep the media that clear the bar.
  media_kept <- step2 |>
    dplyr::count(medium) |>
    dplyr::filter(n >= min_medium_n) |>
    dplyr::pull(medium)

  step3      <- dplyr::filter(step2, medium %in% media_kept)
  n_rare_med <- nrow(step2) - nrow(step3)

  # --- Report every removal -------------------------------------------------
  message(
    "Analysis set: ", nrow(step3), " of ", n_start, " rows\n",
    "  dropped ", n_no_year,  " with no year_set\n",
    "  dropped ", n_too_old,  " released before ", first_decade, "\n",
    "  dropped ", n_rare_med, " in media with < ", min_medium_n, " works\n",
    "  media kept: ", paste(sort(media_kept), collapse = ", ")
  )

  # Stash the drop counts on the object so the report can print them honestly.
  attr(step3, "ff_drops") <- list(
    n_start = n_start, n_no_year = n_no_year,
    n_too_old = n_too_old, n_rare_med = n_rare_med,
    media_kept = sort(media_kept)
  )

  step3
}


# ------------------------------------------------------------------------------
# SECTION 4: SUMMARISING
# ------------------------------------------------------------------------------

#' Median horizon for any grouping, with the group size alongside it
#'
#' We use the MEDIAN rather than the mean throughout. With a variable whose
#' maximum is 100 trillion, a mean is meaningless -- one Doctor Who episode
#' would drag the 2000s average into the billions. The median just asks
#' "what does a typical work in this group look like?"
#'
#' `n` travels with every median on purpose. A median of 635 years looks
#' dramatic until you see it rests on 6 works.
#'
#' @param df       Data frame with a `horizon` column.
#' @param ...      Columns to group by, unquoted, e.g. release_decade, medium.
#' @param min_n    Groups smaller than this get `median_horizon = NA` so they
#'                 are visibly missing rather than misleadingly precise.
#' @return A tibble: one row per group, with median_horizon, n, and quartiles.
ff_median_horizon <- function(df, ..., min_n = 1) {
  df |>
    dplyr::group_by(...) |>
    dplyr::summarise(
      n              = dplyr::n(),
      median_horizon = stats::median(horizon),
      q25            = stats::quantile(horizon, 0.25),
      q75            = stats::quantile(horizon, 0.75),
      .groups = "drop"
    ) |>
    # Blank out medians that rest on too few works to trust.
    dplyr::mutate(median_horizon = dplyr::if_else(n >= min_n, median_horizon, NA_real_))
}


#' Share of each decade's works belonging to each medium
#'
#' This is the "confound" table. If film makes up 19% of 1950s works and 48%
#' of 2020s works, then a pooled trend across all media is partly measuring
#' the changing mix of media rather than any change in imagination.
#'
#' @param df  Analysis-set data frame.
#' @return A tibble: release_decade, medium, n, share (sums to 1 per decade).
ff_composition <- function(df) {
  df |>
    dplyr::count(release_decade, medium, name = "n") |>
    dplyr::group_by(release_decade) |>
    dplyr::mutate(share = n / sum(n)) |>
    dplyr::ungroup()
}


# ------------------------------------------------------------------------------
# SECTION 5: MODELLING
# ------------------------------------------------------------------------------

#' Fit one straight-line trend per medium and return the slopes in a table
#'
#' WHY log1p(horizon) AS THE OUTCOME
#'   `log1p(x)` is log(x + 1). Two reasons we model the log:
#'     - Horizons span 0 to 100 trillion. Untransformed, the handful of
#'       deep-future works would dominate the fit completely.
#'     - On a log scale, a slope becomes a *percentage* change per year, which
#'       is the natural way to describe "the horizon is shrinking by X% a year".
#'   The "+1" exists because log(0) is undefined and one work has horizon 0.
#'
#' HOW TO READ `pct_per_year`
#'   A slope of -0.02 on the log scale means exp(-0.02) - 1 = -1.98%, i.e. the
#'   typical horizon shrinks about 2% per year of release date.
#'
#' @param df     Analysis-set data frame.
#' @param min_n  Media with fewer works than this are skipped entirely.
#' @return A tibble: one row per medium with slope, CI, p-value, and n.
ff_slopes_by_medium <- function(df, min_n = 60) {

  df |>
    dplyr::group_by(medium) |>
    dplyr::filter(dplyr::n() >= min_n) |>
    # `group_modify` runs the function once per medium and stacks the results.
    dplyr::group_modify(~ {
      fit <- stats::lm(log1p(horizon) ~ released, data = .x)
      ci  <- stats::confint(fit)["released", ]
      tidy_row <- summary(fit)$coefficients["released", ]

      tibble::tibble(
        n            = nrow(.x),
        slope        = tidy_row[["Estimate"]],
        std_error    = tidy_row[["Std. Error"]],
        p_value      = tidy_row[["Pr(>|t|)"]],
        ci_low       = ci[[1]],
        ci_high      = ci[[2]],
        # Convert the log-scale slope into a percentage change per year.
        pct_per_year     = (exp(tidy_row[["Estimate"]]) - 1) * 100,
        pct_per_year_low = (exp(ci[[1]]) - 1) * 100,
        pct_per_year_high= (exp(ci[[2]]) - 1) * 100
      )
    }) |>
    dplyr::ungroup() |>
    # A trend is "significant" here if its confidence interval excludes zero.
    dplyr::mutate(significant = (ci_low < 0 & ci_high < 0) | (ci_low > 0 & ci_high > 0)) |>
    dplyr::arrange(pct_per_year)
}


#' Fit the two pooled models: without and with a control for medium
#'
#' The comparison between these two is the analytical crux. If the trend
#' shrinks a lot once `medium` is added, then much of the apparent decline was
#' really the changing mix of media.
#'
#' @param df  Analysis-set data frame.
#' @return A named list of two lm objects, `pooled` and `with_medium`.
ff_pooled_models <- function(df) {
  list(
    pooled      = stats::lm(log1p(horizon) ~ released, data = df),
    with_medium = stats::lm(log1p(horizon) ~ released + medium, data = df)
  )
}


#' Pull the `released` slope out of a model as a one-row tibble
#'
#' Saves repeating the same extraction code for each model.
#'
#' @param fit    An lm object containing a `released` term.
#' @param label  Character name for this model, used in the output table.
#' @return A one-row tibble with the slope, its CI, p-value, and R-squared.
ff_slope_row <- function(fit, label) {
  co <- summary(fit)$coefficients["released", ]
  ci <- stats::confint(fit)["released", ]

  tibble::tibble(
    model        = label,
    slope        = co[["Estimate"]],
    p_value      = co[["Pr(>|t|)"]],
    ci_low       = ci[[1]],
    ci_high      = ci[[2]],
    pct_per_year = (exp(co[["Estimate"]]) - 1) * 100,
    r_squared    = summary(fit)$r.squared,
    n            = length(stats::residuals(fit))
  )
}


# ------------------------------------------------------------------------------
# SECTION 6: WRITING JSON FOR THE INTERACTIVE REPORT
# ------------------------------------------------------------------------------
# The report is a standalone HTML file whose charts are drawn in JavaScript.
# To get R's results into that page we serialise each summary table to JSON and
# paste it into an HTML template. These two functions do that conversion using
# base R only, so the report has no extra package dependencies.
# ------------------------------------------------------------------------------

#' Escape a character vector so it is safe inside a JSON string
#'
#' Handles the four things that break JSON or HTML:
#'   \  and  "   -- would end the string early
#'   newlines/tabs -- not allowed literally inside a JSON string
#'   <           -- escaped as < so the text "</script>" inside a title
#'                  can never terminate the <script> tag it is embedded in
#'
#' @param x  Character vector.
#' @return The same vector with those characters escaped.
ff_json_escape <- function(x) {
  x <- as.character(x)
  x <- gsub("\\\\", "\\\\\\\\", x)   # backslash first, or we escape our escapes
  x <- gsub('"',    '\\\\"',    x)
  x <- gsub("\r",   "\\\\r",    x)
  x <- gsub("\n",   "\\\\n",    x)
  x <- gsub("\t",   "\\\\t",    x)
  x <- gsub("<",    "\\\\u003c", x)
  x
}


#' Convert a flat data frame to a JSON array of objects
#'
#' Produces `[{"col":value,...},...]`. Only handles flat (non-nested) tables,
#' which is all this report needs.
#'
#' Type handling:
#'   numeric  -> bare number; NA and non-finite values become `null`
#'   logical  -> true / false
#'   anything else -> quoted, escaped string
#'
#' @param df      A flat data frame.
#' @param digits  Round numeric columns to this many decimal places.
#' @return A single JSON string.
ff_to_json <- function(df, digits = 4) {

  if (nrow(df) == 0) return("[]")

  # Build a character matrix of formatted values, one column at a time.
  cols <- lapply(names(df), function(nm) {
    v <- df[[nm]]

    if (is.numeric(v)) {
      out <- ifelse(is.finite(v), format(round(v, digits), scientific = FALSE, trim = TRUE), "null")
    } else if (is.logical(v)) {
      out <- ifelse(is.na(v), "null", ifelse(v, "true", "false"))
    } else {
      out <- ifelse(is.na(v), "null", paste0('"', ff_json_escape(v), '"'))
    }

    paste0('"', nm, '":', out)
  })

  # Stitch the per-column strings into one object per row.
  rows <- do.call(paste, c(cols, sep = ","))
  paste0("[{", paste(rows, collapse = "},{"), "}]")
}


#' Convert a named list of single values to a JSON object
#'
#' Used for the report's metadata block (row counts, settings, date).
#'
#' @param x  A named list or vector of length-1 values.
#' @return A single JSON string like `{"key":value,...}`.
ff_to_json_object <- function(x) {
  parts <- vapply(names(x), function(nm) {
    v <- x[[nm]]
    val <- if (is.numeric(v) && is.finite(v)) {
      format(v, scientific = FALSE, trim = TRUE)
    } else if (is.logical(v) && !is.na(v)) {
      if (v) "true" else "false"
    } else {
      paste0('"', ff_json_escape(paste(v, collapse = ", ")), '"')
    }
    paste0('"', nm, '":', val)
  }, character(1))

  paste0("{", paste(parts, collapse = ","), "}")
}


#' Fill placeholders in an HTML template and write the finished report
#'
#' The template contains tokens like `{{WORKS}}`. For each name/value pair in
#' `payload`, every occurrence of `{{NAME}}` is replaced by the value.
#'
#' `fixed = TRUE` matters: without it, characters in the JSON would be
#' interpreted as regular expression syntax and the substitution would mangle
#' the data.
#'
#' @param template_path  Path to the HTML template file.
#' @param output_path    Path to write the finished report to.
#' @param payload        Named list of replacement strings.
#' @return The output path, invisibly.
ff_render_report <- function(template_path, output_path, payload) {

  if (!file.exists(template_path)) {
    stop("Template not found: ", template_path, call. = FALSE)
  }

  # Read the template as one string, keeping UTF-8 intact.
  html <- paste(readLines(template_path, warn = FALSE, encoding = "UTF-8"), collapse = "\n")

  # Substitute each token, and check that it actually existed in the template.
  for (nm in names(payload)) {
    token <- paste0("{{", nm, "}}")
    if (!grepl(token, html, fixed = TRUE)) {
      warning("Token ", token, " not found in template; value unused.", call. = FALSE)
    }
    html <- gsub(token, payload[[nm]], html, fixed = TRUE)
  }

  # Warn about any token the template wanted but the payload did not supply.
  leftover <- regmatches(html, gregexpr("\\{\\{[A-Z_]+\\}\\}", html))[[1]]
  if (length(leftover) > 0) {
    warning("Template still contains unfilled tokens: ",
            paste(unique(leftover), collapse = ", "), call. = FALSE)
  }

  dir.create(dirname(output_path), recursive = TRUE, showWarnings = FALSE)

  # useBytes = TRUE writes the UTF-8 bytes we already have, without letting
  # Windows re-encode them into the local codepage and mangle accented titles.
  con <- file(output_path, open = "wb")
  writeLines(html, con, useBytes = TRUE)
  close(con)

  message("Wrote report: ", output_path,
          " (", round(file.size(output_path) / 1024), " KB)")

  invisible(output_path)
}
