"""Split benchmark dirs into K size-balanced folds for cross-validation.

Per top-level dir under <bench-path>/bench, size = total bytes of original/*.ll.
Greedy largest-first bin-packing (LPT) balances total IR size across folds, so
each fold holds out ~1/K of the code. Writes <out-dir>/fold_<i>/dirs.txt (one
benchmark dir name per line).
"""

import argparse
from pathlib import Path


def main() -> None:
    ap = argparse.ArgumentParser(description=__doc__)
    ap.add_argument("--bench-path", type=Path, required=True)
    ap.add_argument("--k", type=int, required=True, help="number of folds")
    ap.add_argument("--out-dir", type=Path, required=True)
    ap.add_argument(
        "--include",
        default="",
        help="comma-separated dir names to restrict to (default: all)",
    )
    args = ap.parse_args()

    bench = args.bench_path / "bench"
    only = set(args.include.split(",")) if args.include else None

    sizes: dict[str, int] = {}
    for d in sorted(bench.iterdir()):
        if not (d / "original").is_dir():
            continue
        if only is not None and d.name not in only:
            continue
        sizes[d.name] = sum(f.stat().st_size for f in (d / "original").glob("*.ll"))

    if not sizes:
        raise SystemExit(f"no benchmark dirs with original/ under {bench}")
    if not 1 <= args.k <= len(sizes):
        raise SystemExit(f"--k must be in 1..{len(sizes)} (have {len(sizes)} dirs)")

    # Greedy LPT: place the largest dirs first, each into the smallest fold.
    folds: list[list[str]] = [[] for _ in range(args.k)]
    totals = [0] * args.k
    for name, size in sorted(sizes.items(), key=lambda kv: -kv[1]):
        i = min(range(args.k), key=lambda j: totals[j])
        folds[i].append(name)
        totals[i] += size

    for i, names in enumerate(folds):
        d = args.out_dir / f"fold_{i}"
        d.mkdir(parents=True, exist_ok=True)
        (d / "dirs.txt").write_text("\n".join(sorted(names)) + "\n")
        print(f"fold {i}: {len(names):>4} dirs, {totals[i] / 1e6:8.1f} MB")


if __name__ == "__main__":
    main()
