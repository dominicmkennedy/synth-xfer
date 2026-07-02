from argparse import ArgumentParser
import csv
from dataclasses import dataclass
from pathlib import Path
import sys

from xdsl.ir import Attribute

from synth_xfer._util.domain import AbstractDomain
from synth_xfer._util.pattern import is_root_preserving_cut_projection, refine_pattern
from synth_xfer._util.pattern_dsl import (
    ArgRef,
    NodeRef,
    PatternDag,
    PatternNode,
    PatternRef,
)


@dataclass(frozen=True, slots=True)
class _EnumState:
    kept: frozenset[int]
    cut: frozenset[int]


@dataclass(frozen=True, slots=True)
class PatternStats:
    unique: int
    weighted: int


@dataclass(frozen=True, slots=True)
class ProcessResult:
    non_enumerated: dict[str, int]
    split_dropped: dict[str, int]
    input_stats: PatternStats
    droppable: PatternStats
    producer_cut: PatternStats
    split: PatternStats
    unchanged_incomplete: PatternStats


@dataclass(slots=True)
class PatternCache:
    dags: dict[str, PatternDag]

    def dag_of(self, pattern_text: str) -> PatternDag:
        dag = self.dags.get(pattern_text)
        if dag is None:
            dag = PatternDag(pattern_text)
            self.dags[pattern_text] = dag
        return dag


def _new_cache() -> PatternCache:
    return PatternCache({})


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


def _max_insert(counts: dict[str, int], pattern: PatternDag, count: int) -> None:
    pattern_text = str(pattern)
    counts[pattern_text] = max(counts.get(pattern_text, 0), count)


def _stats_from_counts(counts: dict[str, int]) -> PatternStats:
    return PatternStats(len(counts), sum(counts.values()))


def process_pattern_counts(
    input_counts: dict[str, int],
    domain: AbstractDomain,
    cache: PatternCache,
) -> ProcessResult:
    non_enumerated: dict[str, int] = {}
    split_dropped: dict[str, int] = {}
    droppable: dict[str, int] = {}
    producer_cut: dict[str, int] = {}
    split: dict[str, int] = {}
    unchanged_incomplete: dict[str, int] = {}

    for source_text, source_count in input_counts.items():
        source_dag = cache.dag_of(source_text)
        refinement = refine_pattern(source_dag, domain)

        match refinement.kind:
            case "droppable":
                droppable[source_text] = source_count
            case "unchanged_incomplete":
                unchanged_incomplete[source_text] = source_count
                _max_insert(non_enumerated, source_dag, source_count)
            case "producer_cut":
                if len(refinement.kept) != 1:
                    raise AssertionError(
                        f"producer_cut produced {len(refinement.kept)} leaves: "
                        f"{source_dag}"
                    )
                refined = refinement.kept[0]
                if not is_root_preserving_cut_projection(source_dag, refined):
                    raise AssertionError(
                        "producer_cut was not root-preserving:\n"
                        f"  source:  {source_dag}\n"
                        f"  refined: {refined}"
                    )
                producer_cut[source_text] = source_count
                _max_insert(non_enumerated, refined, source_count)
            case "split":
                if not refinement.kept:
                    raise AssertionError(f"split produced no kept leaves: {source_dag}")
                split[source_text] = source_count
                for leaf in refinement.kept:
                    leaf_text = str(leaf)
                    if leaf_text in input_counts:
                        _max_insert(
                            non_enumerated,
                            leaf,
                            max(source_count, input_counts[leaf_text]),
                        )
                    else:
                        _max_insert(split_dropped, leaf, source_count)
            case _:
                raise AssertionError(
                    "unexpected refinement kind:\n"
                    f"  kind:   {refinement.kind}\n"
                    f"  source: {source_dag}\n"
                    f"  kept:   {tuple(str(leaf) for leaf in refinement.kept)}\n"
                    f"  drop:   {tuple(str(leaf) for leaf in refinement.dropped)}"
                )

    return ProcessResult(
        non_enumerated,
        split_dropped,
        _stats_from_counts(input_counts),
        _stats_from_counts(droppable),
        _stats_from_counts(producer_cut),
        _stats_from_counts(split),
        _stats_from_counts(unchanged_incomplete),
    )


def _build_subdag(dag: PatternDag, kept: frozenset[int]) -> PatternDag:
    """Materialise a sub-DAG from global keep/cut decisions.

    Each original NodeRef maps to exactly one rebuilt NodeRef when kept, or one
    cut ArgRef when not kept. This preserves shared SSA identity.
    """
    arg_types: list[Attribute] = []
    arg_of: dict[PatternRef, ArgRef] = {}
    node_of: dict[NodeRef, NodeRef] = {}
    nodes: list[PatternNode] = []

    def cut_arg(orig: PatternRef) -> ArgRef:
        existing = arg_of.get(orig)
        if existing is not None:
            return existing
        ref = ArgRef(len(arg_types))
        arg_types.append(_result_type(dag, orig))
        arg_of[orig] = ref
        return ref

    def build(ref: PatternRef) -> PatternRef:
        if isinstance(ref, ArgRef):
            return cut_arg(ref)
        if ref.index not in kept:
            return cut_arg(ref)

        existing = node_of.get(ref)
        if existing is not None:
            return existing

        node = dag.nodes[ref.index]
        operands = tuple(build(operand) for operand in node.operands)
        lowered = NodeRef(len(nodes))
        node_of[ref] = lowered
        nodes.append(PatternNode(node.op, operands))
        return lowered

    root = build(dag.result)
    assert isinstance(root, NodeRef)
    return PatternDag.from_parts(tuple(arg_types), tuple(nodes), root)


