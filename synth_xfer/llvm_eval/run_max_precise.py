import argparse
import subprocess
import sys
from concurrent.futures import ThreadPoolExecutor
from pathlib import Path


# The max-precise console script lives next to the interpreter running us.
MAX_PRECISE = str(Path(sys.executable).parent / "max-precise")


def _run_one(
    tsv: Path, timeout: int, output_dir: Path | None
) -> tuple[Path, int, str]:
    cmd = [MAX_PRECISE, "--input", str(tsv), "--timeout", str(timeout)]
    if output_dir is not None:
        cmd += ["--output", str(output_dir / tsv.name)]
    proc = subprocess.run(
        cmd, stdin=subprocess.DEVNULL, capture_output=True, text=True
    )
    return tsv, proc.returncode, (proc.stdout + proc.stderr).strip()


def main() -> None:
    p = argparse.ArgumentParser(
        description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter
    )
    p.add_argument("src_dir", type=Path, help="Folder of histogram TSVs")
    # max-precise already parallelizes across the rows of a single file, so total
    # worker processes ~= jobs * cpu_count(); keep --jobs small.
    p.add_argument("--jobs", type=int, default=4, help="Parallel file workers")
    p.add_argument("--timeout", type=int, default=10, help="Per-query solver timeout (s)")
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
    print(f"running max-precise over {len(tsvs)} files (jobs={args.jobs}, timeout={args.timeout}s)")

    failures = 0
    with ThreadPoolExecutor(max_workers=args.jobs) as pool:
        for tsv, rc, log in pool.map(
            lambda t: _run_one(t, args.timeout, args.output_dir), tsvs
        ):
            tag = "[done]   " if rc == 0 else f"[FAIL {rc}]"
            failures += rc != 0
            print(f"{tag} {tsv.stem}")
            if log:
                print("\n".join(f"    {line}" for line in log.splitlines()))

    print(f"done: {len(tsvs) - failures} ok, {failures} failed")
    sys.exit(1 if failures else 0)


if __name__ == "__main__":
    main()
