"""
Run the Olist analysis end to end.

    python scripts/run_analysis.py --setup   # create tables, load CSVs, build views, then analyse
    python scripts/run_analysis.py           # just re-run the analysis queries + charts

Each query in sql/analysis/ is executed with psql, its result is saved to
results/<query>.csv, and the key charts are written to images/.

Connection settings come from the standard PostgreSQL environment variables
(PGHOST, PGPORT, PGUSER, PGPASSWORD, PGDATABASE). Defaults match docker-compose.yml.
"""

from __future__ import annotations

import argparse
import io
import os
import subprocess
from pathlib import Path

import matplotlib

matplotlib.use("Agg")
import matplotlib.pyplot as plt
import matplotlib.ticker as mtick
import pandas as pd

ROOT = Path(__file__).resolve().parents[1]
SQL_DIR = ROOT / "sql"
RESULTS_DIR = ROOT / "results"
IMAGES_DIR = ROOT / "images"

PG_DEFAULTS = {
    "PGHOST": "localhost",
    "PGPORT": "5432",
    "PGUSER": "postgres",
    "PGPASSWORD": "postgres",
    "PGDATABASE": "olist",
}

# Chart styling: one accent colour, recessive grid, no chart junk
BLUE, ORANGE, INK, MUTED, GRID = "#2a78d6", "#eb6834", "#0b0b0b", "#52514e", "#e4e3df"
plt.rcParams.update({
    "figure.dpi": 150,
    "font.size": 10,
    "axes.edgecolor": GRID,
    "axes.labelcolor": MUTED,
    "axes.titlesize": 13,
    "axes.titleweight": "bold",
    "axes.titlecolor": INK,
    "axes.titlelocation": "left",
    "axes.spines.top": False,
    "axes.spines.right": False,
    "axes.grid": True,
    "axes.axisbelow": True,
    "grid.color": GRID,
    "grid.linewidth": 0.8,
    "xtick.color": MUTED,
    "ytick.color": MUTED,
})


# ----------------------------------------------------------------------------
# Database helpers
# ----------------------------------------------------------------------------
def pg_env() -> dict:
    env = os.environ.copy()
    for key, value in PG_DEFAULTS.items():
        env.setdefault(key, value)
    return env


def run_sql_file(path: Path) -> str:
    """Execute a SQL file with psql (stops on the first error)."""
    out = subprocess.run(
        ["psql", "-v", "ON_ERROR_STOP=1", "-q", "-f", str(path)],
        cwd=ROOT, env=pg_env(), capture_output=True, text=True,
    )
    if out.returncode != 0:
        raise RuntimeError(f"{path.name} failed:\n{out.stderr}")
    return out.stdout


def query_to_df(path: Path) -> pd.DataFrame:
    """Run a single-SELECT SQL file and return the result as a DataFrame."""
    out = subprocess.run(
        ["psql", "-v", "ON_ERROR_STOP=1", "--csv", "-f", str(path)],
        cwd=ROOT, env=pg_env(), capture_output=True, text=True,
    )
    if out.returncode != 0:
        raise RuntimeError(f"{path.name} failed:\n{out.stderr}")
    return pd.read_csv(io.StringIO(out.stdout))


# ----------------------------------------------------------------------------
# Charts
# ----------------------------------------------------------------------------
def save(fig, name: str) -> None:
    fig.tight_layout()
    fig.savefig(IMAGES_DIR / name, bbox_inches="tight", facecolor="white")
    plt.close(fig)


def chart_monthly_revenue(df: pd.DataFrame) -> None:
    df["order_month"] = pd.to_datetime(df["order_month"])
    fig, ax = plt.subplots(figsize=(9, 4))
    ax.plot(df["order_month"], df["revenue"] / 1e6, color=BLUE, linewidth=2, marker="o", markersize=4)
    peak = df.loc[df["revenue"].idxmax()]
    ax.annotate(f"Peak: {peak['order_month']:%b %Y}\nR${peak['revenue'] / 1e6:.2f}M",
                (peak["order_month"], peak["revenue"] / 1e6), xytext=(-40, -45),
                textcoords="offset points", color=INK, fontsize=9,
                arrowprops=dict(arrowstyle="-", color=MUTED, lw=0.8))
    ax.set_title("Monthly revenue, delivered orders")
    ax.set_ylabel("Revenue (R$ millions)")
    ax.set_ylim(bottom=0)
    save(fig, "01_monthly_revenue.png")


def chart_weekday_hour(df: pd.DataFrame) -> None:
    pivot = df.pivot_table(index="weekday_name", columns="hour", values="orders", aggfunc="sum")
    order = df.drop_duplicates("weekday").sort_values("weekday")["weekday_name"]
    pivot = pivot.reindex(order).fillna(0)
    fig, ax = plt.subplots(figsize=(10, 3.4))
    im = ax.imshow(pivot.values, aspect="auto", cmap="Blues")
    ax.set_xticks(range(0, 24, 2), [f"{h}h" for h in range(0, 24, 2)])
    ax.set_yticks(range(len(pivot.index)), pivot.index)
    ax.grid(False)
    ax.set_title("When customers order: day of week x hour")
    fig.colorbar(im, ax=ax, label="Orders", shrink=0.8)
    save(fig, "02_orders_heatmap.png")


