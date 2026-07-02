import argparse
import collections
import csv
import io
import json
from multiprocessing import Pool, current_process
import os
from pathlib import Path
import shutil
import subprocess
import sys
import time
from typing import Callable, Literal, cast

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

RunMode = Literal[
    "stats", "histogram", "slice-kb", "slice-ucr", "slice-scr", "comptime", "walltime"
]
RunStatus = Literal["success", "fail", "timeout", "crash"]
PerfMetric = int | float
ScalarStats = dict[str, float]
PerfSamples = dict[str, list[PerfMetric]]
OptPayload = ScalarStats | PerfSamples
OptResult = tuple[Path, RunStatus, OptPayload, str]

# Per-worker config, populated by _init_worker so it survives non-fork start
# methods too.
_OPT: Path | None = None
_BENCH_DIR: Path | None = None
_HIST_DIR: Path | None = None
_SLICE_DIR: Path | None = None
_MODE: RunMode | None = None
_COMPTIME_REPEAT: int = 3
_COMPTIME_CPUS: tuple[int, ...] = ()
_COMPTIME_PERF_CPU: int | None = None


def _init_worker(
    opt: Path,
    bench_dir: Path,
    hist_dir: Path | None,
    slice_dir: Path | None,
    mode: RunMode,
    comptime_repeat: int,
    comptime_cpus: tuple[int, ...],
    comptime_perf_cpu: int | None,
) -> None:
    global _OPT, _BENCH_DIR, _HIST_DIR, _SLICE_DIR, _MODE
    global _COMPTIME_REPEAT, _COMPTIME_CPUS, _COMPTIME_PERF_CPU
    _OPT, _BENCH_DIR, _HIST_DIR, _SLICE_DIR, _MODE = (
        opt,
        bench_dir,
        hist_dir,
        slice_dir,
        mode,
    )
    _COMPTIME_REPEAT, _COMPTIME_CPUS = (
        comptime_repeat,
        comptime_cpus,
    )
    _COMPTIME_PERF_CPU = comptime_perf_cpu


def _rel_stem(input_file: Path) -> Path:
    """benchmark-relative path with /original/ folded out and no .ll suffix."""
    assert _BENCH_DIR is not None
    rel = input_file.relative_to(_BENCH_DIR)
    parts = list(rel.parts)
    if "original" in parts:
        parts.remove("original")
    return Path(*parts).with_suffix("")


def _parse_perf_stat(stderr: str) -> dict[str, PerfMetric]:
    metrics: dict[str, PerfMetric] = {}
    for row in csv.reader(io.StringIO(stderr), delimiter=","):
        if not row:
            continue

        value = row[0].strip()
        if not value or value.startswith("<"):
            continue

        unit = row[1].strip() if len(row) > 1 else ""
        event = row[2].strip() if len(row) > 2 else ""
        label = event or unit

        try:
            parsed = float(value)
        except ValueError:
            continue

        if label == "instructions:u":
            metrics["instructions"] = int(parsed)
        elif label == "task-clock:u":
            if unit.startswith("msec"):
                metrics["task_clock_ms"] = parsed
            elif unit.startswith("seconds"):
                metrics["task_clock_ms"] = parsed * 1000.0
            else:
                metrics["task_clock_ms"] = parsed

    missing = {"instructions", "task_clock_ms"} - metrics.keys()
    if missing:
        raise ValueError(f"perf stat output missing {sorted(missing)}")
    return metrics


