# ============================================================================
# Hatiya Island — Temperature and rainfall trends (Section 2.5.1)
# Mann–Kendall test, Theil–Sen slope, Precipitation Concentration Index (PCI)
# and coefficient of variation (CV) of rainfall, from BMD monthly records.
# ----------------------------------------------------------------------------
# INPUT (BMD Climate Division exports, Hatiya station; place them in data/bmd/):
#   Monthly_Highest_Maximum_Temperature_6_.csv  (°C, 2000–2025)
#   Monthly_Lowest_Minimum_Temperature_5_.csv   (°C, 2000–2025)
#   Monthly_Total_Rainfall_11_.csv              (mm, 1999–2025)
# NOTE: BMD temperature files give the HIGHEST maximum and LOWEST minimum
#   temperature of each month (monthly extremes), not monthly means.
#   Annual series used here:
#     TXm = annual mean of the 12 monthly highest maxima
#     TNm = annual mean of the 12 monthly lowest minima
#     TXx = annual highest maximum; TNn = annual lowest minimum
# OUTPUT: outputs/tables/climate_trends.csv, outputs/tables/annual_series.csv
#         outputs/figures/FigS1_temperature.tif, figures/FigS2_rainfall_PCI.tif (600 dpi)
# ============================================================================

## ---- 0. Settings -------------------------------------------------------------
F_TX   <- "data/bmd/Monthly_Highest_Maximum_Temperature_6_.csv"
F_TN   <- "data/bmd/Monthly_Lowest_Minimum_Temperature_5_.csv"
F_RAIN <- "data/bmd/Monthly_Total_Rainfall_11_.csv"
LAST_YEAR <- 2025      # last complete calendar year in the files
ALPHA     <- 0.05

pkgs <- c("dplyr", "tidyr", "readr", "ggplot2", "trend", "modifiedmk")
new  <- pkgs[!pkgs %in% installed.packages()[, "Package"]]
if (length(new)) install.packages(new, repos = "https://cloud.r-project.org")
invisible(lapply(pkgs, library, character.only = TRUE))
dir.create("outputs/tables",  recursive = TRUE, showWarnings = FALSE)
dir.create("outputs/figures", recursive = TRUE, showWarnings = FALSE)
missing <- c(F_TX, F_TN, F_RAIN)[!file.exists(c(F_TX, F_TN, F_RAIN))]
if (length(missing)) stop("BMD files not found: ", paste(missing, collapse = ", "),
                          "\nThese data are not redistributed; see data/bmd/README.md for how to obtain them.")

## ---- 1. Read BMD files (skip the letter-head; "**" or blank = missing) --------
read_bmd <- function(file, value_name) {
  lines <- readLines(file, warn = FALSE, encoding = "UTF-8")
  start <- grep("^Station,Year", lines)[1]
  df <- read.csv(text = paste(lines[start:length(lines)], collapse = "\n"),
                 na.strings = c("**", "", " "), strip.white = TRUE)
  df <- df[!is.na(df$Year) & df$Station != "", ]
  df %>% select(-Station) %>%
    pivot_longer(-Year, names_to = "mon", values_to = value_name) %>%
    mutate(year = as.integer(Year), month = match(mon, month.abb)) %>%
    select(year, month, all_of(value_name))
}
monthly <- read_bmd(F_TX, "tx") %>%
  full_join(read_bmd(F_TN, "tn"),   by = c("year", "month")) %>%
  full_join(read_bmd(F_RAIN, "rain"), by = c("year", "month")) %>%
  filter(year <= LAST_YEAR) %>% arrange(year, month)

stopifnot(all(monthly$rain >= 0, na.rm = TRUE),
          all(monthly$tx > monthly$tn, na.rm = TRUE))
cat("Temperature years:", range(monthly$year[!is.na(monthly$tx)]),
    "| Rainfall years:", range(monthly$year[!is.na(monthly$rain)]),
    "| missing months (tx, tn, rain):",
    sum(is.na(monthly$tx) & monthly$year >= 2000), sum(is.na(monthly$tn) & monthly$year >= 2000),
    sum(is.na(monthly$rain)), "\n")

## ---- 2. Annual and seasonal series -------------------------------------------
# Seasons: winter DJF (December counted with the following year), pre-monsoon
# MAM, monsoon JJAS, post-monsoon ON. A year/season is used only when all of
# its months are available (no na.rm).
annual <- monthly %>% group_by(year) %>%
  summarise(PCI  = 100 * sum(rain^2) / sum(rain)^2,   # Oliver (1980); computed
            TXm = mean(tx), TNm = mean(tn),             # before 'rain' is summed
            TXx = max(tx), TNn = min(tn),
            rain = sum(rain), .groups = "drop") %>%
  relocate(PCI, .after = rain)

seasonal <- monthly %>%
  mutate(year = ifelse(month == 12, year + 1L, year),
         season = case_when(month %in% c(12, 1, 2) ~ "Winter (DJF)",
                            month %in% 3:5        ~ "Pre-monsoon (MAM)",
                            month %in% 6:9        ~ "Monsoon (JJAS)",
                            TRUE                  ~ "Post-monsoon (ON)")) %>%
  filter(year <= LAST_YEAR) %>%
  group_by(season, year) %>%
  summarise(n = n(), TXm = mean(tx), TNm = mean(tn), rain = sum(rain), .groups = "drop") %>%
  filter(n == ifelse(season == "Monsoon (JJAS)", 4, ifelse(season == "Post-monsoon (ON)", 2, 3)))

