# ============================================================================
# Hatiya Island — Tropical cyclone frequency and intensity (Section 2.5.2)
# Source: IBTrACS v04r01, North Indian basin (Knapp et al. 2010, 2018)
# Storms whose track passes within 100 km and 200 km of the island centroid,
# 1996–2025; Mann–Kendall trend test and Poisson regression on annual counts;
# trend in intensity of the storms that approached the island.
# ----------------------------------------------------------------------------
# OUTPUT: outputs/tables/ibtracs_storms_100km.csv, ibtracs_storms_200km.csv,
#         ibtracs_annual_counts.csv, ibtracs_trends.csv
#         outputs/figures/FigS3_cyclone_counts.tif (600 dpi)
# ============================================================================

## ---- 0. Settings -------------------------------------------------------------
# Reference point used in the manuscript: the 1996 island-footprint centroid (22.252° N, 91.108° E),
# rounded. Using the 2025 centroid (22.214° N, 91.107° E) gives 32 instead of 34 systems within
# 200 km and no significant trend for any radius or storm class (see README).
CENTROID_LAT <- 22.26
CENTROID_LON <- 91.10
RADII_KM     <- c(100, 200)
FIRST_SEASON <- 1996
LAST_SEASON  <- 2025
STORM_KT     <- 34        # cyclonic storm threshold (IMD: >= 34 kt)
STEP_MIN     <- 30        # track interpolation step (minutes)
IB_URL  <- paste0("https://www.ncei.noaa.gov/data/international-best-track-archive-",
                  "for-climate-stewardship-ibtracs/v04r01/access/csv/ibtracs.NI.list.v04r01.csv")
IB_FILE <- "data/ibtracs/ibtracs.NI.list.v04r01.csv.gz"  # snapshot shipped with the repository

pkgs <- c("dplyr", "readr", "ggplot2", "trend")
new  <- pkgs[!pkgs %in% installed.packages()[, "Package"]]
if (length(new)) install.packages(new, repos = "https://cloud.r-project.org")
invisible(lapply(pkgs, library, character.only = TRUE))
dir.create("outputs/tables",  recursive = TRUE, showWarnings = FALSE)
dir.create("outputs/figures", recursive = TRUE, showWarnings = FALSE)

## ---- 1. Read IBTrACS (download once; record the download date in Methods) ------
if (!file.exists(IB_FILE)) {                    # fall back to a fresh download if the snapshot is absent
  IB_FILE <- sub("\\.gz$", "", IB_FILE)
  if (!file.exists(IB_FILE)) download.file(IB_URL, IB_FILE, mode = "wb")
}
cat("IBTrACS file MD5:", unname(tools::md5sum(IB_FILE)), "\n")
hdr <- names(readr::read_csv(IB_FILE, n_max = 0, show_col_types = FALSE))
ib  <- readr::read_csv(IB_FILE, skip = 2, col_names = hdr, na = c("", " "),
                       col_types = readr::cols(.default = "c"), show_col_types = FALSE) %>%
  transmute(SID, SEASON = as.integer(SEASON), NAME, TRACK_TYPE,
            time = as.POSIXct(ISO_TIME, tz = "UTC"),
            lat = as.numeric(LAT), lon = as.numeric(LON),
            wmo_wind = as.numeric(WMO_WIND), wmo_pres = as.numeric(WMO_PRES),
            usa_wind = as.numeric(USA_WIND)) %>%
  filter(TRACK_TYPE == "main", SEASON >= FIRST_SEASON, SEASON <= LAST_SEASON) %>%
  arrange(SID, time)

## ---- 2. Interpolate tracks and compute distance to the centroid ----------------
haversine <- function(lat1, lon1, lat2, lon2) {
  r <- pi / 180
  a <- sin((lat2 - lat1) * r / 2)^2 + cos(lat1 * r) * cos(lat2 * r) * sin((lon2 - lon1) * r / 2)^2
  2 * 6371 * asin(sqrt(a))
}
interp_track <- function(df) {
  df <- df[!is.na(df$lat) & !is.na(df$lon) & !duplicated(df$time), ]
  if (nrow(df) < 2) return(data.frame(SID = df$SID, time = df$time, lat = df$lat, lon = df$lon))
  tt <- seq(min(df$time), max(df$time), by = STEP_MIN * 60)
  data.frame(SID = df$SID[1], time = tt,
             lat = approx(as.numeric(df$time), df$lat, as.numeric(tt))$y,
             lon = approx(as.numeric(df$time), df$lon, as.numeric(tt))$y)
}
dense <- do.call(rbind, lapply(split(ib, ib$SID), interp_track)) %>%
  mutate(dist_km = haversine(lat, lon, CENTROID_LAT, CENTROID_LON))

## ---- 3. Storm-level table ----------------------------------------------------------
# Intensity: WMO_WIND (IMD, 3-min sustained, kt) and WMO_PRES (hPa). If an IMD
# value is missing, the JTWC 1-min wind (USA_WIND) is used ONLY to classify the
# system as a storm; it is not mixed into the intensity series.
storms <- ib %>% group_by(SID) %>%
  summarise(season = first(SEASON), name = first(NAME),
            lmi_kt   = suppressWarnings(max(wmo_wind, na.rm = TRUE)),
            min_pres = suppressWarnings(min(wmo_pres, na.rm = TRUE)),
            usa_lmi  = suppressWarnings(max(usa_wind, na.rm = TRUE)), .groups = "drop") %>%
  mutate(across(c(lmi_kt, min_pres, usa_lmi), ~ ifelse(is.infinite(.), NA, .)),
         is_storm = coalesce(lmi_kt, usa_lmi) >= STORM_KT) %>%
  left_join(dense %>% group_by(SID) %>% summarise(min_dist_km = min(dist_km)), by = "SID")

