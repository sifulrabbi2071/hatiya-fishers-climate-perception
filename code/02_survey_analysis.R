# ============================================================================
# Hatiya Island — Fishers' Climate Change Survey (n = 150)
# Reproducible analysis for the manuscript (survey part).
# Reproduces: Table 1 (socio-demographics), Cronbach's alpha and composite
#             indices (LEK, CPI, ASI), Tables 2-3 (item summaries), robustness
#             checks of perception (experience subgroups, straight-lining),
#             adaptation-strategy and barrier summaries, Table 5 (binary
#             logistic regression) and its sensitivity analysis (Section 2.6),
#             and Figs 3, 4, 5, 7 and 8 (Figs 1, 2 and 6 are maps/diagrams).
# ----------------------------------------------------------------------------
# INPUT : data/survey/hatiya_fishers_survey_2025.sav
# OUTPUT: outputs/figures/Figure_3.tif, Figure_4.tif, Figure_5.tif, Figure_7.tif, Figure_8.tif (600 dpi) and console tables
# Figures carry no in-figure titles; captions are given in the manuscript.
# ============================================================================

## ---- 0. Packages ----------------------------------------------------------
pkgs <- c("haven", "dplyr", "ggplot2", "stringr", "psych")
new  <- pkgs[!pkgs %in% installed.packages()[, "Package"]]
if (length(new)) install.packages(new, repos = "https://cloud.r-project.org")
invisible(lapply(pkgs, library, character.only = TRUE))

dir.create("outputs/figures", recursive = TRUE, showWarnings = FALSE)

## ---- 1. Read data ----------------------------------------------------------
dat <- haven::read_sav("data/survey/hatiya_fishers_survey_2025.sav")
stopifnot(nrow(dat) == 150)

lek <- paste0("B", 1:10)
cpi <- paste0("C", 1:10)
asi <- paste0("D", 1:10)
bar <- paste0("E", 1:9)
d   <- dat %>% mutate(across(all_of(c(lek, cpi, asi, bar)), as.numeric))
stopifnot(!anyNA(d[c(lek, cpi, asi, bar)]))

theme_pub <- theme_minimal(base_size = 12, base_family = "sans") +
  theme(axis.title = element_text(face = "bold"),
        panel.grid.major.y = element_blank(),
        panel.grid.minor   = element_blank(),
        legend.position    = "top",
        plot.background    = element_rect(fill = "white", colour = NA),
        plot.margin        = margin(6, 18, 6, 6))
theme_set(theme_pub)
save_fig <- function(p, file, w = 7, h = 5)
  ggsave(file.path("outputs/figures", file), p, width = w, height = h,
         dpi = 600, device = "tiff", compression = "lzw", bg = "white")

## ---- 2. Table 1. Socio-demographic profile --------------------------------
demo <- c("A2_age", "A3_education", "A4_occupation", "A5_experience",
          "A6_vessel", "A7_income", "A8_household", "A9_credit")
tab1 <- do.call(rbind, lapply(demo, function(v) {
  x  <- haven::as_factor(dat[[v]], levels = "labels")
  tb <- table(x)                       # keeps empty categories (n = 0)
  data.frame(Variable = v, Category = names(tb), n = as.integer(tb),
             Percent  = round(100 * as.integer(tb) / nrow(dat), 1))
}))
cat("\n== Table 1 ==\n"); print(tab1, row.names = FALSE)

## ---- 3. Reliability and composite indices ---------------------------------
alpha_raw <- function(cols) psych::alpha(d[cols], warnings = FALSE)$total$raw_alpha
cat("\n== Cronbach's alpha ==\n",
    "LEK:", round(alpha_raw(lek), 2),
    " CPI:", round(alpha_raw(cpi), 2),
    " ASI:", round(alpha_raw(asi), 2), "\n")

d <- d %>% mutate(LEK = rowMeans(across(all_of(lek))),
                  CPI = rowMeans(across(all_of(cpi))),
                  ASI = rowMeans(across(all_of(asi))))
cat("\n== Composite indices (mean ± SD, 1-5 scale) ==\n")
for (v in c("LEK", "CPI", "ASI"))
  cat(sprintf("%s = %.2f ± %.2f\n", v, mean(d[[v]]), sd(d[[v]])))
cat(sprintf("CPI on 0-100 scale = %.1f\n", (mean(d$CPI) - 1) / 4 * 100))

