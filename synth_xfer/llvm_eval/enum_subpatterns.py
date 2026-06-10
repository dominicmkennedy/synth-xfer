"""Enumerate same-root sub-patterns from the aggregated slice-kb DAG file.

Input: the ``dags.tsv`` produced by ``run_opt_benchmark --slice-kb`` -- one row
per distinct full DAG (``count``, ``size``, ``pattern``). Each ``pattern`` is
reconstructed into a :class:`PatternDag` (the hash-consing parser restores the
original interior + leaf sharing). For every DAG we enumerate every *same-root*
sub-pattern: the root node is always kept, and each descendant is independently
either kept or pruned back to a boundary leaf. Every sub-pattern is itself a
PatternDag; we canonicalize it via ``str(...)`` (commutative operands ordered
canonically; boundary leaves numbered by shared-value identity, so a value
reused in two cut points becomes one ``argN``) and sum the parent DAG's
``count`` into that pattern.

Output (``--out``): ``count``, ``size``, ``pattern``, sorted by descending count
and optionally truncated to ``--top N``. ``size`` is the sub-pattern's operation
(non-boundary) node count; only sub-patterns with size in ``[--min-size,
--max-size]`` (default 2..4) are emitted, the upper bound applied *during*
generation so enumeration stays small however large the source DAG is.
"""

import argparse
from collections import Counter
import sys

from xdsl.ir import Attribute

from synth_xfer._util.pattern_dsl import (
    ArgRef,
    NodeRef,
    PatternDag,
    PatternNode,
    PatternRef,
)

sys.setrecursionlimit(100000)


def _result_type(dag: PatternDag, ref: PatternRef) -> Attribute:
    """Result type of a ref within ``dag`` (used to type a cut boundary)."""
    if isinstance(ref, ArgRef):
        return dag.arg_types[ref.index]
    return dag.nodes[ref.index].op.spec.result_type


# A sub-structure is either ('cut', ref) -- prune to a boundary, shared by ref
# identity -- or ('keep', node, [child_subs]) -- retain this op. "Size" is the
# operation (non-boundary) node count; we never materialise sub-structures with
# more than `cap` ops, pruning during generation.


def _subs(dag: PatternDag, ref: PatternRef, cap: int, memo: dict) -> list:
    """List of (n_ops, sub) for sub-structures rooted at ``ref`` with
    ``n_ops <= cap``. Always includes the cut option. Memoised on (ref, cap)."""
    key = (ref, cap)
    if key in memo:
        return memo[key]
    out: list = [(0, ("cut", ref))]
    if isinstance(ref, NodeRef) and cap >= 1:
        node = dag.nodes[ref.index]
        child_opts = [_subs(dag, op, cap - 1, memo) for op in node.operands]

        def combos(idx: int, used: int):
            if idx == len(child_opts):
                yield []
                return
            for s, sub in child_opts[idx]:
                if used + s <= cap - 1:
                    for rest in combos(idx + 1, used + s):
                        rest.append((s, sub))
                        yield rest

        for combo in combos(0, 0):
            combo.reverse()
            total = 1 + sum(s for s, _ in combo)
            out.append((total, ("keep", node, [sub for _, sub in combo])))
    memo[key] = out
    return out


def _build_subdag(dag: PatternDag, sub) -> PatternDag:
    """Materialise a sub-structure as a PatternDag. Cut points referring to the
    same original ref share one ArgRef (shared-value identity); kept nodes each
    get a fresh NodeRef (sharing is unfolded, matching the rendered pattern)."""
    arg_types: list = []
    arg_of: dict[PatternRef, ArgRef] = {}
    nodes: list[PatternNode] = []

    def build(s) -> PatternRef:
        if s[0] == "cut":
            orig = s[1]
            existing = arg_of.get(orig)
            if existing is not None:
                return existing
            ref = ArgRef(len(arg_types))
            arg_types.append(_result_type(dag, orig))
            arg_of[orig] = ref
            return ref
        _, node, children = s
        operands = tuple(build(c) for c in children)
        nr = NodeRef(len(nodes))
        nodes.append(PatternNode(node.op, operands))
        return nr

    root = build(sub)
    assert isinstance(root, NodeRef)
    return PatternDag.from_parts(tuple(arg_types), tuple(nodes), root)


