from argparse import ArgumentParser
from collections import Counter
from collections.abc import Iterator
import csv
from dataclasses import dataclass
from pathlib import Path
import sys

from xdsl.ir import Attribute

from synth_xfer._util.domain import AbstractDomain
from synth_xfer._util.pattern import refine_pattern
from synth_xfer._util.pattern_dsl import (
    ArgRef,
    NodeRef,
    PatternDag,
    PatternNode,
    PatternRef,
)


@dataclass(frozen=True, slots=True)
class LoadedPatterns:
    counts: dict[str, int]
    rows: int
    canonical_collisions: int
    canonical_collision_count_delta: int


@dataclass(frozen=True, slots=True)
class RefineStats:
    total_refinement_results: int
    changed_refinement_results: int
    unchanged_refinement_results: int
    sources_with_changed_refinements: int
    sources_with_no_output: int
    refined_patterns_already_in_input: int
    refined_patterns_added: int


@dataclass(frozen=True, slots=True)
class CutSubpattern:
    ref: PatternRef


@dataclass(frozen=True, slots=True)
class KeepSubpattern:
    node: PatternNode
    children: tuple["Subpattern", ...]


Subpattern = CutSubpattern | KeepSubpattern


def _result_type(dag: PatternDag, ref: PatternRef) -> Attribute:
    if isinstance(ref, ArgRef):
        return dag.arg_types[ref.index]
    return dag.nodes[ref.index].op.spec.result_type


def read_pattern_counts(path: Path) -> LoadedPatterns:
    counts: dict[str, int] = {}
    rows = 0
    canonical_collisions = 0
    canonical_collision_count_delta = 0

    with path.open(newline="") as f:
        reader = csv.DictReader(f, delimiter="\t")

        for row in reader:
            pattern = str(PatternDag(row["pattern"]))
            count = int(row["count"])
            rows += 1
            if pattern in counts:
                canonical_collisions += 1
                canonical_collision_count_delta += count
                counts[pattern] += count
            else:
                counts[pattern] = count

    return LoadedPatterns(
        counts=counts,
        rows=rows,
        canonical_collisions=canonical_collisions,
        canonical_collision_count_delta=canonical_collision_count_delta,
    )


def enumerate_subpattern_counts(
    dag_counts: dict[str, int],
    min_size: int,
    max_size: int,
) -> Counter[str]:
    counts: Counter[str] = Counter()
    for pattern, count in dag_counts.items():
        dag = PatternDag(pattern)
        for subdag in subdags_of(dag, min_size, max_size):
            counts[str(subdag)] += count
    return counts


def refine_pattern_counts(
    pattern_counts: dict[str, int] | Counter[str],
    domain: AbstractDomain,
) -> tuple[dict[str, int], RefineStats]:
    refined_counts: dict[str, int] = {}
    added_patterns: set[str] = set()
    existing_refined_patterns: set[str] = set()
    total_refinement_results = 0
    unchanged_refinement_results = 0
    changed_refinement_results = 0
    sources_with_changed_refinements = 0
    sources_with_no_output = 0

    for pattern_text, count in pattern_counts.items():
        pattern = PatternDag(pattern_text)
        refined_patterns = refine_pattern(pattern, domain)
        if not refined_patterns:
            sources_with_no_output += 1

        source_changed = False
        for refined_pattern in refined_patterns:
            total_refinement_results += 1
            refined_text = str(refined_pattern)
            if refined_text == pattern_text:
                unchanged_refinement_results += 1
            else:
                changed_refinement_results += 1
                source_changed = True

            if refined_text not in pattern_counts:
                refined_count = count
                added_patterns.add(refined_text)
            else:
                existing_refined_patterns.add(refined_text)
                refined_count = max(count, pattern_counts[refined_text])

            refined_counts[refined_text] = max(
                refined_counts.get(refined_text, 0),
                refined_count,
            )

        if source_changed:
            sources_with_changed_refinements += 1

    return refined_counts, RefineStats(
        total_refinement_results=total_refinement_results,
        changed_refinement_results=changed_refinement_results,
        unchanged_refinement_results=unchanged_refinement_results,
        sources_with_changed_refinements=sources_with_changed_refinements,
        sources_with_no_output=sources_with_no_output,
        refined_patterns_already_in_input=len(existing_refined_patterns),
        refined_patterns_added=len(added_patterns),
    )


def _build_subdag(dag: PatternDag, sub: Subpattern) -> PatternDag:
    """Materialise a sub-structure as a PatternDag. Cut points referring to the
    same original ref share one ArgRef (shared-value identity); kept nodes each
    get a fresh NodeRef (sharing is unfolded, matching the rendered pattern)."""
    arg_types: list[Attribute] = []
    arg_of: dict[PatternRef, ArgRef] = {}
    nodes: list[PatternNode] = []

    def build(s: Subpattern) -> PatternRef:
        if isinstance(s, CutSubpattern):
            orig = s.ref
            existing = arg_of.get(orig)
            if existing is not None:
                return existing
            ref = ArgRef(len(arg_types))
            arg_types.append(_result_type(dag, orig))
            arg_of[orig] = ref
            return ref

        operands = tuple(build(c) for c in s.children)
        nr = NodeRef(len(nodes))
        nodes.append(PatternNode(s.node.op, operands))
        return nr

    root = build(sub)
    assert isinstance(root, NodeRef)
    return PatternDag.from_parts(tuple(arg_types), tuple(nodes), root)


