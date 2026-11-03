"""
Hatiya Island — study-area map (Fig. 1) and shoreline-change figure (Fig. 6).
Inputs : GADM v4.1 Bangladesh boundaries (downloaded to data/boundaries/ on first run),
         GEE exports in data/shoreline/ (island polygons and hatiya_area_change.csv)
Outputs: outputs/figures/Fig1.tif, Fig6.tif (600 dpi, 174 mm wide, no in-figure titles)
Requires: Python >= 3.9, geopandas, pandas, numpy, matplotlib
          (pip install geopandas matplotlib). GADM files are downloaded on first run.
Run from the repository root:  python3 code/05_maps_shoreline.py
"""
import os, urllib.request, zipfile
import geopandas as gpd, pandas as pd, numpy as np
import matplotlib; matplotlib.use("Agg")
import matplotlib.pyplot as plt
from matplotlib.patches import Patch, Rectangle, FancyArrow
from matplotlib.lines import Line2D

plt.rcParams.update({"font.family": "sans-serif", "font.sans-serif": ["Arial", "Liberation Sans", "DejaVu Sans"], "font.size": 8,
                     "axes.linewidth": 0.6, "xtick.major.width": 0.6, "ytick.major.width": 0.6})
MM = 1 / 25.4
UTM = 32646
C_STABLE, C_ERO, C_ACC = "#d9cfc1", "#C0392B", "#2E8B57"
WATER, LAND = "#e6f0f7", "#ececec"

def deg_ticks(ax, xt, yt):
    ax.set_xticks(xt); ax.set_yticks(yt)
    ax.set_xticklabels([f"{x:.1f}°E" if abs(x*10-round(x*10))<1e-6 else f"{x:.2f}°E" for x in xt])
    ax.set_yticklabels([f"{y:.1f}°N" if abs(y*10-round(y*10))<1e-6 else f"{y:.2f}°N" for y in yt])
    ax.tick_params(length=2, pad=1.5, labelsize=6.5)
    ax.set_xlabel(""); ax.set_ylabel("")

def scalebar(ax, x0, y0, km, lat):
    dlon = km / (111.32 * np.cos(np.radians(lat)))
    ax.add_patch(Rectangle((x0, y0), dlon / 2, dlon * 0.04, fc="k", ec="k", lw=0.5))
    ax.add_patch(Rectangle((x0 + dlon / 2, y0), dlon / 2, dlon * 0.04, fc="w", ec="k", lw=0.5))
    for f, t in [(0, "0"), (0.5, f"{km/2:g}"), (1, f"{km:g} km")]:
        ax.text(x0 + f * dlon, y0 + dlon * 0.07, t, ha="center", va="bottom", fontsize=6)

def north(ax, x, y, size):
    ax.annotate("N", xy=(x, y), xytext=(x, y - size), ha="center", va="center", fontsize=7, fontweight="bold",
                arrowprops=dict(arrowstyle="-|>", lw=0.8, color="k"))

# GADM v4.1 boundaries for Bangladesh (downloaded once if not present)
os.makedirs("data/boundaries", exist_ok=True); os.makedirs("outputs/figures", exist_ok=True)
for lev in (2, 3):
    f = f"data/boundaries/gadm41_BGD_{lev}.json"
    if not os.path.exists(f):
        z = f + ".zip"
        urllib.request.urlretrieve(f"https://geodata.ucdavis.edu/gadm/gadm4.1/json/gadm41_BGD_{lev}.json.zip", z)
        zipfile.ZipFile(z).extractall("data/boundaries")
g2 = gpd.read_file("data/boundaries/gadm41_BGD_2.json")
g3 = gpd.read_file("data/boundaries/gadm41_BGD_3.json")
isl = {y: gpd.read_file(f"data/shoreline/hatiya_island_{y}.shp").to_crs(4326) for y in ["1996", "2025"]}

