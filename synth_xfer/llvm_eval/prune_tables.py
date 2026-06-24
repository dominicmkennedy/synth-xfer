from argparse import ArgumentParser, BooleanOptionalAction
from collections import defaultdict
from dataclasses import dataclass
from pathlib import Path
from statistics import mean, median, stdev
import sys
from typing import Any, Callable, Hashable, Iterable, cast

from synth_xfer._util.domain import AbstractDomain, get_bvs_from_abst, is_top
from synth_xfer._util.max_precise import _concrete_width
from synth_xfer._util.parse_mlir import HelperFuncs
from synth_xfer._util.tsv import EnumData

Row = tuple[tuple[str, ...], str]
Interval = tuple[int, int]
AbsValue = Interval | None
KBFeature = tuple[int, int, AbsValue, int]
CRFeature = tuple[tuple[Interval, ...], AbsValue]


@dataclass(frozen=True)
class PruneOptions:
    drop_top: bool
    drop_bottom: bool
    drop_locally_complete: bool
    prune_subsumed: bool
    max_rows_per_bw: int


@dataclass(frozen=True)
class FileStats:
    rows_seen: int
    rows_kept: int
    count_seen: int
    count_kept: int
    top: int
    top_count: int
    bottom: int
    bottom_count: int
    sequential: int
    sequential_count: int
    subsumed: int
    subsumed_count: int
    capped: int
    capped_count: int
    empty: bool
    count_per_row: tuple[int, ...]
    kept_count_per_row: tuple[int, ...]
    count_deltas_after_subsumption: tuple[int, ...]

    @classmethod
    def zero(cls) -> "FileStats":
        return cls(
            rows_seen=0,
            rows_kept=0,
            count_seen=0,
            count_kept=0,
            top=0,
            top_count=0,
            bottom=0,
            bottom_count=0,
            sequential=0,
            sequential_count=0,
            subsumed=0,
            subsumed_count=0,
            capped=0,
            capped_count=0,
            empty=True,
            count_per_row=(),
            kept_count_per_row=(),
            count_deltas_after_subsumption=(),
        )

    def __add__(self, other: "FileStats") -> "FileStats":
        return FileStats(
            rows_seen=self.rows_seen + other.rows_seen,
            rows_kept=self.rows_kept + other.rows_kept,
            count_seen=self.count_seen + other.count_seen,
            count_kept=self.count_kept + other.count_kept,
            top=self.top + other.top,
            top_count=self.top_count + other.top_count,
            bottom=self.bottom + other.bottom,
            bottom_count=self.bottom_count + other.bottom_count,
            sequential=self.sequential + other.sequential,
            sequential_count=self.sequential_count + other.sequential_count,
            subsumed=self.subsumed + other.subsumed,
            subsumed_count=self.subsumed_count + other.subsumed_count,
            capped=self.capped + other.capped,
            capped_count=self.capped_count + other.capped_count,
            empty=self.empty and other.empty,
            count_per_row=self.count_per_row + other.count_per_row,
            kept_count_per_row=self.kept_count_per_row + other.kept_count_per_row,
            count_deltas_after_subsumption=(
                self.count_deltas_after_subsumption + other.count_deltas_after_subsumption
            ),
        )


@dataclass(frozen=True)
class Summary:
    min: float
    max: float
    median: float
    mean: float
    stddev: float

    @classmethod
    def of(cls, values: Iterable[float]) -> "Summary | None":
        xs = list(values)
        if not xs:
            return None
        return cls(
            min=min(xs),
            max=max(xs),
            median=median(xs),
            mean=mean(xs),
            stddev=stdev(xs) if len(xs) > 1 else 0.0,
        )

    def fmt(self, *, suffix: str = "") -> str:
        return (
            f"min={self.min:.2f}{suffix} max={self.max:.2f}{suffix} "
            f"med={self.median:.2f}{suffix} mean={self.mean:.2f}{suffix} "
            f"stddev={self.stddev:.2f}{suffix}"
        )


def prune_group(
    rows: list[Row],
    domain: AbstractDomain,
    arg_widths: list[int],
    result_width: int,
) -> list[int]:
    """Minimal-cover pruning for rows of one bitwidth.
    Row B is redundant if another row A matches every query B matches, and A's
    ideal is at least as precise as B's ideal under the domain's meet semantics.
    The returned list maps each input row to the row that should receive its
    count; kept rows map to themselves.

    ``arg_widths`` / ``result_width`` give each operand and the ideal its own
    bitwidth: an operand like a Select condition is ``i1`` regardless of the
    group's data width, so it cannot be parsed at a single ``bw``.
    """
    if domain == AbstractDomain.KnownBits:
        return _prune_knownbits_group(rows, domain, arg_widths, result_width)
    if domain in (AbstractDomain.UConstRange, AbstractDomain.SConstRange):
        return _prune_const_range_group(rows, domain, arg_widths, result_width)
    raise NotImplementedError(f"{domain} not supported yet")


