from __future__ import annotations

from io import StringIO
from pathlib import Path

from xdsl.dialects.func import FuncOp, ReturnOp
from xdsl.ir import Block, BlockArgument, Operation, Region, SSAValue
from xdsl.printer import Printer
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


def dag_to_mlir_program(dag: DAG) -> str:
    """Convert a DAG into the MLIR code that it represents.

    Recovers the original FuncOp by navigating up the xdsl IR from any vertex
    that carries a non-None mlir_op, then uses xdsl's Printer to serialise it.
    Raises ValueError if no vertex with an attached mlir_op can be found.
    """

    func_op: FuncOp | None = None
    for v in iter_vertices(dag.root):
        if v.mlir_op is None:
            continue
        mlir_op = v.mlir_op

        # Resolve the containing Block.
        if isinstance(mlir_op, BlockArgument):
            block: Block | None = mlir_op.block
        else:
            block = mlir_op.parent

        if block is None:
            continue

        # Block → Region → parent Operation (FuncOp).
        region: Region | None = block.parent
        if region is None:
            continue

        parent = region.parent
        if isinstance(parent, FuncOp):
            func_op = parent
            break

    if func_op is None:
        raise ValueError(
            "dag_to_mlir_program: no vertex with an attached mlir_op found; "
            "cannot recover the original FuncOp"
        )

    output = StringIO()
    Printer(stream=output).print_op(func_op)
    return output.getvalue()


def pattern_to_mlir_program(pattern: DAG, program_dags: dict[str, DAG]) -> str:
    """Synthesise a valid MLIR function for a pattern DAG.

    Pattern DAGs carry no type information, so a concrete match is found in
    `program_dags` to borrow types and attributes from.  The returned function
    contains exactly the matched subgraph; pattern leaves become function
    arguments.
    """
    from io import StringIO

    from xdsl.ir import BlockArgument as BA
    from xdsl.printer import Printer

    from agent.stitch.matcher import match_with_all_bindings

    # ------------------------------------------------------------------ #
    # 1. Find one concrete binding: {id(pattern_vertex) -> program_vertex} #
    # ------------------------------------------------------------------ #
    binding: dict[int, Vertex] | None = None
    for dag in program_dags.values():
        hits = match_with_all_bindings(dag, pattern)
        if hits:
            binding = hits[0]
            break

    if binding is None:
        raise ValueError("pattern_to_mlir_program: pattern matches no program DAG")

    # ------------------------------------------------------------------ #
    # 2. Walk pattern in post-order; collect leaves and internals          #
    # ------------------------------------------------------------------ #
    seen: set[int] = set()
    postorder: list[Vertex] = []

    def _walk(v: Vertex) -> None:
        if id(v) in seen:
            return
        seen.add(id(v))
        for arg in v.args:
            _walk(arg)
        postorder.append(v)

    _walk(pattern.root)

    leaves = [v for v in postorder if v.opcode == Opcode.leaf()]
    internals = [v for v in postorder if v.opcode != Opcode.leaf()]

    # ------------------------------------------------------------------ #
    # 3. Assign SSA names (keyed by PATTERN vertex id)                   #
    # ------------------------------------------------------------------ #
    # Keying by pattern vertex id (not program vertex id) ensures each
    # pattern vertex gets a unique name even when multiple pattern vertices
    # bind to the same program vertex (e.g. get_all_ones called 3× on the
    # same arg all map to one program op — the old program-vertex key caused
    # them to overwrite each other, producing duplicate SSA names).
    name: dict[int, str] = {}  # id(pattern_vertex) → SSA name
    arg_counter = 0
    val_counter = 0
    for pv in postorder:
        if pv.opcode == Opcode.leaf():
            name[id(pv)] = f"%arg{arg_counter}"
            arg_counter += 1
        else:
            name[id(pv)] = f"%{val_counter}"
            val_counter += 1

    # ------------------------------------------------------------------ #
    # 4. Helper: print a single xdsl Attribute to a string                #
    # ------------------------------------------------------------------ #
    def _attr_str(attr: object) -> str:
        out = StringIO()
        Printer(stream=out).print_attribute(attr)  # type: ignore[arg-type]
        return out.getvalue()

    def _result_type(prog_v: Vertex) -> str:
        op = prog_v.mlir_op
        if op is None:
            raise ValueError("program vertex has no mlir_op")
        if isinstance(op, BA):
            return _attr_str(op.type)
        return _attr_str(op.results[0].type)

    # ------------------------------------------------------------------ #
    # 5. Build function signature                                          #
    # ------------------------------------------------------------------ #
    arg_parts = [f"{name[id(lv)]} : {_result_type(binding[id(lv)])}" for lv in leaves]
    root_prog = binding[id(pattern.root)]
    ret_type = _result_type(root_prog)

    lines: list[str] = [f"func.func @pattern({', '.join(arg_parts)}) -> {ret_type} {{"]

    # ------------------------------------------------------------------ #
    # 6. Emit body ops                                                     #
    # ------------------------------------------------------------------ #
    for pat_v in internals:
        prog_v = binding[id(pat_v)]
        op = prog_v.mlir_op
        if op is None or isinstance(op, BA):
            raise ValueError("internal pattern vertex missing Operation mlir_op")

        result_name = name[id(pat_v)]
        result_type = _result_type(prog_v)
        operand_names = ", ".join(name[id(a)] for a in pat_v.args)
        operand_types = ", ".join(_result_type(binding[id(a)]) for a in pat_v.args)

        # Attributes + properties (xdsl keeps them in separate dicts)
        all_attrs = dict(op.attributes) | dict(op.properties)
        if all_attrs:
            attr_out = StringIO()
            Printer(stream=attr_out).print_attr_dict(all_attrs)
            attrs_part = f" {attr_out.getvalue()}"
        else:
            attrs_part = ""

        lines.append(
            f'  {result_name} = "{op.name}"({operand_names}){attrs_part}'
            f" : ({operand_types}) -> {result_type}"
        )

    # ------------------------------------------------------------------ #
    # 7. Return and close                                                  #
    # ------------------------------------------------------------------ #
    root_name = name[id(pattern.root)]
    lines.append(f"  func.return {root_name} : {ret_type}")
    lines.append("}")

    return "\n".join(lines)


def dag_vertices(dag: DAG) -> list[Vertex]:
    """Convenience helper for callers that want all vertices in a DAG."""

    return iter_vertices(dag.root)


def dag_to_mlir_ops(dag: DAG) -> list[Operation | BlockArgument]:
    """Recover MLIR ops/block-args captured while building the DAG."""

    return [v.mlir_op for v in dag_vertices(dag) if v.mlir_op is not None]
