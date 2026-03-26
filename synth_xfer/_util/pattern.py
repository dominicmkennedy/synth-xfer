from dataclasses import dataclass
from itertools import product
from pathlib import Path
from random import Random
import re
from typing import cast

import pandas as pd
from xdsl.dialects.func import CallOp, FuncOp, ReturnOp
from xdsl.ir import BlockArgument, Operation, OpResult, SSAValue

from synth_xfer._util.domain import AbstractDomain
from synth_xfer._util.parse_mlir import get_fns, parse_mlir_mod
from synth_xfer._util.tsv import EnumData, EnumMetaData

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

_COMMUTATIVE_OPS = {
    "Add",
    "AddNsw",
    "AddNswNuw",
    "AddNuw",
    "And",
    "AvgCeilS",
    "AvgCeilU",
    "AvgFloorS",
    "AvgFloorU",
    "Mul",
    "MulNsw",
    "MulNswNuw",
    "MulNuw",
    "Or",
    "OrDisjoint",
    "Smax",
    "Smin",
    "Umax",
    "Umin",
    "Xor",
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


def _camel_to_snake(name: str) -> str:
    pieces: list[str] = []
    for i, ch in enumerate(name):
        cond = not name[i - 1].isupper() or (i + 1 < len(name) and name[i + 1].islower())
        if i and ch.isupper() and cond:
            pieces.append("_")
        pieces.append(ch.lower())
    return "".join(pieces)


def _infer_variant_constraints(transfer_op: str, stem: str) -> frozenset[str]:
    snake = _camel_to_snake(stem)
    if snake.endswith("_nsw_nuw"):
        return frozenset({f"{transfer_op}_nsw", f"{transfer_op}_nuw"})
    if snake.endswith(("_disjoint", "_exact", "_nsw", "_nuw")):
        return frozenset({snake})
    return frozenset()


def _build_op_resolver(
    operations_dir: Path,
) -> dict[tuple[str, frozenset[str]], str]:
    resolver: dict[tuple[str, frozenset[str]], str] = {}
    for path in sorted(operations_dir.glob("*.mlir")):
        mod = parse_mlir_mod(path)
        concrete_op = get_fns(mod).get("concrete_op")
        if concrete_op is None:
            continue
        ops = [op for op in concrete_op.body.block.ops if not isinstance(op, ReturnOp)]
        if len(ops) != 1:
            continue
        op = ops[0]
        if not op.name.startswith("transfer."):
            continue
        transfer_op = op.name.removeprefix("transfer.")
        constraints = _infer_variant_constraints(
            transfer_op, path.stem
        ) | _BASE_CONSTRAINTS.get(transfer_op, frozenset())
        resolver[(transfer_op, constraints)] = path.stem
    return resolver


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
    resolver: dict[tuple[str, frozenset[str]], str],
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

    op_name = resolver.get((transfer_op, frozenset(constraints)))
    if op_name is not None:
        return op_name

    remaining = frozenset(constraints - base_constraints)
    expected = _TRANSFER_FLAG_TO_OP.get((transfer_op, remaining), base_name)
    raise ValueError(
        f"Could not resolve transfer op '{transfer_op}' with constraints "
        f"{sorted(constraints)} to '{expected}'."
    )


def load_pattern(pattern_path: Path) -> PatternDag:
    operations_dir = Path(__file__).resolve().parents[2] / "mlir" / "Operations"

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
    resolver = _build_op_resolver(operations_dir)
    node_ids = {op: i for i, op in enumerate(concrete_ops)}

    nodes: list[DagNode] = []
    for i, op in enumerate(concrete_ops):
        transfer_op = op.name.removeprefix("transfer.")
        operation = _resolve_operation(
            transfer_op, constraints_by_node.get(i, set()), resolver
        )
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

    dag = load_pattern(pattern_path)
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


def _load_op_data(
    data_dir: Path, domain: AbstractDomain, op: str, bw: int
) -> tuple[int, pd.DataFrame]:
    path = data_dir / str(domain) / f"{op}.tsv"
    if not path.exists():
        raise FileNotFoundError(f"Missing data file '{path}'.")
    with path.open() as f:
        data = EnumData.read_tsv(f)
    return data.metadata.arity, cast(
        pd.DataFrame, data.enumdata[data.enumdata["bw"] == bw].copy()
    )


def _append_unique(dst: list[str], src: pd.Series) -> None:
    seen = set(dst)
    for value in cast(list[str], src.astype(str).tolist()):
        if value not in seen:
            seen.add(value)
            dst.append(value)


def _collect_pattern_arg_values(
    dag: PatternDag,
    op_tables: dict[str, tuple[int, pd.DataFrame]],
) -> dict[str, list[str]]:
    arg_values = {arg: [] for arg in dag.args}

    for node in dag.nodes:
        arity, frame = op_tables[node.operation]
        for operand_index, operand in enumerate(node.operands):
            if operand not in arg_values:
                continue
            # A pattern arg may appear in multiple operand positions across the DAG.
            # We intentionally use the union of all matching operand domains here.
            positions = (
                range(arity) if node.operation in _COMMUTATIVE_OPS else (operand_index,)
            )
            for position in positions:
                column = f"arg_{position}"
                if column not in frame.columns:
                    raise ValueError(
                        f"Data for op '{node.operation}' is missing column '{column}'."
                    )
                _append_unique(arg_values[operand], cast(pd.Series, frame[column]))

    return arg_values


def _decode_index(index: int, domains: list[list[str]]) -> tuple[str, ...]:
    result = ["" for _ in domains]
    for i in range(len(domains) - 1, -1, -1):
        result[i] = domains[i][index % len(domains[i])]
        index //= len(domains[i])
    return tuple(result)


def _rows_for_bw(
    dag: PatternDag,
    domain: AbstractDomain,
    bw_spec: tuple[int, int | None],
    data_dir: Path,
    rng: Random,
) -> list[tuple[object, ...]]:
    bw, samples = bw_spec
    op_tables = {
        node.operation: _load_op_data(data_dir, domain, node.operation, bw)
        for node in dag.nodes
    }
    arg_values = _collect_pattern_arg_values(dag, op_tables)
    domains = [arg_values[arg] for arg in dag.args]
    total = 1
    for values in domains:
        total *= len(values)

    if samples is None:
        rows = product(*domains)
    else:
        if samples > total:
            raise ValueError(
                f"Requested {samples} samples for bw={bw}, but only {total} inputs exist."
            )
        rows = (_decode_index(i, domains) for i in rng.sample(range(total), samples))
    return [(bw, *values, "(bottom)") for values in rows]


def generate_inputs(
    path: Path,
    domain: AbstractDomain,
    bw_specs: list[tuple[int, int | None]],
    data_dir: Path,
    rng: Random,
) -> EnumData:
    if domain not in (
        AbstractDomain.KnownBits,
        AbstractDomain.UConstRange,
        AbstractDomain.SConstRange,
    ):
        raise NotImplementedError(
            f"generate input not implemented for domain '{domain}'."
        )

    dag = load_pattern(path)
    rows: list[tuple[object, ...]] = []
    hbw: list[tuple[int, int, int]] = []
    seen: set[int] = set()
    for spec in sorted(bw_specs, key=lambda spec: spec[0]):
        bw, _ = spec
        if bw in seen:
            raise ValueError(f"Duplicate bw spec for bw={bw}.")
        seen.add(bw)
        bw_rows = _rows_for_bw(dag, domain, spec, data_dir, rng)
        rows.extend(bw_rows)
        hbw.append((bw, len(bw_rows), 0))

    metadata = EnumMetaData(
        domain=domain,
        op=f"pattern_{path.stem}",
        arity=len(dag.args),
        seed=None,
        lbw=[],
        mbw=[],
        hbw=hbw,
    )
    df = pd.DataFrame.from_records(
        rows,
        columns=["bw"] + [f"arg_{i}" for i in range(len(dag.args))] + ["ideal"],
    )

    return EnumData(metadata, df)