def prune_by_dominance[T](
    features: list[T],
    dominates: Callable[[T, T], bool],
    key: Callable[[T], Hashable] | None = None,
) -> list[int]:
    target = list(range(len(features)))
    key_fn = key if key is not None else lambda feat: feat
    seen: dict[object, int] = {}
    for i, feat in enumerate(features):
        feat_key = key_fn(feat)
        if feat_key in seen:
            target[i] = seen[feat_key]
        else:
            seen[feat_key] = i

    order = [i for i, dst in enumerate(target) if dst == i]
    for B in order:
        for A in order:
            if A != B and dominates(features[A], features[B]):
                target[B] = A
                break

    def resolve(i: int) -> int:
        while target[i] != i:
            i = target[i]
        return i

    return [resolve(i) for i in range(len(features))]


def row_int(row: Any, col: str) -> int:
    return int(cast(int, row[col]))


def _prune_knownbits_group(
    rows: list[Row],
    domain: AbstractDomain,
    arg_widths: list[int],
    result_width: int,
) -> list[int]:
    # Per-row masks: combined arg (zero/one) masks, ideal (zero/one) masks, and
    # the count of known arg bits (a dominator can only have <= as many).
    feats: list[KBFeature] = []
    for args, ideal in rows:
        aZ = aO = shift = 0
        for s, w in zip(args, arg_widths):
            z, o = cast(tuple[int, int], get_bvs_from_abst(s, domain, w))
            aZ |= z << shift
            aO |= o << shift
            shift += w
        output = get_bvs_from_abst(ideal, domain, result_width)
        feats.append((aZ, aO, output, bin(aZ | aO).count("1")))

    def dominates(a: KBFeature, b: KBFeature) -> bool:
        aZ, aO, a_out, akc = a
        bZ, bO, b_out, bkc = b
        if a_out is None:
            output_covers = True
        elif b_out is None:
            output_covers = False
        else:
            aoZ, aoO = a_out
            boZ, boO = b_out
            output_covers = not (boZ & ~aoZ) and not (boO & ~aoO)
        return akc <= bkc and not (aZ & ~bZ) and not (aO & ~bO) and output_covers

    return prune_by_dominance(feats, dominates, key=lambda feat: feat[:3])


def _prune_const_range_group(
    rows: list[Row],
    domain: AbstractDomain,
    arg_widths: list[int],
    result_width: int,
) -> list[int]:
    def contains(outer: AbsValue, inner: AbsValue) -> bool:
        if inner is None:
            return True
        if outer is None:
            return False
        return outer[0] <= inner[0] and inner[1] <= outer[1]

    feats: list[CRFeature] = []
    for args, ideal in rows:
        arg_ranges = tuple(
            cast(Interval, get_bvs_from_abst(arg, domain, w))
            for arg, w in zip(args, arg_widths)
        )
        ideal_range = get_bvs_from_abst(ideal, domain, result_width)
        feats.append((arg_ranges, ideal_range))

    def dominates(a: CRFeature, b: CRFeature) -> bool:
        a_args, a_out = a
        b_args, b_out = b
        return all(
            contains(a_arg, b_arg) for a_arg, b_arg in zip(a_args, b_args)
        ) and contains(b_out, a_out)

    return prune_by_dominance(feats, dominates)


