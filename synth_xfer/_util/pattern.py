from dataclasses import dataclass
from pathlib import Path

from synth_xfer._util.domain import AbstractDomain
from synth_xfer._util.eval import eval_pattern_exact, eval_pattern_norm
from synth_xfer._util.jit import Jit
from synth_xfer._util.lower import LowerToLLVM
from synth_xfer._util.parse_mlir import HelperFuncs, get_fns, parse_mlir_mod
from synth_xfer._util.pattern_dsl import (
    ArgRef,
    NodeRef,
    PatternDag,
    PatternOp,
    PatternRef,
    _format_alpha_pattern_ref,
    canonicalize_pattern_operands,
    format_pattern_ref,
)
from synth_xfer._util.tsv import EnumData
from synth_xfer._util.xfer_data import (
    enumdata_to_eval_input,
    enumdata_to_run_input,
    resolve_xfer_name,
)

_KB = AbstractDomain.KnownBits
_UCR = AbstractDomain.UConstRange
_SCR = AbstractDomain.SConstRange

_COMPLETENESS_TABLE: dict[PatternOp, dict[AbstractDomain, tuple[bool, bool]]] = {
    # each tuple is (forward complete, backward complete)
    # binary ops
    PatternOp.Add: {_KB: (False, False), _UCR: (False, False), _SCR: (False, False)},
    PatternOp.AddNsw: {_KB: (False, False), _UCR: (False, False), _SCR: (True, True)},
    PatternOp.AddNuw: {_KB: (False, False), _UCR: (True, True), _SCR: (False, False)},
    PatternOp.AddNswNuw: {_KB: (False, False), _UCR: (True, True), _SCR: (True, True)},
    PatternOp.And: {_KB: (True, True), _UCR: (False, False), _SCR: (False, False)},
    PatternOp.Ashr: {_KB: (False, False), _UCR: (False, False), _SCR: (False, False)},
    PatternOp.AshrExact: {
        _KB: (False, False),
        _UCR: (False, False),
        _SCR: (False, False),
    },
    PatternOp.Lshr: {_KB: (False, False), _UCR: (False, False), _SCR: (False, False)},
    PatternOp.LshrExact: {
        _KB: (False, False),
        _UCR: (False, False),
        _SCR: (False, False),
    },
    PatternOp.Mul: {_KB: (False, False), _UCR: (False, False), _SCR: (False, False)},
    PatternOp.MulNsw: {_KB: (False, False), _UCR: (False, False), _SCR: (False, True)},
    PatternOp.MulNuw: {_KB: (False, False), _UCR: (False, True), _SCR: (False, False)},
    PatternOp.MulNswNuw: {_KB: (False, False), _UCR: (False, True), _SCR: (False, True)},
    PatternOp.Or: {_KB: (True, True), _UCR: (False, False), _SCR: (False, False)},
    PatternOp.OrDisjoint: {_KB: (True, True), _UCR: (False, False), _SCR: (False, False)},
    PatternOp.Sdiv: {_KB: (False, False), _UCR: (False, False), _SCR: (False, False)},
    PatternOp.SdivExact: {
        _KB: (False, False),
        _UCR: (False, False),
        _SCR: (False, False),
    },
    PatternOp.Shl: {_KB: (False, False), _UCR: (False, False), _SCR: (False, False)},
    PatternOp.ShlNsw: {_KB: (False, False), _UCR: (False, False), _SCR: (False, False)},
    PatternOp.ShlNuw: {_KB: (False, False), _UCR: (False, False), _SCR: (False, False)},
    PatternOp.ShlNswNuw: {
        _KB: (False, False),
        _UCR: (False, False),
        _SCR: (False, False),
    },
    PatternOp.Mods: {_KB: (False, False), _UCR: (False, False), _SCR: (False, False)},
    PatternOp.Sub: {_KB: (False, False), _UCR: (False, False), _SCR: (False, False)},
    PatternOp.SubNsw: {_KB: (False, False), _UCR: (False, False), _SCR: (True, True)},
    PatternOp.SubNuw: {_KB: (False, False), _UCR: (True, True), _SCR: (False, False)},
    PatternOp.SubNswNuw: {_KB: (False, False), _UCR: (True, True), _SCR: (True, True)},
    PatternOp.Udiv: {_KB: (False, False), _UCR: (False, False), _SCR: (False, False)},
    PatternOp.UdivExact: {
        _KB: (False, False),
        _UCR: (False, False),
        _SCR: (False, False),
    },
    PatternOp.Modu: {_KB: (False, False), _UCR: (False, False), _SCR: (False, False)},
    PatternOp.Xor: {_KB: (True, True), _UCR: (False, False), _SCR: (False, False)},
    PatternOp.Umax: {_KB: (False, False), _UCR: (True, True), _SCR: (False, False)},
    PatternOp.Umin: {_KB: (False, False), _UCR: (True, True), _SCR: (False, False)},
    PatternOp.Smax: {_KB: (False, False), _UCR: (False, False), _SCR: (True, True)},
    PatternOp.Smin: {_KB: (False, False), _UCR: (False, False), _SCR: (True, True)},
    PatternOp.SaddSat: {_KB: (False, False), _UCR: (False, False), _SCR: (True, True)},
    PatternOp.UaddSat: {_KB: (False, False), _UCR: (True, True), _SCR: (False, False)},
    PatternOp.SsubSat: {_KB: (False, False), _UCR: (False, False), _SCR: (True, True)},
    PatternOp.UsubSat: {_KB: (False, False), _UCR: (True, True), _SCR: (False, False)},
    PatternOp.SmulSat: {_KB: (False, False), _UCR: (False, False), _SCR: (False, True)},
    PatternOp.UmulSat: {_KB: (False, False), _UCR: (False, True), _SCR: (False, False)},
    PatternOp.SshlSat: {_KB: (False, False), _UCR: (False, True), _SCR: (False, False)},
    PatternOp.UshlSat: {_KB: (False, False), _UCR: (False, True), _SCR: (False, False)},
    # unary ops
    PatternOp.Abs: {_KB: (False, False), _UCR: (True, False), _SCR: (False, False)},
    PatternOp.AbsUndef: {_KB: (False, False), _UCR: (True, False), _SCR: (True, False)},
    PatternOp.PopCount: {_KB: (False, False), _UCR: (False, False), _SCR: (False, False)},
    PatternOp.CountLZero: {_KB: (False, False), _UCR: (True, True), _SCR: (False, False)},
    PatternOp.CountLZeroUndef: {
        _KB: (False, False),
        _UCR: (True, False),
        _SCR: (False, False),
    },
    PatternOp.CountRZero: {
        _KB: (False, False),
        _UCR: (False, False),
        _SCR: (False, False),
    },
    PatternOp.CountRZeroUndef: {
        _KB: (False, False),
        _UCR: (False, False),
        _SCR: (False, False),
    },
    # cast ops
    PatternOp.TruncToBool: {_KB: (True, True), _UCR: (True, False), _SCR: (True, False)},
    PatternOp.ZextBool: {_KB: (True, True), _UCR: (True, True), _SCR: (True, True)},
    PatternOp.SextBool: {_KB: (False, True), _UCR: (False, True), _SCR: (True, True)},
    # ternary ops
    PatternOp.Select: {_KB: (False, True), _UCR: (False, True), _SCR: (False, True)},
    PatternOp.ICmpEq: {_KB: (True, False), _UCR: (True, False), _SCR: (True, False)},
    PatternOp.ICmpNe: {_KB: (True, False), _UCR: (True, False), _SCR: (True, False)},
    PatternOp.ICmpSlt: {_KB: (True, False), _UCR: (True, False), _SCR: (True, True)},
    PatternOp.ICmpSle: {_KB: (True, False), _UCR: (True, False), _SCR: (True, True)},
    PatternOp.ICmpSgt: {_KB: (True, False), _UCR: (True, False), _SCR: (True, True)},
    PatternOp.ICmpSge: {_KB: (True, False), _UCR: (True, False), _SCR: (True, True)},
    PatternOp.ICmpUlt: {_KB: (True, False), _UCR: (True, True), _SCR: (True, False)},
    PatternOp.ICmpUle: {_KB: (True, False), _UCR: (True, True), _SCR: (True, False)},
    PatternOp.ICmpUgt: {_KB: (True, False), _UCR: (True, True), _SCR: (True, False)},
    PatternOp.ICmpUge: {_KB: (True, False), _UCR: (True, True), _SCR: (True, False)},
}


