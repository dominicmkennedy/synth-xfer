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
    # TODO add these ops to the dialect
    # PatternOp.SaddSat: {_KB: (False, False), _UCR: (False, False), _SCR: (True, True)},
    # PatternOp.UaddSat: {_KB: (False, False), _UCR: (True, True), _SCR: (False, False)},
    # PatternOp.SsubSat: {_KB: (False, False), _UCR: (False, False), _SCR: (True, True)},
    # PatternOp.UsubSat: {_KB: (False, False), _UCR: (True, True), _SCR: (False, False)},
    # PatternOp.SmulSat: {_KB: (False, False), _UCR: (False, False), _SCR: (False, True)},
    # PatternOp.UmulSat: {_KB: (False, False), _UCR: (False, True), _SCR: (False, False)},
    # PatternOp.SshlSat: {_KB: (False, False), _UCR: (False, True), _SCR: (False, False)},
    # PatternOp.UshlSat: {_KB: (False, False), _UCR: (False, True), _SCR: (False, False)},
    # unary ops
    # PatternOp.Not: {_KB: (True, True), _UCR: (True, True), _SCR: (True, True)},
    # PatternOp.Neg: {_KB: (False, False), _UCR: (False, False), _SCR: (False, False)},
    # PatternOp.Abs: {_KB: (False, False), _UCR: (True, False), _SCR: (False, False)},
    # PatternOp.AbsUndef: {_KB: (False, False), _UCR: (True, False), _SCR: (True, False)},
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
    # PatternOp.TruncToBool: {_KB: (True, True), _UCR: (True, False), _SCR: (True, False)},
    # PatternOp.ZextBool: {_KB: (True, True), _UCR: (True, True), _SCR: (True, True)},
    # PatternOp.SextBool: {_KB: (False, True), _UCR: (False, True), _SCR: (True, True)},
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


def _has_reuse(dag: PatternDag) -> bool:
    consumers: dict[PatternRef, int] = {
        **{ArgRef(i): 0 for i in range(dag.num_args)},
        **{NodeRef(i): 0 for i, _ in enumerate(dag.nodes)},
    }
    for node in dag.nodes:
        for operand in node.operands:
            consumers[operand] += 1
    return any(count > 1 for count in consumers.values())


def analyze_pattern(dag: PatternDag, domain: AbstractDomain) -> str:
    if domain not in (_KB, _UCR, _SCR):
        raise NotImplementedError(f"analyze not implemented for domain '{domain}'.")

    reuse = _has_reuse(dag)
    all_edges_complete = True
    body: list[str] = []

    for i, node in enumerate(dag.nodes):
        if i:
            body.append("")

        operands = ", ".join(format_pattern_ref(operand) for operand in node.operands)
        body.append(f"  n{i} = {node.op.value}({operands})")

        _, consumer_backward = _COMPLETENESS_TABLE[node.op][domain]

        for operand in node.operands:
            if not isinstance(operand, NodeRef):
                continue

            producer = dag.nodes[operand.index]
            producer_forward, _ = _COMPLETENESS_TABLE[producer.op][domain]

            is_complete = producer_forward or consumer_backward
            all_edges_complete = all_edges_complete and is_complete

            body.append(
                f"    {format_pattern_ref(operand)} : "
                f"{'complete' if is_complete else 'incomplete'}"
            )

    coincides = all_edges_complete and not reuse

    lines = [
        f"Coincide:  {coincides}",
        f"SSA Reuse: {reuse}",
        "Complete Edges:",
        *body,
    ]

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