def prune_file(path: Path, out_dir: Path, options: PruneOptions) -> FileStats:
    with path.open() as f:
        data = EnumData.read_tsv(f)
    frame = data.enumdata

    if "ideal" not in frame.columns:
        if len(frame) == 0:
            return FileStats.zero()
        sys.exit(f"{path.name}: no 'ideal' column; run max-precise first")

    arg_cols = [f"arg_{a}" for a in range(data.metadata.arity)]

    # Per-operand types from the pattern's lowering: a Select condition is i1,
    # an icmp result is i1, etc., independent of the group's data width. Reuse
    # the same inference max-precise used to fill the table so each operand and
    # the ideal are parsed at their true width rather than a single `bw`.
    hlprs = HelperFuncs(data.metadata.op, data.metadata.domain)

    def widths_for(bw: int) -> tuple[list[int], int]:
        arg_widths = [_concrete_width(t, bw) for t in hlprs.conc_arg_ty]
        return arg_widths, _concrete_width(hlprs.conc_ret_ty, bw)

    if options.drop_locally_complete and "sequential_ideal" not in frame.columns:
        sys.exit(f"{path.name}: no 'sequential_ideal' column")

    has_count = "count" in frame.columns

    def row_count(pos: int) -> int:
        return row_int(frame.iloc[pos], "count") if has_count else 1

    count_per_row = (
        tuple(int(v) for v in frame["count"])
        if has_count
        else tuple(1 for _ in range(len(frame)))
    )
    count_seen = sum(count_per_row)

    n_seen = n_top = n_bottom = n_sequential = n_subsumed = n_capped = 0
    top_count = bottom_count = sequential_count = subsumed_count = capped_count = 0

    # Drop top/bottom rows and bucket survivors by bitwidth (rows of
    # different widths never match the same query, so pruning is per-width).
    # Each entry keeps its original row position to slice the frame later.
    groups: dict[int, list[tuple[int, tuple[str, ...], str]]] = defaultdict(list)
    for pos, (_, row) in enumerate(frame.iterrows()):
        argvals = tuple(str(row[c]) for c in arg_cols)
        ideal = str(row["ideal"])
        sequential_ideal = (
            str(row["sequential_ideal"]) if "sequential_ideal" in frame.columns else None
        )
        bw = row_int(row, "bw")
        cnt = row_count(pos)
        n_seen += 1
        if any(v == "(bottom)" for v in argvals):
            n_bottom += 1
            bottom_count += cnt
        else:
            if ideal == "(bottom)":
                n_bottom += 1
                bottom_count += cnt
            if ideal == "(bottom)" and options.drop_bottom:
                continue
            if options.drop_top and is_top(
                ideal, data.metadata.domain, widths_for(bw)[1]
            ):
                n_top += 1
                top_count += cnt
                continue
            if options.drop_locally_complete and ideal == sequential_ideal:
                n_sequential += 1
                sequential_count += cnt
                continue
            groups[bw].append((pos, argvals, ideal))

    # Per bitwidth: subsumption-prune, then cap, collecting kept positions.
    cap = options.max_rows_per_bw
    keep_positions: list[int] = []
    merged_counts: dict[int, int] = {}
    count_deltas: list[int] = []
    for bw, grp in groups.items():
        arg_widths, result_width = widths_for(bw)
        targets = (
            prune_group(
                [(a, d) for _, a, d in grp],
                data.metadata.domain,
                arg_widths,
                result_width,
            )
            if options.prune_subsumed
            else list(range(len(grp)))
        )
        subsumed_count_by_target: dict[int, int] = {}
        if has_count:
            for local_idx, target_idx in enumerate(targets):
                if local_idx == target_idx:
                    continue
                dst_pos = grp[target_idx][0]
                src_pos = grp[local_idx][0]
                src_count = row_count(src_pos)
                if dst_pos not in merged_counts:
                    merged_counts[dst_pos] = row_count(dst_pos)
                merged_counts[dst_pos] += src_count
                subsumed_count_by_target[dst_pos] = (
                    subsumed_count_by_target.get(dst_pos, 0) + src_count
                )
        kept = [pos for i, (pos, _, _) in enumerate(grp) if targets[i] == i]
        if not has_count:
            for local_idx, target_idx in enumerate(targets):
                if local_idx == target_idx:
                    continue
                dst_pos = grp[target_idx][0]
                subsumed_count_by_target[dst_pos] = (
                    subsumed_count_by_target.get(dst_pos, 0) + 1
                )
        bw_subsumed = len(grp) - len(kept)
        bw_subsumed_count = sum(subsumed_count_by_target.values())
        n_subsumed += bw_subsumed
        subsumed_count += bw_subsumed_count
        count_deltas.extend(subsumed_count_by_target.values())
        if cap and len(kept) > cap:
            capped_positions = kept[cap:]
            bw_capped = len(capped_positions)
            bw_capped_count = sum(
                merged_counts.get(pos, row_count(pos)) for pos in capped_positions
            )
            n_capped += bw_capped
            capped_count += bw_capped_count
            kept = kept[:cap]
        keep_positions.extend(kept)

    pattern_kept = len(keep_positions)

    if pattern_kept == 0:
        return FileStats(
            rows_seen=n_seen,
            rows_kept=0,
            count_seen=count_seen,
            count_kept=0,
            top=n_top,
            top_count=top_count,
            bottom=n_bottom,
            bottom_count=bottom_count,
            sequential=n_sequential,
            sequential_count=sequential_count,
            subsumed=n_subsumed,
            subsumed_count=subsumed_count,
            capped=n_capped,
            capped_count=capped_count,
            empty=True,
            count_per_row=count_per_row,
            kept_count_per_row=(),
            count_deltas_after_subsumption=tuple(count_deltas),
        )

    if merged_counts:
        frame = frame.copy()
        for pos, count in merged_counts.items():
            frame.at[pos, "count"] = count

    kept_frame = frame.iloc[sorted(keep_positions)].reset_index(drop=True)
    EnumData(data.metadata, kept_frame).write_tsv(out_dir / path.name)
    kept_count_per_row = (
        tuple(int(v) for v in kept_frame["count"])
        if has_count
        else tuple(1 for _ in range(pattern_kept))
    )

    return FileStats(
        rows_seen=n_seen,
        rows_kept=pattern_kept,
        count_seen=count_seen,
        count_kept=(
            sum(int(v) for v in kept_frame["count"]) if has_count else pattern_kept
        ),
        top=n_top,
        top_count=top_count,
        bottom=n_bottom,
        bottom_count=bottom_count,
        sequential=n_sequential,
        sequential_count=sequential_count,
        subsumed=n_subsumed,
        subsumed_count=subsumed_count,
        capped=n_capped,
        capped_count=capped_count,
        empty=False,
        count_per_row=count_per_row,
        kept_count_per_row=kept_count_per_row,
        count_deltas_after_subsumption=tuple(count_deltas),
    )