def _worker_cpu() -> int:
    if not _COMPTIME_CPUS:
        raise RuntimeError("no CPUs available for comptime worker pinning")
    worker_idx = int(current_process().name.rsplit("-", 1)[1]) - 1
    return _COMPTIME_CPUS[worker_idx % len(_COMPTIME_CPUS)]


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

        if _MODE == "walltime":
            start = time.perf_counter()
            ret = subprocess.run(
                cmd, stdin=subprocess.DEVNULL, capture_output=True, timeout=1800.0, env={}
            )
            elapsed = time.perf_counter() - start
            if ret.returncode != 0:
                return (input_file, "fail", {}, ret.stderr.decode())
            return (input_file, "success", {"wall_time_s": elapsed}, "")

        if _MODE == "comptime":
            if _COMPTIME_PERF_CPU is None:
                raise RuntimeError("no CPU available for perf worker pinning")
            samples: dict[str, list[PerfMetric]] = collections.defaultdict(list)
            perf_cmd = [
                "taskset",
                "-c",
                str(_COMPTIME_PERF_CPU),
                "perf",
                "stat",
                "-x",
                ",",
                "-e",
                "instructions:u,task-clock:u",
                "--no-big-num",
                "--",
                "taskset",
                "-c",
                str(_worker_cpu()),
            ] + cmd
            for _ in range(_COMPTIME_REPEAT):
                ret = subprocess.run(
                    perf_cmd,
                    stdin=subprocess.DEVNULL,
                    capture_output=True,
                    timeout=1800.0,
                    env={},
                )
                if ret.returncode != 0:
                    return (input_file, "fail", {}, ret.stderr.decode())
                metrics = _parse_perf_stat(ret.stderr.decode())
                for k, v in metrics.items():
                    samples[k].append(v)
            return (
                input_file,
                "success",
                {k: v for k, v in samples.items()},
                "",
            )

        ret = subprocess.run(
            cmd, stdin=subprocess.DEVNULL, capture_output=True, timeout=1800.0, env={}
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


def _read_proc_int(path: Path) -> int | None:
    try:
        return int(path.read_text().strip())
    except OSError:
        return None


def _comptime_cpus() -> tuple[int, ...]:
    sched_getaffinity = getattr(os, "sched_getaffinity", None)
    if sched_getaffinity is not None:
        affinity = cast(Callable[[int], set[int]], sched_getaffinity)
        return tuple(sorted(affinity(0)))
    return tuple(range(os.cpu_count() or 1))


def _check_comptime_environment() -> tuple[tuple[int, ...], int]:
    if sys.platform != "linux":
        sys.exit("error: --comptime requires Linux perf/taskset")
    if shutil.which("perf") is None:
        sys.exit("error: --comptime requires perf in PATH")
    if shutil.which("taskset") is None:
        sys.exit("error: --comptime requires taskset in PATH")

    aslr = _read_proc_int(Path("/proc/sys/kernel/randomize_va_space"))
    if aslr != 0:
        sys.exit("error: disable ASLR first: sudo sysctl kernel.randomize_va_space=0")

    perf_paranoid = _read_proc_int(Path("/proc/sys/kernel/perf_event_paranoid"))
    if perf_paranoid != -1:
        sys.exit(
            "error: enable userland perf first: sudo sysctl kernel.perf_event_paranoid=-1"
        )

    cpus = _comptime_cpus()
    if len(cpus) < 2:
        sys.exit("error: --comptime requires at least two CPUs in its affinity")
    return cpus[:-1], cpus[-1]


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
    """Merge per-input .hist shards into per-pattern TSVs.

    Each shard line is: <domain> <id> <bw> <arg_0> <arg_1> ... <count>
    followed by optional ignored fields. Counts are summed across shards per
    (domain, id, bw, args), then emitted sorted by count desc.
    """
    domain_meta = {
        "kb": ("", AbstractDomain.KnownBits),
        "scr": ("SCR", AbstractDomain.SConstRange),
        "ucr": ("UCR", AbstractDomain.UConstRange),
    }
    names: dict[str, dict[int, tuple[str, str, int]]] = {}
    for domain, (prefix, _) in domain_meta.items():
        if prefix:
            stems = sorted(p.stem for p in patterns_dir.glob(f"{prefix}*.inc"))
            names[domain] = {
                i: (
                    stem,
                    stem.removeprefix(prefix),
                    PatternDag.from_id(stem.removeprefix(prefix)).num_args,
                )
                for i, stem in enumerate(stems)
            }
        else:
            stems = sorted(
                p.stem
                for p in patterns_dir.glob("*.inc")
                if not p.stem.startswith(("SCR", "UCR"))
            )
            names[domain] = {
                i: (stem, stem, PatternDag.from_id(stem).num_args)
                for i, stem in enumerate(stems)
            }

    # (domain, id) -> {(bw, args-tuple) -> count}
    acc: dict[tuple[str, int], dict[tuple[int, tuple[str, ...]], int]] = (
        collections.defaultdict(dict)
    )
    shards = sorted((hist_dir / "shards").rglob("*.hist"))
    for shard in shards:
        with shard.open() as f:
            for line in f:
                parts = line.rstrip("\n").split("\t")
                domain = parts[0]
                pid = int(parts[1])
                bw = int(parts[2])
                arity = names[domain][pid][2]
                args = tuple(parts[3 : 3 + arity])
                count = int(parts[3 + arity])
                key = (bw, args)
                acc[(domain, pid)][key] = acc[(domain, pid)].get(key, 0) + count

    n_tables = 0
    for (domain, pid), rows in acc.items():
        # The filename is the bare pattern id (no `pattern_` prefix); the YAML
        # header's `op` field carries the decoded expression for readability.
        name, pattern_id, arity = names[domain].get(
            pid, (f"{domain}_{pid:03d}", f"{pid:03d}", 0)
        )
        pattern = PatternDag.from_id(pattern_id)
        ranked = sorted(rows.items(), key=lambda kv: -kv[1])
        bw_counts = collections.Counter(bw for bw, _ in rows)
        out_path = hist_dir / f"{name}.tsv"
        metadata = EnumMetaData(
            domain=domain_meta[domain][1],
            op=pattern,
            arity=arity,
            seed=None,
            lbw=[],
            mbw=[],
            hbw=[(bw, count, 0) for bw, count in sorted(bw_counts.items())],
        )
        records: list[tuple[object, ...]] = []
        for (bw, args), count in ranked:
            records.append((bw, count, *args))
        columns = ["bw", "count"] + [f"arg_{i}" for i in range(arity)]
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
        "--comptime",
        type=Path,
        default=None,
        help=(
            "Per-input compile-time JSON output path. Values contain perf "
            "measurement sample arrays."
        ),
    )
    p.add_argument(
        "--walltime",
        type=Path,
        default=None,
        help=(
            "Per-input coarse wall-clock compile-time JSON output path. Values "
            "are seconds."
        ),
    )
    p.add_argument(
        "--comptime-repeat",
        type=int,
        default=3,
        help=(
            "Number of times to run each input in --comptime mode. The JSON "
            "metrics are sample arrays."
        ),
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
        "inputs (domain + id + width + operands, summed bits_added/bottom) and "
        "write shards under <dir>/shards/, then merge them into per-pattern "
        "<dir>/<id>.tsv. Avoids the giant raw [pNNN] logs entirely.",
    )
    p.add_argument(
        "--jobs",
        type=int,
        default=None,
        help=("Parallel worker processes. Default: available CPU affinity count."),
    )
    args = p.parse_args()

    selected_modes = [
        args.stats is not None,
        args.comptime is not None,
        args.walltime is not None,
        args.pattern_hist is not None,
        args.slice_kb,
        args.slice_ucr,
        args.slice_scr,
    ]
    if sum(selected_modes) != 1:
        p.error(
            "exactly one of --stats, --comptime, --walltime, --pattern-hist, "
            "--slice-kb, --slice-ucr, or --slice-scr is required"
        )
    if args.comptime_repeat < 1:
        p.error("--comptime-repeat must be at least 1")

    if args.stats is not None:
        mode: RunMode = "stats"
    elif args.comptime is not None:
        mode = "comptime"
    elif args.walltime is not None:
        mode = "walltime"
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

    comptime_cpus: tuple[int, ...] = ()
    comptime_perf_cpu: int | None = None
    if mode == "comptime":
        comptime_cpus, comptime_perf_cpu = _check_comptime_environment()
    else:
        comptime_cpus = _comptime_cpus()

    if args.jobs is None:
        args.jobs = len(comptime_cpus)
    elif args.jobs < 1:
        p.error("--jobs must be at least 1")
    elif mode == "comptime" and args.jobs > len(comptime_cpus):
        p.error(
            f"--jobs={args.jobs} exceeds available CPU affinity count "
            f"({len(comptime_cpus)})"
        )

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
    elif args.comptime is not None:
        output_dir = args.comptime.parent
    elif args.walltime is not None:
        output_dir = args.walltime.parent
    elif args.pattern_hist is not None:
        output_dir = args.pattern_hist
    else:
        output_dir = Path(__file__).resolve().parent / "outputs" / mode
    output_dir.mkdir(parents=True, exist_ok=True)
    slice_dir = output_dir if mode in ("slice-kb", "slice-ucr", "slice-scr") else None
    test_log_path = output_dir / "test.log"

    stats_acc: dict[str, float] = {}
    comptime_acc: dict[str, PerfSamples] = {}
    walltime_acc: dict[str, float] = {}
    fail = False
    n_timeout = 0

    with Pool(
        processes=args.jobs,
        initializer=_init_worker,
        initargs=(
            args.opt_path,
            bench_dir,
            hist_dir,
            slice_dir,
            mode,
            args.comptime_repeat,
            comptime_cpus,
            comptime_perf_cpu,
        ),
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
                    if mode == "comptime":
                        comptime_acc[rel] = cast(PerfSamples, stats)
                    elif mode == "walltime":
                        walltime_acc[rel] = cast(ScalarStats, stats)["wall_time_s"]
                    else:
                        scalar_stats = cast(ScalarStats, stats)
                        for k, v in scalar_stats.items():
                            if k in STATS_NONDETER_KEYS:
                                continue
                            stats_acc[k] = stats_acc.get(k, 0) + v

    if args.stats is not None:
        with args.stats.open("w") as f:
            json.dump(stats_acc, f, indent=2, sort_keys=True)
        print(f"aggregated stats written to {args.stats} ({len(stats_acc)} keys)")

    if args.comptime is not None:
        with args.comptime.open("w") as f:
            json.dump(comptime_acc, f, indent=2, sort_keys=True)
        print(f"compile times written to {args.comptime} ({len(comptime_acc)} files)")

    if args.walltime is not None:
        with args.walltime.open("w") as f:
            json.dump(walltime_acc, f, indent=2, sort_keys=True)
        print(f"wall times written to {args.walltime} ({len(walltime_acc)} files)")

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
