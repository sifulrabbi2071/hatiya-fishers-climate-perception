/* ============================================================================
 * Hatiya Island — Shoreline erosion and accretion, 1996–2025 (Section 2.5.3)
 * Google Earth Engine (JavaScript Code Editor)
 * ----------------------------------------------------------------------------
 * 1. Dry-season (Nov–Apr) median composites of Landsat Collection 2 Level-2
 *    surface reflectance:  1996 = Landsat 5 TM;  2025 = Landsat 8 OLI + Landsat 9 OLI-2
 *    (optional intermediate epochs 2006 and 2016 to test whether erosion accelerated)
 * 2. Water/land separation with MNDWI (Xu 2006); land = MNDWI < threshold
 * 3. Island footprint = largest contiguous landmass inside the AOI
 * 4. Erosion = land in epoch A but not B; accretion = land in B but not A;
 *    areas in UTM 46N (EPSG:32646)
 * 5. Threshold sensitivity (−0.1, 0, +0.1)
 * 6. Exports: island polygons (SHP), area/change table (CSV), list of Landsat
 *    scenes used in every composite (CSV) — keep these as evidence for reviewers.
 * The exports used in the manuscript are archived in data/shoreline/ of this repository.
 * ==========================================================================*/

// ---------------------------------------------------------------- 0. Settings
var AOI = ee.Geometry.Rectangle([90.93, 22.00, 91.27, 22.50]);  // Hatiya + surrounding water
var SEED = ee.Geometry.Point([91.10, 22.26]);                    // a point inside the island
var CLOUD_MAX = 20;            // scene-level CLOUD_COVER filter (%)
var APPLY_QA_MASK = true;      // pixel-level cloud/shadow mask from QA_PIXEL
var MAIN_T = 0;                // main MNDWI threshold
var THRESHOLDS = [-0.1, 0, 0.1];
var CRS = 'EPSG:32646';        // WGS 84 / UTM zone 46N
var SCALE = 30;
var EXPORT_FOLDER = 'Hatiya_shoreline';
var FILL_HOLES = false;        // true = remove inland water bodies (ponds, creeks) from the
                               // footprint so that only the outer shoreline defines the island

// Epochs. Note: filterDate() excludes the end date itself.
// The two main epochs reproduce the settings used in the manuscript.
var EPOCHS = [
  {name: '1996', start: '1995-11-01', end: '1996-04-30', sensor: 'L5',  year: 1996},
  {name: '2006', start: '2005-11-01', end: '2006-04-30', sensor: 'L5',  year: 2006},  // optional
  {name: '2016', start: '2015-11-01', end: '2016-04-30', sensor: 'L8',  year: 2016},  // optional
  {name: '2025', start: '2024-11-01', end: '2025-04-30', sensor: 'L89', year: 2025}
];

// ------------------------------------------------- 1. Landsat C2 L2 preparation
// Surface reflectance scaling for Collection 2 Level-2: DN * 0.0000275 − 0.2
function maskAndScale(img, greenBand, swirBand) {
  var sr = img.select([greenBand, swirBand], ['GREEN', 'SWIR1'])
              .multiply(0.0000275).add(-0.2);
  if (APPLY_QA_MASK) {
    // QA_PIXEL bits 0–4: fill, dilated cloud, cirrus, cloud, cloud shadow
    var qa = img.select('QA_PIXEL');
    var clear = qa.bitwiseAnd(parseInt('11111', 2)).eq(0);
    sr = sr.updateMask(clear);
  }
  return ee.Image(sr.copyProperties(img, ['system:time_start', 'LANDSAT_PRODUCT_ID', 'CLOUD_COVER']));
}
function prepTM(img)  { return maskAndScale(img, 'SR_B2', 'SR_B5'); }  // Landsat 4–5 TM
function prepOLI(img) { return maskAndScale(img, 'SR_B3', 'SR_B6'); }  // Landsat 8–9 OLI

function rawCollection(e) {
  var col;
  if (e.sensor === 'L5') {
    col = ee.ImageCollection('LANDSAT/LT05/C02/T1_L2');
  } else if (e.sensor === 'L8') {
    col = ee.ImageCollection('LANDSAT/LC08/C02/T1_L2');
  } else {
    col = ee.ImageCollection('LANDSAT/LC08/C02/T1_L2')
            .merge(ee.ImageCollection('LANDSAT/LC09/C02/T1_L2'));
  }
  return col.filterBounds(AOI)
            .filterDate(e.start, e.end)
            .filter(ee.Filter.lt('CLOUD_COVER', CLOUD_MAX));
}

function mndwiComposite(e) {
  var raw = rawCollection(e);
  var prep = (e.sensor === 'L5') ? raw.map(prepTM) : raw.map(prepOLI);
  return prep.median().clip(AOI).normalizedDifference(['GREEN', 'SWIR1']).rename('MNDWI');
}

