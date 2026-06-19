from argparse import ArgumentParser
from collections import Counter
from collections.abc import Callable, Iterator
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


def read_pattern_counts(path: Path) -> dict[str, int]:
    counts: dict[str, int] = {}

    with path.open(newline="") as f:
        reader = csv.DictReader(f, delimiter="\t")

        for row in reader:
            pattern = str(PatternDag(row["pattern"]))
            count = int(row["count"])
            counts[pattern] = counts.get(pattern, 0) + count

    return counts


def _cut_projection_texts(dag: PatternDag) -> set[str]:
    projections: set[str] = set()
    memo: dict[tuple[PatternRef, int], list[tuple[int, Subpattern]]] = {}
    for _, sub in _subs(dag, dag.result, len(dag.nodes), memo):
        if isinstance(sub, KeepSubpattern):
            projections.add(str(_build_subdag(dag, sub)))
    return projections


def _accept_refinement(
    source_text: str,
    refined_text: str,
    input_counts: dict[str, int],
    projection_cache: dict[str, set[str]],
    dag_of: Callable[[str], PatternDag],
) -> bool:
    if refined_text in input_counts:
        return True
    if refined_text == source_text:
        return False

    projections = projection_cache.get(source_text)
    if projections is None:
        projections = _cut_projection_texts(dag_of(source_text))
        projection_cache[source_text] = projections
    return refined_text in projections


def process_pattern_counts(
    input_counts: dict[str, int],
    domain: AbstractDomain,
    min_size: int,
    max_size: int,
) -> tuple[dict[str, int], int]:
    dag_cache: dict[str, PatternDag] = {}
    refine_cache: dict[str, tuple[str, ...]] = {}

    def dag_of(pattern_text: str) -> PatternDag:
        dag = dag_cache.get(pattern_text)
        if dag is None:
            dag = PatternDag(pattern_text)
            dag_cache[pattern_text] = dag
        return dag

    def refined_texts(pattern_text: str) -> tuple[str, ...]:
        refined = refine_cache.get(pattern_text)
        if refined is None:
            refined = tuple(
                str(pattern) for pattern in refine_pattern(dag_of(pattern_text), domain)
            )
            refine_cache[pattern_text] = refined
        return refined

    subpattern_counts: Counter[str] = Counter()
    source_subpatterns: dict[str, set[str]] = {}
    for source_text, source_count in input_counts.items():
        source_dag = dag_of(source_text)
        source_counts: Counter[str] = Counter()
        for subdag in subdags_of(source_dag, min_size, max_size):
            source_counts[str(subdag)] += source_count
        subpattern_counts.update(source_counts)
        source_subpatterns[source_text] = set(source_counts)

    refined_counts: dict[str, int] = {}
    accepted_by_subpattern: dict[str, tuple[str, ...]] = {}
    projection_cache: dict[str, set[str]] = {}

    for pattern_text, count in subpattern_counts.items():
        accepted: list[str] = []
        for refined_text in refined_texts(pattern_text):
            if not _accept_refinement(
                pattern_text,
                refined_text,
                input_counts,
                projection_cache,
                dag_of,
            ):
                continue

            refined_count = (
                max(count, input_counts[refined_text])
                if refined_text in input_counts
                else count
            )
            refined_counts[refined_text] = max(
                refined_counts.get(refined_text, 0),
                refined_count,
            )
            accepted.append(refined_text)
        accepted_by_subpattern[pattern_text] = tuple(accepted)

    dropped_patterns = sum(
        1
        for subpatterns in source_subpatterns.values()
        if not any(accepted_by_subpattern.get(pattern) for pattern in subpatterns)
    )

    return refined_counts, dropped_patterns


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

    input_counts = read_pattern_counts(args.input)
    refined_counts, dropped_patterns = process_pattern_counts(
        input_counts,
        domain,
        args.min_size,
        args.max_size,
    )
    written = write_pattern_counts(args.output, refined_counts, args.top)
    unique_inputs = len(input_counts)
    percent_dropped = (
        0.0 if unique_inputs == 0 else 100.0 * dropped_patterns / unique_inputs
    )
    percent_original = 0.0 if unique_inputs == 0 else 100.0 * written / unique_inputs

    print("Stats:")
    print(f"  Number of Unique inputs: {unique_inputs}")
    print(f"  Number of Dropped patterns: {dropped_patterns}")
    print(f"  Percent dropped by refinement: {percent_dropped:.2f}%")
    print(f"  Number of patterns after refinement: {written}")
    print(f"  Percent of original after refinement: {percent_original:.2f}%")
    print(f"  Wrote: {args.output}")


if __name__ == "__main__":
    main()