def _subs(
    dag: PatternDag,
    ref: PatternRef,
    cap: int,
    memo: dict[tuple[PatternRef, int], list[tuple[int, Subpattern]]],
) -> list[tuple[int, Subpattern]]:
    """List of (n_ops, sub) for sub-structures rooted at ``ref`` with
    ``n_ops <= cap``. Always includes the cut option. Memoised on (ref, cap)."""
    key = (ref, cap)
    if key in memo:
        return memo[key]
    out: list[tuple[int, Subpattern]] = [(0, CutSubpattern(ref))]
    if isinstance(ref, NodeRef) and cap >= 1:
        node = dag.nodes[ref.index]
        child_opts = [_subs(dag, op, cap - 1, memo) for op in node.operands]

        def combos(idx: int, used: int) -> Iterator[list[tuple[int, Subpattern]]]:
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
            out.append((total, KeepSubpattern(node, tuple(sub for _, sub in combo))))
    memo[key] = out
    return out


def subdags_of(dag: PatternDag, min_size: int, max_size: int) -> list[PatternDag]:
    result: list[PatternDag] = []
    memo: dict[tuple[PatternRef, int], list[tuple[int, Subpattern]]] = {}
    for size, sub in _subs(dag, dag.result, max_size, memo):
        if isinstance(sub, KeepSubpattern) and size >= min_size:
            result.append(_build_subdag(dag, sub))
    return result


def write_pattern_counts(
    path: Path,
    counts: dict[str, int],
    top: int | None,
) -> int:
    rows = sorted(counts.items(), key=lambda item: (-item[1], item[0]))
    if top is not None:
        rows = rows[:top]

    with path.open("w", newline="") as f:
        writer = csv.DictWriter(
            f,
            fieldnames=["count", "pattern"],
            delimiter="\t",
            lineterminator="\n",
        )
        writer.writeheader()
        for pattern, count in rows:
            writer.writerow({"count": count, "pattern": pattern})

    return len(rows)


def main() -> None:
    p = ArgumentParser()
    p.add_argument("-i", "--input", type=Path, required=True)
    p.add_argument("-o", "--output", type=Path, required=True)
    p.add_argument(
        "-d",
        "--domain",
        type=str,
        choices=[str(domain) for domain in AbstractDomain],
        required=True,
    )
    p.add_argument(
        "--min-size",
        type=int,
        default=2,
        help="drop subpatterns with fewer than this many operation nodes",
    )
    p.add_argument(
        "--max-size",
        type=int,
        default=6,
        help="only enumerate subpatterns with at most this many operation nodes",
    )
    p.add_argument("--top", type=int, default=None, help="keep only the top N rows")
    args = p.parse_args()

    sys.setrecursionlimit(100000)
    domain = AbstractDomain[args.domain]

    loaded = read_pattern_counts(args.input)
    subpattern_counts = enumerate_subpattern_counts(
        loaded.counts,
        args.min_size,
        args.max_size,
    )
    refined_counts, refine_stats = refine_pattern_counts(subpattern_counts, domain)
    written = write_pattern_counts(args.output, refined_counts, args.top)

    print("Stats:")
    print(f"  Input DAG rows: {loaded.rows}")
    print(f"  Canonical input DAGs: {len(loaded.counts)}")
    print(f"  Canonical input collisions: {loaded.canonical_collisions}")
    print(
        "  Counts added by canonical input collisions: "
        f"{loaded.canonical_collision_count_delta}"
    )
    print(f"  Enumerated subpatterns: {len(subpattern_counts)}")
    print(f"  Refined output patterns: {len(refined_counts)}")
    print(f"  Output rows written: {written}")
    print(f"  Total refinement results: {refine_stats.total_refinement_results}")
    print(f"  Changed refinement results: {refine_stats.changed_refinement_results}")
    print(f"  Unchanged refinement results: {refine_stats.unchanged_refinement_results}")
    print(
        "  Sources with changed refinements: "
        f"{refine_stats.sources_with_changed_refinements}"
    )
    print(f"  Sources dropped by refinement: {refine_stats.sources_with_no_output}")
    print(
        "  Refined patterns already in input: "
        f"{refine_stats.refined_patterns_already_in_input}"
    )
    print(f"  Refined patterns added: {refine_stats.refined_patterns_added}")
    print(f"  Wrote: {args.output}")


if __name__ == "__main__":
    main()
