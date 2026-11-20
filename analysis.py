"""Run every SQL file in ./sql against the Olist data, save results and charts.

Usage:
    python get_data.py      # once, downloads the CSVs into ./data
    python analysis.py      # builds olist.duckdb, writes results/*.csv and charts/*.png
"""
from pathlib import Path

import duckdb
import matplotlib.pyplot as plt
import matplotlib.ticker as mtick

ROOT = Path(__file__).parent
SQL, RESULTS, CHARTS = ROOT / "sql", ROOT / "results", ROOT / "charts"
RESULTS.mkdir(exist_ok=True)
CHARTS.mkdir(exist_ok=True)

BLUE, ORANGE, GRAY, INK, MUTED = "#2a78d6", "#eb6834", "#b8b7b0", "#0b0b0b", "#52514e"
plt.rcParams.update({
    "font.family": "DejaVu Sans", "font.size": 10, "axes.edgecolor": GRAY,
    "axes.labelcolor": MUTED, "xtick.color": MUTED, "ytick.color": MUTED,
    "axes.spines.top": False, "axes.spines.right": False, "axes.grid": True,
    "grid.color": "#e7e6e1", "grid.linewidth": 0.8, "axes.axisbelow": True,
    "figure.dpi": 150, "savefig.bbox": "tight",
})


def title(ax, main, sub):
    ax.set_title(main, loc="left", fontsize=13, fontweight="bold", color=INK, pad=22)
    ax.text(0, 1.02, sub, transform=ax.transAxes, fontsize=9.5, color=MUTED)


con = duckdb.connect(str(ROOT / "olist.duckdb"))
con.execute(f"SET file_search_path = '{ROOT}'")
con.execute((SQL / "00_build_tables.sql").read_text())

res = {}
for f in sorted(SQL.glob("0[1-9]_*.sql")):
    df = con.execute(f.read_text()).df()
    res[f.stem] = df
    df.to_csv(RESULTS / f"{f.stem}.csv", index=False)
    print(f"\n=== {f.stem}\n{df.to_string(index=False)}")

# 1. Monthly revenue
m = res["02_monthly_kpis"]
fig, ax = plt.subplots(figsize=(9, 4))
ax.plot(m["order_month"], m["revenue_brl"] / 1e3, color=BLUE, lw=2)
ax.scatter(m["order_month"].iloc[-1], m["revenue_brl"].iloc[-1] / 1e3, color=BLUE, s=30, zorder=3)
peak = m.loc[m["revenue_brl"].idxmax()]
ax.annotate(f"Nov 2017 (Black Friday): R${peak.revenue_brl/1e3:,.0f}k", (peak.order_month, peak.revenue_brl / 1e3),
            xytext=(-200, 0), textcoords="offset points", color=INK, fontsize=9,
            arrowprops=dict(arrowstyle="-", color=GRAY))
ax.yaxis.set_major_formatter(mtick.FuncFormatter(lambda v, _: f"R${v:,.0f}k"))
title(ax, "Revenue grew fast in 2017, then flattened in 2018", "Monthly revenue (items + freight), Jan 2017 – Aug 2018")
fig.savefig(CHARTS / "01_monthly_revenue.png"); plt.close(fig)

# 2. Late delivery vs review
d = res["05_late_delivery_vs_reviews"]
labels = [f"{b.split('. ')[1]}\n{p:.1f}% of orders" for b, p in zip(d["delivery_bucket"], d["pct_of_orders"])]
fig, ax = plt.subplots(figsize=(9, 4))
colors = [BLUE] + [ORANGE] * (len(d) - 1)
bars = ax.bar(labels, d["avg_review"], color=colors, width=0.6)
for b, v, n in zip(bars, d["avg_review"], d["pct_of_orders"]):
    ax.text(b.get_x() + b.get_width() / 2, v + 0.08, f"{v:.2f}★", ha="center", color=INK, fontsize=10, fontweight="bold")
ax.set_ylim(0, 5)
ax.set_ylabel("Average review score (1–5)")
title(ax, "A late order costs about 2 stars", "Average review score by how late the order arrived vs. the promised date")
fig.savefig(CHARTS / "02_late_delivery_reviews.png"); plt.close(fig)

# 3. Categories
c = res["04_category_performance"].iloc[::-1]
fig, ax = plt.subplots(figsize=(9, 4.5))
ax.barh(c["category"].str.replace("_", " "), c["revenue_brl"] / 1e3, color=BLUE, height=0.6)
for y, (v, p) in enumerate(zip(c["revenue_brl"], c["pct_of_revenue"])):
    ax.text(v / 1e3 + 15, y, f"R${v/1e3:,.0f}k  ({p}%)", va="center", fontsize=8.5, color=MUTED)
ax.xaxis.set_major_formatter(mtick.FuncFormatter(lambda v, _: f"R${v:,.0f}k"))
ax.grid(axis="y", visible=False)
ax.set_xlim(0, c["revenue_brl"].max() / 1e3 * 1.3)
title(ax, "Top 10 categories by revenue", "Revenue (items + freight), Jan 2017 – Aug 2018")
fig.savefig(CHARTS / "03_top_categories.png"); plt.close(fig)

# 4. RFM segments
r = res["08_rfm_segments"].iloc[::-1]
fig, ax = plt.subplots(figsize=(9, 4))
y = range(len(r))
ax.barh([i + 0.2 for i in y], r["pct_customers"], height=0.38, color=GRAY, label="% of customers")
ax.barh([i - 0.2 for i in y], r["pct_revenue"], height=0.38, color=BLUE, label="% of revenue")
ax.set_yticks(list(y), r["segment"])
ax.xaxis.set_major_formatter(mtick.PercentFormatter())
ax.grid(axis="y", visible=False)
ax.legend(frameon=False, loc="lower right")
title(ax, "Customer segments (RFM)", "Share of customers vs. share of revenue per segment")
fig.savefig(CHARTS / "04_rfm_segments.png"); plt.close(fig)

print("\nCharts written to", CHARTS)
