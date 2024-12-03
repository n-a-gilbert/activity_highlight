library(tidyverse)
library(janitor)
library(lubridate)
library(lutz)
library(here)
library(GLMMadaptive)

setwd(here::here("data"))

# Wood Thrush detections from birdweater
# downloaded from https://www.birdweather.com/
woth <- readr::read_csv("woth.csv") |> 
  janitor::clean_names()

# VIIRs dataset for the focal sites from Google Earth Engine
alan <- readr::read_csv("woth_sites_alan.csv")

sites_alan <- readr::read_csv("woth_sites.csv") |> 
  tibble::add_column( alan = alan$avg_rad) 

d <- woth |> 
  dplyr::select(timestamp, latitude, longitude) |> 
  dplyr::group_by(latitude, longitude) |> 
  dplyr::mutate(n = n()) |>
  dplyr::filter(n >= 25) |>
  dplyr::mutate(zone = lutz::tz_lookup_coords( latitude, longitude, method = "fast")) |>
  dplyr::rowwise() |> 
  dplyr::mutate(date_time = lubridate::mdy_hm( timestamp, tz = zone)) |> 
  dplyr::mutate(time = hms::as_hms( date_time ) ) |> 
  dplyr::mutate(date = as.Date( date_time) ) |> 
  dplyr::filter(!is.na(date_time)) |> 
  dplyr::ungroup() |> 
  dplyr::group_by(latitude, longitude) |> 
  dplyr::mutate(site = dplyr::cur_group_id()) |> 
  dplyr::ungroup() |> 
  dplyr::left_join(sites_alan)

site <- d |> 
  dplyr::select(site, latitude, longitude, zone) |> 
  dplyr::distinct() 

min_date <- min( d$date )
max_date <- max( d$date )

occasions <- vector("list", length = nrow(site))

for( i in 1:nrow(site)) {
  occasions[[i]] <- data.frame(
    site = site$site[i],
    start = seq(from = lubridate::ymd_hms( paste( min_date, "00:00:00", sep = " "),
                                           tz = site$zone[i]),
                to = lubridate::ymd_hms( paste( max_date, "00:00:00", sep = " "),
                                         tz = site$zone[i]),
                by = "30 min")) |>
    dplyr::mutate(end = c(start[2:length(start)],
                          start[length(start)] + minutes(30)))
}

occ <- do.call(rbind.data.frame, occasions)
occ$capt <- 0

for( i in 1:nrow(d)){
  occ[   occ$site == d$site[i] &
           occ$start <= d$date_time[i] &
           occ$end > d$date_time[i], "capt"] <- 1
}

final <- occ |> 
  tibble::as_tibble() |> 
  dplyr::mutate( mid = start + (difftime(end, start, units = "secs") / 2)) |> 
  dplyr::mutate( mid_time = as.numeric( difftime( mid,
                                                  lubridate::floor_date(mid, "day"),
                                                  units = "mins"))) |> 
  dplyr::group_by(site, mid_time) |> 
  dplyr::summarise( success = sum(capt), 
                    failure = dplyr::n() - success) |> 
  dplyr::group_by(mid_time) |> 
  dplyr::mutate( bin_30min = dplyr::cur_group_id()) |> 
  dplyr::ungroup() |> 
  dplyr::left_join(
    site |> 
      dplyr::select(site, latitude, longitude)) |> 
  dplyr::select(site, latitude, longitude, time = bin_30min, success, failure) |> 
  dplyr::left_join( sites_alan |> 
                      dplyr::select(site, alan)) |> 
  dplyr::mutate(alan = as.numeric( scale( log1p( alan ) ) ) )

m1 <- GLMMadaptive::mixed_model(
  fixed = cbind(success, failure) ~
    cos( 2 * pi * time / 48 ) + sin( 2 * pi * time / 48 ) +
    cos( 2 * pi * time / 24 ) + sin( 2 * pi * time / 24), 
  random = ~ cos( 2 * pi * time / 48 ) + sin( 2 * pi * time / 48 ) +
    cos( 2 * pi * time / 24 ) + sin( 2 * pi * time / 24) || site,
  data = final, 
  family = binomial(), 
  iter_EM = 0)

setwd(here::here("results"))
save(
  m1, 
  final, 
  file = "woth_m1_data.RData"
)

newdat <- with(
  final,
  expand.grid(
    time = seq(0, 48, length.out = 96)))

marg_eff <- GLMMadaptive::effectPlotData( m1, newdat, marginal = TRUE) |> 
  dplyr::mutate(across(pred:upp, function(x) plogis(x))) |> 
  dplyr::mutate(time = time / 2)

ggplot() +
  geom_ribbon(data = marg_eff, aes(x = time, ymin = low, ymax = upp),
              color = NA, 
              fill = MetBrewer::MetPalettes$Hiroshige[[1]][9],
              alpha = 0.3) +
  geom_line(data = marg_eff, aes(x = time, y = pred),
            color = MetBrewer::MetPalettes$Hiroshige[[1]][9],
            linewidth = 1.5) + 
  scale_x_continuous( limits = c(0, 24),
                      breaks = c(0, 4, 8, 12, 16, 20, 24)) +
  labs(x = "Time of Day (Hour)", 
       y = "Probability of activity") +
  theme_minimal() +
  theme(axis.line = element_line(color = "black", linewidth = 0.2),
        axis.title = element_text(color = "black", size = 11), 
        axis.text = element_text(color = "black", size = 10))

# second model with effect of artificial light at night (alan)
# too computationally intensive to fit :(
m2 <- GLMMadaptive::mixed_model(
  fixed = cbind(success, failure) ~
    cos( 2 * pi * time / 48 )*alan +
    sin( 2 * pi * time / 48 )*alan +
    cos( 2 * pi * time / 24 )*alan +
    sin( 2 * pi * time / 24)*alan, 
  random = ~ cos( 2 * pi * time / 48 )*alan +
    sin( 2 * pi * time / 48 )*alan +
    cos( 2 * pi * time / 24 )*alan +
    sin( 2 * pi * time / 24)*alan || site,
  data = final, 
  family = binomial(), 
  iter_EM = 0)
