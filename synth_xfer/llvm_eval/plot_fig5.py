"""Plot the pattern-frequency CDF (paper figure 5) from pattern count TSVs.

Each input is a <count, pattern> TSV. Per file, every pattern's frequency is its
count over the file total; the curve gives the fraction of the file's patterns
whose frequency is at or below x. A dashed line in the series colour marks the
frequency of the pattern at rank RANK_MARKER, the usual --top cutoff.
"""

from argparse import ArgumentParser
import csv
from pathlib import Path

import matplotlib.pyplot as plt
from matplotlib.ticker import FuncFormatter, PercentFormatter
from matplotlib.typing import ColorType
import numpy as np

RANK_MARKER = 10_000
COLORS = ["#D81B60", "#1E88E5", "#FFC107"]
FIGSIZE = (16.0, 4.0)  # inches; 4:1
LABEL_FONTSIZE = 18
TICK_FONTSIZE = 14
LEGEND_FONTSIZE = 14


def load_counts(path: Path) -> np.ndarray:
    """Positive counts from a <count, pattern> TSV, in file order."""
    counts: list[float] = []
    with path.open(newline="") as f:
        reader = csv.DictReader(f, delimiter="\t")
        missing = {"pattern", "count"} - set(reader.fieldnames or ())
        if missing:
            raise ValueError(f"{path} is missing required columns: {sorted(missing)}")
        for row in reader:
            try:
                count = float(row["count"])
            except ValueError:
                continue
            if count > 0:
                counts.append(count)
    if not counts:
        raise ValueError(f"{path} has no positive counts")
    return np.asarray(counts)


def apply_cutoffs(
    counts: np.ndarray, min_count: int | None, top_n: int | None
) -> np.ndarray:
    """Counts sorted descending, restricted to >= min_count and the top_n largest."""
    if min_count is not None:
        counts = counts[counts >= min_count]
    counts = np.sort(counts)[::-1]
    if top_n is not None:
        counts = counts[:top_n]
    return counts


def plot_cdf(
    inputs: list[tuple[str, Path]],
    output: Path,
    top_n: int | None = None,
    min_count: int | None = None,
    xscale: str = "log",
) -> None:
    fig, ax = plt.subplots(figsize=FIGSIZE)
    ax.set_prop_cycle(color=COLORS)
    marker_lines: list[tuple[float, ColorType]] = []

    for label, path in inputs:
        counts = load_counts(path)
        full_total = counts.sum()  # denominator: whole file, before cutoffs
        counts = apply_cutoffs(counts, min_count, top_n)
        if counts.size == 0:
            print(f"Warning: {path} has no rows after filtering; skipping")
            continue

        freqs = np.sort(counts / full_total)
        cdf = np.arange(1, len(freqs) + 1) / len(freqs)
        (line,) = ax.step(freqs, cdf, where="post", label=label)

        if counts.size >= RANK_MARKER:
            marker_freq = float(counts[RANK_MARKER - 1] / full_total)
            marker_cdf = np.searchsorted(freqs, marker_freq, side="right") / len(freqs)
            print(
                f"{label}: rank {RANK_MARKER:,} frequency is {marker_freq * 100:.5g}%; "
                f"CDF sees {marker_cdf * 100:.5g}% of pattern space"
            )
            marker_lines.append((marker_freq, line.get_color()))

    for marker_freq, color in marker_lines:
        ax.axvline(marker_freq, color=color, linestyle="--", linewidth=1, alpha=0.7)

    ax.set_xscale(xscale)
    if xscale == "linear":
        ax.set_xlim(left=0)
    ax.set_ylim(bottom=0)
    ax.xaxis.set_major_formatter(FuncFormatter(lambda x, _: f"{x * 100:.5g}%"))
    ax.yaxis.set_major_formatter(PercentFormatter(xmax=1.0))
    ax.tick_params(axis="both", labelsize=TICK_FONTSIZE)
    ax.set_xlabel("Patterns", fontsize=LABEL_FONTSIZE)
    ax.set_ylabel("Observed %", fontsize=LABEL_FONTSIZE)
    ax.legend(fontsize=LEGEND_FONTSIZE)

    fig.tight_layout()
    fig.savefig(output, dpi=300)
    plt.close(fig)


def main() -> None:
    p = ArgumentParser(description=__doc__)
    p.add_argument(
        "-i",
        "--input",
        nargs=2,
        action="append",
        metavar=("LABEL", "TSV"),
        required=True,
        help="legend label and its <count, pattern> TSV; repeat once per series",
    )
    p.add_argument(
        "-o",
        "--output",
        type=Path,
        required=True,
        help="figure file to write; the extension picks the format (.pdf, .png, ...)",
    )
    p.add_argument(
        "--top-n",
        type=int,
        default=None,
        help="only include the top N most frequent patterns from each file",
    )
    p.add_argument(
        "--min-count",
        type=int,
        default=None,
        help="only include patterns with count >= this value",
    )
    p.add_argument(
        "--xscale",
        choices=["linear", "log"],
        default="log",
        help="x-axis scale (default: log)",
    )
    args = p.parse_args()

    inputs = [(label, Path(tsv)) for label, tsv in args.input]
    plot_cdf(inputs, args.output, args.top_n, args.min_count, args.xscale)
    print(f"Wrote {args.output}")


if __name__ == "__main__":
    main()
