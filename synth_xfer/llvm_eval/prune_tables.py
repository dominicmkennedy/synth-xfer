from argparse import ArgumentParser, BooleanOptionalAction
from collections import defaultdict
from dataclasses import dataclass
from io import StringIO
from pathlib import Path
from statistics import mean, median, stdev
import sys
from typing import Any, Callable, Hashable, Iterable, cast

from xdsl.ir import Attribute

from synth_xfer._util.domain import AbstractDomain, get_bvs_from_abst, is_top
from synth_xfer._util.max_precise import _concrete_width, compute_max_precise
from synth_xfer._util.parse_mlir import HelperFuncs
from synth_xfer._util.pattern_dsl import (
    ArgRef,
    NodeRef,
    PatternDag,
    PatternNode,
    PatternOp,
    PatternRef,
    canonicalize_pattern_operands,
)
from synth_xfer._util.smt_solver import SolverKind
from synth_xfer._util.tsv import EnumData

Row = tuple[tuple[str, ...], str]
Interval = tuple[int, int]
AbsValue = Interval | None
KBFeature = tuple[int, int, AbsValue, int]
CRFeature = tuple[tuple[Interval, ...], AbsValue]
NodeEvalCache = dict[tuple[AbstractDomain, PatternOp, int, tuple[str, ...]], str]
RowValueCache = dict[tuple[int, tuple[str, ...]], dict[PatternRef, str]]
_MAX_ARGUMENT_SPECIALIZATION_SPLITS = 14


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
    timeout: int
    timeout_count: int
    argument_specialized: int
    argument_specialized_count: int
    subdag_specialized: int
    subdag_specialized_count: int
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
            timeout=0,
            timeout_count=0,
            argument_specialized=0,
            argument_specialized_count=0,
            subdag_specialized=0,
            subdag_specialized_count=0,
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
            timeout=self.timeout + other.timeout,
            timeout_count=self.timeout_count + other.timeout_count,
            argument_specialized=(self.argument_specialized + other.argument_specialized),
            argument_specialized_count=(
                self.argument_specialized_count + other.argument_specialized_count
            ),
            subdag_specialized=self.subdag_specialized + other.subdag_specialized,
            subdag_specialized_count=(
                self.subdag_specialized_count + other.subdag_specialized_count
            ),
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


@dataclass(frozen=True)
class Table:
    path: Path
    data: EnumData
    pattern_id: str
    domain: AbstractDomain
    row_ideals: dict[tuple[int, tuple[str, ...]], set[str]]


@dataclass(frozen=True)
class SubdagSpecialization:
    general_pattern_id: str
    arg_sources: tuple[PatternRef, ...]


@dataclass(frozen=True)
class ArgumentSpecialization:
    general_pattern_id: str
    arg_sources: tuple[ArgRef, ...]


@dataclass(frozen=True)
class PostDropStats:
    argument_rows: int
    argument_count: int
    subdag_rows: int
    subdag_count: int
    table_dropped: bool
    kept_count_per_row: tuple[int, ...]


@dataclass(frozen=True)
class _EnumState:
    kept: frozenset[int]
    cut: frozenset[int]


def _ref_type(dag: PatternDag, ref: PatternRef) -> Attribute:
    if isinstance(ref, ArgRef):
        return dag.arg_types[ref.index]
    return dag.nodes[ref.index].op.spec.result_type


def _enumerate_cut_states(dag: PatternDag) -> set[_EnumState]:
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

        cut_state = _EnumState(state.kept, state.cut | frozenset((index,)))
        kept_state = _EnumState(state.kept | frozenset((index,)), state.cut)
        return {cut_state} | expand_operands(dag.nodes[index].operands, kept_state)

    return expand_operands(dag.nodes[root].operands, initial)


