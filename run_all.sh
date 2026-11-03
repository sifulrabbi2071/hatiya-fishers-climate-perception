#!/usr/bin/env bash
# Reproduce all statistics, tables and figures of the manuscript.
# Usage (from the repository root):  bash run_all.sh
# Logs and outputs are written to outputs/.
set -u
cd "$(dirname "$0")"
mkdir -p outputs/logs

run () {  # run <label> <log file> <command...>
  local label="$1" log="$2"; shift 2
  printf '%-54s' "$label"
  if "$@" > "outputs/logs/$log" 2>&1; then echo "done"; else echo "FAILED (see outputs/logs/$log)"; fi
}

run "1. Survey analysis (Tables 1-3, 5; Figs 3-5, 7, 8)" 02_survey_analysis.log  Rscript code/02_survey_analysis.R
if ls data/bmd/*.csv >/dev/null 2>&1; then
  run "2. Temperature and rainfall trends (Table S1)" 03_climate_trends.log   Rscript code/03_climate_trends.R
else
  printf '%-54s%s\n' "2. Temperature and rainfall trends" "skipped: BMD data not supplied (see data/bmd/README.md)"
fi
run "3. Tropical cyclones (Tables S2-S3)"           04_cyclones_ibtracs.log Rscript code/04_cyclones_ibtracs.R
run "4. Maps and shoreline change (Figs 1, 6)"      05_maps_shoreline.log   python3 code/05_maps_shoreline.py
run "5. Framework diagram (Fig. 2)"                 06_framework_diagram.log python3 code/06_framework_diagram.py
echo
echo "Figures: outputs/figures/   Tables: outputs/tables/   Console results: outputs/logs/"
