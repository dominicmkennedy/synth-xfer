from argparse import ArgumentParser, BooleanOptionalAction
from collections import defaultdict
from dataclasses import dataclass
from pathlib import Path
import sys
from typing import Any, Callable, Hashable, cast

from synth_xfer._util.domain import AbstractDomain, get_bvs_from_abst, is_top
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
    top: int
    bottom: int
    sequential: int
    subsumed: int
    capped: int
    empty: bool
    largest_bw: int | None
    largest_bw_rows: int

    @classmethod
    def zero(cls) -> "FileStats":
        return cls(
            rows_seen=0,
            rows_kept=0,
            top=0,
            bottom=0,
            sequential=0,
            subsumed=0,
            capped=0,
            empty=True,
            largest_bw=None,
            largest_bw_rows=0,
        )

    def __add__(self, other: "FileStats") -> "FileStats":
        largest_bw = self.largest_bw
        largest_bw_rows = self.largest_bw_rows
        if other.largest_bw_rows > largest_bw_rows:
            largest_bw = other.largest_bw
            largest_bw_rows = other.largest_bw_rows
        return FileStats(
            rows_seen=self.rows_seen + other.rows_seen,
            rows_kept=self.rows_kept + other.rows_kept,
            top=self.top + other.top,
            bottom=self.bottom + other.bottom,
            sequential=self.sequential + other.sequential,
            subsumed=self.subsumed + other.subsumed,
            capped=self.capped + other.capped,
            empty=self.empty and other.empty,
            largest_bw=largest_bw,
            largest_bw_rows=largest_bw_rows,
        )


def prune_group(rows: list[Row], domain: AbstractDomain, bw: int) -> list[int]:
    """Minimal-cover pruning for rows of one bitwidth.
    Row B is redundant if another row A matches every query B matches, and A's
    ideal is at least as precise as B's ideal under the domain's meet semantics.
    The returned list maps each input row to the row that should receive its
    count; kept rows map to themselves.
    """
    if domain == AbstractDomain.KnownBits:
        return _prune_knownbits_group(rows, domain, bw)
    if domain in (AbstractDomain.UConstRange, AbstractDomain.SConstRange):
        return _prune_const_range_group(rows, domain, bw)
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


