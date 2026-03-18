from __future__ import annotations

from dataclasses import dataclass, field

from xdsl.dialects.func import CallOp
from xdsl.ir import BlockArgument, Operation
from xdsl_smt.dialects.transfer import CmpOp, Constant as ConstantOp, GetOp


def _int_attr_value(op: Operation, attr_name: str) -> int | None:
    attr = op.attributes.get(attr_name)
    if attr is None:
        return None

    # xdsl IntegerAttr[IndexType] value shape: attr.value.data
    value = getattr(attr, "value", None)
    data = getattr(value, "data", None)
    if isinstance(data, int):
        return data

    return None


@dataclass(frozen=True)
class Opcode:
    """Node kind used by DAG matching.

    Two vertices with equal `Opcode` are considered the same node kind.
    """

    key: str
    arity: int

    @staticmethod
    def leaf() -> Opcode:
        return Opcode("leaf", 0)

    @staticmethod
    def from_mlir_op(mlir_op: Operation | BlockArgument) -> Opcode:
        if isinstance(mlir_op, BlockArgument):
            return Opcode("block_argument", 0)

        arity = len(mlir_op.operands)

        if isinstance(mlir_op, ConstantOp):
            cst = _int_attr_value(mlir_op, "value")
            if cst is not None:
                return Opcode(f"{mlir_op.name}[{cst}]", 0)

        if isinstance(mlir_op, GetOp):
            index = _int_attr_value(mlir_op, "index")
            if index is not None:
                return Opcode(f"{mlir_op.name}[{index}]", arity)

        if isinstance(mlir_op, CmpOp):
            pred = _int_attr_value(mlir_op, "predicate")
            if pred is not None:
                return Opcode(f"{mlir_op.name}[{pred}]", arity)

        if isinstance(mlir_op, CallOp):
            callee = mlir_op.callee.string_value()
            return Opcode(f"{mlir_op.name}[{callee}]", arity)

        return Opcode(mlir_op.name, arity)


@dataclass(eq=False)
class Vertex:
    """A DAG node used for MLIR pattern matching.

    `opcode` must be inferred from `mlir_op`, except synthetic wildcard nodes such as
    `Opcode.leaf()` used in patterns.
    """

    opcode: Opcode
    args: list[Vertex] = field(default_factory=list)
    mlir_op: Operation | BlockArgument | None = None


def _clone_subtree(
    v: Vertex,
    memo: dict[int, Vertex],
    subst: tuple[int, Vertex] | None = None,
) -> Vertex:
    if subst is not None and id(v) == subst[0]:
        return _clone_subtree(subst[1], memo)
    key = id(v)
    if key in memo:
        return memo[key]
    copied = Vertex(opcode=v.opcode, mlir_op=v.mlir_op)
    memo[key] = copied
    copied.args = [_clone_subtree(arg, memo, subst) for arg in v.args]
    return copied


class DAG:
    """A directed acyclic graph represented by a single root."""

    root: Vertex

    def __init__(self, root: Vertex) -> None:
        self.root = root
        self.inst_count = sum(1 for v in iter_vertices(root) if v.opcode != Opcode.leaf())

    def clone(self) -> DAG:
        return DAG(root=_clone_subtree(self.root, {}))

    def __str__(self) -> str:
        leaf_name: dict[int, str] = {}
        var_name: dict[int, str] = {}
        stmts: list[str] = []
        leaf_ctr = [0]
        var_ctr = [0]

        def name_of(v: Vertex) -> str:
            vid = id(v)
            if v.opcode == Opcode.leaf():
                if vid not in leaf_name:
                    leaf_name[vid] = f"_{leaf_ctr[0]}"
                    leaf_ctr[0] += 1
                return leaf_name[vid]
            return var_name[vid]

        def visit(v: Vertex) -> None:
            vid = id(v)
            if vid in var_name or vid in leaf_name:
                return
            if v.opcode == Opcode.leaf():
                leaf_name[vid] = f"_{leaf_ctr[0]}"
                leaf_ctr[0] += 1
                return
            for arg in v.args:
                visit(arg)
            lhs = f"%{var_ctr[0]}"
            var_ctr[0] += 1
            var_name[vid] = lhs
            arg_names = ", ".join(name_of(a) for a in v.args)
            stmts.append(f"  {lhs} = {v.opcode.key}({arg_names})")

        visit(self.root)

        params = ", ".join(leaf_name.values())
        ret = name_of(self.root)
        header = f"def f({params}):"
        body = "\n".join(stmts)
        return f"{header}\n{body}\n  return {ret}"

    def clone_with_substitution(self, target: Vertex, replacement: Vertex) -> DAG:
        """Clone this DAG, replacing every occurrence of `target` (by identity)
        with an independent deep-cloned copy of `replacement`.

        `target` must be a leaf node (args == []).
        """
        return DAG(root=_clone_subtree(self.root, {}, subst=(id(target), replacement)))


def iter_vertices(root: Vertex) -> list[Vertex]:
    """Return all vertices reachable from root in top-down order."""

    seen: set[int] = set()
    ordered: list[Vertex] = []

    def visit(v: Vertex) -> None:
        key = id(v)
        if key in seen:
            return
        seen.add(key)
        ordered.append(v)
        for arg in v.args:
            visit(arg)

    visit(root)

    return ordered
