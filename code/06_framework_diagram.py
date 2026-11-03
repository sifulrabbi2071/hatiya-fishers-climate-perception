# Hatiya Island — methodological framework diagram (Fig. 2). Requires: matplotlib.
# Run from the repository root:  python3 code/06_framework_diagram.py
import matplotlib; matplotlib.use("Agg")
import matplotlib.pyplot as plt
from matplotlib.patches import FancyBboxPatch
plt.rcParams.update({"font.family": "sans-serif", "font.sans-serif": ["Arial", "Liberation Sans", "DejaVu Sans"]})
MM = 1/25.4
fig = plt.figure(figsize=(174*MM, 190*MM)); ax = fig.add_axes([0, 0, 1, 1]); ax.set_xlim(0, 100); ax.set_ylim(0, 110); ax.axis("off")
def box(x, y, w, h, title, body, ec, fc, tc, fs=7.2, bfs=6.3):
    ax.add_patch(FancyBboxPatch((x, y), w, h, boxstyle="round,pad=0.25,rounding_size=1.6", ec=ec, fc=fc, lw=1.0))
    if body:
        ax.text(x + w/2, y + h - 2.4, title, ha="center", va="top", fontsize=fs, fontweight="bold", color=tc)
        ax.text(x + w/2, y + h - 6.0, body, ha="center", va="top", fontsize=bfs, color="#222222", linespacing=1.35)
    else:
        ax.text(x + w/2, y + h/2, title, ha="center", va="center", fontsize=fs, fontweight="bold", color=tc, linespacing=1.3)
def arrow(x1, y1, x2, y2, c):
    ax.annotate("", xy=(x2, y2), xytext=(x1, y1), arrowprops=dict(arrowstyle="-|>", color=c, lw=1.0, shrinkA=0, shrinkB=0))
DK, BL, GR, GD, PU = "#1f4e5f", "#2c7bb6", "#1a7f3c", "#b8860b", "#6a51a3"
box(8, 101, 84, 7.5, "Mixed-methods convergence–divergence assessment, Hatiya Island, Bangladesh (1996–2025)", None, DK, "#e8eff2", DK, fs=7.6)
box(20, 89.8, 60, 8.3, "Study area and scoping", "Estuarine island in the Meghna estuary; fishing-dependent community; 30-year reference period", DK, "#eef3f5", DK)
arrow(50, 101, 50, 98.3, DK)
box(3, 80, 44, 6.5, "A. Fishers' knowledge, perception and adaptation\n(primary survey data)", None, BL, "#d6e6f4", BL, fs=6.8)
box(53, 80, 44, 6.5, "B. Observed climate and environmental record\n(instrumental, satellite and secondary data)", None, GR, "#d7eedd", GR, fs=6.8)
arrow(40, 89.8, 25, 86.8, DK); arrow(60, 89.8, 75, 86.8, DK)
A = [("A1  Household survey", "n = 150 small-scale fishers; face-to-face structured\ninterviews, August–November 2025"),
     ("A2  Questionnaire", "Socio-demographics; Local Ecological Knowledge (LEK);\nClimate Perception (CPI); Adaptation Strategies (ASI);\nbarrier checklist; five-point Likert items"),
     ("A3  Reliability and indices", "Cronbach's α (LEK 0.81; CPI 0.89; ASI 0.39);\ncomposite indices; item means, SD and % agreement"),
     ("A4  Determinants of adaptation", "Binary logistic regression (high vs low adapter);\nOLS and Spearman sensitivity analysis (R)")]
B = [("B1  Temperature and rainfall", "BMD Hatiya station: monthly extreme temperature\n(2000–2025) and rainfall (1999–2025);\nMann–Kendall, Theil–Sen slope, PCI"),
     ("B2  Tropical cyclones", "IBTrACS v04r01, 1996–2025; systems within\n100 and 200 km of the island centroid;\nfrequency and intensity trends"),
     ("B3  Shoreline change", "Landsat 5/8/9 dry-season composites (1996, 2006,\n2016, 2025); MNDWI; erosion–accretion budget;\nthreshold sensitivity (±0.1)"),
     ("B4  Salinity intrusion", "Secondary evidence: national saline-soil trends\n(SRDI) and recent Hatiya field surveys")]
ys = [66, 52.5, 39, 25.5]
for (t, b), y in zip(A, ys): box(3, y, 44, 11.5, t, b, BL, "#eef5fb", BL)
for (t, b), y in zip(B, ys): box(53, y, 44, 11.5, t, b, GR, "#eef8f0", GR)
for i in range(3):
    arrow(25, ys[i], 25, ys[i+1] + 11.5 + 0.3, BL); arrow(75, ys[i], 75, ys[i+1] + 11.5 + 0.3, GR)
arrow(25, 80, 25, 77.8, BL); arrow(75, 80, 75, 77.8, GR)
box(10, 12.5, 80, 10, "Convergence–divergence assessment", "Hazard-by-hazard comparison of the share of fishers perceiving change with the observed\nrecord; each signal classified as convergence, partial convergence or divergence", GD, "#fbf3df", GD)
arrow(25, 25.5, 38, 22.8, BL); arrow(75, 25.5, 62, 22.8, GR)
box(10, 0.3, 80, 9.6, "Interpretation and synthesis", "Reliability of local knowledge; erosive coping and maladaptation;\nstructural barriers; implications for coastal adaptation policy", PU, "#efe9f6", PU)
arrow(50, 12.5, 50, 10.2, GD)
import os; os.makedirs("outputs/figures", exist_ok=True)
fig.savefig("outputs/figures/Fig2.tif", dpi=600, pil_kwargs={"compression": "tiff_lzw"})