def _build_subdag_with_sources(
    dag: PatternDag,
    kept: frozenset[int],
) -> tuple[PatternDag, tuple[PatternRef, ...]]:
    arg_types: list[Attribute] = []
    arg_sources: list[PatternRef] = []
    arg_of: dict[PatternRef, ArgRef] = {}
    node_of: dict[NodeRef, NodeRef] = {}
    nodes: list[PatternNode] = []

    def cut_arg(orig: PatternRef) -> ArgRef:
        existing = arg_of.get(orig)
        if existing is not None:
            return existing
        ref = ArgRef(len(arg_types))
        arg_types.append(_ref_type(dag, orig))
        arg_sources.append(orig)
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
    return PatternDag.from_parts(tuple(arg_types), tuple(nodes), root), tuple(arg_sources)


def _canonicalize_sources(
    dag: PatternDag,
    arg_sources: tuple[PatternRef, ...],
) -> tuple[str, tuple[PatternRef, ...]]:
    def render_key(node: object) -> str:
        if isinstance(node, ArgRef):
            return f"arg{node.index}"
        op, operands = cast(tuple[PatternOp, tuple[object, ...]], node)
        return f"{op.value}({', '.join(render_key(operand) for operand in operands)})"

    def canonicalize_ref(ref: PatternRef) -> object:
        if isinstance(ref, ArgRef):
            return ref
        node = dag.nodes[ref.index]
        operands = tuple(canonicalize_ref(operand) for operand in node.operands)
        op, operands = canonicalize_pattern_operands(node.op, operands, key=render_key)
        return op, operands

    root = canonicalize_ref(dag.result)
    source_order: list[PatternRef] = []
    arg_map: dict[int, int] = {}

    def render(node: object) -> str:
        if isinstance(node, ArgRef):
            new_index = arg_map.get(node.index)
            if new_index is None:
                new_index = len(source_order)
                arg_map[node.index] = new_index
                source_order.append(arg_sources[node.index])
            return f"arg{new_index}"

        op, operands = cast(tuple[PatternOp, tuple[object, ...]], node)
        return f"{op.value}({', '.join(render(operand) for operand in operands)})"

    canonical = PatternDag(render(root))
    return canonical.to_id(), tuple(source_order)


def enumerate_subdag_specializations(
    specialized_dag: PatternDag,
) -> list[SubdagSpecialization]:
    specializations: dict[tuple[str, tuple[PatternRef, ...]], SubdagSpecialization] = {}
    for state in _enumerate_cut_states(specialized_dag):
        if not state.cut:
            continue
        general_dag, arg_sources = _build_subdag_with_sources(
            specialized_dag,
            state.kept,
        )
        general_pattern_id, canonical_sources = _canonicalize_sources(
            general_dag,
            arg_sources,
        )
        key = (general_pattern_id, canonical_sources)
        specializations[key] = SubdagSpecialization(
            general_pattern_id,
            canonical_sources,
        )
    return sorted(
        specializations.values(),
        key=lambda e: (
            e.general_pattern_id,
            tuple(str(source) for source in e.arg_sources),
        ),
    )


def _arg_occurrences(dag: PatternDag) -> tuple[ArgRef, ...]:
    occurrences: list[ArgRef] = []

    def visit(ref: PatternRef) -> None:
        if isinstance(ref, ArgRef):
            occurrences.append(ref)
            return

        for operand in dag.nodes[ref.index].operands:
            visit(operand)

    visit(dag.result)
    return tuple(occurrences)


