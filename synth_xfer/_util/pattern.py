from dataclasses import dataclass
from pathlib import Path
import re

from xdsl.dialects.builtin import ModuleOp, StringAttr
from xdsl.dialects.func import CallOp, FuncOp, ReturnOp
from xdsl.ir import BlockArgument, Operation, OpResult, SSAValue

from synth_xfer._util.domain import AbstractDomain
from synth_xfer._util.eval import eval_pattern_exact, eval_pattern_norm
from synth_xfer._util.jit import Jit
from synth_xfer._util.lower import LowerToLLVM
from synth_xfer._util.parse_mlir import (
    get_fns,
    get_helper_funcs,
    get_solution,
    inline_mod,
    parse_mlir_mod,
)
from synth_xfer._util.tsv import EnumData
from synth_xfer._util.xfer_data import (
    enumdata_to_eval_inputs,
    enumdata_to_run_inputs,
    namespace_module,
    resolve_xfer_name,
)

_BASE_CONSTRAINTS: dict[str, frozenset[str]] = {
    "ashr": frozenset({"shift_lt_bw"}),
    "lshr": frozenset({"shift_lt_bw"}),
    "srem": frozenset({"no_sdiv_ov", "rhs_neq_zero"}),
    "sdiv": frozenset({"no_sdiv_ov", "rhs_neq_zero"}),
    "shl": frozenset({"shift_lt_bw"}),
    "urem": frozenset({"rhs_neq_zero"}),
    "udiv": frozenset({"rhs_neq_zero"}),
}

_TRANSFER_BASE_TO_OP: dict[str, str] = {
    "add": "Add",
    "and": "And",
    "ashr": "Ashr",
    "countl_one": "CountLOne",
    "countl_zero": "CountLZero",
    "countr_one": "CountROne",
    "countr_zero": "CountRZero",
    "lshr": "Lshr",
    "mul": "Mul",
    "or": "Or",
    "popcount": "PopCount",
    "sdiv": "Sdiv",
    "shl": "Shl",
    "smax": "Smax",
    "smin": "Smin",
    "srem": "Mods",
    "sub": "Sub",
    "udiv": "Udiv",
    "umax": "Umax",
    "umin": "Umin",
    "urem": "Modu",
    "xor": "Xor",
}

_TRANSFER_FLAG_TO_OP: dict[tuple[str, frozenset[str]], str] = {
    ("add", frozenset({"add_nsw"})): "AddNsw",
    ("add", frozenset({"add_nuw"})): "AddNuw",
    ("add", frozenset({"add_nsw", "add_nuw"})): "AddNswNuw",
    ("ashr", frozenset({"ashr_exact"})): "AshrExact",
    ("lshr", frozenset({"lshr_exact"})): "LshrExact",
    ("mul", frozenset({"mul_nsw"})): "MulNsw",
    ("mul", frozenset({"mul_nuw"})): "MulNuw",
    ("mul", frozenset({"mul_nsw", "mul_nuw"})): "MulNswNuw",
    ("or", frozenset({"or_disjoint"})): "OrDisjoint",
    ("sdiv", frozenset({"sdiv_exact"})): "SdivExact",
    ("shl", frozenset({"shl_nsw"})): "ShlNsw",
    ("shl", frozenset({"shl_nuw"})): "ShlNuw",
    ("shl", frozenset({"shl_nsw", "shl_nuw"})): "ShlNswNuw",
    ("sub", frozenset({"sub_nsw"})): "SubNsw",
    ("sub", frozenset({"sub_nuw"})): "SubNuw",
    ("sub", frozenset({"sub_nsw", "sub_nuw"})): "SubNswNuw",
    ("udiv", frozenset({"udiv_exact"})): "UdivExact",
}

_KB = AbstractDomain.KnownBits
_UCR = AbstractDomain.UConstRange
_SCR = AbstractDomain.SConstRange