@dataclass(frozen=True, slots=True)
class PatternOperandReport:
    ref: PatternRef
    complete: bool
    reused: bool


@dataclass(frozen=True, slots=True)
class PatternNodeReport:
    index: int
    op: PatternOp
    operands: tuple[PatternRef, ...]
    operand_reports: tuple[PatternOperandReport, ...]


@dataclass(frozen=True, slots=True)
class PatternReport:
    coincides: bool
    reuse: bool
    nodes: tuple[PatternNodeReport, ...]


def _consumer_counts(dag: PatternDag) -> dict[PatternRef, int]:
    consumers: dict[PatternRef, int] = {
        **{ArgRef(i): 0 for i in range(dag.num_args)},
        **{NodeRef(i): 0 for i, _ in enumerate(dag.nodes)},
    }
    for node in dag.nodes:
        for operand in node.operands:
            consumers[operand] += 1
    return consumers


def analyze_pattern(dag: PatternDag, domain: AbstractDomain) -> PatternReport:
    if domain not in (_KB, _UCR, _SCR):
        raise NotImplementedError(f"analyze not implemented for domain '{domain}'.")

    consumers = _consumer_counts(dag)
    reuse = any(count > 1 for count in consumers.values())
    all_edges_complete = True
    node_reports: list[PatternNodeReport] = []

    for i, node in enumerate(dag.nodes):
        _, consumer_backward = _COMPLETENESS_TABLE[node.op][domain]
        operand_reports: list[PatternOperandReport] = []

        for operand in node.operands:
            reused = consumers[operand] > 1

            if isinstance(operand, NodeRef):
                producer = dag.nodes[operand.index]
                producer_forward, _ = _COMPLETENESS_TABLE[producer.op][domain]
                is_complete = producer_forward or consumer_backward
            else:
                is_complete = True

            is_complete = is_complete and not reused
            all_edges_complete = all_edges_complete and is_complete
            operand_reports.append(PatternOperandReport(operand, is_complete, reused))

        node_reports.append(
            PatternNodeReport(
                i,
                node.op,
                node.operands,
                tuple(operand_reports),
            )
        )

    coincides = all_edges_complete and not reuse

    return PatternReport(coincides, reuse, tuple(node_reports))


