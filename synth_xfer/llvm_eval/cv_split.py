import argparse
from pathlib import Path
import random


def main() -> None:
    ap = argparse.ArgumentParser(description=__doc__)
    ap.add_argument("--bench-path", type=Path, required=True)
    ap.add_argument("--k", type=int, required=True, help="number of folds")
    ap.add_argument("--out-dir", type=Path, required=True)
    ap.add_argument(
        "--include", default="", help="comma-separated project dirs (default: all)"
    )
    ap.add_argument("--seed", type=int, default=0, help="shuffle seed (reproducible)")
    args = ap.parse_args()

    bench = args.bench_path / "bench"
    only = set(args.include.split(",")) if args.include else None
    files = [
        f
        for f in sorted(bench.glob("*/original/*.ll"))
        if only is None or f.relative_to(bench).parts[0] in only
    ]
    if not files:
        raise SystemExit(f"no original/*.ll files under {bench}")
    if not 1 <= args.k <= len(files):
        raise SystemExit(f"--k must be in 1..{len(files)} (have {len(files)} files)")

    # Random order scatters each project across folds; placing each file into the
    # smallest fold keeps total IR size balanced.
    random.Random(args.seed).shuffle(files)
    folds: list[list[str]] = [[] for _ in range(args.k)]
    totals = [0] * args.k
    for f in files:
        i = min(range(args.k), key=lambda j: totals[j])
        folds[i].append(str(f.relative_to(bench)))
        totals[i] += f.stat().st_size

    for i, names in enumerate(folds):
        d = args.out_dir / f"fold_{i}"
        d.mkdir(parents=True, exist_ok=True)
        (d / "files.txt").write_text("\n".join(sorted(names)) + "\n")
        print(f"fold {i}: {len(names):>6} files, {totals[i] / 1e6:8.1f} MB")


if __name__ == "__main__":
    main()
