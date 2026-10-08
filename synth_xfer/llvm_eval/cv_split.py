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
    ap.add_argument(
        "--by-project",
        action="store_true",
        help="keep each project whole in a single fold (no project spans folds), "
        "instead of scattering files across folds",
    )
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

    folds: list[list[str]] = [[] for _ in range(args.k)]
    totals = [0] * args.k

    if args.by_project:
        # Group whole projects so no project spans folds: a held-out fold then has
        # no sibling files in training, which file-level splitting cannot promise.
        groups: dict[str, list[Path]] = {}
        for f in files:
            groups.setdefault(f.relative_to(bench).parts[0], []).append(f)
        if args.k > len(groups):
            raise SystemExit(f"--k must be <= {len(groups)} projects for --by-project")
        # Largest-first (LPT): a few projects hold ~10% of the corpus each, so
        # random order leaves folds up to ~1.35x apart in bytes; LPT is ~1.00x.
        units = [
            (sum(f.stat().st_size for f in fs), [str(f.relative_to(bench)) for f in fs])
            for fs in groups.values()
        ]
        units.sort(key=lambda u: -u[0])
        n_proj = [0] * args.k
    else:
        # Random order scatters each project across folds; placing each file into the
        # smallest fold keeps total IR size balanced.
        units = [(f.stat().st_size, [str(f.relative_to(bench))]) for f in files]
        random.Random(args.seed).shuffle(units)
        n_proj = None

    for size, names in units:
        i = min(range(args.k), key=lambda j: totals[j])
        folds[i].extend(names)
        totals[i] += size
        if n_proj is not None:
            n_proj[i] += 1

    for i, names in enumerate(folds):
        d = args.out_dir / f"fold_{i}"
        d.mkdir(parents=True, exist_ok=True)
        (d / "files.txt").write_text("\n".join(sorted(names)) + "\n")
        extra = f"{n_proj[i]:>4} projects, " if n_proj is not None else ""
        print(f"fold {i}: {extra}{len(names):>6} files, {totals[i] / 1e6:8.1f} MB")


if __name__ == "__main__":
    main()
