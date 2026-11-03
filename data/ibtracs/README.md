# Tropical-cyclone tracks (IBTrACS)

`ibtracs.NI.list.v04r01.csv.gz` is a gzip-compressed snapshot of the International Best Track Archive for
Climate Stewardship, version v04r01, North Indian basin, downloaded on 3 November 2026 from
NOAA National Centers for Environmental Information.

- Source: https://www.ncei.noaa.gov/products/international-best-track-archive
- Citation: Knapp et al. (2010), doi:10.1175/2009BAMS2755.1; Knapp et al. (2018), doi:10.25921/82ty-9e16
- MD5 of the compressed file: `b5f05ec6c8a37a51f48e78f4e43a8610` (printed by the script); of the uncompressed CSV: `5b2ee844a60e3f3a88b6f07cf7d10d07`
- `code/04_cyclones_ibtracs.R` reads the compressed file directly; if it is removed, the script downloads the current version instead.

NOAA revises IBTrACS from time to time. The analysis uses only 1996–2025, and snapshots
downloaded on 6 October, 15 October and 3 November 2026 gave identical results.
