from argparse import ArgumentParser
from collections import defaultdict
from dataclasses import dataclass
from pathlib import Path
import shutil
import sys

from synth_xfer._util.pattern_dsl import PatternOp
from synth_xfer._util.tsv import EnumData


@dataclass(frozen=True)
class TableScore:
    path: Path
    root: PatternOp
    total_count: int
    rows: int


def score_table(path: Path) -> TableScore:
    with path.open() as f:
        data = EnumData.read_tsv(f)

    if "count" not in data.enumdata.columns:
        raise ValueError(f"{path} has no 'count' column")

    root = data.metadata.op.nodes[data.metadata.op.result.index].op
    counts = [int(count) for count in data.enumdata["count"]]
    return TableScore(
        path=path,
        root=root,
        total_count=sum(counts),
        rows=len(data.enumdata),
    )


def select_tables(
    tables: list[TableScore],
    max_tsvs: int | None,
    max_tsvs_per_root: int | None,
    count_at_least: int | None,
) -> tuple[list[TableScore], list[TableScore]]:
    selected: list[TableScore] = []
    dropped: list[TableScore] = []
    per_root: defaultdict[PatternOp, int] = defaultdict(int)

    ranked = sorted(tables, key=lambda t: (-t.total_count, t.root.value, t.path.name))
    for table in ranked:
        if count_at_least is not None and table.total_count < count_at_least:
            dropped.append(table)
            continue

        keep = (max_tsvs is None or len(selected) < max_tsvs) and (
            max_tsvs_per_root is None or per_root[table.root] < max_tsvs_per_root
        )
        if keep:
            selected.append(table)
            per_root[table.root] += 1
        else:
            dropped.append(table)

    selected.sort(key=lambda t: t.path.name)
    dropped.sort(key=lambda t: t.path.name)
    return selected, dropped


def count_by_root(tables: list[TableScore]) -> dict[PatternOp, int]:
    counts: defaultdict[PatternOp, int] = defaultdict(int)
    for table in tables:
        counts[table.root] += 1
    return dict(counts)


def fmt_limit(value: int | None) -> str:
    return "none" if value is None else str(value)


def main() -> None:
    ap = ArgumentParser(
        description=(
            "Copy TSV tables from one directory to another, optionally applying "
            "global, per-root, and row-count filters."
        )
    )
    ap.add_argument("--tsv-dir", type=Path, required=True, help="Input TSV directory")
    ap.add_argument("--out-dir", type=Path, required=True, help="Output TSV directory")
    ap.add_argument(
        "--max-tsvs",
        type=int,
        metavar="N",
        help="Maximum number of TSV files to keep globally",
    )
    ap.add_argument(
        "--max-tsvs-per-root",
        type=int,
        metavar="N",
        help="Maximum number of TSV files to keep for each root op",
    )
    ap.add_argument(
        "--count-at-least",
        type=int,
        metavar="N",
        help=("Keep only tables whose count rows sum to at least N."),
    )
    args = ap.parse_args()

    if args.max_tsvs is not None and args.max_tsvs < 1:
        ap.error("--max-tsvs must be at least 1")
    if args.max_tsvs_per_root is not None and args.max_tsvs_per_root < 1:
        ap.error("--max-tsvs-per-root must be at least 1")
    if args.count_at_least is not None and args.count_at_least < 1:
        ap.error("--count-at-least must be at least 1")

    tsv_files = sorted(args.tsv_dir.glob("*.tsv"))
    if not tsv_files:
        sys.exit(f"error: no *.tsv files found in {args.tsv_dir}")

    tables: list[TableScore] = []
    for path in tsv_files:
        try:
            tables.append(score_table(path))
        except Exception as exc:
            sys.exit(f"error: failed to read {path}: {exc}")

    selected, dropped = select_tables(
        tables,
        max_tsvs=args.max_tsvs,
        max_tsvs_per_root=args.max_tsvs_per_root,
        count_at_least=args.count_at_least,
    )

    args.out_dir.mkdir(parents=True, exist_ok=True)
    for table in selected:
        shutil.copy2(table.path, args.out_dir / table.path.name)

    root_width = max(len(table.root.value) for table in tables)
    print(
        f"tables: {len(tables)} -> {len(selected)} "
        f"(max={fmt_limit(args.max_tsvs)}, "
        f"max_per_root={fmt_limit(args.max_tsvs_per_root)}, "
        f"count_at_least={fmt_limit(args.count_at_least)})"
    )
    print()
    print("Tables per root")
    before_by_root = count_by_root(tables)
    after_by_root = count_by_root(selected)
    for root in sorted(before_by_root, key=lambda r: r.value):
        print(
            f"  {root.value:<{root_width}}  "
            f"{before_by_root[root]} -> {after_by_root.get(root, 0)} tables"
        )


if __name__ == "__main__":
    main()