def enumerate_argument_specializations(
    specialized_dag: PatternDag,
) -> list[ArgumentSpecialization]:
    occurrences = _arg_occurrences(specialized_dag)
    occurrence_counts: dict[ArgRef, int] = defaultdict(int)
    repeated_positions: list[int] = []
    for pos, occurrence in enumerate(occurrences):
        occurrence_counts[occurrence] += 1
        if occurrence_counts[occurrence] > 1:
            repeated_positions.append(pos)

    if not repeated_positions:
        return []
    if len(repeated_positions) > _MAX_ARGUMENT_SPECIALIZATION_SPLITS:
        return []

    specialized_pattern_id = specialized_dag.to_id()
    specializations: dict[tuple[str, tuple[ArgRef, ...]], ArgumentSpecialization] = {}

    def build_generalized(
        split_positions: frozenset[int],
    ) -> tuple[PatternDag, tuple[ArgRef, ...]]:
        arg_sources = [ArgRef(index) for index in range(specialized_dag.num_args)]
        occurrence_pos = 0

        def render(ref: PatternRef) -> str:
            nonlocal occurrence_pos
            if isinstance(ref, ArgRef):
                current_pos = occurrence_pos
                occurrence_pos += 1
                if current_pos not in split_positions:
                    return f"arg{ref.index}"

                new_arg = len(arg_sources)
                arg_sources.append(ref)
                return f"arg{new_arg}"

            node = specialized_dag.nodes[ref.index]
            operands = tuple(render(operand) for operand in node.operands)
            return f"{node.op.value}({', '.join(operands)})"

        return PatternDag(render(specialized_dag.result)), tuple(arg_sources)

    for mask in range(1, 1 << len(repeated_positions)):
        split_positions = frozenset(
            pos for bit, pos in enumerate(repeated_positions) if mask & (1 << bit)
        )
        general_dag, arg_sources = build_generalized(split_positions)
        try:
            general_pattern_id, canonical_sources = _canonicalize_sources(
                general_dag,
                arg_sources,
            )
        except ValueError:
            continue
        if general_pattern_id == specialized_pattern_id:
            continue
        canonical_arg_sources = cast(tuple[ArgRef, ...], canonical_sources)
        key = (general_pattern_id, canonical_arg_sources)
        specializations[key] = ArgumentSpecialization(
            general_pattern_id,
            canonical_arg_sources,
        )

    return sorted(
        specializations.values(),
        key=lambda e: (
            e.general_pattern_id,
            tuple(str(source) for source in e.arg_sources),
        ),
    )


def read_table(path: Path) -> Table:
    with path.open() as f:
        data = EnumData.read_tsv(f)
    if "ideal" not in data.enumdata.columns:
        raise ValueError(f"{path.name}: no 'ideal' column; run max-precise first")

    arg_cols = [f"arg_{i}" for i in range(data.metadata.arity)]
    row_ideals: dict[tuple[int, tuple[str, ...]], set[str]] = defaultdict(set)
    records = cast(list[dict[str, Any]], data.enumdata.to_dict("records"))
    for row in records:
        bw = int(row["bw"])
        args = tuple(str(row[col]) for col in arg_cols)
        row_ideals[(bw, args)].add(str(row["ideal"]))

    return Table(
        path=path,
        data=data,
        pattern_id=data.metadata.op.to_id(),
        domain=data.metadata.domain,
        row_ideals=dict(row_ideals),
    )


def _compute_values_for_refs(
    pattern: PatternDag,
    domain: AbstractDomain,
    bw: int,
    args: tuple[str, ...],
    refs: tuple[PatternRef, ...],
    timeout: int,
    solver_kind: SolverKind,
    cache: NodeEvalCache,
) -> dict[PatternRef, str]:
    values: dict[PatternRef, str] = {ArgRef(index): arg for index, arg in enumerate(args)}

    def value_of(ref: PatternRef) -> str:
        existing = values.get(ref)
        if existing is not None:
            return existing

        assert isinstance(ref, NodeRef)
        node = pattern.nodes[ref.index]
        node_args = tuple(value_of(operand) for operand in node.operands)
        key = (domain, node.op, bw, node_args)
        value = cache.get(key)
        if value is None:
            value = compute_max_precise(
                PatternDag.single_node(node.op),
                domain,
                bw,
                node_args,
                timeout,
                solver_kind,
            )
            cache[key] = value
        values[ref] = value
        return value

    for ref in refs:
        value_of(ref)

    return values