def _enumerate_states(dag: PatternDag, max_size: int) -> set[_EnumState]:
    root = dag.result.index
    initial = _EnumState(frozenset((root,)), frozenset())

    def expand_operands(
        operands: tuple[PatternRef, ...],
        state: _EnumState,
    ) -> set[_EnumState]:
        states = {state}
        for operand in operands:
            next_states: set[_EnumState] = set()
            for current in states:
                next_states.update(expand_ref(operand, current))
            states = next_states
        return states

    def expand_ref(ref: PatternRef, state: _EnumState) -> set[_EnumState]:
        if isinstance(ref, ArgRef):
            return {state}

        index = ref.index
        if index in state.kept:
            return expand_operands(dag.nodes[index].operands, state)
        if index in state.cut:
            return {state}

        states = {_EnumState(state.kept, state.cut | frozenset((index,)))}
        if len(state.kept) < max_size:
            kept_state = _EnumState(state.kept | frozenset((index,)), state.cut)
            states.update(expand_operands(dag.nodes[index].operands, kept_state))
        return states

    return expand_operands(dag.nodes[root].operands, initial)


def subdags_of(dag: PatternDag, min_size: int, max_size: int) -> list[PatternDag]:
    result: list[PatternDag] = []
    seen: set[str] = set()

    for state in _enumerate_states(dag, max_size):
        if not min_size <= len(state.kept) <= max_size:
            continue
        subdag = _build_subdag(dag, state.kept)
        text = str(subdag)
        if text in seen:
            continue
        seen.add(text)
        result.append(subdag)

    result.sort(key=str)
    return result


def enumerate_output_pool(
    input_counts: dict[str, int],
    min_size: int,
    max_size: int,
    cache: PatternCache,
) -> dict[str, int]:
    enumerated_in: dict[str, int] = {}

    for pattern_text, count in input_counts.items():
        for subdag in subdags_of(cache.dag_of(pattern_text), min_size, max_size):
            sub_text = str(subdag)
            if sub_text in input_counts:
                _max_insert(enumerated_in, subdag, max(count, input_counts[sub_text]))

    return enumerated_in


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


def _format_stats(label: str, stats: PatternStats, denominator: PatternStats) -> str:
    unique_percent = (
        0.0 if denominator.unique == 0 else 100.0 * stats.unique / denominator.unique
    )
    weighted_percent = (
        0.0
        if denominator.weighted == 0
        else 100.0 * stats.weighted / denominator.weighted
    )
    return (
        f"  {label}: {stats.unique} unique ({unique_percent:.2f}%), "
        f"{stats.weighted} weighted ({weighted_percent:.2f}%)"
    )


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
        help="when --enumerate is used, drop subpatterns with fewer than this many operation nodes",
    )
    p.add_argument(
        "--max-size",
        type=int,
        default=6,
        help="when --enumerate is used, only enumerate subpatterns with at most this many operation nodes",
    )
    p.add_argument("--top", type=int, default=None, help="keep only the top N rows")
    p.add_argument(
        "--enumerate",
        action="store_true",
        dest="enumerate",
        help="also generate enumerated_in.tsv",
    )
    p.add_argument(
        "--split-dropped-output",
        type=Path,
        default=None,
        help="write split-refined patterns dropped because they were not in the input",
    )
    args = p.parse_args()

    sys.setrecursionlimit(100000)
    domain = AbstractDomain[args.domain]

    input_counts = read_pattern_counts(args.input)
    cache = _new_cache()
    result = process_pattern_counts(input_counts, domain, cache)

    output_written = write_pattern_counts(args.output, result.non_enumerated, args.top)
    split_dropped_written = None
    if args.split_dropped_output is not None:
        split_dropped_written = write_pattern_counts(
            args.split_dropped_output, result.split_dropped, args.top
        )

    print("Stats:")
    print(
        f"  Canonical inputs: {result.input_stats.unique} unique, "
        f"{result.input_stats.weighted} weighted"
    )
    print(_format_stats("Fully complete / dropped", result.droppable, result.input_stats))
    print(_format_stats("Producer-cut refined", result.producer_cut, result.input_stats))
    print(_format_stats("Split refined", result.split, result.input_stats))
    print(
        _format_stats(
            "Unchanged incomplete",
            result.unchanged_incomplete,
            result.input_stats,
        )
    )
    print(f"  Wrote: {args.output} ({output_written} rows)")
    if split_dropped_written is not None:
        print(f"  Wrote: {args.split_dropped_output} ({split_dropped_written} rows)")

    if args.enumerate:
        enumerated_in = enumerate_output_pool(
            result.non_enumerated,
            args.min_size,
            args.max_size,
            cache,
        )
        enumerated_in_path = Path("enumerated_in.tsv")
        enumerated_in_written = write_pattern_counts(
            enumerated_in_path, enumerated_in, args.top
        )
        denominator = _stats_from_counts(result.non_enumerated)
        print("Enumeration Stats:")
        print(
            _format_stats(
                "Enumerated in non_enumerated",
                _stats_from_counts(enumerated_in),
                denominator,
            )
        )
        print(f"  Wrote: {enumerated_in_path} ({enumerated_in_written} rows)")


if __name__ == "__main__":
    main()
