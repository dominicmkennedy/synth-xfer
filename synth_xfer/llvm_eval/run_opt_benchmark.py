import argparse
import collections
import json
from multiprocessing import Pool
import os
from pathlib import Path
import subprocess
import sys
from typing import Literal

try:
    import tqdm
except ImportError:
    tqdm = None

import pandas as pd

from synth_xfer._util.domain import AbstractDomain
from synth_xfer._util.pattern_dsl import PatternDag
from synth_xfer._util.tsv import EnumData, EnumMetaData

sys.setrecursionlimit(100000)

# Counters whose values vary run-to-run; excluded from the aggregate so repeated
# runs are comparable.
STATS_NONDETER_KEYS = {
    "dse.NumDomMemDefChecks",
    "ir.NumInstrRenumberings",
    "basicaa.SearchTimes",
    "aa.NumMayAlias",
    "capture-tracking.NumCaptured",
    "aa.NumMustAlias",
    "memory-builtins.ObjectVisitorArgument",
    "aa.NumNoAlias",
    "assume-queries.NumAssumeQueries",
    "capture-tracking.NumNotCaptured",
    "ipt.NumInstScanned",
    "simplifycfg.NumSimpl",
}

RunMode = Literal["stats", "histogram", "slice-kb", "slice-ucr", "slice-scr"]
RunStatus = Literal["success", "fail", "timeout", "crash"]
OptResult = tuple[Path, RunStatus, dict[str, float], str]

# Per-worker config, populated by _init_worker so it survives non-fork start
# methods too.
_OPT: Path | None = None
_BENCH_DIR: Path | None = None
_HIST_DIR: Path | None = None
_SLICE_DIR: Path | None = None
_MODE: RunMode | None = None


def _init_worker(
    opt: Path,
    bench_dir: Path,
    hist_dir: Path | None,
    slice_dir: Path | None,
    mode: RunMode,
) -> None:
    global _OPT, _BENCH_DIR, _HIST_DIR, _SLICE_DIR, _MODE
    _OPT, _BENCH_DIR, _HIST_DIR, _SLICE_DIR, _MODE = (
        opt,
        bench_dir,
        hist_dir,
        slice_dir,
        mode,
    )


def _rel_stem(input_file: Path) -> Path:
    """benchmark-relative path with /original/ folded out and no .ll suffix."""
    assert _BENCH_DIR is not None
    rel = input_file.relative_to(_BENCH_DIR)
    parts = list(rel.parts)
    if "original" in parts:
        parts.remove("original")
    return Path(*parts).with_suffix("")


def run_opt(input_file: Path) -> OptResult:
    assert _OPT is not None
    assert _MODE is not None

    try:
        cmd = [
            _OPT,
            "-O3",
            "-disable-loop-unrolling",
            "-vectorize-loops=false",
            "-vectorize-slp=false",
            "-disable-output",
            input_file,
        ]
        if _MODE == "stats":
            cmd += ["--stats", "--stats-json", "-enable-pattern-off-baseline"]
        elif _MODE == "histogram":
            assert _HIST_DIR is not None
            hist_path = _HIST_DIR / "shards" / _rel_stem(input_file).with_suffix(".hist")
            hist_path.parent.mkdir(parents=True, exist_ok=True)
            cmd += [f"-value-tracking-pattern-histogram={hist_path}"]
        elif _MODE == "slice-kb":
            cmd += ["-debug-only=dag-slicer", "-enable-knownbits-pattern-mining"]
        elif _MODE == "slice-ucr":
            cmd += ["-debug-only=dag-slicer", "-enable-uconstrange-pattern-mining"]
        elif _MODE == "slice-scr":
            cmd += ["-debug-only=dag-slicer", "-enable-sconstrange-pattern-mining"]

        ret = subprocess.run(
            cmd, stdin=subprocess.DEVNULL, capture_output=True, timeout=600.0, env={}
        )
        if ret.returncode != 0:
            return (input_file, "fail", {}, ret.stderr.decode())

        if _MODE in ("slice-kb", "slice-ucr", "slice-scr"):
            assert _SLICE_DIR is not None
            debug_output = _SLICE_DIR / _rel_stem(input_file).with_suffix(".dag")
            debug_output.parent.mkdir(parents=True, exist_ok=True)
            debug_output.write_bytes(ret.stderr)
            return (input_file, "success", {}, "")

        if _MODE == "histogram":
            return (input_file, "success", {}, "")

        err = ret.stderr.decode()
        stats = {}
        json_start = err.find("{")
        json_end = err.rfind("}")
        if json_start != -1 and json_end > json_start:
            try:
                stats = json.loads(err[json_start : json_end + 1])
            except json.JSONDecodeError:
                stats = {}

        return (input_file, "success", stats, "")
    except subprocess.TimeoutExpired:
        return (input_file, "timeout", {}, "")
    except Exception as e:
        return (input_file, "crash", {}, str(e))