# ------------------------------------------------------------------ Fig. 1
fig = plt.figure(figsize=(174 * MM, 105 * MM))
axA = fig.add_axes([0.04, 0.08, 0.40, 0.88]); axB = fig.add_axes([0.53, 0.08, 0.45, 0.88])
for ax in (axA, axB): ax.set_facecolor(WATER)
g2.plot(ax=axA, color=LAND, edgecolor="#9a9a9a", lw=0.25)
g2[g2.NAME_2 == "Noakhali"].plot(ax=axA, color="#f2c48d", edgecolor="#9a9a9a", lw=0.25)
axA.add_patch(Rectangle((90.85, 21.95), 0.5, 0.7, fill=False, ec="red", lw=0.9))
axA.set_xlim(88.0, 92.75); axA.set_ylim(20.55, 26.7); axA.set_aspect(1 / np.cos(np.radians(23.5)))
deg_ticks(axA, [89, 90, 91, 92], [21, 22, 23, 24, 25, 26])
axA.text(90.1, 21.1, "Bay of Bengal", fontsize=7, style="italic", ha="center", color="#2b5d7d")
axA.text(88.25, 26.45, "(a)", fontsize=8, fontweight="bold")
axA.legend(handles=[Patch(fc="#f2c48d", ec="#9a9a9a", lw=0.3, label="Noakhali District"),
                    Patch(fill=False, ec="red", label="Extent of panel (b)")],
           loc="lower left", fontsize=6, frameon=True, framealpha=0.9, borderpad=0.4)
scalebar(axA, 91.35, 20.75, 100, 21)
north(axA, 92.45, 26.45, 0.35)

ext = (90.85, 91.35, 21.90, 22.65)
ctx = g3.cx[ext[0]:ext[1], ext[2]:ext[3]]
ctx[ctx.NAME_3 != "Hatiya"].plot(ax=axB, color=LAND, edgecolor="#b5b5b5", lw=0.3)
ctx[ctx.NAME_3 == "Hatiya"].plot(ax=axB, color="#f7e9d4", edgecolor="#b5b5b5", lw=0.3)
isl["2025"].plot(ax=axB, color="#7fb27f", edgecolor="#2f6b2f", lw=0.5)
axB.set_xlim(ext[0], ext[1]); axB.set_ylim(ext[2], ext[3]); axB.set_aspect(1 / np.cos(np.radians(22.3)))
deg_ticks(axB, [90.9, 91.0, 91.1, 91.2, 91.3], [21.9, 22.0, 22.1, 22.2, 22.3, 22.4, 22.5, 22.6])
for (x, y, t, s) in [(91.105, 22.25, "Hatiya\n(study area)", "normal"), (90.935, 22.17, "Manpura\n(Bhola)", "normal"),
                     (91.265, 22.6, "Noakhali\nmainland", "normal"), (91.17, 21.95, "Bay of Bengal", "italic"),
                     (91.0, 22.30, "Meghna\nestuary", "italic"), (91.02, 22.005, "Nijhum Dwip", "normal")]:
    axB.text(x, y, t, fontsize=6.5, ha="center", va="center", style=s,
             color="#2b5d7d" if s == "italic" else "k")
axB.text(ext[0] + 0.01, ext[3] - 0.03, "(b)", fontsize=8, fontweight="bold")
axB.legend(handles=[Patch(fc="#7fb27f", ec="#2f6b2f", lw=0.5, label="Island footprint 2025 (Landsat)"),
                    Patch(fc="#f7e9d4", ec="#b5b5b5", lw=0.3, label="Hatiya Upazila (GADM)"),
                    Patch(fc=LAND, ec="#b5b5b5", lw=0.3, label="Other land (GADM)")],
           loc="upper left", bbox_to_anchor=(0.0, 0.94), fontsize=5.8, frameon=True, framealpha=0.95, borderpad=0.4)
scalebar(axB, 90.87, 21.925, 10, 21.93)
north(axB, 91.32, 22.62, 0.04)
fig.savefig("outputs/figures/Fig1.tif", dpi=600, pil_kwargs={"compression": "tiff_lzw"})
plt.close(fig)

# ------------------------------------------------------------------ Fig. 6
a = isl["1996"].to_crs(UTM).geometry.iloc[0].buffer(0)
b = isl["2025"].to_crs(UTM).geometry.iloc[0].buffer(0)
parts = {"Stable": a.intersection(b), "Eroded": a.difference(b), "Accreted": b.difference(a)}
area = {k: v.area / 1e6 for k, v in parts.items()}
fig = plt.figure(figsize=(174 * MM, 120 * MM))
axA = fig.add_axes([0.06, 0.07, 0.38, 0.91]); axB = fig.add_axes([0.58, 0.14, 0.40, 0.78])
axA.set_facecolor(WATER)
for k, c in [("Stable", C_STABLE), ("Eroded", C_ERO), ("Accreted", C_ACC)]:
    gpd.GeoSeries([parts[k]], crs=UTM).to_crs(4326).plot(ax=axA, color=c, lw=0)
