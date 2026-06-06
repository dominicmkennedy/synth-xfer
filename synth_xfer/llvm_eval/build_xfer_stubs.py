import argparse
import csv
from pathlib import Path
import shutil

from synth_xfer._util.domain import AbstractDomain
from synth_xfer._util.pattern_dsl import PatternDag


def _render_kb_top(pattern_id: str, arity: int) -> str:
    params = ", ".join(f"std::array<APInt, 2> ssa_{i}" for i in range(arity))
    return (
        f"namespace {pattern_id} {{\n"
        f"std::array<APInt, 2> solution({params}) {{\n"
        f"\tunsigned bw = ssa_0[0].getBitWidth();\n"
        f"\treturn std::array<APInt, 2>{{APInt(bw, 0), APInt(bw, 0)}};\n"
        f"}}\n"
        f"}}\n"
    )


def _patterns_from_tsv(tsv_path: Path) -> list[PatternDag]:
    with tsv_path.open(newline="") as f:
        reader = csv.DictReader(f, delimiter="\t")
        if reader.fieldnames is None or "pattern" not in reader.fieldnames:
            raise ValueError(f"{tsv_path}: no 'pattern' column")
        rows = [row["pattern"].strip() for row in reader]

    return [PatternDag(x) for x in rows]


def main():
    p = argparse.ArgumentParser(formatter_class=argparse.RawDescriptionHelpFormatter)
    p.add_argument(
        "--tsv",
        type=Path,
        required=True,
        help="TSV file with a `pattern` column of expression strings",
    )
    p.add_argument(
        "--output-dir",
        type=Path,
        required=True,
        help="Output transformer dir: <id>.inc files are written under inc/",
    )
    p.add_argument(
        "-d",
        "--domain",
        type=str,
        choices=[str(x) for x in AbstractDomain],
        required=True,
        help="Abstract Domain",
    )
    args = p.parse_args()
    domain = AbstractDomain[args.domain]
    patterns = _patterns_from_tsv(args.tsv)

    inc_dir = args.output_dir / "inc"
    if inc_dir.exists():
        shutil.rmtree(inc_dir)
    inc_dir.mkdir(parents=True)

    for pattern in patterns:
        id = pattern.to_id()
        if domain == AbstractDomain.KnownBits:
            (inc_dir / f"{id}.inc").write_text(_render_kb_top(id, pattern.num_args))
        elif domain == AbstractDomain.UConstRange:
            assert False
        elif domain == AbstractDomain.SConstRange:
            assert False
        else:
            assert False

    print(f"wrote {len(patterns)} files")


if __name__ == "__main__":
    main()
