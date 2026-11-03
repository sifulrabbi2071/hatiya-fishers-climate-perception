# Fishers' climate-change perception and the observed record on Hatiya Island, Bangladesh

Data and code for the manuscript:

> Rabbi MSI, Parven A. Knowledge, perception, and adaptation of island fishers to climate change:
> convergence and divergence with observed environmental trends on Hatiya Island, Bangladesh.
> Manuscript in preparation.

The study compares the climate-change perceptions of 150 small-scale fishers on Hatiya Island
with the observed record of temperature, rainfall, tropical cyclones, shoreline change and salinity
(1996–2025), and examines how the fishers adapt and what holds them back.

## Repository contents

```
├── README.md, LICENSE, LICENSE-DATA.md, CITATION.cff, .zenodo.json
├── hatiya-fishers-climate-perception.Rproj   RStudio project (sets the working directory)
├── run_all.sh                 Reproduce everything in one command
├── install_packages.R         R packages used
├── requirements.txt           Python packages used
├── code/
│   ├── 01_shoreline_gee.js        Landsat shoreline analysis (Google Earth Engine)
│   ├── 02_survey_analysis.R       Survey statistics, reliability, regression; Figs 3–5, 7, 8
│   ├── 03_climate_trends.R        Mann–Kendall, Theil–Sen and PCI for BMD station data
│   ├── 04_cyclones_ibtracs.R      Cyclone counts and trends within 100 and 200 km
│   ├── 05_maps_shoreline.py       Study-area map (Fig. 1) and shoreline-change figure (Fig. 6)
│   └── 06_framework_diagram.py    Methodological framework (Fig. 2)
├── data/
│   ├── survey/        Anonymized questionnaire data, codebook
│   ├── shoreline/     Island polygons, area-change table, Landsat scene list (GEE exports)
│   ├── ibtracs/       IBTrACS v04r01 North Indian snapshot
│   ├── bmd/           Meteorological data: not included, see README
│   └── boundaries/    GADM boundaries: downloaded on first run
└── docs/
    └── questionnaire_english.pdf
```

Each data folder has its own README describing the files and their sources.

## How to reproduce

**Requirements:** R ≥ 4.3 and Python ≥ 3.9. The shoreline step (`01_shoreline_gee.js`) also needs a
Google Earth Engine account; its outputs are already archived in `data/shoreline/`, so it does not
need to be rerun to reproduce the results.

```bash
Rscript install_packages.R
pip install -r requirements.txt
bash run_all.sh
```

Figures are written to `outputs/figures/`, tables to `outputs/tables/` and the printed results to
`outputs/logs/`. Run any script on its own from the repository root, for example
`Rscript code/02_survey_analysis.R`.

**Windows / RStudio:** open `hatiya-fishers-climate-perception.Rproj` in RStudio (this makes the
repository root the working directory) and run the R scripts in `code/` in numerical order; run
the two Python scripts from a terminal opened in the repository root (`python code/05_maps_shoreline.py`).
`run_all.sh` needs a bash shell (Git Bash on Windows) with `Rscript` and `python3` on the path.

The temperature and rainfall step runs only after the BMD files have been obtained and placed in
`data/bmd/` (see `data/bmd/README.md`); otherwise `run_all.sh` skips it.

To rerun the shoreline analysis, paste `code/01_shoreline_gee.js` into the
[Earth Engine Code Editor](https://code.earthengine.google.com), run it, and start the export tasks.

## Expected results

| Quantity | Value | Script |
|---|---|---|
| Cronbach's α (LEK / CPI / ASI) | 0.81 / 0.89 / 0.39 | 02 |
| Climate Perception Index | 3.94 ± 0.56 (73.5 on 0–100) | 02 |
| Logistic regression of high adaptation | all p > 0.35; McFadden pseudo-R² = 0.01 | 02 |
| Monthly extreme Tmax / Tmin trend, 2000–2025 | +0.56 / +0.45 °C per decade (p < 0.001) | 03 |
| Annual rainfall trend; mean PCI; PCI trend | p = 0.14; 18.4; p = 0.87 | 03 |
| Systems within 200 km / 100 km, 1996–2025 | 34 (p = 0.35) / 20 (p = 0.12) | 04 |
| Island footprint, 1996 → 2025 | 392.3 → 372.5 km²; eroded 70.8 km², accreted 51.1 km² | 05 |
| Erosion north of 22.25° N, 2006–2025 | 23.0 km² | 05 |

**Cyclone reference point.** Distances are measured from 22.26° N, 91.10° E, the rounded centroid of the
1996 island footprint. Because the island has migrated south, the 2025 centroid lies 5 km further south;
using it gives 32 instead of 34 systems within 200 km (Mann–Kendall p = 0.68 instead of 0.35) and the
same 20 systems within 100 km, so no trend becomes significant.

Tested end to end from a clean copy with R 4.3.3 (haven 2.5.4, dplyr 1.1.4, tidyr 1.3.1,
readr 2.1.5, ggplot2 3.4.4, stringr 1.5.1, psych 2.4.1, trend 1.1.9, modifiedmk 1.6) and
Python 3.13 (geopandas 1.2.0, pandas 3.0.5, matplotlib 3.11.2, shapely 2.2.0).
Figure appearance can differ slightly with the installed fonts; the numbers do not.

## Data sources and permissions

| Data | Source | In this repository |
|---|---|---|
| Household survey (n = 150) | Collected by the authors, August–November 2025 | Yes, anonymized |
| Shoreline polygons and areas | Derived by the authors from USGS Landsat Collection 2 Level-2 | Yes |
| Tropical-cyclone tracks | NOAA IBTrACS v04r01 (Knapp et al. 2010, 2018) | Yes, snapshot of 3 Nov 2026 |
| Temperature and rainfall | Bangladesh Meteorological Department, Hatiya station | No: available from BMD on request |
| Administrative boundaries | GADM v4.1 | No: downloaded automatically |

The survey contains no names, contact details, locations or photographs. Participation was
voluntary and verbal informed consent was obtained before each interview.

## Licence

- Code (`code/`, `run_all.sh`, `install_packages.R`): MIT Licence, see `LICENSE`
- Data produced by the authors (`data/survey/`, `data/shoreline/`, `docs/`): Creative Commons
  Attribution 4.0 International (CC BY 4.0), see `LICENSE-DATA.md`
- Third-party data remain under the terms of their providers (NOAA, USGS, GADM, BMD).

## Citation

If you use these data or code, please cite this archive (and the manuscript above once it is published):

> Rabbi MSI, Parven A (2026). Data and code for: Knowledge, perception, and adaptation of island
> fishers to climate change on Hatiya Island, Bangladesh (v1.0.0) [Data set and software]. Zenodo.

The DOI is shown on the Zenodo record; the "Cite as" box there gives the citation in other styles.

## Authors

- Md Siful Islam Rabbi (corresponding author), ORCID [0009-0008-3516-4626](https://orcid.org/0009-0008-3516-4626)
- Afshana Parven, ORCID [0000-0003-0415-101X](https://orcid.org/0000-0003-0415-101X), afshana.parven@gmail.com

Department of Fisheries and Marine Science, Noakhali Science and Technology University, Noakhali,
Bangladesh.