## ---- 3. Trend test helper ----------------------------------------------------------
# Mann–Kendall test; if the lag-1 autocorrelation of the Sen-detrended series is
# significant, the Hamed–Rao modified test is reported instead.
trend_test <- function(x, yr, variable, period) {
  ok <- !is.na(x); x <- x[ok]; yr <- yr[ok]
  if (length(x) < 10) return(NULL)
  b0     <- unname(trend::sens.slope(x)$estimates)
  r1     <- acf(x - b0 * seq_along(x), lag.max = 1, plot = FALSE)$acf[2]
  r1_sig <- isTRUE(abs(r1) > qnorm(1 - ALPHA / 2) / sqrt(length(x)))
  mk <- trend::mk.test(x); p <- mk$p.value; z <- unname(mk$statistic); test <- "MK"
  if (r1_sig) {
    mm <- modifiedmk::mmkh(x)
    p <- unname(mm["new P-value"]); z <- unname(mm["Corrected Zc"]); test <- "MK (Hamed-Rao)"
  }
  sen <- trend::sens.slope(x)
  data.frame(variable, period, n_years = length(x), first = min(yr), last = max(yr),
             mean = mean(x), lag1_r = round(r1, 2), test, Z = z, p_value = p,
             sen_per_decade = unname(sen$estimates) * 10,
             sen_low = sen$conf.int[1] * 10, sen_high = sen$conf.int[2] * 10)
}

res <- list()
for (v in c("TXm", "TNm", "TXx", "TNn", "rain", "PCI"))
  res[[length(res) + 1]] <- trend_test(annual[[v]], annual$year, v, "Annual")
for (s in c("Winter (DJF)", "Pre-monsoon (MAM)", "Monsoon (JJAS)", "Post-monsoon (ON)")) {
  ss <- seasonal %>% filter(season == s) %>% arrange(year)
  for (v in c("TXm", "TNm", "rain"))
    res[[length(res) + 1]] <- trend_test(ss[[v]], ss$year, v, s)
}
trends <- do.call(rbind, res)
options(width = 220)
cat("\n== Trend results (Sen slope per decade: °C, mm or PCI units) ==\n")
print(trends %>% mutate(across(c(mean, Z, sen_per_decade, sen_low, sen_high), ~ round(., 2)),
                        p_value = formatC(p_value, format = "g", digits = 3)), row.names = FALSE)

## ---- 4. Rainfall variability ------------------------------------------------------------
cv <- function(x) 100 * sd(x) / mean(x)
cat("\n== Rainfall variability ==\n")
cat(sprintf("Annual rainfall: mean = %.0f mm, CV = %.1f%%\n", mean(annual$rain), cv(annual$rain)))
for (s in c("Winter (DJF)", "Pre-monsoon (MAM)", "Monsoon (JJAS)", "Post-monsoon (ON)")) {
  x <- seasonal$rain[seasonal$season == s]
  cat(sprintf("%-18s mean = %6.0f mm, CV = %5.1f%%\n", s, mean(x), cv(x)))
}
cat(sprintf("PCI: mean = %.1f (range %.1f-%.1f); years > 20 (strongly irregular): %d of %d\n",
            mean(annual$PCI), min(annual$PCI), max(annual$PCI),
            sum(annual$PCI > 20), nrow(annual)))

readr::write_csv(trends, "outputs/tables/climate_trends.csv")
readr::write_csv(annual, "outputs/tables/annual_series.csv")

## ---- 5. Figures (no in-figure titles) ----------------------------------------------
theme_set(theme_minimal(base_size = 12) +
          theme(axis.title = element_text(face = "bold"), panel.grid.minor = element_blank(),
                legend.position = "top",
                plot.background = element_rect(fill = "white", colour = NA)))
sen_fit <- function(x, yr) {
  b <- unname(trend::sens.slope(x)$estimates); a <- median(x - b * yr)
  data.frame(year = yr, fit = a + b * yr)
}
ta <- annual %>% filter(!is.na(TXm))
tl <- bind_rows(data.frame(year = ta$year, value = ta$TXm, var = "Mean monthly highest maximum"),
                data.frame(year = ta$year, value = ta$TNm, var = "Mean monthly lowest minimum"))
fits <- bind_rows(sen_fit(ta$TXm, ta$year) %>% mutate(var = "Mean monthly highest maximum"),
                  sen_fit(ta$TNm, ta$year) %>% mutate(var = "Mean monthly lowest minimum"))
cols <- c("Mean monthly highest maximum" = "#D55E00", "Mean monthly lowest minimum" = "#0072B2")
fS1 <- ggplot(tl, aes(year, value, colour = var)) +
  geom_line() + geom_point(size = 1.4) +
  geom_line(data = fits, aes(year, fit, colour = var), linetype = "dashed") +
  facet_wrap(~ var, ncol = 1, scales = "free_y") +
  scale_colour_manual(values = cols, guide = "none") +
  labs(x = "Year", y = "Temperature (\u00B0C)")
ggsave("outputs/figures/FigS1_temperature.tif", fS1, width = 7, height = 5.5, dpi = 600,
       device = "tiff", compression = "lzw", bg = "white")

k <- max(annual$rain) / 30
fS2 <- ggplot(annual, aes(year)) +
  geom_col(aes(y = rain), fill = "#4C6E91", width = .7) +
  geom_line(aes(y = PCI * k), colour = "#D55E00") +
  geom_point(aes(y = PCI * k), colour = "#D55E00", size = 1.4) +
  scale_y_continuous(name = "Annual rainfall (mm, bars)",
                     sec.axis = sec_axis(~ . / k, name = "PCI (line)")) +
  labs(x = "Year")
ggsave("outputs/figures/FigS2_rainfall_PCI.tif", fS2, width = 7, height = 4.5, dpi = 600,
       device = "tiff", compression = "lzw", bg = "white")

cat("\n"); print(R.version.string)
for (p in pkgs) cat(p, as.character(packageVersion(p)), "\n")
