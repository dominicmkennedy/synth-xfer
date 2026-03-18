from __future__ import annotations

from pathlib import Path

from xdsl.dialects.func import FuncOp, ReturnOp
from xdsl.ir import BlockArgument, Operation, SSAValue
from xdsl_smt.dialects.transfer import Constant as ConstantOp

from agent.stitch.util import DAG, Opcode, Vertex, iter_vertices
from synth_xfer._util.parse_mlir import parse_mlir_mod


def _new_vertex_for_op(op: Operation, args: list[Vertex], result_index: int) -> Vertex:
    _ = result_index
    return Vertex(opcode=Opcode.from_mlir_op(op), args=args, mlir_op=op)


def func_to_dag(func: FuncOp) -> DAG:
    """Convert a single MLIR function into a single-root DAG."""

    value_to_vertex: dict[SSAValue, Vertex] = {}

    for arg in func.args:
        value_to_vertex[arg] = Vertex(
            opcode=Opcode.from_mlir_op(arg),
            args=[],
            mlir_op=arg,
        )

    root: Vertex | None = None
    for block in func.body.blocks:
        for op in block.ops:
            if isinstance(op, ReturnOp):
                # Assume one returned value and one DAG root.
                returned = op.operands[0]
                root = value_to_vertex[returned]
                continue

            op_args: list[Vertex] = []
            if not isinstance(op, ConstantOp):
                for operand in op.operands:
                    node = value_to_vertex.get(operand)
                    if node is None:
                        if isinstance(operand, BlockArgument):
                            node = Vertex(
                                opcode=Opcode.from_mlir_op(operand),
                                mlir_op=operand,
                            )
                        else:
                            owner = operand.owner
                            assert isinstance(owner, Operation)
                            node = Vertex(
                                opcode=Opcode.from_mlir_op(owner),
                                mlir_op=owner,
                            )
                        value_to_vertex[operand] = node
                    op_args.append(node)

            for result_idx, result in enumerate(op.results):
                value_to_vertex[result] = _new_vertex_for_op(op, op_args, result_idx)

    if root is None:
        root = next(reversed(value_to_vertex.values()))

    return DAG(root=root)


def mlir_program_to_dags(program_or_path: str | Path) -> dict[str, DAG]:
    """Parse an MLIR module and return one DAG per function name."""

    source: str | Path
    source = program_or_path
    if isinstance(program_or_path, Path):
        source = program_or_path.read_text()

    module = parse_mlir_mod(source)

    dags: dict[str, DAG] = {}
    for op in module.ops:
        if isinstance(op, FuncOp):
            dags[op.sym_name.data] = func_to_dag(op)

    return dags


def mlir_program_to_single_dag(program_or_path: str | Path) -> DAG:
    """Parse and return the DAG of the first function in the module."""

    dags = mlir_program_to_dags(program_or_path)
    if not dags:
        raise ValueError("no FuncOp found in MLIR program")
    return next(iter(dags.values()))


def dag_vertices(dag: DAG) -> list[Vertex]:
    """Convenience helper for callers that want all vertices in a DAG."""

    return iter_vertices(dag.root)


def dag_to_mlir_ops(dag: DAG) -> list[Operation | BlockArgument]:
    """Recover MLIR ops/block-args captured while building the DAG."""

    return [v.mlir_op for v in dag_vertices(dag) if v.mlir_op is not None]