def _is_droppable_refinement(dag: PatternDag, domain: AbstractDomain) -> bool:
    if len(dag.nodes) <= 1:
        return True

    report = analyze_pattern(dag, domain)
    return all(
        operand_report.complete
        for node_report in report.nodes
        for operand_report in node_report.operand_reports
    )


def _split_shares_args(
    dag: PatternDag,
    consumer: NodeRef,
    operand_index: int,
) -> bool:
    producer = dag.nodes[consumer.index].operands[operand_index]
    assert isinstance(producer, NodeRef)

    _, upstream_sources, _ = dag.subdag_with_cut(producer)
    _, downstream_sources, _ = dag.subdag_with_cut(dag.result, (consumer, operand_index))
    upstream_args = {source for source in upstream_sources if isinstance(source, ArgRef)}
    downstream_args = {
        source for source in downstream_sources if isinstance(source, ArgRef)
    }
    return bool(upstream_args & downstream_args)


def _split_pattern(
    dag: PatternDag,
    consumer: NodeRef,
    operand_index: int,
) -> tuple[PatternDag, PatternDag]:
    producer = dag.nodes[consumer.index].operands[operand_index]
    assert isinstance(producer, NodeRef)

    upstream, _, _ = dag.subdag_with_cut(producer)
    downstream, _, _ = dag.subdag_with_cut(dag.result, (consumer, operand_index))
    return upstream, downstream


def refine_pattern(dag: PatternDag, domain: AbstractDomain) -> tuple[PatternDag, ...]:
    # Refinement rules:
    # - Complete node-to-node edges are uninteresting composition boundaries, so
    #   try splitting the DAG into the producer-side subpattern and the root-side
    #   subpattern with that edge replaced by a fresh argument.
    # - Reused operands are never split because the shared value is semantically
    #   relevant to why the full pattern does not coincide.
    # - If the two split subpatterns would share any original argN, reject the
    #   split instead of duplicating correlated inputs across independent DAGs.
    # - Recurse after every accepted split and return only final refined leaves;
    #   drop leaves that are single ops or whose operand uses are all complete.
    seen: dict[str, PatternDag] = {}

    def add_leaf(leaf: PatternDag) -> None:
        if _is_droppable_refinement(leaf, domain):
            return
        seen.setdefault(str(leaf), leaf)

    def visit(current: PatternDag) -> None:
        report = analyze_pattern(current, domain)
        split_found = False

        for node_report in report.nodes:
            consumer = NodeRef(node_report.index)
            for operand_index, operand_report in enumerate(node_report.operand_reports):
                if not isinstance(operand_report.ref, NodeRef):
                    continue
                if not operand_report.complete:
                    continue
                if _split_shares_args(current, consumer, operand_index):
                    continue

                split_found = True
                for subpattern in _split_pattern(current, consumer, operand_index):
                    visit(subpattern)

        if not split_found:
            add_leaf(current)

    visit(dag)
    return tuple(seen.values())