def chart_top_categories(df: pd.DataFrame) -> None:
    top = df.head(10).iloc[::-1]
    fig, ax = plt.subplots(figsize=(9, 4.5))
    ax.barh(top["category"].str.replace("_", " "), top["revenue"] / 1e6, color=BLUE, height=0.7)
    for y, (rev, share) in enumerate(zip(top["revenue"], top["revenue_share_pct"])):
        ax.text(rev / 1e6, y, f"  {share:.1f}%", va="center", color=MUTED, fontsize=8)
    ax.set_title("Top 10 categories by revenue (label = share of total)")
    ax.set_xlabel("Revenue (R$ millions)")
    ax.grid(axis="y", visible=False)
    save(fig, "03_top_categories.png")


def chart_late_vs_reviews(df: pd.DataFrame) -> None:
    labels = df["delivery_bucket"].str[3:]
    colors = [BLUE if "late" not in b else ORANGE for b in df["delivery_bucket"]]
    fig, ax = plt.subplots(figsize=(9, 4))
    bars = ax.bar(labels, df["avg_review"], color=colors, width=0.65)
    ax.bar_label(bars, fmt="%.2f", padding=3, color=INK, fontsize=9)
    ax.set_ylim(0, 5.4)
    ax.set_title("Average review score by delivery timeliness")
    ax.set_ylabel("Avg review score (1-5)")
    ax.grid(axis="x", visible=False)
    plt.setp(ax.get_xticklabels(), rotation=15, ha="right")
    save(fig, "04_late_delivery_vs_reviews.png")


def chart_cohorts(df: pd.DataFrame) -> None:
    df["cohort_month"] = pd.to_datetime(df["cohort_month"]).dt.strftime("%Y-%m")
    pivot = df[df["month_number"] > 0].pivot(index="cohort_month", columns="month_number", values="retention_pct")
    fig, ax = plt.subplots(figsize=(8, 6))
    im = ax.imshow(pivot.values, aspect="auto", cmap="Blues")
    ax.set_xticks(range(len(pivot.columns)), [f"M+{c}" for c in pivot.columns])
    ax.set_yticks(range(len(pivot.index)), pivot.index)
    for (i, j), v in pd.DataFrame(pivot.values).stack().dropna().items():
        ax.text(j, i, f"{v:.2f}%", ha="center", va="center", fontsize=7,
                color="white" if v > pivot.values[~pd.isna(pivot.values)].max() * 0.6 else INK)
    ax.grid(False)
    ax.set_title("Customer retention by first-purchase cohort")
    save(fig, "05_cohort_retention.png")


def chart_rfm(df: pd.DataFrame) -> None:
    d = df.sort_values("pct_customers")
    fig, axes = plt.subplots(1, 2, figsize=(11, 4), sharey=True)
    axes[0].barh(d["segment"], d["pct_customers"], color=BLUE, height=0.65)
    axes[0].set_title("Share of customers")
    axes[1].barh(d["segment"], d["pct_revenue"], color=BLUE, height=0.65)
    axes[1].set_title("Share of revenue")
    for ax in axes:
        ax.xaxis.set_major_formatter(mtick.PercentFormatter(decimals=0))
        ax.grid(axis="y", visible=False)
    fig.suptitle("RFM customer segments", x=0.01, ha="left", fontweight="bold", color=INK)
    save(fig, "06_rfm_segments.png")


def chart_state_delivery(df: pd.DataFrame) -> None:
    d = df.sort_values("avg_delivery_days")
    fig, ax = plt.subplots(figsize=(9, 5.5))
    colors = [ORANGE if x >= d["avg_delivery_days"].quantile(0.75) else BLUE for x in d["avg_delivery_days"]]
    ax.barh(d["customer_state"], d["avg_delivery_days"], color=colors, height=0.7)
    ax.set_title("Average delivery time by customer state (slowest quartile highlighted)")
    ax.set_xlabel("Days from purchase to delivery")
    ax.grid(axis="y", visible=False)
    ax.tick_params(axis="y", labelsize=8)
    save(fig, "07_delivery_days_by_state.png")


CHARTS = {
    "q01_monthly_revenue": chart_monthly_revenue,
    "q02_orders_by_weekday_hour": chart_weekday_hour,
    "q03_top_categories": chart_top_categories,
    "q05_late_delivery_vs_reviews": chart_late_vs_reviews,
    "q07_cohort_retention": chart_cohorts,
    "q08_rfm_segments": chart_rfm,
    "q04_state_performance": chart_state_delivery,
}


# ----------------------------------------------------------------------------
def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("--setup", action="store_true", help="create tables, load data and build views first")
    args = parser.parse_args()

    RESULTS_DIR.mkdir(exist_ok=True)
    IMAGES_DIR.mkdir(exist_ok=True)

    if args.setup:
        for name in ["01_create_tables.sql", "02_load_data.sql", "03_create_views.sql"]:
            print(f"-> {name}")
            output = run_sql_file(SQL_DIR / name)
            if output.strip():
                print(output)

    for path in sorted((SQL_DIR / "analysis").glob("q*.sql")):
        df = query_to_df(path)
        df.to_csv(RESULTS_DIR / f"{path.stem}.csv", index=False)
        print(f"-> {path.stem}: {len(df)} rows")
        if path.stem in CHARTS:
            CHARTS[path.stem](df.copy())

    print(f"\nDone. Results in {RESULTS_DIR.name}/, charts in {IMAGES_DIR.name}/")


if __name__ == "__main__":
    main()
