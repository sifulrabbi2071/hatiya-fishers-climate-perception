# Shoreline change (Google Earth Engine exports)

Produced by `code/01_shoreline_gee.js` (Landsat Collection 2 Level-2, dry-season
November–April median composites, MNDWI, largest contiguous landmass, four-pixel connectivity).
The GEE export names were shortened to lower case when archived: `Hatiya_island_YYYY` →
`hatiya_island_YYYY`, `Hatiya_area_change` → `hatiya_area_change`, and `Hatiya_scene_list` →
`hatiya_landsat_scenes`.

| File | Description |
|---|---|
| `hatiya_island_1996.*`, `hatiya_island_2006.*`, `hatiya_island_2025.*` | Island footprint polygons (ESRI shapefile, EPSG:4326), MNDWI threshold 0 |
| `hatiya_area_change.csv` | Area, erosion, accretion and net change for 1996–2025 and three sub-periods, at MNDWI thresholds −0.1, 0 and +0.1 (km², UTM 46N) |
| `hatiya_landsat_scenes.csv` | Every Landsat scene used in each composite: product ID, date and cloud cover (1996: 16; 2006: 19; 2016: 25; 2025: 67) |

The 2016 polygon was not exported; its areas are in `hatiya_area_change.csv`.
