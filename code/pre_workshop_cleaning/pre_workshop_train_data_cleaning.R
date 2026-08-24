# Cleaning Train Data for Workshop ----

## Load packages ----
library(tidyverse)
library(here)

## Load data ----
routes_df <- read.csv(here("data", "train_router", "raw", "routes_raw.csv"))

## Clean duration ----
routes_df <- routes_df |>
    mutate(
        duration,
        # remove parenthetical notes, e.g. "(round trip)"
        duration = str_remove(duration, "\\(.*\\)"),
        # remove anything after a "·", e.g. "· 2 trains", "· change at Neussargues"
        duration = str_remove(duration, "·.*$"),
        # remove specific phrases
        duration = str_remove(duration, "round trip"),
        duration = str_remove(duration, "daylight only"),
        # remove stray commas left behind (e.g. "2 days,")
        duration = str_remove_all(duration, ",")
    )

## Write csv ----
write.csv(routes_df, here("data", "train_router", "routes.csv"), row.names = FALSE, fileEncoding = "UTF-8")




