import argparse
import json
import os
from pathlib import Path
import subprocess
import sys

from synth_xfer._util.domain import AbstractDomain
from synth_xfer.llvm_eval.process_patterns import (
    PatternCache,
    process_pattern_counts,
    read_pattern_counts,
    write_pattern_counts,
)

HERE = Path(__file__).resolve().parent
DOMAIN = AbstractDomain.KnownBits

METRICS = [
    ("BitsAdded", "value-tracking.PatternKBBitsAdded"),
    ("BitsAddedTop", "value-tracking.PatternKBBitsAddedTopLevel"),
    ("MatchesTop", "value-tracking.NumKBPatternMatchesTopLevel"),
    ("ImprovedQTop", "value-tracking.NumPatternKBImprovedQueriesTopLevel"),
]


def run(cmd: list[str], env: dict[str, str] | None = None) -> None:
    print(f"    $ {' '.join(cmd)}", flush=True)
    subprocess.run(cmd, check=True, env=env)


def parse_args() -> argparse.Namespace:
    ap = argparse.ArgumentParser(
        description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter
    )
    ap.add_argument(
        "--llvm-dir",
        type=Path,
        required=True,
        help="llvm-project checkout (build/bin/opt)",
    )
    ap.add_argument(
        "--bench-dir", type=Path, required=True, help="llvm-opt-benchmark checkout"
    )
    ap.add_argument(
        "--cv-dir", type=Path, default=Path("outputs/cv"), help="results root"
    )
    ap.add_argument("--k", type=int, default=5, help="number of folds")
    ap.add_argument(
        "--subset", default="", help="comma-separated project names to restrict to"
    )
    ap.add_argument("--seed", type=int, default=0, help="cv_split shuffle seed")
    ap.add_argument(
        "--top",
        type=int,
        default=10000,
        help="keep only the top K patterns by count (default 10000; pass a large N to keep all)",
    )
    ap.add_argument(
        "--train-all",
        action="store_true",
        help="train ONE model on all folds and eval per fold (in-sample), instead of "
        "leave-one-out. Reuses an existing split+mining; see --reuse-from.",
    )
    ap.add_argument(
        "--reuse-from",
        type=Path,
        default=None,
        help="dir holding an existing fold_*/files.txt + slice/dags.tsv to reuse as "
        "inputs (default: --cv-dir). Only used with --train-all.",
    )
    return ap.parse_args()


def split(args: argparse.Namespace) -> list[Path]:
    print(
        f">>> splitting benchmark files into {args.k} size-balanced folds under {args.cv_dir}"
    )
    cmd = [
        sys.executable,
        "-m",
        "synth_xfer.llvm_eval.cv_split",
        "--bench-path",
        str(args.bench_dir),
        "--k",
        str(args.k),
        "--out-dir",
        str(args.cv_dir),
        "--seed",
        str(args.seed),
    ]
    if args.subset:
        cmd += ["--include", args.subset]
    run(cmd)
    return [args.cv_dir / f"fold_{i}" / "files.txt" for i in range(args.k)]


def mine(args: argparse.Namespace, fold_files: list[Path], opt: Path) -> None:
    """Mine each fold's raw DAGs once (against the pre-built opt); skip if present."""
    print("\n>>> mining raw DAGs per fold (slice-kb, once each)")
    for i in range(args.k):
        dags = args.cv_dir / f"fold_{i}" / "slice" / "dags.tsv"
        if dags.exists() and dags.stat().st_size:
            print(f"    fold {i}: dags.tsv exists, skipping mine")
            continue
        n = len(fold_files[i].read_text().split())
        print(f"    fold {i}: mining {n} files")
        run(
            [
                sys.executable,
                "-m",
                "synth_xfer.llvm_eval.run_opt_benchmark",
                "--bench-path",
                str(args.bench_dir),
                "--opt-path",
                str(opt),
                "--slice-kb",
                "--filter-file",
                str(fold_files[i]),
                "--slice-dir",
                str(dags.parent),
            ]
        )


def combine_pattern_list(
    args: argparse.Namespace, others: list[int], out: Path, src: Path
) -> int:
    """Combine the given folds' mined DAG counts (under `src`) and refine to a pattern list.

    Disjoint folds -> per-pattern counts are additive, so merging their count maps
    equals mining the union (process_patterns sums duplicates the same way).
    """
    counts: dict[str, int] = {}
    for j in others:
        dags = src / f"fold_{j}" / "slice" / "dags.tsv"
        for pat, n in read_pattern_counts(dags).items():
            counts[pat] = counts.get(pat, 0) + n
    print(f">>> refine {len(counts)} training DAGs -> pattern list")
    cache = PatternCache({})
    result = process_pattern_counts(counts, DOMAIN, cache)

    kept: dict[str, int] = {}
    dropped_long = 0
    for text, n in result.non_enumerated.items():
        try:
            cache.dag_of(text).to_id()
        except ValueError:
            dropped_long += 1
            continue
        kept[text] = n

    n_pat = write_pattern_counts(out, kept, args.top)
    print(
        f"    {n_pat} patterns (top {args.top}; dropped {dropped_long} over-length; "
        f"from {result.input_stats.unique} canonical inputs)"
    )
    return n_pat