axA.set_xlim(90.98, 91.21); axA.set_ylim(22.06, 22.455); axA.set_aspect(1 / np.cos(np.radians(22.25)))
deg_ticks(axA, [91.0, 91.05, 91.1, 91.15, 91.2], [22.1, 22.2, 22.3, 22.4])
axA.legend(handles=[Patch(fc=C_STABLE, label=f"Stable ({area['Stable']:.1f} km²)"),
                    Patch(fc=C_ERO, label=f"Eroded ({area['Eroded']:.1f} km²)"),
                    Patch(fc=C_ACC, label=f"Accreted ({area['Accreted']:.1f} km²)")],
           loc="upper right", fontsize=6.3, frameon=True, framealpha=0.95, title="1996–2025", title_fontsize=6.5)
axA.text(90.987, 22.44, "(a)", fontsize=8, fontweight="bold")
scalebar(axA, 90.99, 22.072, 5, 22.07)
north(axA, 90.99, 22.415, 0.02)

df = pd.read_csv("data/shoreline/hatiya_area_change.csv")
iv = [("1996", "2006"), ("2006", "2016"), ("2016", "2025")]
lab = ["1996–2006", "2006–2016", "2016–2025"]
def get(t, f, to, col):
    r = df[(np.isclose(df.threshold, t)) & (df["from"].astype(str) == f) & (df["to"].astype(str) == to)]
    return float(r[col].iloc[0])
x = np.arange(len(iv)); w = 0.36
for j, (col, c, name) in enumerate([("erosion_rate_km2_yr", C_ERO, "Erosion"), ("accretion_rate_km2_yr", C_ACC, "Accretion")]):
    sg = -1 if name == "Erosion" else 1          # erosion plotted as land lost (negative)
    mid = sg * np.array([get(0, f, t, col) for f, t in iv])
    vals = np.array([[sg * get(th, f, t, col) for th in (-0.1, 0, 0.1)] for f, t in iv])
    lo, hi = vals.min(1), vals.max(1)
    axB.bar(x, mid, 0.55, color=c, label=name + (" (land lost)" if sg < 0 else " (land gained)"))
    axB.errorbar(x, mid, yerr=[mid - lo, hi - mid], fmt="none", ecolor="k", elinewidth=0.6, capsize=2)
net = [get(0, f, t, "net_rate_km2_yr") for f, t in iv]
axB.plot(x, net, "D", color="k", ms=4, label="Net change", zorder=5)
axB.axhline(0, color="k", lw=0.5)
axB.set_xticks(x); axB.set_xticklabels(lab, fontsize=7)
axB.set_ylabel(r"Rate of change (km$^{2}$ yr$^{-1}$)", fontsize=7.5, fontweight="bold")
axB.tick_params(labelsize=6.5, length=2)
axB.spines[["top", "right"]].set_visible(False)
axB.legend(fontsize=6.3, frameon=False, loc="upper right")
axB.set_ylim(-5.8, 5.2)
axB.text(-0.55, 5.45, "(b)", fontsize=8, fontweight="bold")
fig.savefig("outputs/figures/Fig6.tif", dpi=600, pil_kwargs={"compression": "tiff_lzw"})
plt.close(fig)
print({k: round(v, 2) for k, v in area.items()})

# ------------------------------------------------------------------ Zonal check (Section 3.4)
# Erosion and accretion north and south of 22.25° N, reported in the Results text.
from shapely.geometry import box
fp = {y: gpd.read_file(f"data/shoreline/hatiya_island_{y}.shp").to_crs(UTM).geometry.iloc[0].buffer(0)
      for y in ["1996", "2006", "2025"]}
north_zone = gpd.GeoSeries([box(90.9, 22.25, 91.3, 22.6)], crs=4326).to_crs(UTM).iloc[0]
for y0, y1 in [("1996", "2006"), ("2006", "2025"), ("1996", "2025")]:
    ero, acc = fp[y0].difference(fp[y1]), fp[y1].difference(fp[y0])
    print(f"{y0}-{y1}: eroded north {ero.intersection(north_zone).area/1e6:.1f} km², "
          f"south {ero.difference(north_zone).area/1e6:.1f} km² | accreted north "
          f"{acc.intersection(north_zone).area/1e6:.1f} km², south {acc.difference(north_zone).area/1e6:.1f} km²")