def drop_specialized_rows(
    specialized_table: Table,
    tables_by_key: dict[tuple[AbstractDomain, str], Table],
    argument_specializations: list[ArgumentSpecialization],
    subdag_specializations: list[SubdagSpecialization],
    timeout: int,
    solver_kind: SolverKind,
    cache: NodeEvalCache,
) -> PostDropStats:
    arg_cols = [f"arg_{i}" for i in range(specialized_table.data.metadata.arity)]
    subdag_specializations = sorted(
        subdag_specializations,
        key=lambda specialization: sum(
            isinstance(source, NodeRef) for source in specialization.arg_sources
        ),
    )

    frame = specialized_table.data.enumdata
    records = cast(list[dict[str, Any]], frame.to_dict("records"))
    if not argument_specializations and not subdag_specializations:
        kept_count_per_row = (
            tuple(int(row["count"]) for row in records)
            if "count" in frame.columns
            else tuple(1 for _ in records)
        )
        return PostDropStats(0, 0, 0, 0, False, kept_count_per_row)

    keep_positions: list[int] = []
    argument_rows = subdag_rows = 0
    argument_count = subdag_count = 0
    row_value_cache: RowValueCache = {}
    for pos, row in enumerate(records):
        count = int(row["count"]) if "count" in frame.columns else 1
        bw = int(row["bw"])
        args = tuple(str(row[col]) for col in arg_cols)
        ideal = str(row["ideal"])

        drop_reason: str | None = None
        for specialization in argument_specializations:
            general_table = tables_by_key[
                (specialized_table.domain, specialization.general_pattern_id)
            ]
            projected_args = tuple(
                args[source.index] for source in specialization.arg_sources
            )
            general_ideals = general_table.row_ideals.get((bw, projected_args))
            if general_ideals is not None and ideal in general_ideals:
                drop_reason = "argument"
                break

        for specialization in subdag_specializations:
            if drop_reason is not None:
                break

            general_table = tables_by_key[
                (specialized_table.domain, specialization.general_pattern_id)
            ]
            row_key = (bw, args)
            values = row_value_cache.get(row_key)
            if values is None:
                values = cast(
                    dict[PatternRef, str],
                    {ArgRef(index): arg for index, arg in enumerate(args)},
                )
                row_value_cache[row_key] = values

            missing_sources = tuple(
                source for source in specialization.arg_sources if source not in values
            )
            if missing_sources:
                values.update(
                    _compute_values_for_refs(
                        specialized_table.data.metadata.op,
                        specialized_table.domain,
                        bw,
                        args,
                        missing_sources,
                        timeout,
                        solver_kind,
                        cache,
                    )
                )
            projected_args = tuple(
                values[source] for source in specialization.arg_sources
            )
            general_ideals = general_table.row_ideals.get((bw, projected_args))
            if general_ideals is not None and ideal in general_ideals:
                drop_reason = "subdag"
                break

        if drop_reason == "argument":
            argument_rows += 1
            argument_count += count
        elif drop_reason == "subdag":
            subdag_rows += 1
            subdag_count += count
        else:
            keep_positions.append(pos)

    table_dropped = not keep_positions
    if table_dropped:
        kept_count_per_row = ()
    else:
        kept = frame.iloc[keep_positions].reset_index(drop=True)
        EnumData(specialized_table.data.metadata, kept).write_tsv(specialized_table.path)
        kept_count_per_row = (
            tuple(int(v) for v in kept["count"])
            if "count" in kept.columns
            else tuple(1 for _ in range(len(kept)))
        )

    return PostDropStats(
        argument_rows,
        argument_count,
        subdag_rows,
        subdag_count,
        table_dropped,
        kept_count_per_row,
    )


def leading_timeout_counts(lines: list[str]) -> tuple[int, ...]:
    """Counts for max-precise rows commented out after timing out.

    These rows are written after the frontmatter and before the TSV header as
    commented data rows. They do not have ideal/sequential_ideal columns, but
    they still end with the original count column.
    """
    if not lines:
        return ()

    assert lines[0].strip() == "# ---"
    end = next(i for i in range(1, len(lines)) if lines[i].strip() == "# ---")

    counts: list[int] = []
    for line in lines[end + 1 :]:
        if not line.startswith("# "):
            break
        fields = line[2:].split("\t")
        if len(fields) < 2:
            continue
        try:
            int(fields[0])
            counts.append(int(fields[-1]))
        except ValueError:
            continue
    return tuple(counts)


