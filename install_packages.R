# Install the R packages used in this repository (run once).
pkgs <- c("haven", "dplyr", "tidyr", "readr", "ggplot2", "stringr", "psych", "trend", "modifiedmk")
new  <- pkgs[!pkgs %in% installed.packages()[, "Package"]]
if (length(new)) install.packages(new, repos = "https://cloud.r-project.org")
for (p in pkgs) cat(sprintf("%-11s %s\n", p, as.character(packageVersion(p))))