# Intensity of each storm while it was inside the search radius
inside_wind <- function(R) {
  ib %>% mutate(d = haversine(lat, lon, CENTROID_LAT, CENTROID_LON)) %>%
    filter(d <= R) %>% group_by(SID) %>%
    summarise(wind_in_radius = suppressWarnings(max(wmo_wind, na.rm = TRUE)), .groups = "drop") %>%
    mutate(wind_in_radius = ifelse(is.infinite(wind_in_radius), NA, wind_in_radius))
}

## ---- 4. Counts, trend tests and intensity trends -------------------------------------
years  <- FIRST_SEASON:LAST_SEASON
counts <- data.frame(year = years)
trends <- list()
for (R in RADII_KM) {
  sel <- storms %>% filter(min_dist_km <= R) %>% left_join(inside_wind(R), by = "SID") %>%
    arrange(season)
  readr::write_csv(sel, sprintf("outputs/tables/ibtracs_storms_%dkm.csv", R))
  for (cls in c("all", "storm")) {
    s <- if (cls == "storm") filter(sel, is_storm) else sel
    n <- sapply(years, function(y) sum(s$season == y))
    counts[[sprintf("n_%s_%dkm", cls, R)]] <- n
    mk  <- trend::mk.test(n)
    sen <- trend::sens.slope(n)
    pois <- glm(n ~ years, family = quasipoisson)
    trends[[length(trends) + 1]] <- data.frame(
      radius_km = R, systems = ifelse(cls == "storm", paste0(">= ", STORM_KT, " kt"), "all systems"),
      variable = "annual count", total = sum(n), mean_per_year = mean(n),
      MK_Z = unname(mk$statistic), MK_p = mk$p.value, sen_per_decade = unname(sen$estimates) * 10,
      poisson_IRR_per_decade = exp(10 * coef(pois)[2]),
      poisson_p = summary(pois)$coefficients[2, 4],
      dispersion = summary(pois)$dispersion)
  }
  # intensity of approaching storms (each storm one observation, ordered in time)
  si <- sel %>% filter(is_storm, !is.na(lmi_kt))
  if (nrow(si) >= 8) {
    kt <- cor.test(si$season, si$lmi_kt, method = "kendall", exact = FALSE)
    trends[[length(trends) + 1]] <- data.frame(
      radius_km = R, systems = paste0(">= ", STORM_KT, " kt"),
      variable = "lifetime max wind (kt) vs year", total = nrow(si), mean_per_year = NA,
      MK_Z = unname(kt$statistic), MK_p = kt$p.value,
      sen_per_decade = NA,   # storms are irregularly spaced in time: Kendall tau only
      poisson_IRR_per_decade = NA, poisson_p = NA, dispersion = NA)
  }
}
counts_out <- counts
trends <- do.call(rbind, trends)
options(width = 200)
cat("\n== Annual counts ==\n"); print(counts_out, row.names = FALSE)
cat("\n== Trend tests ==\n")
print(trends %>% mutate(across(where(is.numeric), ~ round(., 3))), row.names = FALSE)
readr::write_csv(counts_out, "outputs/tables/ibtracs_annual_counts.csv")
readr::write_csv(trends, "outputs/tables/ibtracs_trends.csv")

cat("\n== Storms (>= ", STORM_KT, " kt) within 100 km ==\n", sep = "")
print(storms %>% filter(min_dist_km <= 100, is_storm) %>%
        select(season, name, lmi_kt, min_pres, min_dist_km) %>%
        mutate(min_dist_km = round(min_dist_km)) %>% arrange(season), row.names = FALSE)

## ---- 5. Figure (no in-figure title) ---------------------------------------------------
cl <- rbind(data.frame(year = years, n = counts[[sprintf("n_storm_%dkm", RADII_KM[1])]],
                       radius = paste0("Within ", RADII_KM[1], " km")),
            data.frame(year = years, n = counts[[sprintf("n_storm_%dkm", RADII_KM[2])]],
                       radius = paste0("Within ", RADII_KM[2], " km")))
fS3 <- ggplot(cl, aes(year, n, fill = radius)) +
  geom_col(position = position_dodge(width = .8), width = .75) +
  scale_fill_manual(values = c("#D55E00", "#0072B2"), name = NULL) +
  scale_y_continuous(breaks = 0:max(cl$n)) +
  labs(x = "Year", y = paste0("Cyclonic storms (>= ", STORM_KT, " kt)")) +
  theme_minimal(base_size = 12) +
  theme(axis.title = element_text(face = "bold"), panel.grid.minor = element_blank(),
        legend.position = "top", plot.background = element_rect(fill = "white", colour = NA))
ggsave("outputs/figures/FigS3_cyclone_counts.tif", fS3, width = 7.5, height = 4.2, dpi = 600,
       device = "tiff", compression = "lzw", bg = "white")

cat("\n"); print(R.version.string)
for (p in pkgs) cat(p, as.character(packageVersion(p)), "\n")