_COMPLETENESS_TABLE: dict[str, dict[AbstractDomain, tuple[bool, bool]]] = {
    "Add": {_KB: (False, False), _UCR: (False, False), _SCR: (False, False)},
    "AddNsw": {_KB: (False, False), _UCR: (False, False), _SCR: (True, True)},
    "AddNuw": {_KB: (False, False), _UCR: (True, True), _SCR: (False, False)},
    "AddNswNuw": {_KB: (False, False), _UCR: (True, True), _SCR: (True, True)},
    "And": {_KB: (True, True), _UCR: (False, False), _SCR: (False, False)},
    "Ashr": {_KB: (False, False), _UCR: (False, False), _SCR: (False, False)},
    "AshrExact": {_KB: (False, False), _UCR: (False, False), _SCR: (False, False)},
    "Lshr": {_KB: (False, False), _UCR: (False, False), _SCR: (False, False)},
    "LshrExact": {_KB: (False, False), _UCR: (False, False), _SCR: (False, False)},
    "Mul": {_KB: (False, False), _UCR: (False, False), _SCR: (False, False)},
    "MulNsw": {_KB: (False, False), _UCR: (False, False), _SCR: (False, True)},
    "MulNuw": {_KB: (False, False), _UCR: (False, True), _SCR: (False, False)},
    "MulNswNuw": {_KB: (False, False), _UCR: (False, True), _SCR: (False, True)},
    "Or": {_KB: (True, True), _UCR: (False, False), _SCR: (False, False)},
    "OrDisjoint": {_KB: (True, True), _UCR: (False, False), _SCR: (False, False)},
    "Sdiv": {_KB: (False, False), _UCR: (False, False), _SCR: (False, False)},
    "SdivExact": {_KB: (False, False), _UCR: (False, False), _SCR: (False, False)},
    "Shl": {_KB: (False, False), _UCR: (False, False), _SCR: (False, False)},
    "ShlNsw": {_KB: (False, False), _UCR: (False, False), _SCR: (False, False)},
    "ShlNuw": {_KB: (False, False), _UCR: (False, False), _SCR: (False, False)},
    "ShlNswNuw": {_KB: (False, False), _UCR: (False, False), _SCR: (False, False)},
    "Mods": {_KB: (False, False), _UCR: (False, False), _SCR: (False, False)},
    "Sub": {_KB: (False, False), _UCR: (False, False), _SCR: (False, False)},
    "SubNsw": {_KB: (False, False), _UCR: (False, False), _SCR: (True, True)},
    "SubNuw": {_KB: (False, False), _UCR: (True, True), _SCR: (False, False)},
    "SubNswNuw": {_KB: (False, False), _UCR: (True, True), _SCR: (True, True)},
    "Udiv": {_KB: (False, False), _UCR: (False, False), _SCR: (False, False)},
    "UdivExact": {_KB: (False, False), _UCR: (False, False), _SCR: (False, False)},
    "Modu": {_KB: (False, False), _UCR: (False, False), _SCR: (False, False)},
    "Xor": {_KB: (True, True), _UCR: (False, False), _SCR: (False, False)},
}

_OP_FALLBACKS: dict[str, str] = {
    op_name: _TRANSFER_BASE_TO_OP[transfer_op]
    for (transfer_op, _), op_name in _TRANSFER_FLAG_TO_OP.items()
}


@dataclass(frozen=True)
class DagNode:
    operation: str
    operands: tuple[str, ...]


@dataclass(frozen=True)
class PatternDag:
    args: tuple[str, ...]
    nodes: tuple[DagNode, ...]
    result: str
    expression: str


@dataclass(frozen=True)
class CompletenessReport:
    dag: PatternDag
    edges: tuple[tuple[str, bool], ...]
    reuse: bool

    @property
    def coincides(self) -> bool:
        return all(is_complete for _, is_complete in self.edges) and not self.reuse


def _render_expr(ref: str, nodes: tuple[DagNode, ...]) -> str:
    if not ref.startswith("n"):
        return ref
    node = nodes[int(ref.removeprefix("n"))]
    operands = ", ".join(_render_expr(operand, nodes) for operand in node.operands)
    return f"{node.operation}({operands})"


def _value_ref(value: SSAValue, node_ids: dict[Operation, int]) -> str:
    if isinstance(value, BlockArgument):
        return f"arg{value.index}"
    assert isinstance(value, OpResult)
    return f"n{node_ids[value.op]}"


def _extract_constraints(op_constraint: FuncOp, num_nodes: int) -> dict[int, set[str]]:
    constraints: dict[int, set[str]] = {}
    for op in op_constraint.body.block.ops:
        if not isinstance(op, CallOp):
            continue
        if len(op.results) != 1:
            raise ValueError("Expected constraint helper calls to have one result.")
        name_hint = op.results[0].name_hint
        if name_hint is None:
            raise ValueError(
                "Expected constraint helper call result to have an SSA name."
            )

        ssa_constraint_re = re.compile(r"ssa_(\d+)_con_(\d+)_z$")
        match = ssa_constraint_re.fullmatch(name_hint)

        if match is None:
            raise ValueError(f"Unexpected constraint SSA name '{name_hint}'.")
        node_id = int(match.group(1))
        if node_id >= num_nodes:
            raise ValueError(
                f"Constraint '{name_hint}' references node {node_id}, but only "
                f"{num_nodes} concrete ops exist."
            )
        constraints.setdefault(node_id, set()).add(op.callee.root_reference.data)
    return constraints