def subdags_of(dag: PatternDag, min_size: int, max_size: int):
    """Yield every same-root sub-pattern of ``dag`` as a PatternDag, with
    operation-node count in ``[min_size, max_size]``."""
    memo: dict = {}
    for size, sub in _subs(dag, dag.result, max_size, memo):
        if sub[0] == "keep" and size >= min_size:
            yield _build_subdag(dag, sub)


def write_tsv(path, counts: Counter, sizes: dict, top: int | None = None) -> int:
    """Write count/size/pattern rows sorted by descending count, optionally
    truncated to top N. Leading fixed columns are padded to align as plain text;
    ``pattern`` (variable-width) stays last. Returns the number of rows written."""
    ranked = sorted(counts.items(), key=lambda kv: (-kv[1], kv[0]))
    if top is not None:
        ranked = ranked[:top]

    headers = ["count", "size"]
    rows = [(str(n), str(sizes[pat]), pat) for pat, n in ranked]
    widths = [
        max(len(h), *(len(r[i]) for r in rows)) if rows else len(h)
        for i, h in enumerate(headers)
    ]

    def fmt(fields):
        lead = "  ".join(f.ljust(w) for f, w in zip(fields, widths))
        return f"{lead}  {fields[-1]}\n"

    with open(path, "w") as o:
        o.write(fmt(headers + ["pattern"]))
        for r in rows:
            o.write(fmt(r))
    return len(ranked)


def main() -> None:
    ap = argparse.ArgumentParser(
        description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter
    )
    ap.add_argument(
        "in_dags",
        nargs="?",
        default="dags.tsv",
        help="aggregated DAG TSV from run_opt_benchmark --slice-kb (default dags.tsv)",
    )
    ap.add_argument(
        "--out", default="subdags_aggregated.tsv", help="output TSV: count, size, pattern"
    )
    ap.add_argument(
        "--min-size",
        type=int,
        default=2,
        help="drop sub-patterns with fewer than this many operation nodes (default 2)",
    )
    ap.add_argument(
        "--max-size",
        type=int,
        default=4,
        help="only enumerate sub-patterns with at most this many operation nodes "
        "(default 4); bounds enumeration at the source",
    )
    ap.add_argument(
        "--top",
        type=int,
        default=None,
        help="keep only the top N rows by count (default: all)",
    )
    args = ap.parse_args()

    if args.max_size < args.min_size:
        sys.exit(f"error: --max-size ({args.max_size}) < --min-size ({args.min_size})")

    counts: Counter = Counter()
    sizes: dict[str, int] = {}
    n_dags = 0
    bad = 0

    with open(args.in_dags, "r", errors="replace") as f:
        header = f.readline().rstrip("\n").split("\t")
        if "pattern" not in header:
            sys.exit(
                f"error: {args.in_dags} has no 'pattern' column -- regenerate it "
                f"with run_opt_benchmark --slice-kb (header was: {header!r})"
            )
        pat_col = header.index("pattern")
        for line in f:
            cols = line.rstrip("\n").split("\t")
            if len(cols) <= pat_col:
                bad += 1
                continue
            try:
                cnt = int(cols[0])
                dag = PatternDag(cols[pat_col])
            except ValueError:
                bad += 1
                continue
            n_dags += 1
            for sub in subdags_of(dag, args.min_size, args.max_size):
                pat = str(sub)
                counts[pat] += cnt
                sizes[pat] = len(sub.nodes)

    n_written = write_tsv(args.out, counts, sizes, args.top)
    print(f"read {n_dags} DAGs from {args.in_dags}")
    if bad:
        print(f"skipped {bad} malformed row(s)")
    print(
        f"wrote {args.out} ({n_written} of {len(counts)} distinct sub-patterns, "
        f"size {args.min_size}..{args.max_size}, ranked by count)"
    )


if __name__ == "__main__":
    main()
