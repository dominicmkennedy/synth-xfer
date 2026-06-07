"""Optimize KnownBits pattern TSVs for lookup-table generation.

Port of llvm-project/table_builder/prune_table.py, adapted to the EnumData
TSVs produced by run_max_precise.py (e.g. outputs/test_pat/tables). Reads the
ideal-filled per-pattern TSVs and writes optimized copies containing only the
rows worth keeping for a sound + optimal meet-based lookup:

  - Drop rows whose ideal output is top (all '?'); under meet semantics they
    contribute nothing.
  - Drop rows where any arg or the ideal is bottom (unreachable input); those
    cannot be represented as ternary masks and carry no lookup value.
  - Drop rows subsumed by a more-general row that already covers their output
    (minimal-cover pruning), per bitwidth.

The YAML header is preserved via EnumData round-tripping. Every input TSV must
have an `ideal` column (run max-precise first).

Example:
    python3 -m synth_xfer.llvm_eval.prune_tables \\
        --tsv-dir outputs/test_pat/tables --out-dir outputs/test_pat/pruned
"""

from argparse import ArgumentParser, BooleanOptionalAction
from collections import defaultdict
from pathlib import Path
import sys

from synth_xfer._util.domain import AbstractDomain
from synth_xfer._util.tsv import EnumData


def is_top(s: str) -> bool:
    return s != "" and all(c == "?" for c in s)


def ternary_masks(s: str) -> tuple[int, int]:
    """Convert a ternary string to (zero_mask, one_mask). Bit position is
    irrelevant for the subset comparisons below, as long as it is consistent
    across rows of the same width -- so we just walk LSB-first."""
    z = o = 0
    for i, ch in enumerate(reversed(s)):
        if ch == "0":
            z |= 1 << i
        elif ch == "1":
            o |= 1 << i
    return z, o


def prune_group(rows: list[tuple[tuple[str, ...], str]]) -> list[bool]:
    """Minimal-cover pruning for rows of one bitwidth under OR/meet semantics.

    A row matches an input iff its known arg bits are a subset of (and agree
    with) the input's known bits; the lookup ORs the outputs of every matching
    row. So row B is redundant if some other row A is strictly more general
    (A's arg constraints are a subset of B's) AND A's output already covers
    B's output bits: whenever B matches, A matches too and contributes at least
    everything B would. Dropping B leaves the transfer function unchanged.

    Returns a keep-flag per input row (original order preserved).
    """
    n = len(rows)
    # Per-row masks: combined arg (zero/one) masks, ideal (zero/one) masks, and
    # the count of known arg bits (a dominator can only have <= as many).
    feats = []
    for args, ideal in rows:
        aZ = aO = shift = 0
        for s in args:
            z, o = ternary_masks(s)
            aZ |= z << shift
            aO |= o << shift
            shift += len(s)
        oZ, oO = ternary_masks(ideal)
        feats.append((aZ, aO, oZ, oO, bin(aZ | aO).count("1")))

    keep = [True] * n
    # Drop exact duplicates first (identical args AND ideal). This is the only
    # way two rows could mutually dominate, so removing the extras up front
    # makes the dominance relation below a strict partial order -- safe to apply
    # in a single pass.
    seen: set = set()
    for i in range(n):
        key = feats[i][:4]
        if key in seen:
            keep[i] = False
        else:
            seen.add(key)

    # Survivors ordered by known-arg-bit count ascending: a dominator A of B has
    # akc <= bkc, so once akc > bkc the rest (also larger) cannot dominate B.
    order = sorted((i for i in range(n) if keep[i]), key=lambda i: feats[i][4])
    for B in order:
        bZ, bO, boZ, boO, bkc = feats[B]
        for A in order:
            if A == B:
                continue
            aZ, aO, _, _, akc = feats[A]
            if akc > bkc:
                break
            # A's arg constraints subset of B's (A more general / agrees)?
            if (aZ & ~bZ) or (aO & ~bO):
                continue
            # A's output covers B's (B's known output bits subset of A's)?
            _, _, aoZ, aoO, _ = feats[A]
            if (boZ & ~aoZ) or (boO & ~aoO):
                continue
            keep[B] = False
            break
    return keep