def main() -> None:
    ap = ArgumentParser()
    ap.add_argument("--tsv-dir", type=Path, required=True)
    ap.add_argument("--out-dir", type=Path, required=True)
    ap.add_argument(
        "--drop-top",
        action=BooleanOptionalAction,
        default=True,
        help="Drop rows whose ideal output is top",
    )
    ap.add_argument(
        "--drop-bottom",
        action=BooleanOptionalAction,
        default=True,
        help="Drop rows whose ideal output is bottom. Rows with bottom args are always dropped.",
    )
    ap.add_argument(
        "--drop-locally-complete",
        action=BooleanOptionalAction,
        default=True,
        help="Drop rows whose ideal output equals sequential_ideal",
    )
    ap.add_argument(
        "--prune-subsumed",
        action=BooleanOptionalAction,
        default=True,
        help="Drop rows subsumed by a more-general row that covers that output",
    )
    ap.add_argument(
        "--max-rows-per-bw",
        type=int,
        default=0,
        metavar="N",
        help="Cap the number of kept rows per bitwidth",
    )
    args = ap.parse_args()

    tsv_files = sorted(args.tsv_dir.glob("*.tsv"))
    args.out_dir.mkdir(parents=True, exist_ok=True)
    name_width = max((len(p.name) for p in tsv_files), default=0)
    options = PruneOptions(
        drop_top=args.drop_top,
        drop_bottom=args.drop_bottom,
        drop_locally_complete=args.drop_locally_complete,
        prune_subsumed=args.prune_subsumed,
        max_rows_per_bw=args.max_rows_per_bw,
    )

    total = FileStats.zero()
    n_empty = 0
    per_file: list[FileStats] = []
    for path in tsv_files:
        stats = prune_file(path, args.out_dir, options)
        per_file.append(stats)
        print(
            f"{path.name:<{name_width}}  rows: {stats.rows_seen:>6}   "
            f"kept: {stats.rows_kept:>5}"
        )
        total += stats
        n_empty += int(stats.empty)

    def pct(part: int, whole: int) -> float:
        return 0.0 if whole == 0 else 100.0 * part / whole

    def fmt_int(value: int) -> str:
        return f"{value:,}"

    def fmt_float(value: float, *, suffix: str = "") -> str:
        return f"{value:,.2f}{suffix}"

    def print_summary_table(title: str, rows: list[tuple[str, Summary]]) -> None:
        if not rows:
            return
        print()
        print(title)
        print(
            f"  {'metric':<42} {'min':>14} {'max':>14} {'med':>14} "
            f"{'mean':>14} {'stddev':>14}"
        )
        for label, summary in rows:
            print(
                f"  {label:<42} {fmt_float(summary.min):>14} "
                f"{fmt_float(summary.max):>14} {fmt_float(summary.median):>14} "
                f"{fmt_float(summary.mean):>14} {fmt_float(summary.stddev):>14}"
            )

    def print_before_after_summary_table(
        title: str, rows: list[tuple[str, Summary | None, Summary | None]]
    ) -> None:
        rows = [
            (label, before, after)
            for label, before, after in rows
            if before is not None or after is not None
        ]
        if not rows:
            return
        print()
        print(title)
        print(
            f"  {'metric':<34} {'phase':<7} {'min':>14} {'max':>14} "
            f"{'med':>14} {'mean':>14} {'stddev':>14}"
        )
        for label, before, after in rows:
            for phase, summary in (("before", before), ("after", after)):
                if summary is None:
                    continue
                print(
                    f"  {label:<34} {phase:<7} {fmt_float(summary.min):>14} "
                    f"{fmt_float(summary.max):>14} "
                    f"{fmt_float(summary.median):>14} "
                    f"{fmt_float(summary.mean):>14} "
                    f"{fmt_float(summary.stddev):>14}"
                )

    def print_drop_table(rows: list[tuple[str, int, int]]) -> None:
        print()
        print("Dropped Rows")
        print(
            f"  {'reason':<24} {'rows':>14} {'row %':>9} {'count':>18} {'weighted %':>12}"
        )
        for label, rows_dropped, count_dropped in rows:
            print(
                f"  {label:<24} {fmt_int(rows_dropped):>14} "
                f"{fmt_float(pct(rows_dropped, total.rows_seen), suffix='%'):>9} "
                f"{fmt_int(count_dropped):>18} "
                f"{fmt_float(pct(count_dropped, total.count_seen), suffix='%'):>12}"
            )

    def print_overall_reduction() -> None:
        empty_count = sum(s.count_seen for s in per_file if s.empty)
        rows_dropped = total.rows_seen - total.rows_kept
        count_dropped = total.count_seen - total.count_kept
        print()
        print("Overall Reduction")
        print(f"  {'metric':<24} {'absolute':>18} {'percent':>10}")
        print(
            f"  {'tables dropped':<24} {fmt_int(n_empty):>18} "
            f"{fmt_float(pct(n_empty, len(tsv_files)), suffix='%'):>10}"
        )
        print(
            f"  {'tables dropped weight':<24} {fmt_int(empty_count):>18} "
            f"{fmt_float(pct(empty_count, total.count_seen), suffix='%'):>10}"
        )
        print(
            f"  {'rows dropped':<24} {fmt_int(rows_dropped):>18} "
            f"{fmt_float(pct(rows_dropped, total.rows_seen), suffix='%'):>10}"
        )
        print(
            f"  {'rows dropped weight':<24} {fmt_int(count_dropped):>18} "
            f"{fmt_float(pct(count_dropped, total.count_seen), suffix='%'):>10}"
        )

    print(
        f"Optimized {len(tsv_files) - n_empty} TSVs -> {args.out_dir} "
        f"({n_empty} empty patterns skipped)"
    )
    print(
        f"Rows: {fmt_int(total.rows_seen)} seen, {fmt_int(total.rows_kept)} kept, "
        f"{fmt_int(total.rows_seen - total.rows_kept)} dropped"
    )
    print(f"Input tables: {fmt_int(len(tsv_files))}")
    print_overall_reduction()

    print_before_after_summary_table(
        "Input/Output Distributions",
        [
            (
                "rows per table",
                Summary.of(s.rows_seen for s in per_file),
                Summary.of(s.rows_kept for s in per_file),
            ),
            (
                "count per row",
                Summary.of(total.count_per_row),
                Summary.of(total.kept_count_per_row),
            ),
            (
                "count per table",
                Summary.of(s.count_seen for s in per_file),
                Summary.of(s.count_kept for s in per_file),
            ),
        ],
    )

    print_drop_table(
        [
            ("bottom", total.bottom, total.bottom_count),
            ("ideal==top", total.top, total.top_count),
            ("locally complete", total.sequential, total.sequential_count),
            ("subsumed", total.subsumed, total.subsumed_count),
            ("capped", total.capped, total.capped_count),
        ]
    )

    print()
    print(f"Tables dropped because all rows were dropped: {fmt_int(n_empty)}")

    output_summaries: list[tuple[str, Summary]] = []
    delta_summary = Summary.of(total.count_deltas_after_subsumption)
    if delta_summary is not None:
        output_summaries.append(
            ("subsumption count delta per receiving row", delta_summary)
        )
    shrink_summary = Summary.of(
        pct(s.rows_seen - s.rows_kept, s.rows_seen) for s in per_file if s.rows_seen > 0
    )
    if shrink_summary is not None:
        output_summaries.append(("output row reduction by table (%)", shrink_summary))
    count_shrink_summary = Summary.of(
        pct(s.count_seen - s.count_kept, s.count_seen)
        for s in per_file
        if s.count_seen > 0
    )
    if count_shrink_summary is not None:
        output_summaries.append(
            ("output count reduction by table (%)", count_shrink_summary)
        )
    print_summary_table("Output Distributions", output_summaries)


if __name__ == "__main__":
    main()