def prune_file(path: Path, out_dir: Path, options: PruneOptions) -> FileStats:
    with path.open() as f:
        lines = f.read().splitlines()
    timeout_count_per_row = leading_timeout_counts(lines)
    n_timeout = len(timeout_count_per_row)
    timeout_count = sum(timeout_count_per_row)
    data = EnumData.read_tsv(StringIO("\n".join(lines) + "\n"))
    frame = data.enumdata

    if "ideal" not in frame.columns:
        if len(frame) == 0:
            (out_dir / path.name).unlink(missing_ok=True)
            if not timeout_count_per_row:
                return FileStats.zero()
            return FileStats(
                rows_seen=n_timeout,
                rows_kept=0,
                count_seen=timeout_count,
                count_kept=0,
                top=0,
                top_count=0,
                bottom=0,
                bottom_count=0,
                sequential=0,
                sequential_count=0,
                timeout=n_timeout,
                timeout_count=timeout_count,
                argument_specialized=0,
                argument_specialized_count=0,
                subdag_specialized=0,
                subdag_specialized_count=0,
                subsumed=0,
                subsumed_count=0,
                capped=0,
                capped_count=0,
                empty=True,
                count_per_row=timeout_count_per_row,
                kept_count_per_row=(),
                count_deltas_after_subsumption=(),
            )
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

    computed_count_per_row = (
        tuple(int(v) for v in frame["count"])
        if has_count
        else tuple(1 for _ in range(len(frame)))
    )
    count_per_row = timeout_count_per_row + computed_count_per_row
    count_seen = sum(count_per_row)

    n_seen = n_timeout
    n_top = n_bottom = n_sequential = n_subsumed = n_capped = 0
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
        (out_dir / path.name).unlink(missing_ok=True)
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
            timeout=n_timeout,
            timeout_count=timeout_count,
            argument_specialized=0,
            argument_specialized_count=0,
            subdag_specialized=0,
            subdag_specialized_count=0,
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
        timeout=n_timeout,
        timeout_count=timeout_count,
        argument_specialized=0,
        argument_specialized_count=0,
        subdag_specialized=0,
        subdag_specialized_count=0,
        subsumed=n_subsumed,
        subsumed_count=subsumed_count,
        capped=n_capped,
        capped_count=capped_count,
        empty=False,
        count_per_row=count_per_row,
        kept_count_per_row=kept_count_per_row,
        count_deltas_after_subsumption=tuple(count_deltas),
    )


def apply_post_drop_stats(stats: FileStats, post: PostDropStats) -> FileStats:
    rows_dropped = post.argument_rows + post.subdag_rows
    count_dropped = post.argument_count + post.subdag_count
    return FileStats(
        rows_seen=stats.rows_seen,
        rows_kept=stats.rows_kept - rows_dropped,
        count_seen=stats.count_seen,
        count_kept=stats.count_kept - count_dropped,
        top=stats.top,
        top_count=stats.top_count,
        bottom=stats.bottom,
        bottom_count=stats.bottom_count,
        sequential=stats.sequential,
        sequential_count=stats.sequential_count,
        timeout=stats.timeout,
        timeout_count=stats.timeout_count,
        argument_specialized=post.argument_rows,
        argument_specialized_count=post.argument_count,
        subdag_specialized=post.subdag_rows,
        subdag_specialized_count=post.subdag_count,
        subsumed=stats.subsumed,
        subsumed_count=stats.subsumed_count,
        capped=stats.capped,
        capped_count=stats.capped_count,
        empty=post.table_dropped,
        count_per_row=stats.count_per_row,
        kept_count_per_row=post.kept_count_per_row,
        count_deltas_after_subsumption=stats.count_deltas_after_subsumption,
    )