def main() -> None:
    ap = ArgumentParser()
    ap.add_argument("--tsv-dir", type=Path, required=True)
    ap.add_argument("--out-dir", type=Path, required=True)
    ap.add_argument(
        "--drop-top", action=BooleanOptionalAction, default=True,
        help="Drop rows whose ideal output is top (all '?'). Use "
             "--no-drop-top to keep them.",
    )
    ap.add_argument(
        "--prune-subsumed", action=BooleanOptionalAction, default=True,
        help="Drop rows subsumed by a more-general row that already covers "
             "their output (minimal-cover pruning). Use --no-prune-subsumed "
             "to disable.",
    )
    ap.add_argument(
        "--max-rows-per-bw", type=int, default=0, metavar="N",
        help="Cap the number of kept rows per bitwidth: if a bitwidth has more "
             "than N surviving rows, keep only the first N (in original "
             "order). Default 0 (no cap); a common value is 200.",
    )
    args = ap.parse_args()

    tsv_files = sorted(args.tsv_dir.glob("*.tsv"))
    if not tsv_files:
        sys.exit(f"No TSVs found in {args.tsv_dir}")
    args.out_dir.mkdir(parents=True, exist_ok=True)
    name_width = max(len(p.name) for p in tsv_files)

    n_seen = n_kept = n_top = n_bottom = n_subsumed = n_capped = n_empty = 0
    for path in tsv_files:
        with path.open() as f:
            data = EnumData.read_tsv(f)
        frame = data.enumdata

        # The ternary mask / meet-subset pruning is KnownBits-specific; ConstRange
        # domains use [lb, ub] intervals and need different semantics (not yet).
        if data.metadata.domain != AbstractDomain.KnownBits:
            raise NotImplementedError(
                f"{path.name}: {data.metadata.domain} not supported yet"
            )
        if "ideal" not in frame.columns:
            sys.exit(f"{path.name}: no 'ideal' column; run max-precise first")

        arg_cols = [f"arg_{a}" for a in range(data.metadata.arity)]

        # Drop top/bottom rows and bucket survivors by bitwidth (rows of
        # different widths never match the same query, so pruning is per-width).
        # Each entry keeps its original row position to slice the frame later.
        groups: dict[int, list[tuple[int, tuple[str, ...], str]]] = defaultdict(list)
        for pos, (_, row) in enumerate(frame.iterrows()):
            argvals = tuple(str(row[c]) for c in arg_cols)
            ideal = str(row["ideal"])
            n_seen += 1
            if any(v == "(bottom)" for v in argvals + (ideal,)):
                n_bottom += 1
            elif args.drop_top and is_top(ideal):
                n_top += 1
            else:
                groups[int(row["bw"])].append((pos, argvals, ideal))

        # Per bitwidth: subsumption-prune, then cap, collecting kept positions.
        cap = args.max_rows_per_bw
        keep_positions: list[int] = []
        kept_by_bw: dict[int, int] = {}
        for bw, grp in groups.items():
            flags = (
                prune_group([(a, d) for _, a, d in grp])
                if args.prune_subsumed
                else [True] * len(grp)
            )
            kept = [pos for (pos, _, _), keep in zip(grp, flags) if keep]
            n_subsumed += len(grp) - len(kept)
            if cap and len(kept) > cap:
                n_capped += len(kept) - cap
                kept = kept[:cap]
            kept_by_bw[bw] = len(kept)
            keep_positions.extend(kept)
            n_kept += len(kept)

        pattern_kept = len(keep_positions)
        top_bw, top_bw_rows = max(
            kept_by_bw.items(), key=lambda kv: kv[1], default=("-", 0)
        )
        print(f"{path.name:<{name_width}}  rows: {len(frame):>6}   "
              f"kept: {pattern_kept:>5}   largest: {top_bw_rows:>5} (bw={top_bw})")

        # Nothing survived -> no usable lookup rows, skip writing entirely.
        if pattern_kept == 0:
            n_empty += 1
            continue

        kept_frame = frame.iloc[sorted(keep_positions)].reset_index(drop=True)
        EnumData(data.metadata, kept_frame).write_tsv(args.out_dir / path.name)

    print(f"Optimized {len(tsv_files) - n_empty} TSVs -> {args.out_dir} "
          f"({n_empty} empty patterns skipped)")
    print(f"Rows seen: {n_seen}  kept: {n_kept}  dropped: {n_seen - n_kept} "
          f"(top: {n_top}, bottom: {n_bottom}, subsumed: {n_subsumed}, "
          f"capped: {n_capped})")


if __name__ == "__main__":
    main()