def _format_benchmark_rel(input_file: Path, bench_dir: Path) -> str:
    rel = input_file.relative_to(bench_dir)
    parts = list(rel.parts)
    if "original" in parts:
        parts.remove("original")
    return str(Path(*parts))


def _render_blocks(
    items: list[tuple[str, int]],
) -> tuple[collections.Counter, dict[str, int]]:
    counts: collections.Counter = collections.Counter()
    size: dict[str, int] = {}
    for line, cnt in items:
        dag = PatternDag.from_ssa(line)
        key = str(dag)
        counts[key] += cnt
        size[key] = len(dag.nodes)

    return counts, size


def _count_blocks(path: str) -> dict[str, int]:
    counts: dict[str, int] = {}
    with open(path, "r") as f:
        for line in f:
            line = line.strip()
            if line.startswith("%0"):
                counts[line] = counts.get(line, 0) + 1
    return counts


def _aggregate_dags(slice_dir: Path, jobs: int) -> None:
    """Collapse the per-file .dag logs under `slice_dir` into distinct DAGs and write dags.tsv

    Two-pass for speed
    1) count records by raw line text (count_blocks)
    2) cannoncal renderings (render_blocks)
    """
    dag_files = [str(p) for p in slice_dir.rglob("*.dag")]
    print(f"aggregating {len(dag_files)} .dag logs with {jobs} workers ...")

    raw: collections.Counter = collections.Counter()
    with Pool(jobs) as pool:
        for local in pool.imap_unordered(_count_blocks, dag_files, chunksize=16):
            raw.update(local)
    print(f"counted {sum(raw.values())} records, {len(raw)} distinct DAG lines")

    dag_counts: collections.Counter = collections.Counter()
    dag_size: dict[str, int] = {}
    items = list(raw.items())
    chunk = max(1, len(items) // (jobs * 8) + 1)
    chunks = [items[i : i + chunk] for i in range(0, len(items), chunk)]
    with Pool(jobs) as pool:
        for counts, size in pool.imap_unordered(_render_blocks, chunks):
            dag_counts.update(counts)
            dag_size.update(size)

    out = slice_dir / "dags.tsv"
    with out.open("w") as o:
        o.write("count\tsize\tpattern\n")
        for pat, n in sorted(dag_counts.items(), key=lambda kv: (-kv[1], kv[0])):
            o.write(f"{n}\t{dag_size[pat]}\t{pat}\n")
    print(f"wrote {out} ({len(dag_counts)} distinct DAGs)")


def _merge_histograms(hist_dir: Path, patterns_dir: Path) -> None:
    """Merge per-input .hist shards into ranked per-pattern TSVs.

    Each shard line is: <id> <arg_0> <arg_1> ... <count> <bits_added> <conflict>
    (tab-separated). We sum count/bits_added/conflict across shards per
    (id, args), then per id emit pattern_<name>.tsv ranked by count desc.
    """
    names = dict(enumerate(sorted(p.stem for p in patterns_dir.glob("*.inc"))))
    # id -> {args-tuple -> [count, bits_added, conflict]}
    acc: dict[int, dict[tuple[str, ...], list[int]]] = collections.defaultdict(dict)
    shards = sorted((hist_dir / "shards").rglob("*.hist"))
    for shard in shards:
        with shard.open() as f:
            for line in f:
                parts = line.rstrip("\n").split("\t")
                if len(parts) < 4:
                    continue
                pid = int(parts[0])
                count, bits_added, conflict = (
                    int(parts[-3]),
                    int(parts[-2]),
                    int(parts[-1]),
                )
                args = tuple(parts[1:-3])
                row = acc[pid].setdefault(args, [0, 0, 0])
                row[0] += count
                row[1] += bits_added
                row[2] += conflict

    n_tables = 0
    for pid, rows in acc.items():
        # The filename is the bare pattern id (no `pattern_` prefix); the YAML
        # header's `op` field carries the decoded expression for readability.
        name = names.get(pid, f"{pid:03d}")
        pattern = PatternDag.from_id(name)
        arity = max(len(a) for a in rows) if rows else 0
        ranked = sorted(rows.items(), key=lambda kv: -kv[1][0])
        # distinct-row count per bitwidth for hbw. The instance width N is the
        # width of the iN-typed operands; i1 operands (e.g. a select condition or
        # an icmp result feeding another op) are always length 1, so taking the
        # max across a row recovers N for width-heterogeneous patterns instead of
        # latching onto a leading i1 arg.
        bw_counts = collections.Counter(max(len(x) for x in a) for a in rows if a)
        out_path = hist_dir / f"{name}.tsv"
        metadata = EnumMetaData(
            domain=AbstractDomain.KnownBits,
            op=pattern,
            arity=arity,
            seed=None,
            lbw=[],
            mbw=[],
            hbw=[(bw, count, 0) for bw, count in sorted(bw_counts.items())],
        )
        records: list[tuple[object, ...]] = []
        for rank, (args, (count, bits_added, conflict)) in enumerate(ranked, 1):
            bw = max(len(a) for a in args) if args else 0
            records.append((bw, rank, count, *args, bits_added, conflict))
        columns = (
            ["bw", "rank", "count"]
            + [f"arg_{i}" for i in range(arity)]
            + ["bits_added", "conflict"]
        )
        frame = pd.DataFrame.from_records(records, columns=columns)
        EnumData(metadata, frame).write_tsv(out_path)
        n_tables += 1
    print(f"merged {len(shards)} shards -> {n_tables} pattern TSVs in {hist_dir}")


def main() -> None:
    p = argparse.ArgumentParser(description="Run -O3 over llvm-opt-benchmark")
    p.add_argument(
        "--bench-path",
        type=Path,
        required=True,
        help="Path to the llvm-opt-benchmark checkout",
    )
    p.add_argument(
        "--opt-path",
        type=Path,
        required=True,
        help="LLVM opt binary to run",
    )
    p.add_argument(
        "--filter",
        default="",
        help="Comma-separated benchmark dir names to include (default: all)",
    )
    p.add_argument(
        "--stats",
        type=Path,
        default=None,
        help="Aggregated stats JSON output path.",
    )
    p.add_argument(
        "--slice-kb",
        action="store_true",
        help="Run pattern slicer over computeKnownBits",
    )
    p.add_argument(
        "--slice-ucr",
        action="store_true",
        help="Run pattern slicer over computeConstantRange",
    )
    p.add_argument(
        "--slice-scr",
        action="store_true",
        help="Run pattern slicer over computeConstantRange",
    )
    p.add_argument(
        "--pattern-hist",
        type=Path,
        default=None,
        help="If set, have opt accumulate a per-input histogram of pattern "
        "inputs (id + operand known bits, summed bits_added/conflict) and "
        "write shards under <dir>/shards/, then merge them into per-pattern "
        "<dir>/pattern_<id>.tsv. Avoids the giant raw [pNNN] logs entirely.",
    )
    p.add_argument(
        "--jobs",
        type=int,
        default=os.cpu_count() or 1,
        help="Parallel worker processes. Default: %(default)s",
    )
    args = p.parse_args()

    selected_modes = [
        args.stats is not None,
        args.pattern_hist is not None,
        args.slice_kb,
        args.slice_ucr,
        args.slice_scr,
    ]
    if sum(selected_modes) != 1:
        p.error(
            "exactly one of --stats, --pattern-hist, --slice-kb, --slice-ucr, or --slice-scr is required"
        )

    if args.stats is not None:
        mode: RunMode = "stats"
    elif args.pattern_hist is not None:
        mode = "histogram"
    elif args.slice_kb:
        mode = "slice-kb"
    elif args.slice_ucr:
        mode = "slice-ucr"
    elif args.slice_scr:
        mode = "slice-scr"
    else:
        assert False

    bench_dir = args.bench_path / "bench"
    if not bench_dir.is_dir():
        sys.exit(f"error: {bench_dir} not found; pass the llvm-opt-benchmark path")
    if not args.opt_path.is_file() or not os.access(args.opt_path, os.X_OK):
        sys.exit(f"error: opt binary {args.opt_path} not found or not executable")

    patterns_dir = (
        args.opt_path.parent.parent.parent
        / "llvm"
        / "lib"
        / "Analysis"
        / "Generated"
        / "patterns"
    )
    filt = set(args.filter.split(",")) if args.filter else None

    work_list: list[Path] = []
    for bench in sorted(bench_dir.iterdir()):
        name = bench.name
        if filt and name not in filt:
            continue
        original_dir = bench / "original"
        if not original_dir.is_dir():
            continue
        for input_file in original_dir.glob("*.ll"):
            work_list.append(input_file)

    hist_dir = args.pattern_hist
    if hist_dir is not None:
        if hist_dir.exists() and not hist_dir.is_dir():
            sys.exit(f"error: --pattern-hist {hist_dir!r} exists but is not a directory")
        (hist_dir / "shards").mkdir(parents=True, exist_ok=True)

    print("total items: ", len(work_list))
    print("threads: ", args.jobs)

    if args.stats is not None:
        output_dir = args.stats.parent
    elif args.pattern_hist is not None:
        output_dir = args.pattern_hist
    else:
        output_dir = Path(__file__).resolve().parent / "outputs" / mode
    output_dir.mkdir(parents=True, exist_ok=True)
    slice_dir = output_dir if mode in ("slice-kb", "slice-ucr", "slice-scr") else None
    test_log_path = output_dir / "test.log"

    stats_acc: dict[str, float] = {}
    fail = False
    n_timeout = 0

    with Pool(
        processes=args.jobs,
        initializer=_init_worker,
        initargs=(args.opt_path, bench_dir, hist_dir, slice_dir, mode),
    ) as pool:
        results = pool.imap_unordered(run_opt, work_list)
        if tqdm is not None:
            results = tqdm.tqdm(
                results, total=len(work_list), miniters=max(1, len(work_list) // 200)
            )

        with test_log_path.open("w") as log:
            for input_file, status, stats, err in results:
                rel = _format_benchmark_rel(input_file, bench_dir)
                if status != "success":
                    msg = f"{rel} {status}"
                    (tqdm.tqdm.write if tqdm is not None else print)(msg)
                    if err:
                        print(err, file=sys.stderr)
                    log.write(msg + "\n")
                    if status == "timeout":
                        n_timeout += 1
                    else:
                        fail = True
                else:
                    for k, v in stats.items():
                        if k in STATS_NONDETER_KEYS:
                            continue
                        stats_acc[k] = stats_acc.get(k, 0) + v

    if args.stats is not None:
        with args.stats.open("w") as f:
            json.dump(stats_acc, f, indent=2, sort_keys=True)
        print(f"aggregated stats written to {args.stats} ({len(stats_acc)} keys)")

    if hist_dir is not None:
        _merge_histograms(hist_dir, patterns_dir)

    if n_timeout:
        print(f"note: {n_timeout} file(s) timed out (non-fatal)", file=sys.stderr)

    if mode in ("slice-kb", "slice-ucr", "slice-scr"):
        assert slice_dir is not None
        _aggregate_dags(slice_dir, args.jobs)

    sys.exit(1 if fail else 0)


if __name__ == "__main__":
    main()