def format_pattern_report(report: PatternReport) -> str:
    body: list[str] = []
    arg_map: dict[int, int] = {}

    def format_report_ref(ref: PatternRef) -> str:
        return _format_alpha_pattern_ref(ref, arg_map)

    display_rows: list[
        tuple[PatternNodeReport, PatternOp, tuple[str, ...], list[str]]
    ] = []

    for node_report in report.nodes:
        op, operand_reports = canonicalize_pattern_operands(
            node_report.op,
            node_report.operand_reports,
            key=lambda operand_report: format_pattern_ref(operand_report.ref),
        )
        operand_labels = tuple(
            format_report_ref(operand_report.ref) for operand_report in operand_reports
        )
        statuses: list[str] = []

        for operand_report in operand_reports:
            status = "complete" if operand_report.complete else "incomplete"
            if operand_report.reused:
                status = f"{status} (reused)"
            statuses.append(status)

        display_rows.append((node_report, op, operand_labels, statuses))

    operand_width = max(
        (
            len(label)
            for _, _, operand_labels, _ in display_rows
            for label in operand_labels
        ),
        default=0,
    )

    for node_report, op, operand_labels, statuses in display_rows:
        if node_report.index:
            body.append("")

        body.append(f"  n{node_report.index} = {op.value}({', '.join(operand_labels)})")
        for operand_label, status in zip(operand_labels, statuses, strict=True):
            body.append(f"    {operand_label:<{operand_width}} : {status}")

    lines = [
        f"Coincide:  {report.coincides}",
        f"SSA Reuse: {report.reuse}",
        "Complete Edges:",
        *body,
    ]

    return "\n".join(lines)


def format_refined_patterns(refined_patterns: tuple[PatternDag, ...]) -> str:
    if not refined_patterns:
        return ""

    lines = ["Refined Patterns:"]
    lines.extend(f"  {pattern}" for pattern in refined_patterns)
    return "\n".join(lines)


def eval_pattern(
    pattern: PatternDag,
    composite_xfer: Path | None,
    xfer_name: str | None,
    data: EnumData,
    bw: int,
) -> tuple[float, float, float, float, float, float, float, float]:
    if bw not in [x[0] for x in data.metadata.mbw + data.metadata.hbw]:
        raise ValueError(f"BW {bw} not in Enum TSV")

    exact_to_eval = enumdata_to_eval_input(data, bw)
    norm_to_eval = enumdata_to_run_input(data, bw)

    rows = data.enumdata[data.enumdata["bw"] == bw]
    if "weight" not in data.enumdata.columns:
        # Uniform weighting: a constant weight makes the eval score a plain
        # unweighted average (the score normalizes by the weight sum).
        weights = [1.0] * len(rows)
    else:
        weights = rows["weight"].astype(float).tolist()

    if composite_xfer:
        comp_mod = parse_mlir_mod(composite_xfer)
        comp_xfer_name = resolve_xfer_name(get_fns(comp_mod), xfer_name)
        helpers = HelperFuncs(data.metadata.op, data.metadata.domain)
        lowerer = LowerToLLVM([bw])
        lowerer.add_fn(helpers.meet_func)
        lowerer.add_fn(helpers.get_top_func)
        lowerer.add_mod(comp_mod, [comp_xfer_name])

        with Jit() as jit:
            jit.add_mod(lowerer)
            shim_ptr = jit.get_fn_ptr(f"{comp_xfer_name}_{bw}_shim")
            seq_sound, comp_sound, seq_exact, comp_exact, seq_dist, comp_dist = (
                eval_pattern_exact(exact_to_eval, weights, str(pattern), shim_ptr)
            )

            seq_norm, comp_norm = eval_pattern_norm(
                norm_to_eval, weights, str(pattern), shim_ptr
            )
    else:
        seq_sound, comp_sound, seq_exact, comp_exact, seq_dist, comp_dist = (
            eval_pattern_exact(exact_to_eval, weights, str(pattern), None)
        )

        seq_norm, comp_norm = eval_pattern_norm(norm_to_eval, weights, str(pattern), None)

    return (
        seq_sound,
        comp_sound,
        seq_exact,
        comp_exact,
        seq_dist,
        comp_dist,
        seq_norm,
        comp_norm,
    )