## ---- 4. Item summaries (Tables 2 and 3; ASI items) ------------------------
likert_summary <- function(cols) {
  lab <- sapply(cols, function(v) attr(dat[[v]], "label"))
  data.frame(item  = cols,
             label = sub("^[A-Z0-9]+:\\s*", "", lab),
             mean  = sapply(cols, function(v) mean(d[[v]])),
             sd    = sapply(cols, function(v) sd(d[[v]])),
             agree = sapply(cols, function(v) 100 * mean(d[[v]] >= 4))) %>%
    arrange(desc(mean))
}
lek_s <- likert_summary(lek); cpi_s <- likert_summary(cpi); asi_s <- likert_summary(asi)
cat("\n== Table 2 (LEK) ==\n"); print(lek_s %>% mutate(across(mean:agree, ~ round(., 2))), row.names = FALSE)
cat("\n== Table 3 (CPI) ==\n"); print(cpi_s %>% mutate(across(mean:agree, ~ round(., 2))), row.names = FALSE)
cat("\n== ASI items ==\n");     print(asi_s %>% mutate(across(mean:agree, ~ round(., 2))), row.names = FALSE)


## ---- 4b. Robustness of perception results ----------------------------------
# (i) experience subgroups: > 20 years vs <= 20 years (Mann–Whitney U)
grp <- as.numeric(d$A5_experience) == 4
cat("\n== Perception by fishing experience (>20 vs <=20 years) ==\n")
for (v in cpi) {
  w <- suppressWarnings(wilcox.test(d[[v]][grp], d[[v]][!grp], exact = FALSE))
  cat(sprintf("%-4s %%agree >20y = %5.1f  <=20y = %5.1f  p = %.3f\n", v,
              100 * mean(d[[v]][grp] >= 4), 100 * mean(d[[v]][!grp] >= 4), w$p.value))
}
# (ii) straight-lining / acquiescence: respondents giving the same answer to all CPI items
sl <- apply(d[cpi], 1, function(r) length(unique(r)) == 1)
cat("\nStraight-liners on CPI:", sum(sl), "of", nrow(d), "\n")
for (v in c("C1", "C2", "C3", "C4", "C5"))
  cat(sprintf("%s %%agree excluding straight-liners = %.1f\n", v, 100 * mean(d[[v]][!sl] >= 4)))
cat("CPI alpha excluding straight-liners =", round(alpha_raw_sub <- psych::alpha(d[!sl, cpi], warnings = FALSE)$total$raw_alpha, 2), "\n")

## ---- 5. Fig 3. LEK item means ± SD ----------------------------------------
f3 <- ggplot(lek_s, aes(reorder(str_wrap(paste0(label, " (", item, ")"), 45), mean), mean)) +
  geom_col(fill = "#4C6E91", width = .7) +
  geom_errorbar(aes(ymin = mean - sd, ymax = pmin(mean + sd, 5)), width = .25) +
  geom_hline(yintercept = 3, linetype = "dashed", colour = "grey40") +
  coord_flip(ylim = c(1, 5.05), expand = FALSE) +
  labs(x = NULL, y = "Mean agreement\n(1 = strongly disagree ... 5 = strongly agree)")
save_fig(f3, "Figure_3.tif", 8, 5.5)

## ---- 6. Fig 4. CPI % agreeing ---------------------------------------------
f4 <- ggplot(cpi_s, aes(reorder(str_wrap(label, 45), agree), agree)) +
  geom_col(fill = "#4C6E91", width = .7) +
  geom_text(aes(label = sprintf("%.0f%%", agree)), hjust = -0.15, size = 3.3) +
  coord_flip(ylim = c(0, 100)) +
  labs(x = NULL, y = "% agreeing / strongly agreeing")
save_fig(f4, "Figure_4.tif", 8, 5.5)

## ---- 7. Fig 5. Perception vs observed record -------------------------------
# Verdicts follow the comparison in Table 4 of the manuscript.
conv <- data.frame(
  hazard  = c("Temperature rise", "Rainfall irregularity", "Cyclone frequency / intensity",
              "Coastal erosion / land loss", "Salinity intrusion"),
  perc    = 100 * sapply(c("C1", "C2", "C3", "C4", "C5"), function(v) mean(d[[v]] >= 4)),
  verdict = factor(c("Convergence", "Convergence", "Divergence", "Partial convergence", "Convergence"),
                   levels = c("Convergence", "Partial convergence", "Divergence")))