def _resolve_operation(
    transfer_op: str,
    constraints: set[str],
) -> str:
    base_name = _TRANSFER_BASE_TO_OP.get(transfer_op)
    if base_name is None:
        raise ValueError(f"No base op mapping found for transfer op '{transfer_op}'.")

    base_constraints = _BASE_CONSTRAINTS.get(transfer_op, frozenset())
    if not base_constraints <= constraints:
        raise ValueError(
            f"Transfer op '{transfer_op}' is missing required base constraints "
            f"{sorted(base_constraints - constraints)}."
        )

    remaining = frozenset(constraints - base_constraints)
    if not remaining:
        return base_name

    op_name = _TRANSFER_FLAG_TO_OP.get((transfer_op, remaining))
    if op_name is None:
        raise ValueError(
            f"Could not resolve transfer op '{transfer_op}' with constraints "
            f"{sorted(constraints)}."
        )
    return op_name


def _resolve_metadata_op(op: str) -> Path:
    if op.startswith("pattern_"):
        return Path("mlir") / "Patterns" / f"{op.removeprefix('pattern_')}.mlir"
    return Path("mlir") / "Operations" / f"{op}.mlir"


def get_fallback_op(op: str) -> str | None:
    return _OP_FALLBACKS.get(op)


def _load_pattern(pattern_path: Path) -> PatternDag:
    pattern_mod = parse_mlir_mod(pattern_path)
    fns = get_fns(pattern_mod)
    concrete_op = fns.get("concrete_op")
    if concrete_op is None:
        raise ValueError(f"Missing concrete_op in '{pattern_path}'.")

    concrete_ops = [
        op for op in concrete_op.body.block.ops if not isinstance(op, ReturnOp)
    ]
    op_constraint = fns.get("op_constraint")
    constraints_by_node = (
        _extract_constraints(op_constraint, len(concrete_ops))
        if op_constraint is not None
        else {}
    )
    node_ids = {op: i for i, op in enumerate(concrete_ops)}

    nodes: list[DagNode] = []
    for i, op in enumerate(concrete_ops):
        transfer_op = op.name.removeprefix("transfer.")
        operation = _resolve_operation(transfer_op, constraints_by_node.get(i, set()))
        if len(op.results) != 1:
            raise ValueError("Expected concrete_op instructions to produce one result.")
        nodes.append(
            DagNode(
                operation=operation,
                operands=tuple(_value_ref(operand, node_ids) for operand in op.operands),
            )
        )

    returns = [op for op in concrete_op.body.block.ops if isinstance(op, ReturnOp)]
    if len(returns) != 1 or len(returns[0].arguments) != 1:
        raise ValueError("Expected concrete_op to contain one single-value return.")
    result = _value_ref(returns[0].arguments[0], node_ids)

    nodes_tuple = tuple(nodes)
    expr = _render_expr(result, nodes_tuple)
    return PatternDag(
        args=tuple(f"arg{i}" for i, _ in enumerate(concrete_op.args)),
        nodes=nodes_tuple,
        result=result,
        expression=expr,
    )


def _completeness(op: str, domain: AbstractDomain) -> tuple[bool, bool]:
    if op not in _COMPLETENESS_TABLE:
        raise ValueError(f"Operation '{op}' is not in the completeness table.")
    return _COMPLETENESS_TABLE[op][domain]


def _has_reuse(dag: PatternDag) -> bool:
    consumers: dict[str, int] = {
        **{arg: 0 for arg in dag.args},
        **{f"n{i}": 0 for i, _ in enumerate(dag.nodes)},
    }
    for node in dag.nodes:
        for operand in node.operands:
            if operand in consumers:
                consumers[operand] += 1
    return any(count > 1 for count in consumers.values())


def analyze_pattern(
    pattern_path: Path,
    domain: AbstractDomain,
) -> CompletenessReport:
    if domain not in (
        AbstractDomain.KnownBits,
        AbstractDomain.UConstRange,
        AbstractDomain.SConstRange,
    ):
        raise NotImplementedError(f"analze not implemented for domain '{domain}'.")

    dag = _load_pattern(pattern_path)
    edges: list[tuple[str, bool]] = []

    for i, node in enumerate(dag.nodes):
        _completeness(node.operation, domain)
        for operand in node.operands:
            if not operand.startswith("n"):
                continue
            producer_idx = int(operand.removeprefix("n"))
            producer = dag.nodes[producer_idx]
            producer_forward, _ = _completeness(producer.operation, domain)
            _, consumer_backward = _completeness(node.operation, domain)
            edge = f"n{producer_idx}({producer.operation}) -> n{i}({node.operation})"
            is_complete = producer_forward or consumer_backward
            edges.append((edge, is_complete))

    return CompletenessReport(
        dag=dag,
        edges=tuple(edges),
        reuse=_has_reuse(dag),
    )