// --------------------------------------------- 2. Island footprint (largest land)
function islandPolygon(mndwi, t) {
  var land = mndwi.lt(t).selfMask();
  var vec = land.reduceToVectors({
    geometry: AOI, crs: CRS, scale: SCALE,
    geometryType: 'polygon', eightConnected: false,  // 4-connectivity: thin channels separate land
    labelProperty: 'land', maxPixels: 1e10
  });
  vec = vec.map(function (f) {
    return f.set('area_km2', f.geometry().area({maxError: 1, proj: CRS}).divide(1e6));
  });
  var largest = ee.Feature(vec.sort('area_km2', false).first());
  if (FILL_HOLES) {
    var g = largest.geometry().transform(CRS, 1);
    var outer = ee.Geometry.Polygon({coords: ee.List(g.coordinates()).get(0), proj: CRS, geodesic: false});
    largest = ee.Feature(outer, {area_km2: outer.area({maxError: 1, proj: CRS}).divide(1e6)});
  }
  // check that the largest landmass is Hatiya (it must contain the seed point)
  return largest.set('contains_seed', largest.geometry().contains({right: SEED, maxError: 1}));
}

// ------------------------------------------------------- 3. Change between epochs
function change(fA, fB, nameA, nameB, years, t) {
  var gA = fA.geometry(), gB = fB.geometry();
  var opt = {maxError: 1, proj: CRS};
  var areaA = gA.area(opt).divide(1e6);
  var areaB = gB.area(opt).divide(1e6);
  var eroded   = gA.difference({right: gB, maxError: 1, proj: CRS}).area(opt).divide(1e6);
  var accreted = gB.difference({right: gA, maxError: 1, proj: CRS}).area(opt).divide(1e6);
  var stable   = gA.intersection({right: gB, maxError: 1, proj: CRS}).area(opt).divide(1e6);
  var net = areaB.subtract(areaA);
  return ee.Feature(null, {
    threshold: t, from: nameA, to: nameB, years: years,
    area_from_km2: areaA, area_to_km2: areaB,
    stable_km2: stable, eroded_km2: eroded, accreted_km2: accreted,
    net_km2: net, net_pct: net.divide(areaA).multiply(100),
    erosion_rate_km2_yr: eroded.divide(years),
    accretion_rate_km2_yr: accreted.divide(years),
    net_rate_km2_yr: net.divide(years),
    seed_check_from: fA.get('contains_seed'), seed_check_to: fB.get('contains_seed')
  });
}

// --------------------------------------------------------------- 4. Run analysis
var mndwi = {}, island = {};
EPOCHS.forEach(function (e) { mndwi[e.name] = mndwiComposite(e); });

var rows = [];
THRESHOLDS.forEach(function (t) {
  island[t] = {};
  EPOCHS.forEach(function (e) { island[t][e.name] = islandPolygon(mndwi[e.name], t); });
  var first = EPOCHS[0], last = EPOCHS[EPOCHS.length - 1];
  // whole period (main result)
  rows.push(change(island[t][first.name], island[t][last.name], first.name, last.name,
                   last.year - first.year, t));
  // consecutive intervals (erosion rate through time)
  for (var i = 0; i < EPOCHS.length - 1; i++) {
    var a = EPOCHS[i], b = EPOCHS[i + 1];
    if (EPOCHS.length > 2) {
      rows.push(change(island[t][a.name], island[t][b.name], a.name, b.name, b.year - a.year, t));
    }
  }
});
var results = ee.FeatureCollection(rows);
print('Area and change (km²) — check contains_seed is true for every epoch', results);

// Scenes used in each composite (product IDs, dates, cloud cover)
var sceneList = ee.FeatureCollection([]);
EPOCHS.forEach(function (e) {
  sceneList = sceneList.merge(ee.FeatureCollection(rawCollection(e).map(function (img) {
    return ee.Feature(null, {
      epoch: e.name,
      product_id: img.get('LANDSAT_PRODUCT_ID'),
      date: ee.Date(img.get('system:time_start')).format('YYYY-MM-dd'),
      cloud_cover: img.get('CLOUD_COVER')
    });
  })));
});
EPOCHS.forEach(function (e) {
  print('Scenes in ' + e.name + ' composite:', rawCollection(e).size());
});

// ------------------------------------------------------------------- 5. Display
Map.centerObject(AOI, 10);
var vis = {min: -0.6, max: 0.6, palette: ['8c510a', 'f6e8c3', '5ab4ac', '01665e']};
Map.addLayer(mndwi[EPOCHS[0].name], vis, 'MNDWI ' + EPOCHS[0].name, false);
Map.addLayer(mndwi[EPOCHS[EPOCHS.length - 1].name], vis, 'MNDWI ' + EPOCHS[EPOCHS.length - 1].name, false);
Map.addLayer(ee.FeatureCollection([island[MAIN_T][EPOCHS[0].name]]).style({color: 'red', fillColor: '00000000'}),
             {}, 'Island ' + EPOCHS[0].name);
Map.addLayer(ee.FeatureCollection([island[MAIN_T][EPOCHS[EPOCHS.length - 1].name]]).style({color: 'blue', fillColor: '00000000'}),
             {}, 'Island ' + EPOCHS[EPOCHS.length - 1].name);
Map.addLayer(SEED, {color: 'yellow'}, 'Seed point');

// -------------------------------------------------------------------- 6. Exports
Export.table.toDrive({collection: results, description: 'Hatiya_area_change',
                      folder: EXPORT_FOLDER, fileFormat: 'CSV'});
Export.table.toDrive({collection: sceneList, description: 'Hatiya_scene_list',
                      folder: EXPORT_FOLDER, fileFormat: 'CSV'});
EPOCHS.forEach(function (e) {
  Export.table.toDrive({
    collection: ee.FeatureCollection([island[MAIN_T][e.name].set('epoch', e.name)]),
    description: 'Hatiya_island_' + e.name, folder: EXPORT_FOLDER, fileFormat: 'SHP'
  });
});