f5 <- ggplot(conv, aes(reorder(hazard, perc), perc, fill = verdict)) +
  geom_col(width = .65) +
  geom_text(aes(label = sprintf("%.0f%%", perc)), hjust = -0.15, size = 3.4) +
  scale_fill_manual(values = c("Convergence" = "#0072B2", "Partial convergence" = "#56B4E9",
                               "Divergence" = "#D55E00"), name = NULL, drop = FALSE) +
  coord_flip(ylim = c(0, 100)) +
  labs(x = NULL, y = "% of fishers perceiving the change")
save_fig(f5, "Figure_5.tif", 8, 4.6)

## ---- 8. Fig 7. Adaptation strategies --------------------------------------
asi_s$type <- ifelse(asi_s$item %in% c("D5", "D7", "D9"),
                     "Reactive / erosive coping", "Proactive / planned adaptation")
f6 <- ggplot(asi_s, aes(reorder(str_wrap(label, 45), mean), mean, fill = type)) +
  geom_col(width = .7) +
  scale_fill_manual(values = c("Proactive / planned adaptation" = "#0072B2",
                               "Reactive / erosive coping"      = "#D55E00"), name = NULL) +
  geom_hline(yintercept = 3, linetype = "dashed", colour = "grey40") +
  coord_flip(ylim = c(1, 5.05), expand = FALSE) +
  labs(x = NULL, y = "Mean frequency (1 = never ... 5 = always)")
save_fig(f6, "Figure_7.tif", 8.5, 5.5)

## ---- 9. Fig 8. Barriers -----------------------------------------------------
barb <- data.frame(item  = bar,
                   label = sub("^Barrier:\\s*", "", sapply(bar, function(v) attr(dat[[v]], "label"))),
                   n     = sapply(bar, function(v) sum(d[[v]])),
                   pct   = sapply(bar, function(v) 100 * mean(d[[v]]))) %>% arrange(desc(pct))
cat("\n== Barriers ==\n"); print(barb %>% mutate(pct = round(pct, 1)), row.names = FALSE)
f7 <- ggplot(barb, aes(reorder(str_wrap(label, 45), pct), pct)) +
  geom_col(fill = "#4C6E91", width = .7) +
  geom_text(aes(label = sprintf("%.0f%%", pct)), hjust = -0.15, size = 3.3) +
  coord_flip(ylim = c(0, 100)) +
  labs(x = NULL, y = "% of respondents reporting barrier")
save_fig(f7, "Figure_8.tif", 8, 5)

## ---- 10. Table 5. Binary logistic regression ------------------------------
d$ASI_total  <- rowSums(d[asi])
d$high_adapt <- as.integer(d$ASI_total > median(d$ASI_total))
preds <- c("A2_age", "A3_education", "A7_income", "A5_experience", "A6_vessel")
dz <- d %>% mutate(across(all_of(preds), ~ as.numeric(scale(as.numeric(.)))))
m  <- glm(high_adapt ~ A2_age + A3_education + A7_income + A5_experience + A6_vessel,
          data = dz, family = binomial)
tab5 <- data.frame(summary(m)$coef, OR = exp(coef(m)), check.names = FALSE)
cat("\n== Table 5 ==\n"); print(round(tab5, 3))
cat("McFadden pseudo-R2 =", round(1 - m$deviance / m$null.deviance, 3), "\n")

## ---- 11. Sensitivity analysis (Section 2.6) --------------------------------
ols <- lm(ASI_total ~ A2_age + A3_education + A7_income + A5_experience + A6_vessel, data = dz)
cat("\n== Sensitivity: OLS on continuous ASI total ==\n")
print(round(summary(ols)$coefficients, 3))
cat("\n== Sensitivity: Spearman correlations with ASI total ==\n")
for (v in preds) {
  ct <- suppressWarnings(cor.test(as.numeric(d[[v]]), d$ASI_total, method = "spearman"))
  cat(sprintf("%-14s rho = %6.3f  p = %.3f\n", v, ct$estimate, ct$p.value))
}

## ---- 12. Software versions (report in Methods) -----------------------------
cat("\n"); print(R.version.string)
for (p in pkgs) cat(p, as.character(packageVersion(p)), "\n")
cat("\nAll figures written to ./figures at 600 dpi.\n")
