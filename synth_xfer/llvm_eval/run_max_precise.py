import argparse
from concurrent.futures import ThreadPoolExecutor, as_completed
from dataclasses import dataclass
from pathlib import Path
import sys
import time

from synth_xfer._util.max_precise import fill_hbw_rows
from synth_xfer._util.smt_solver import SolverKind
from synth_xfer._util.tsv import EnumData


@dataclass(frozen=True)
class FileResult:
    path: Path
    ok: bool
    message: str = ""
    n_rows: int = 0
    elapsed: float = 0.0


def _run_one(
    tsv: Path,
    timeout: int,
    solver_kind: SolverKind,
    output_dir: Path | None,
) -> FileResult:
    start = time.perf_counter()
    try:
        with tsv.open() as f:
            data = EnumData.read_tsv(f)
        n_rows = sum(count for _, count, _ in data.metadata.hbw)
        updated, commented_rows = fill_hbw_rows(data, timeout, solver_kind)
        output_path = tsv if output_dir is None else output_dir / tsv.name
        updated.write_tsv_with_comments(output_path, commented_rows)
    except Exception as exc:
        elapsed = time.perf_counter() - start
        return FileResult(tsv, False, f"{type(exc).__name__}: {exc}", elapsed=elapsed)

    elapsed = time.perf_counter() - start
    return FileResult(tsv, True, n_rows=n_rows, elapsed=elapsed)


def _print_result(result: FileResult) -> bool:
    tag = "[done]   " if result.ok else "[FAIL]  "
    print(f"{tag} {result.path.stem} ({result.n_rows} rows, {result.elapsed:.1f}s)")
    if result.message:
        print("\n".join(f"    {line}" for line in result.message.splitlines()))
    return not result.ok


def main() -> None:
    p = argparse.ArgumentParser(formatter_class=argparse.RawDescriptionHelpFormatter)
    p.add_argument("src_dir", type=Path, help="Folder of histogram TSVs")
    # fill_hbw_rows parallelizes across the high-bitwidth rows in each file, so
    # total workers can be roughly jobs * cpu_count(); keep --jobs small.
    p.add_argument("--jobs", type=int, default=4, help="Parallel file workers")
    p.add_argument("--timeout", type=int, default=30, help="Per-query solver timeout (s)")
    p.add_argument(
        "--solver",
        type=SolverKind,
        choices=list(SolverKind),
        default=SolverKind.bitwuzla,
        help="SMT solver backend",
    )
    p.add_argument(
        "--output-dir",
        type=Path,
        default=None,
        help="Write filled TSVs here as <output-dir>/<name>.tsv instead of "
        "rewriting the inputs in place",
    )
    args = p.parse_args()

    if not args.src_dir.is_dir():
        sys.exit(f"error: {args.src_dir} is not a directory")
    tsvs = sorted(args.src_dir.glob("*.tsv"))
    if not tsvs:
        sys.exit(f"error: no *.tsv in {args.src_dir}")

    if args.output_dir is not None:
        args.output_dir.mkdir(parents=True, exist_ok=True)
    print(
        f"running max-precise over {len(tsvs)} files (jobs={args.jobs}, timeout={args.timeout}s)"
    )

    failures = 0
    if args.jobs == 1:
        for tsv in tsvs:
            result = _run_one(tsv, args.timeout, args.solver, args.output_dir)
            failures += _print_result(result)
    else:
        with ThreadPoolExecutor(max_workers=args.jobs) as pool:
            futures = [
                pool.submit(_run_one, tsv, args.timeout, args.solver, args.output_dir)
                for tsv in tsvs
            ]
            for future in as_completed(futures):
                failures += _print_result(future.result())

    print(f"done: {len(tsvs) - failures} ok, {failures} failed")
    # Per-file failures will be logged, so always exit with 0 for now
    # sys.exit(1 if failures else 0)


if __name__ == "__main__":
    main()