def summarize(
    cv_dir: Path,
    k: int,
    fold_files: list[Path],
    patterns_file: Path | None = None,
    title: str = "cross-validation summary (KnownBits) — held-out folds",
) -> None:
    keys = [key for _, key in METRICS]
    # In train-all every fold shares one pattern list; otherwise it is per-fold.
    shared_pat = (
        len(patterns_file.read_text().splitlines()) - 1
        if patterns_file is not None and patterns_file.exists()
        else None
    )
    rows: list[dict] = []
    for i in range(k):
        stats_path = cv_dir / f"fold_{i}" / "stats.json"
        stats = json.loads(stats_path.read_text()) if stats_path.exists() else {}
        pats = cv_dir / f"fold_{i}" / "patterns.tsv"
        if shared_pat is not None:
            n_pat = shared_pat
        elif pats.exists():
            n_pat = len(pats.read_text().splitlines()) - 1
        else:
            n_pat = 0
        rows.append(
            {
                "fold": i,
                "test_files": len(fold_files[i].read_text().split()),
                "patterns": n_pat,
                "metrics": {key: int(stats.get(key, 0)) for key in keys},
            }
        )
    totals = {key: sum(r["metrics"][key] for r in rows) for key in keys}

    def line(cells: list[object]) -> str:
        return "  ".join(f"{c:>15}" for c in cells)

    print(f"\n=== {title} ===")
    print(line(["fold", "test_files", "patterns", *(lbl for lbl, _ in METRICS)]))
    for r in rows:
        print(
            line(
                [
                    r["fold"],
                    f"{r['test_files']:,}",
                    f"{r['patterns']:,}",
                    *(f"{r['metrics'][key]:,}" for key in keys),
                ]
            )
        )
    print("  ".join(["-" * 15] * (3 + len(keys))))
    print(
        line(
            [
                "sum",
                f"{sum(r['test_files'] for r in rows):,}",
                "",
                *(f"{totals[key]:,}" for key in keys),
            ]
        )
    )
    print(line(["mean", "", "", *(f"{totals[key] // k:,}" for key in keys)]))

    summary = {
        "k": k,
        "folds": rows,
        "sum": totals,
        "mean": {key: totals[key] / k for key in keys},
    }
    out = cv_dir / "summary.json"
    out.write_text(json.dumps(summary, indent=2, sort_keys=True) + "\n")
    print(f"\n>>> wrote {out}")


def train_all(args: argparse.Namespace, src: Path, base_env: dict[str, str]) -> None:
    """Train one model on ALL folds (reusing the split+mining under `src`) and eval
    each fold against it. Writes to args.cv_dir; never touches `src`."""
    cv = args.cv_dir
    cv.mkdir(parents=True, exist_ok=True)
    fold_files = [src / f"fold_{i}" / "files.txt" for i in range(args.k)]

    print(">>> train-on-all: combine ALL folds' DAGs -> one pattern list")
    combine_pattern_list(args, list(range(args.k)), cv / "patterns_all.tsv", src)

    train_manifest = cv / "train_all.txt"
    train_manifest.write_text("".join(f.read_text() for f in fold_files))

    print(">>> train (phase 1) on ALL folds")
    run(
        [str(HERE / "phase1_build_tables.sh")],
        env=base_env
        | {
            "PAT_LIST": str(cv / "patterns_all.tsv"),
            "FILES": str(train_manifest),
            "WORK_DIR": str(cv / "work_all"),
        },
    )

    for k in range(args.k):
        fold = cv / f"fold_{k}"
        fold.mkdir(parents=True, exist_ok=True)
        print(f"\n>>> eval (phase 2) on fold {k} (in-sample)")
        run(
            [str(HERE / "phase2_eval.sh")],
            env=base_env
            | {
                "TABLE_DIR": str(cv / "work_all" / "pruned"),
                "FILES": str(fold_files[k]),
                "STATS": str(fold / "stats.json"),
            },
        )

    summarize(
        cv,
        args.k,
        fold_files,
        patterns_file=cv / "patterns_all.tsv",
        title="train-on-all summary (KnownBits) — per-fold (in-sample)",
    )


def main() -> None:
    args = parse_args()
    opt = args.llvm_dir / "build" / "bin" / "opt"
    base_env = os.environ | {
        "LLVM_DIR": str(args.llvm_dir),
        "BENCH_DIR": str(args.bench_dir),
    }
    sys.setrecursionlimit(100000)

    if args.train_all:
        src = args.reuse_from if args.reuse_from else args.cv_dir
        for i in range(args.k):
            for p in (
                src / f"fold_{i}" / "files.txt",
                src / f"fold_{i}" / "slice" / "dags.tsv",
            ):
                if not p.exists():
                    sys.exit(
                        f"error: {p} not found; --train-all reuses an existing "
                        f"split+mining (run cross-validation first, or point "
                        f"--reuse-from at one with {args.k} folds)"
                    )
        train_all(args, src, base_env)
        return

    fold_files = split(args)
    mine(args, fold_files, opt)

    for k in range(args.k):
        fold = args.cv_dir / f"fold_{k}"
        others = [j for j in range(args.k) if j != k]
        print(f"\n############ fold {k} / {args.k - 1} ############")

        combine_pattern_list(args, others, fold / "patterns.tsv", args.cv_dir)

        train_manifest = fold / "train_files.txt"
        train_manifest.write_text("".join(fold_files[j].read_text() for j in others))

        print(f">>> train (phase 1) on folds != {k}")
        run(
            [str(HERE / "phase1_build_tables.sh")],
            env=base_env
            | {
                "PAT_LIST": str(fold / "patterns.tsv"),
                "FILES": str(train_manifest),
                "WORK_DIR": str(fold / "work"),
            },
        )

        print(f">>> eval (phase 2) on held-out fold {k}")
        run(
            [str(HERE / "phase2_eval.sh")],
            env=base_env
            | {
                "TABLE_DIR": str(fold / "work" / "pruned"),
                "FILES": str(fold_files[k]),
                "STATS": str(fold / "stats.json"),
            },
        )

    summarize(args.cv_dir, args.k, fold_files)


if __name__ == "__main__":
    main()