def _get_pattern_solutions(
    dag: PatternDag, xfer_dir: Path, d: AbstractDomain
) -> dict[str, FuncOp]:
    concrete_ops: dict[str, FuncOp] = {}
    for n in dag.nodes:
        f_path = xfer_dir / f"{d}_{n.operation}" / "solution.mlir"
        sol = get_solution(f_path, d)
        sol.sym_name = StringAttr(n.operation)
        concrete_ops[n.operation] = sol

    return concrete_ops


def construct_pattern_solution(
    pattern_path: Path, xfer_dir: Path, d: AbstractDomain
) -> FuncOp:
    dag = _load_pattern(pattern_path)
    xfers = _get_pattern_solutions(dag, xfer_dir, d)

    first_xfer = xfers[dag.nodes[0].operation]
    input_ty = first_xfer.function_type.inputs.data[0]
    output_tys = first_xfer.function_type.outputs.data

    solution = FuncOp.from_region(
        "solution",
        [input_ty for _ in dag.args],
        output_tys,
    )
    value_map: dict[str, SSAValue] = {
        arg_name: solution.args[i] for i, arg_name in enumerate(dag.args)
    }

    lowered_xfers: list[FuncOp] = []
    for op_name, func in xfers.items():
        lowered = func.clone()
        lowered.sym_name = StringAttr(op_name)
        lowered_xfers.append(lowered)

    for i, node in enumerate(dag.nodes):
        xfer = xfers[node.operation]
        operands = [value_map[operand] for operand in node.operands]
        call = CallOp(node.operation, operands, xfer.function_type.outputs.data)
        solution.body.block.add_op(call)
        value_map[f"n{i}"] = call.results[0]

    solution.body.block.add_op(ReturnOp(value_map[dag.result]))
    mod = ModuleOp([*lowered_xfers, solution])
    inline_mod(mod)
    return get_fns(mod)["solution"]


def eval_pattern(
    sequential_xfer: Path,
    composite_xfer: Path,
    xfer_name: str | None,
    input_path: Path,
    exact_bw: int,
    norm_bw: int,
) -> tuple[float, float, float, float]:
    raw_seq_mod = parse_mlir_mod(sequential_xfer)
    seq_mod = namespace_module(raw_seq_mod, "seq")
    seq_xfer_name = "seq_solution"
    comp_mod = parse_mlir_mod(composite_xfer)
    comp_xfer_name = resolve_xfer_name(get_fns(comp_mod), xfer_name)

    with input_path.open("r") as f:
        data = EnumData.read_tsv(f)

    if exact_bw not in [x[0] for x in data.metadata.mbw + data.metadata.hbw]:
        raise ValueError(f"Exact BW {exact_bw} not in Enum TSV")
    if norm_bw not in [x[0] for x in data.metadata.mbw + data.metadata.hbw]:
        raise ValueError(f"Norm BW {norm_bw} not in Enum TSV")

    exact_to_eval = enumdata_to_eval_inputs(data)[exact_bw]
    norm_to_eval = enumdata_to_run_inputs(data)[norm_bw]

    exact_weights = (
        data.enumdata[data.enumdata["bw"] == exact_bw]["weight"].astype(float).tolist()
    )
    norm_weights = (
        data.enumdata[data.enumdata["bw"] == norm_bw]["weight"].astype(float).tolist()
    )

    helpers = get_helper_funcs(
        _resolve_metadata_op(data.metadata.op), data.metadata.domain
    )
    lowerer = LowerToLLVM(sorted({exact_bw, norm_bw}))
    lowerer.add_fn(helpers.meet_func)
    lowerer.add_fn(helpers.get_top_func)
    lowerer.add_mod(seq_mod, [seq_xfer_name])
    lowerer.add_mod(comp_mod, [comp_xfer_name])

    with Jit() as jit:
        jit.add_mod(lowerer)
        seq_exact, comp_exact = eval_pattern_exact(
            exact_to_eval,
            exact_weights,
            jit.get_fn_ptr(f"{seq_xfer_name}_{exact_bw}_shim"),
            jit.get_fn_ptr(f"{comp_xfer_name}_{exact_bw}_shim"),
        )

        seq_norm, comp_norm = eval_pattern_norm(
            norm_to_eval,
            norm_weights,
            jit.get_fn_ptr(f"{seq_xfer_name}_{norm_bw}_shim"),
            jit.get_fn_ptr(f"{comp_xfer_name}_{norm_bw}_shim"),
        )

    return seq_exact, comp_exact, seq_norm, comp_norm