def drop_specialized_rows_after_pruning(
    tsv_files: list[Path],
    out_dir: Path,
    per_file: list[FileStats],
    timeout: int,
    solver_kind: SolverKind,
) -> list[FileStats]:
    output_by_name = {
        path.name: out_dir / path.name
        for path, stats in zip(tsv_files, per_file)
        if not stats.empty
    }
    if not output_by_name:
        return per_file

    tables: list[Table] = []
    table_indices: dict[str, int] = {}
    for index, path in enumerate(tsv_files):
        output_path = output_by_name.get(path.name)
        if output_path is None:
            continue
        tables.append(read_table(output_path))
        table_indices[path.name] = index

    tables_by_key = {(table.domain, table.pattern_id): table for table in tables}
    if len(tables_by_key) != len(tables):
        sys.exit("error: duplicate domain/pattern TSVs in pruned output")

    subdag_specializations_by_table: dict[str, list[SubdagSpecialization]] = {}
    argument_specializations_by_table: dict[str, list[ArgumentSpecialization]] = {}
    for table in tables:
        subdag_specializations_by_table[table.pattern_id] = [
            specialization
            for specialization in enumerate_subdag_specializations(table.data.metadata.op)
            if (table.domain, specialization.general_pattern_id) in tables_by_key
            and specialization.general_pattern_id != table.pattern_id
        ]
        argument_specializations_by_table[table.pattern_id] = [
            specialization
            for specialization in enumerate_argument_specializations(
                table.data.metadata.op
            )
            if (table.domain, specialization.general_pattern_id) in tables_by_key
            and specialization.general_pattern_id != table.pattern_id
        ]

    updated = list(per_file)
    cache: NodeEvalCache = {}
    for table in tables:
        post = drop_specialized_rows(
            table,
            tables_by_key,
            argument_specializations_by_table[table.pattern_id],
            subdag_specializations_by_table[table.pattern_id],
            timeout,
            solver_kind,
            cache,
        )
        if post.table_dropped:
            table.path.unlink()
        index = table_indices[table.path.name]
        updated[index] = apply_post_drop_stats(updated[index], post)

    return updated


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
    ap.add_argument(
        "--specialization-timeout",
        type=int,
        default=60,
        help="Per-query solver timeout for final subdag-specialization pruning",
    )
    ap.add_argument(
        "--solver",
        type=SolverKind,
        choices=list(SolverKind),
        default=SolverKind.bitwuzla,
        help="SMT solver backend for final subdag-specialization pruning",
    )
    args = ap.parse_args()

    if args.specialization_timeout < 1:
        ap.error("--specialization-timeout must be at least 1")
    if not args.tsv_dir.is_dir():
        sys.exit(f"error: {args.tsv_dir} is not a directory")

    tsv_files = sorted(args.tsv_dir.glob("*.tsv"))
    if not tsv_files:
        sys.exit(f"error: no *.tsv files found in {args.tsv_dir}")

    args.out_dir.mkdir(parents=True, exist_ok=True)
    name_width = max((len(p.name) for p in tsv_files), default=0)
    options = PruneOptions(
        drop_top=args.drop_top,
        drop_bottom=args.drop_bottom,
        drop_locally_complete=args.drop_locally_complete,
        prune_subsumed=args.prune_subsumed,
        max_rows_per_bw=args.max_rows_per_bw,
    )

    per_file: list[FileStats] = []
    for path in tsv_files:
        stats = prune_file(path, args.out_dir, options)
        per_file.append(stats)

    per_file = drop_specialized_rows_after_pruning(
        tsv_files,
        args.out_dir,
        per_file,
        args.specialization_timeout,
        args.solver,
    )

    total = FileStats.zero()
    n_empty = 0
    for path, stats in zip(tsv_files, per_file):
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
            ("timeout", total.timeout, total.timeout_count),
            ("subsumed", total.subsumed, total.subsumed_count),
            ("capped", total.capped, total.capped_count),
            (
                "argument-specialized",
                total.argument_specialized,
                total.argument_specialized_count,
            ),
            (
                "subdag-specialized",
                total.subdag_specialized,
                total.subdag_specialized_count,
            ),
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