def _prune_knownbits_group(rows: list[Row], domain: AbstractDomain, bw: int) -> list[int]:
    # Per-row masks: combined arg (zero/one) masks, ideal (zero/one) masks, and
    # the count of known arg bits (a dominator can only have <= as many).
    feats: list[KBFeature] = []
    for args, ideal in rows:
        aZ = aO = shift = 0
        for s in args:
            z, o = cast(tuple[int, int], get_bvs_from_abst(s, domain, bw))
            aZ |= z << shift
            aO |= o << shift
            shift += len(s)
        output = get_bvs_from_abst(ideal, domain, bw)
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
    rows: list[Row], domain: AbstractDomain, bw: int
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
            cast(Interval, get_bvs_from_abst(arg, domain, bw)) for arg in args
        )
        ideal_range = get_bvs_from_abst(ideal, domain, bw)
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
        sys.exit(f"{path.name}: no 'ideal' column; run max-precise first")

    arg_cols = [f"arg_{a}" for a in range(data.metadata.arity)]

    if options.drop_locally_complete and "sequential_ideal" not in frame.columns:
        sys.exit(f"{path.name}: no 'sequential_ideal' column")

    n_seen = n_top = n_bottom = n_sequential = n_subsumed = n_capped = 0
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
        n_seen += 1
        if sequential_ideal is not None and ideal == sequential_ideal:
            n_sequential += 1
        if any(v == "(bottom)" for v in argvals):
            n_bottom += 1
        else:
            if ideal == "(bottom)":
                n_bottom += 1
            if ideal == "(bottom)" and options.drop_bottom:
                continue
            if options.drop_locally_complete and ideal == sequential_ideal:
                continue
            if options.drop_top and is_top(ideal, data.metadata.domain, bw):
                n_top += 1
                continue
            groups[bw].append((pos, argvals, ideal))

    # Per bitwidth: subsumption-prune, then cap, collecting kept positions.
    cap = options.max_rows_per_bw
    keep_positions: list[int] = []
    kept_by_bw: dict[int, int] = {}
    merged_counts: dict[int, int] = {}
    has_count = "count" in frame.columns
    for bw, grp in groups.items():
        targets = (
            prune_group([(a, d) for _, a, d in grp], data.metadata.domain, bw)
            if options.prune_subsumed
            else list(range(len(grp)))
        )
        if has_count:
            for local_idx, target_idx in enumerate(targets):
                if local_idx == target_idx:
                    continue
                dst_pos = grp[target_idx][0]
                src_pos = grp[local_idx][0]
                if dst_pos not in merged_counts:
                    merged_counts[dst_pos] = row_int(frame.iloc[dst_pos], "count")
                merged_counts[dst_pos] += row_int(frame.iloc[src_pos], "count")
        kept = [pos for i, (pos, _, _) in enumerate(grp) if targets[i] == i]
        n_subsumed += len(grp) - len(kept)
        if cap and len(kept) > cap:
            n_capped += len(kept) - cap
            kept = kept[:cap]
        kept_by_bw[bw] = len(kept)
        keep_positions.extend(kept)

    pattern_kept = len(keep_positions)
    top_bw, top_bw_rows = max(kept_by_bw.items(), key=lambda kv: kv[1], default=(None, 0))

    if pattern_kept == 0:
        return FileStats(
            rows_seen=n_seen,
            rows_kept=0,
            top=n_top,
            bottom=n_bottom,
            sequential=n_sequential,
            subsumed=n_subsumed,
            capped=n_capped,
            empty=True,
            largest_bw=top_bw,
            largest_bw_rows=top_bw_rows,
        )

    if merged_counts:
        frame = frame.copy()
        for pos, count in merged_counts.items():
            frame.at[pos, "count"] = count

    kept_frame = frame.iloc[sorted(keep_positions)].reset_index(drop=True)
    EnumData(data.metadata, kept_frame).write_tsv(out_dir / path.name)

    return FileStats(
        rows_seen=n_seen,
        rows_kept=pattern_kept,
        top=n_top,
        bottom=n_bottom,
        sequential=n_sequential,
        subsumed=n_subsumed,
        capped=n_capped,
        empty=False,
        largest_bw=top_bw,
        largest_bw_rows=top_bw_rows,
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
        default=False,
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
    name_width = max(len(p.name) for p in tsv_files)
    options = PruneOptions(
        drop_top=args.drop_top,
        drop_bottom=args.drop_bottom,
        drop_locally_complete=args.drop_locally_complete,
        prune_subsumed=args.prune_subsumed,
        max_rows_per_bw=args.max_rows_per_bw,
    )

    total = FileStats.zero()
    n_empty = 0
    for path in tsv_files:
        stats = prune_file(path, args.out_dir, options)
        bw_label = "-" if stats.largest_bw is None else str(stats.largest_bw)
        print(
            f"{path.name:<{name_width}}  rows: {stats.rows_seen:>6}   "
            f"kept: {stats.rows_kept:>5}   "
            f"largest: {stats.largest_bw_rows:>5} (bw={bw_label})"
        )
        total += stats
        n_empty += int(stats.empty)

    print(
        f"Optimized {len(tsv_files) - n_empty} TSVs -> {args.out_dir} "
        f"({n_empty} empty patterns skipped)"
    )
    print(
        f"Rows seen: {total.rows_seen}  kept: {total.rows_kept}  "
        f"dropped: {total.rows_seen - total.rows_kept} "
        f"(top: {total.top}, bottom: {total.bottom}, "
        f"sequential: {total.sequential}, subsumed: {total.subsumed}, "
        f"capped: {total.capped})"
    )


if __name__ == "__main__":
    main()
