from collections.abc import Callable
from dataclasses import dataclass
from enum import StrEnum
import re
from typing import cast

from xdsl.dialects.arith import AndIOp
from xdsl.dialects.builtin import i1
from xdsl.dialects.func import CallOp, FuncOp, ReturnOp
from xdsl.ir import Attribute, Operation, SSAValue
from xdsl_smt.dialects.transfer import (
    AbsOp,
    AddOp,
    AndOp,
    AShrOp,
    CmpOp,
    CountLZeroOp,
    CountRZeroOp,
    LShrOp,
    MulOp,
    OrOp,
    PopCountOp,
    SDivOp,
    SelectOp,
    SextBoolOp,
    ShlOp,
    SMaxOp,
    SMinOp,
    SRemOp,
    SubOp,
    TransIntegerType,
    TruncToBoolOp,
    UDivOp,
    UMaxOp,
    UMinOp,
    URemOp,
    XorOp,
    ZextBoolOp,
)


class PatternOp(StrEnum):
    Add = "Add"
    AddNsw = "AddNsw"
    AddNuw = "AddNuw"
    AddNswNuw = "AddNswNuw"
    And = "And"
    Ashr = "Ashr"
    AshrExact = "AshrExact"
    Lshr = "Lshr"
    LshrExact = "LshrExact"
    Mul = "Mul"
    MulNsw = "MulNsw"
    MulNuw = "MulNuw"
    MulNswNuw = "MulNswNuw"
    Or = "Or"
    OrDisjoint = "OrDisjoint"
    Sdiv = "Sdiv"
    SdivExact = "SdivExact"
    Shl = "Shl"
    ShlNsw = "ShlNsw"
    ShlNuw = "ShlNuw"
    ShlNswNuw = "ShlNswNuw"
    Mods = "Mods"
    Sub = "Sub"
    SubNsw = "SubNsw"
    SubNuw = "SubNuw"
    SubNswNuw = "SubNswNuw"
    Udiv = "Udiv"
    UdivExact = "UdivExact"
    Modu = "Modu"
    Xor = "Xor"
    Umax = "Umax"
    Umin = "Umin"
    Smax = "Smax"
    Smin = "Smin"
    PopCount = "PopCount"
    CountLZero = "CountLZero"
    CountLZeroUndef = "CountLZeroUndef"
    CountRZero = "CountRZero"
    CountRZeroUndef = "CountRZeroUndef"
    Select = "Select"
    ICmpEq = "ICmpEq"
    ICmpNe = "ICmpNe"
    ICmpSlt = "ICmpSlt"
    ICmpSle = "ICmpSle"
    ICmpSgt = "ICmpSgt"
    ICmpSge = "ICmpSge"
    ICmpUlt = "ICmpUlt"
    ICmpUle = "ICmpUle"
    ICmpUgt = "ICmpUgt"
    ICmpUge = "ICmpUge"
    Abs = "Abs"
    AbsUndef = "AbsUndef"
    TruncToBool = "TruncToBool"
    ZextBool = "ZextBool"
    SextBool = "SextBool"
    SaddSat = "SaddSat"
    UaddSat = "UaddSat"
    SsubSat = "SsubSat"
    UsubSat = "UsubSat"
    SmulSat = "SmulSat"
    UmulSat = "UmulSat"
    SshlSat = "SshlSat"
    UshlSat = "UshlSat"

    @property
    def spec(self) -> "OpSpec":
        try:
            return _OP_SPECS[self]
        except KeyError as exc:
            raise ValueError(f"Operation '{self.value}' is not supported yet.") from exc

    def build(self, operands: tuple[SSAValue, ...]) -> Operation:
        return self.spec.build(operands)


COMMUTATIVE_OPS: frozenset[PatternOp] = frozenset(
    {
        PatternOp.Add,
        PatternOp.AddNsw,
        PatternOp.AddNuw,
        PatternOp.AddNswNuw,
        PatternOp.And,
        PatternOp.Mul,
        PatternOp.MulNsw,
        PatternOp.MulNuw,
        PatternOp.MulNswNuw,
        PatternOp.Or,
        PatternOp.OrDisjoint,
        PatternOp.SaddSat,
        PatternOp.SmulSat,
        PatternOp.UaddSat,
        PatternOp.UmulSat,
        PatternOp.Xor,
        PatternOp.Umax,
        PatternOp.Umin,
        PatternOp.Smax,
        PatternOp.Smin,
        PatternOp.ICmpEq,
        PatternOp.ICmpNe,
    },
)

_CANONICAL_ICMP_SWAPS: dict[PatternOp, PatternOp] = {
    PatternOp.ICmpSgt: PatternOp.ICmpSlt,
    PatternOp.ICmpSge: PatternOp.ICmpSle,
    PatternOp.ICmpUgt: PatternOp.ICmpUlt,
    PatternOp.ICmpUge: PatternOp.ICmpUle,
}


def canonicalize_pattern_operands[T](
    op: PatternOp,
    operands: tuple[T, ...],
    key: Callable[[T], str],
) -> tuple[PatternOp, tuple[T, ...]]:
    if op in COMMUTATIVE_OPS:
        return op, tuple(sorted(operands, key=key))

    if op in _CANONICAL_ICMP_SWAPS and len(operands) == 2:
        return _CANONICAL_ICMP_SWAPS[op], (operands[1], operands[0])

    return op, operands


@dataclass(frozen=True, slots=True)
class ArgRef:
    index: int


@dataclass(frozen=True, slots=True)
class NodeRef:
    index: int


PatternRef = ArgRef | NodeRef


@dataclass(frozen=True, slots=True)
class PatternNode:
    op: PatternOp
    operands: tuple[PatternRef, ...]


@dataclass(slots=True)
class PatternDag:
    num_args: int
    arg_types: tuple[Attribute, ...]
    nodes: tuple[PatternNode, ...]
    result: NodeRef

    @classmethod
    def from_parts(
        cls,
        arg_types: tuple[Attribute, ...],
        nodes: tuple[PatternNode, ...],
        result: NodeRef,
    ) -> "PatternDag":
        dag = cls.__new__(cls)
        dag.arg_types = arg_types
        dag.nodes = nodes
        dag.result = result
        dag.num_args = len(arg_types)
        return dag

    def is_op(self) -> bool:
        if len(self.nodes) == 1:
            node = self.nodes[self.result.index]
            if node.operands == tuple(ArgRef(i) for i in range(self.num_args)):
                return True

        return False

    def __str__(self) -> str:
        if self.is_op():
            return self.nodes[self.result.index].op.value

        def render_key(node: object) -> str:
            if isinstance(node, ArgRef):
                return f"arg{node.index}"
            node = cast(tuple[PatternOp, tuple[object, ...]], node)
            op, operands = node
            return f"{op.value}({', '.join(render_key(operand) for operand in operands)})"

        def canonicalize_ref(ref: PatternRef) -> object:
            if isinstance(ref, ArgRef):
                return ref
            node = self.nodes[ref.index]
            operands = tuple(canonicalize_ref(operand) for operand in node.operands)
            op, operands = canonicalize_pattern_operands(
                node.op,
                operands,
                key=render_key,
            )

            return op, operands

        arg_map: dict[int, int] = {}

        def render_canonical(node: object) -> str:
            if isinstance(node, ArgRef):
                return _format_alpha_pattern_ref(node, arg_map)

            node = cast(tuple[PatternOp, tuple[object, ...]], node)
            op, operands = node
            return (
                f"{op.value}"
                f"({', '.join(render_canonical(operand) for operand in operands)})"
            )

        return render_canonical(canonicalize_ref(self.result))

    def to_id(self) -> str:
        expression = str(self)
        reparsed = type(self)(expression)
        if reparsed.is_op():
            expression = str(reparsed)

        ident = re.sub(r"[\s,()]+", "_", expression).strip("_")
        if len(ident) > 251:
            raise ValueError(
                f"pattern too long to encode as a .inc filename "
                f"({len(ident)} > 251 chars): {self!s}"
            )
        return ident

    @classmethod
    def from_id(cls, pattern_id: str) -> "PatternDag":
        tokens = pattern_id.split("_")
        pos = 0

        if len(tokens) == 1 and re.fullmatch(r"arg\d+", tokens[0]) is None:
            try:
                return cls.single_node(PatternOp(tokens[0]))
            except ValueError as exc:
                raise ValueError(f"unknown op token {tokens[0]!r}") from exc

        def build() -> str:
            nonlocal pos

            if pos >= len(tokens):
                raise ValueError(f"truncated pattern id: {pattern_id!r}")

            token = tokens[pos]
            pos += 1

            if re.fullmatch(r"arg\d+", token):
                return token

            try:
                op = PatternOp(token)
            except ValueError as exc:
                raise ValueError(
                    f"unknown op token {token!r} in pattern id {pattern_id!r}"
                ) from exc

            operands = [build() for _ in op.spec.operand_types]
            return f"{op.value}({', '.join(operands)})"

        expr = build()
        if pos != len(tokens):
            trailing = "_".join(tokens[pos:])
            raise ValueError(
                f"trailing tokens in pattern id {pattern_id!r}: {trailing!r}"
            )
        return cls(expr)

    def __init__(self, expr: str) -> None:
        self.arg_types, self.nodes, self.result = _PatternExprParser(expr).parse()
        self.num_args = len(self.arg_types)

    @classmethod
    def single_node(cls, op: PatternOp) -> "PatternDag":
        return cls.from_parts(
            op.spec.operand_types,
            (
                PatternNode(
                    op,
                    tuple(ArgRef(index) for index in range(len(op.spec.operand_types))),
                ),
            ),
            NodeRef(0),
        )

    def arg_depths(self) -> dict[ArgRef, int]:
        depths: dict[ArgRef, int] = {}

        def visit(ref: PatternRef, level: int) -> None:
            if isinstance(ref, ArgRef):
                depths[ref] = min(depths.get(ref, level), level)
                return

            node = self.nodes[ref.index]
            for operand in node.operands:
                visit(operand, level + 1)

        visit(self.result, 0)
        return depths

    def subdag_with_cut(
        self,
        root: PatternRef,
        cut: tuple[NodeRef, int] | None = None,
    ) -> tuple["PatternDag", tuple[PatternRef, ...], int | None]:
        arg_types: list[Attribute] = []
        arg_sources: list[PatternRef] = []
        arg_map: dict[ArgRef, ArgRef] = {}
        node_map: dict[NodeRef, NodeRef] = {}
        nodes: list[PatternNode] = []
        cut_arg_index: int | None = None

        def add_arg(source: PatternRef, ty: Attribute) -> ArgRef:
            ref = ArgRef(len(arg_types))
            arg_types.append(ty)
            arg_sources.append(source)
            return ref

        def lower_ref(ref: PatternRef) -> PatternRef:
            nonlocal cut_arg_index

            if isinstance(ref, ArgRef):
                lowered = arg_map.get(ref)
                if lowered is None:
                    lowered = add_arg(ref, self.arg_types[ref.index])
                    arg_map[ref] = lowered
                return lowered

            lowered_node = node_map.get(ref)
            if lowered_node is not None:
                return lowered_node

            node = self.nodes[ref.index]
            lowered_operands: list[PatternRef] = []
            for operand_index, operand in enumerate(node.operands):
                if cut == (ref, operand_index):
                    cut_arg = add_arg(operand, node.op.spec.operand_types[operand_index])
                    cut_arg_index = cut_arg.index
                    lowered_operands.append(cut_arg)
                else:
                    lowered_operands.append(lower_ref(operand))

            lowered_node = NodeRef(len(nodes))
            node_map[ref] = lowered_node
            nodes.append(PatternNode(node.op, tuple(lowered_operands)))
            return lowered_node

        lowered_root = lower_ref(root)
        if isinstance(lowered_root, ArgRef):
            raise ValueError("sub-DAG root must be an operation result")

        return (
            PatternDag.from_parts(tuple(arg_types), tuple(nodes), lowered_root),
            tuple(arg_sources),
            cut_arg_index,
        )


@dataclass(frozen=True, slots=True)
class OpSpec:
    operand_types: tuple[Attribute, ...]
    result_type: Attribute
    op_cls: type[Operation] | None = None
    constraints: tuple[str, ...] = ()
    cmp_pred: str | None = None
    impl_helper: str | None = None

    def build(self, operands: tuple[SSAValue, ...]) -> Operation:
        if self.cmp_pred is not None:
            return CmpOp(operands[0], operands[1], self.cmp_pred)
        if self.impl_helper is not None:
            return CallOp(self.impl_helper, operands, [self.result_type])
        assert self.op_cls is not None
        return self.op_cls(*operands)


_iN = TransIntegerType()

_OP_SPECS: dict[PatternOp, OpSpec] = {
    PatternOp.Add: OpSpec((_iN, _iN), _iN, AddOp),
    PatternOp.AddNsw: OpSpec((_iN, _iN), _iN, AddOp, constraints=("add_nsw",)),
    PatternOp.AddNuw: OpSpec((_iN, _iN), _iN, AddOp, constraints=("add_nuw",)),
    PatternOp.AddNswNuw: OpSpec(
        (_iN, _iN), _iN, AddOp, constraints=("add_nsw", "add_nuw")
    ),
    PatternOp.And: OpSpec((_iN, _iN), _iN, AndOp),
    PatternOp.Ashr: OpSpec((_iN, _iN), _iN, AShrOp, constraints=("shift_lt_bw",)),
    PatternOp.AshrExact: OpSpec(
        (_iN, _iN), _iN, AShrOp, constraints=("ashr_exact", "shift_lt_bw")
    ),
    PatternOp.Lshr: OpSpec((_iN, _iN), _iN, LShrOp, constraints=("shift_lt_bw",)),
    PatternOp.LshrExact: OpSpec(
        (_iN, _iN), _iN, LShrOp, constraints=("lshr_exact", "shift_lt_bw")
    ),
    PatternOp.Mul: OpSpec((_iN, _iN), _iN, MulOp),
    PatternOp.MulNsw: OpSpec((_iN, _iN), _iN, MulOp, constraints=("mul_nsw",)),
    PatternOp.MulNuw: OpSpec((_iN, _iN), _iN, MulOp, constraints=("mul_nuw",)),
    PatternOp.MulNswNuw: OpSpec(
        (_iN, _iN), _iN, MulOp, constraints=("mul_nsw", "mul_nuw")
    ),
    PatternOp.Or: OpSpec((_iN, _iN), _iN, OrOp),
    PatternOp.OrDisjoint: OpSpec((_iN, _iN), _iN, OrOp, constraints=("or_disjoint",)),
    PatternOp.Sdiv: OpSpec(
        (_iN, _iN), _iN, SDivOp, constraints=("rhs_neq_zero", "no_sdiv_ov")
    ),
    PatternOp.SdivExact: OpSpec(
        (_iN, _iN),
        _iN,
        SDivOp,
        constraints=("sdiv_exact", "rhs_neq_zero", "no_sdiv_ov"),
    ),
    PatternOp.Shl: OpSpec((_iN, _iN), _iN, ShlOp, constraints=("shift_lt_bw",)),
    PatternOp.ShlNsw: OpSpec(
        (_iN, _iN), _iN, ShlOp, constraints=("shl_nsw", "shift_lt_bw")
    ),
    PatternOp.ShlNuw: OpSpec(
        (_iN, _iN), _iN, ShlOp, constraints=("shl_nuw", "shift_lt_bw")
    ),
    PatternOp.ShlNswNuw: OpSpec(
        (_iN, _iN),
        _iN,
        ShlOp,
        constraints=("shl_nsw", "shl_nuw", "shift_lt_bw"),
    ),
    PatternOp.Mods: OpSpec(
        (_iN, _iN), _iN, SRemOp, constraints=("rhs_neq_zero", "no_sdiv_ov")
    ),
    PatternOp.Sub: OpSpec((_iN, _iN), _iN, SubOp),
    PatternOp.SubNsw: OpSpec((_iN, _iN), _iN, SubOp, constraints=("sub_nsw",)),
    PatternOp.SubNuw: OpSpec((_iN, _iN), _iN, SubOp, constraints=("sub_nuw",)),
    PatternOp.SubNswNuw: OpSpec(
        (_iN, _iN), _iN, SubOp, constraints=("sub_nsw", "sub_nuw")
    ),
    PatternOp.Udiv: OpSpec((_iN, _iN), _iN, UDivOp, constraints=("rhs_neq_zero",)),
    PatternOp.UdivExact: OpSpec(
        (_iN, _iN), _iN, UDivOp, constraints=("udiv_exact", "rhs_neq_zero")
    ),
    PatternOp.Modu: OpSpec((_iN, _iN), _iN, URemOp, constraints=("rhs_neq_zero",)),
    PatternOp.Xor: OpSpec((_iN, _iN), _iN, XorOp),
    PatternOp.Umax: OpSpec((_iN, _iN), _iN, UMaxOp),
    PatternOp.Umin: OpSpec((_iN, _iN), _iN, UMinOp),
    PatternOp.Smax: OpSpec((_iN, _iN), _iN, SMaxOp),
    PatternOp.Smin: OpSpec((_iN, _iN), _iN, SMinOp),
    PatternOp.SaddSat: OpSpec((_iN, _iN), _iN, impl_helper="sadd_sat"),
    PatternOp.UaddSat: OpSpec((_iN, _iN), _iN, impl_helper="uadd_sat"),
    PatternOp.SsubSat: OpSpec((_iN, _iN), _iN, impl_helper="ssub_sat"),
    PatternOp.UsubSat: OpSpec((_iN, _iN), _iN, impl_helper="usub_sat"),
    PatternOp.SmulSat: OpSpec((_iN, _iN), _iN, impl_helper="smul_sat"),
    PatternOp.UmulSat: OpSpec((_iN, _iN), _iN, impl_helper="umul_sat"),
    PatternOp.SshlSat: OpSpec(
        (_iN, _iN), _iN, constraints=("shift_lt_bw",), impl_helper="sshl_sat"
    ),
    PatternOp.UshlSat: OpSpec(
        (_iN, _iN), _iN, constraints=("shift_lt_bw",), impl_helper="ushl_sat"
    ),
    PatternOp.PopCount: OpSpec((_iN,), _iN, PopCountOp),
    PatternOp.CountLZero: OpSpec((_iN,), _iN, CountLZeroOp),
    PatternOp.CountLZeroUndef: OpSpec(
        (_iN,), _iN, CountLZeroOp, constraints=("nonzero",)
    ),
    PatternOp.CountRZero: OpSpec((_iN,), _iN, CountRZeroOp),
    PatternOp.CountRZeroUndef: OpSpec(
        (_iN,), _iN, CountRZeroOp, constraints=("nonzero",)
    ),
    PatternOp.Abs: OpSpec((_iN,), _iN, AbsOp),
    PatternOp.AbsUndef: OpSpec((_iN,), _iN, AbsOp, constraints=("not_intmin",)),
    PatternOp.TruncToBool: OpSpec((_iN,), i1, TruncToBoolOp),
    PatternOp.ZextBool: OpSpec((i1,), _iN, ZextBoolOp),
    PatternOp.SextBool: OpSpec((i1,), _iN, SextBoolOp),
    PatternOp.Select: OpSpec((i1, _iN, _iN), _iN, SelectOp),
    PatternOp.ICmpEq: OpSpec((_iN, _iN), i1, cmp_pred="eq"),
    PatternOp.ICmpNe: OpSpec((_iN, _iN), i1, cmp_pred="ne"),
    PatternOp.ICmpSlt: OpSpec((_iN, _iN), i1, cmp_pred="slt"),
    PatternOp.ICmpSle: OpSpec((_iN, _iN), i1, cmp_pred="sle"),
    PatternOp.ICmpSgt: OpSpec((_iN, _iN), i1, cmp_pred="sgt"),
    PatternOp.ICmpSge: OpSpec((_iN, _iN), i1, cmp_pred="sge"),
    PatternOp.ICmpUlt: OpSpec((_iN, _iN), i1, cmp_pred="ult"),
    PatternOp.ICmpUle: OpSpec((_iN, _iN), i1, cmp_pred="ule"),
    PatternOp.ICmpUgt: OpSpec((_iN, _iN), i1, cmp_pred="ugt"),
    PatternOp.ICmpUge: OpSpec((_iN, _iN), i1, cmp_pred="uge"),
}


OP_HELPERS: dict[str, str] = {
    "uadd_sat": """func.func @uadd_sat(%arg0: !transfer.integer, %arg1: !transfer.integer) -> !transfer.integer {
    %sum = "transfer.add"(%arg0, %arg1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %overflow = "transfer.uadd_overflow"(%arg0, %arg1) : (!transfer.integer, !transfer.integer) -> i1
    %uint_max = "transfer.get_all_ones"(%arg0) : (!transfer.integer) -> !transfer.integer
    %result = "transfer.select"(%overflow, %uint_max, %sum) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    return %result : !transfer.integer
  }""",
    "sadd_sat": """func.func @sadd_sat(%arg0: !transfer.integer, %arg1: !transfer.integer) -> !transfer.integer {
    %sum = "transfer.add"(%arg0, %arg1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %overflow = "transfer.sadd_overflow"(%arg0, %arg1) : (!transfer.integer, !transfer.integer) -> i1
    %zero = "transfer.constant"(%arg0) {value = 0 : i64} : (!transfer.integer) -> !transfer.integer
    %lhs_neg = "transfer.cmp"(%arg0, %zero) {predicate = 2 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %int_min = "transfer.get_signed_min_value"(%arg0) : (!transfer.integer) -> !transfer.integer
    %int_max = "transfer.get_signed_max_value"(%arg0) : (!transfer.integer) -> !transfer.integer
    %sat = "transfer.select"(%lhs_neg, %int_min, %int_max) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %result = "transfer.select"(%overflow, %sat, %sum) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    return %result : !transfer.integer
  }""",
    "usub_sat": """func.func @usub_sat(%arg0: !transfer.integer, %arg1: !transfer.integer) -> !transfer.integer {
    %diff = "transfer.sub"(%arg0, %arg1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %overflow = "transfer.usub_overflow"(%arg0, %arg1) : (!transfer.integer, !transfer.integer) -> i1
    %zero = "transfer.constant"(%arg0) {value = 0 : i64} : (!transfer.integer) -> !transfer.integer
    %result = "transfer.select"(%overflow, %zero, %diff) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    return %result : !transfer.integer
  }""",
    "ssub_sat": """func.func @ssub_sat(%arg0: !transfer.integer, %arg1: !transfer.integer) -> !transfer.integer {
    %diff = "transfer.sub"(%arg0, %arg1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %overflow = "transfer.ssub_overflow"(%arg0, %arg1) : (!transfer.integer, !transfer.integer) -> i1
    %zero = "transfer.constant"(%arg0) {value = 0 : i64} : (!transfer.integer) -> !transfer.integer
    %lhs_neg = "transfer.cmp"(%arg0, %zero) {predicate = 2 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %int_min = "transfer.get_signed_min_value"(%arg0) : (!transfer.integer) -> !transfer.integer
    %int_max = "transfer.get_signed_max_value"(%arg0) : (!transfer.integer) -> !transfer.integer
    %sat = "transfer.select"(%lhs_neg, %int_min, %int_max) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %result = "transfer.select"(%overflow, %sat, %diff) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    return %result : !transfer.integer
  }""",
    "umul_sat": """func.func @umul_sat(%arg0: !transfer.integer, %arg1: !transfer.integer) -> !transfer.integer {
    %product = "transfer.mul"(%arg0, %arg1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %overflow = "transfer.umul_overflow"(%arg0, %arg1) : (!transfer.integer, !transfer.integer) -> i1
    %uint_max = "transfer.get_all_ones"(%arg0) : (!transfer.integer) -> !transfer.integer
    %result = "transfer.select"(%overflow, %uint_max, %product) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    return %result : !transfer.integer
  }""",
    "smul_sat": """func.func @smul_sat(%arg0: !transfer.integer, %arg1: !transfer.integer) -> !transfer.integer {
    %product = "transfer.mul"(%arg0, %arg1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %overflow = "transfer.smul_overflow"(%arg0, %arg1) : (!transfer.integer, !transfer.integer) -> i1
    %zero = "transfer.constant"(%arg0) {value = 0 : i64} : (!transfer.integer) -> !transfer.integer
    %lhs_neg = "transfer.cmp"(%arg0, %zero) {predicate = 2 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %rhs_neg = "transfer.cmp"(%arg1, %zero) {predicate = 2 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %signs_differ = arith.xori %lhs_neg, %rhs_neg : i1
    %int_min = "transfer.get_signed_min_value"(%arg0) : (!transfer.integer) -> !transfer.integer
    %int_max = "transfer.get_signed_max_value"(%arg0) : (!transfer.integer) -> !transfer.integer
    %sat = "transfer.select"(%signs_differ, %int_min, %int_max) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %result = "transfer.select"(%overflow, %sat, %product) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    return %result : !transfer.integer
  }""",
    "ushl_sat": """func.func @ushl_sat(%arg0: !transfer.integer, %arg1: !transfer.integer) -> !transfer.integer {
    %shifted = "transfer.shl"(%arg0, %arg1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %overflow = "transfer.ushl_overflow"(%arg0, %arg1) : (!transfer.integer, !transfer.integer) -> i1
    %uint_max = "transfer.get_all_ones"(%arg0) : (!transfer.integer) -> !transfer.integer
    %result = "transfer.select"(%overflow, %uint_max, %shifted) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    return %result : !transfer.integer
  }""",
    "sshl_sat": """func.func @sshl_sat(%arg0: !transfer.integer, %arg1: !transfer.integer) -> !transfer.integer {
    %shifted = "transfer.shl"(%arg0, %arg1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %overflow = "transfer.sshl_overflow"(%arg0, %arg1) : (!transfer.integer, !transfer.integer) -> i1
    %zero = "transfer.constant"(%arg0) {value = 0 : i64} : (!transfer.integer) -> !transfer.integer
    %lhs_neg = "transfer.cmp"(%arg0, %zero) {predicate = 2 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %int_min = "transfer.get_signed_min_value"(%arg0) : (!transfer.integer) -> !transfer.integer
    %int_max = "transfer.get_signed_max_value"(%arg0) : (!transfer.integer) -> !transfer.integer
    %sat = "transfer.select"(%lhs_neg, %int_min, %int_max) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %result = "transfer.select"(%overflow, %sat, %shifted) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    return %result : !transfer.integer
  }""",
}


CONSTRAINT_HELPERS: dict[str, str] = {
    "add_nsw": """func.func @add_nsw(%arg0: !transfer.integer, %arg1: !transfer.integer) -> i1 {
    %sadd_ov = "transfer.sadd_overflow"(%arg0, %arg1) : (!transfer.integer, !transfer.integer) -> i1
    %true = arith.constant true
    %no_ov = arith.xori %sadd_ov, %true : i1
    return %no_ov : i1
  }""",
    "add_nuw": """func.func @add_nuw(%arg0: !transfer.integer, %arg1: !transfer.integer) -> i1 {
    %uadd_ov = "transfer.uadd_overflow"(%arg0, %arg1) : (!transfer.integer, !transfer.integer) -> i1
    %true = arith.constant true
    %no_ov = arith.xori %uadd_ov, %true : i1
    return %no_ov : i1
  }""",
    "sub_nsw": """func.func @sub_nsw(%arg0: !transfer.integer, %arg1: !transfer.integer) -> i1 {
    %ssub_ov = "transfer.ssub_overflow"(%arg0, %arg1) : (!transfer.integer, !transfer.integer) -> i1
    %true = arith.constant true
    %no_ov = arith.xori %ssub_ov, %true : i1
    return %no_ov : i1
  }""",
    "sub_nuw": """func.func @sub_nuw(%arg0: !transfer.integer, %arg1: !transfer.integer) -> i1 {
    %usub_ov = "transfer.usub_overflow"(%arg0, %arg1) : (!transfer.integer, !transfer.integer) -> i1
    %true = arith.constant true
    %no_ov = arith.xori %usub_ov, %true : i1
    return %no_ov : i1
  }""",
    "mul_nsw": """func.func @mul_nsw(%arg0: !transfer.integer, %arg1: !transfer.integer) -> i1 {
    %smul_ov = "transfer.smul_overflow"(%arg0, %arg1) : (!transfer.integer, !transfer.integer) -> i1
    %true = arith.constant true
    %no_ov = arith.xori %smul_ov, %true : i1
    return %no_ov : i1
  }""",
    "mul_nuw": """func.func @mul_nuw(%arg0: !transfer.integer, %arg1: !transfer.integer) -> i1 {
    %umul_ov = "transfer.umul_overflow"(%arg0, %arg1) : (!transfer.integer, !transfer.integer) -> i1
    %true = arith.constant true
    %no_ov = arith.xori %umul_ov, %true : i1
    return %no_ov : i1
  }""",
    "shl_nsw": """func.func @shl_nsw(%arg0: !transfer.integer, %arg1: !transfer.integer) -> i1 {
    %sshl_ov = "transfer.sshl_overflow"(%arg0, %arg1) : (!transfer.integer, !transfer.integer) -> i1
    %true = arith.constant true
    %no_ov = arith.xori %sshl_ov, %true : i1
    return %no_ov : i1
  }""",
    "shl_nuw": """func.func @shl_nuw(%arg0: !transfer.integer, %arg1: !transfer.integer) -> i1 {
    %ushl_ov = "transfer.ushl_overflow"(%arg0, %arg1) : (!transfer.integer, !transfer.integer) -> i1
    %true = arith.constant true
    %no_ov = arith.xori %ushl_ov, %true : i1
    return %no_ov : i1
  }""",
    "ashr_exact": """func.func @ashr_exact(%arg0: !transfer.integer, %arg1: !transfer.integer) -> i1 {
    %ashr = "transfer.ashr"(%arg0, %arg1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %shl = "transfer.shl"(%ashr, %arg1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %exact = "transfer.cmp"(%shl, %arg0) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    return %exact : i1
  }""",
    "lshr_exact": """func.func @lshr_exact(%arg0: !transfer.integer, %arg1: !transfer.integer) -> i1 {
    %lshr = "transfer.lshr"(%arg0, %arg1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %shl = "transfer.shl"(%lshr, %arg1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %exact = "transfer.cmp"(%shl, %arg0) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    return %exact : i1
  }""",
    "sdiv_exact": """func.func @sdiv_exact(%arg0: !transfer.integer, %arg1: !transfer.integer) -> i1 {
    %const = "transfer.constant"(%arg1) {value = 0 : i64} : (!transfer.integer) -> !transfer.integer
    %srem = "transfer.srem"(%arg0, %arg1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %exact = "transfer.cmp"(%srem, %const) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    return %exact : i1
  }""",
    "udiv_exact": """func.func @udiv_exact(%arg0: !transfer.integer, %arg1: !transfer.integer) -> i1 {
    %const = "transfer.constant"(%arg1) {value = 0 : i64} : (!transfer.integer) -> !transfer.integer
    %urem = "transfer.urem"(%arg0, %arg1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %exact = "transfer.cmp"(%urem, %const) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    return %exact : i1
  }""",
    "shift_lt_bw": """func.func @shift_lt_bw(%arg0: !transfer.integer, %arg1: !transfer.integer) -> i1 {
    %bitwidth = "transfer.get_bit_width"(%arg0) : (!transfer.integer) -> !transfer.integer
    %shift_amt_lt_bw = "transfer.cmp"(%arg1, %bitwidth) {predicate = 6 : i64} : (!transfer.integer, !transfer.integer) -> i1
    return %shift_amt_lt_bw : i1
  }""",
    "rhs_neq_zero": """func.func @rhs_neq_zero(%arg0: !transfer.integer, %arg1: !transfer.integer) -> i1 {
    %const = "transfer.constant"(%arg1) {value = 0 : index} : (!transfer.integer) -> !transfer.integer
    %rhs_not = "transfer.cmp"(%const, %arg1) {predicate = 1 : i64} : (!transfer.integer, !transfer.integer) -> i1
    return %rhs_not : i1
  }""",
    "not_intmin": """func.func @not_intmin(%arg0: !transfer.integer) -> i1 {
    %int_min = "transfer.get_signed_min_value"(%arg0) : (!transfer.integer) -> !transfer.integer
    %not_int_min = "transfer.cmp"(%int_min, %arg0) {predicate = 1 : i64} : (!transfer.integer, !transfer.integer) -> i1
    return %not_int_min : i1
  }""",
    "no_sdiv_ov": """func.func @no_sdiv_ov(%arg0: !transfer.integer, %arg1: !transfer.integer) -> i1 {
    %int_min = "transfer.get_signed_min_value"(%arg0) : (!transfer.integer) -> !transfer.integer
    %lhs_not_int_min = "transfer.cmp"(%int_min, %arg0) {predicate = 1 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %neg = "transfer.get_all_ones"(%arg0) : (!transfer.integer) -> !transfer.integer
    %rhs_not_neg = "transfer.cmp"(%neg, %arg1) {predicate = 1 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %no_overflow = arith.ori %lhs_not_int_min, %rhs_not_neg : i1
    return %no_overflow : i1
  }""",
    "or_disjoint": """func.func @or_disjoint(%arg0: !transfer.integer, %arg1: !transfer.integer) -> i1 {
    %0 = "transfer.constant"(%arg1) {value = 0 : index} : (!transfer.integer) -> !transfer.integer
    %1 = "transfer.and"(%arg0, %arg1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %2 = "transfer.cmp"(%1, %0) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    return %2 : i1
  }""",
    "nonzero": """func.func @nonzero(%arg0: !transfer.integer) -> i1 {
    %const_0 = "transfer.constant"(%arg0) {value = 0 : i64} : (!transfer.integer) -> !transfer.integer
    %not_0 = "transfer.cmp"(%arg0, %const_0) {predicate = 1 : i64} : (!transfer.integer, !transfer.integer) -> i1
    return %not_0 : i1
  }""",
}


class _PatternExprParser:
    def __init__(self, expr: str):
        self.expr = expr
        self.tokens: list[str] = []
        self.pos = 0
        cursor = 0
        while cursor < len(expr):
            _EXPR_TOKEN_RE = re.compile(r"\s*([A-Za-z_][A-Za-z_0-9]*|\(|\)|,)")
            match = _EXPR_TOKEN_RE.match(expr, cursor)
            if match is None:
                raise ValueError(f"Unexpected token near '{expr[cursor:]}'.")
            self.tokens.append(match.group(1))
            cursor = match.end()
        if not self.tokens:
            raise ValueError("Pattern expression is empty.")

        self.nodes: list[PatternNode] = []
        self.interned: dict[tuple[PatternOp, tuple[PatternRef, ...]], NodeRef] = {}
        self.args: set[int] = set()
        self.arg_types: dict[int, Attribute] = {}

    def parse(self) -> tuple[tuple[Attribute, ...], tuple[PatternNode, ...], NodeRef]:
        if len(self.tokens) == 1:
            result = self._parse_bare_op_shorthand()
        else:
            result = self._parse_value()
        if self.pos != len(self.tokens):
            raise ValueError(f"Unexpected token '{self.tokens[self.pos]}'.")
        if not isinstance(result, NodeRef):
            raise ValueError("Pattern expression must have an operation at the root.")

        max_arg = max(self.args, default=-1)
        missing = set(range(max_arg + 1)) - self.args
        if missing:
            raise ValueError(
                f"Pattern arguments must be contiguous; missing {sorted(missing)}."
            )

        return (
            tuple(self.arg_types[index] for index in range(max_arg + 1)),
            tuple(self.nodes),
            result,
        )

    def _parse_bare_op_shorthand(self) -> NodeRef:
        name = self._consume()

        try:
            op = PatternOp(name)
        except ValueError as exc:
            raise ValueError(f"Unknown pattern operation '{name}'.") from exc

        operands: list[PatternRef] = []
        for index, expected_ty in enumerate(op.spec.operand_types):
            self._record_arg_type(index, expected_ty)
            self.args.add(index)
            operands.append(ArgRef(index))

        return self._add_node(op, tuple(operands))

    def _record_arg_type(self, index: int, ty: Attribute) -> None:
        existing_ty = self.arg_types.get(index)
        if existing_ty is not None and existing_ty != ty:
            raise ValueError(
                f"Pattern argument 'arg{index}' is used as both {existing_ty} and {ty}."
            )
        self.arg_types[index] = ty

    def _add_node(
        self,
        op: PatternOp,
        operands: tuple[PatternRef, ...],
    ) -> NodeRef:
        key = (op, operands)
        existing = self.interned.get(key)
        if existing is not None:
            return existing

        ref = NodeRef(len(self.nodes))
        self.nodes.append(PatternNode(op, operands))
        self.interned[key] = ref
        return ref

    def _peek(self) -> str | None:
        if self.pos >= len(self.tokens):
            return None
        return self.tokens[self.pos]

    def _consume(self, expected: str | None = None) -> str:
        token = self._peek()
        if token is None:
            raise ValueError("Unexpected end of pattern expression.")
        if expected is not None and token != expected:
            raise ValueError(f"Expected '{expected}', got '{token}'.")
        self.pos += 1
        return token

    def _ref_type(self, ref: PatternRef) -> Attribute:
        if isinstance(ref, ArgRef):
            return self.arg_types.get(ref.index, _iN)
        return self.nodes[ref.index].op.spec.result_type

    def _parse_value(self) -> PatternRef:
        name = self._consume()
        arg_match = re.fullmatch(r"arg(\d+)", name)
        if arg_match is not None:
            index = int(arg_match.group(1))
            self.args.add(index)
            return ArgRef(index)

        try:
            op = PatternOp(name)
        except ValueError as exc:
            raise ValueError(f"Unknown pattern operation '{name}'.") from exc
        spec = op.spec
        self._consume("(")
        operands: list[PatternRef] = []
        if self._peek() != ")":
            while True:
                operands.append(self._parse_value())
                if self._peek() != ",":
                    break
                self._consume(",")
        self._consume(")")

        if len(operands) != len(spec.operand_types):
            raise ValueError(
                f"Operation '{name}' expects {len(spec.operand_types)} operands, "
                f"got {len(operands)}."
            )
        for operand, expected_ty in zip(operands, spec.operand_types):
            if isinstance(operand, ArgRef):
                self._record_arg_type(operand.index, expected_ty)
            actual_ty = self._ref_type(operand)
            if actual_ty != expected_ty:
                raise ValueError(
                    f"Operation '{name}' expected {expected_ty} operand, "
                    f"but {format_pattern_ref(operand)} has type {actual_ty}."
                )

        return self._add_node(op, tuple(operands))


def format_pattern_ref(ref: PatternRef) -> str:
    if isinstance(ref, ArgRef):
        return f"arg{ref.index}"
    return f"n{ref.index}"


def _format_alpha_pattern_ref(ref: PatternRef, arg_map: dict[int, int]) -> str:
    if isinstance(ref, NodeRef):
        return format_pattern_ref(ref)

    index = arg_map.get(ref.index)
    if index is None:
        index = len(arg_map)
        arg_map[ref.index] = index
    return f"arg{index}"


def _append_dag_ops(fn: FuncOp, dag: PatternDag) -> dict[PatternRef, SSAValue]:
    value_map: dict[PatternRef, SSAValue] = {
        ArgRef(i): arg for i, arg in enumerate(fn.body.block.args)
    }
    for idx, node in enumerate(dag.nodes):
        operands = tuple(value_map[operand] for operand in node.operands)
        op = node.op.build(operands)
        fn.body.block.add_op(op)
        op.results[0].name_hint = f"n{idx}"
        value_map[NodeRef(idx)] = op.results[0]
    return value_map


def lower_concrete_op(dag: PatternDag) -> FuncOp:
    res_ty = dag.nodes[dag.result.index].op.spec.result_type
    fn = FuncOp.from_region("concrete_op", dag.arg_types, [res_ty])
    value_map = _append_dag_ops(fn, dag)
    fn.body.block.add_op(ReturnOp(value_map[dag.result]))
    return fn


def lower_op_constraint(dag: PatternDag) -> tuple[FuncOp | None, set[str]]:
    helper_names = {helper for node in dag.nodes for helper in node.op.spec.constraints}
    if not helper_names:
        return None, set()

    fn = FuncOp.from_region("op_constraint", dag.arg_types, [i1])
    value_map = _append_dag_ops(fn, dag)
    constraint_values: list[SSAValue] = []
    for node_idx, node in enumerate(dag.nodes):
        for con_idx, helper in enumerate(node.op.spec.constraints):
            operands = [value_map[operand] for operand in node.operands]
            call = CallOp(helper, operands, [i1])
            call.results[0].name_hint = f"ssa_{node_idx}_con_{con_idx}_z"
            fn.body.block.add_op(call)
            constraint_values.append(call.results[0])

    result = constraint_values[0]
    for idx, constraint in enumerate(constraint_values[1:]):
        and_op = AndIOp(result, constraint, i1)
        and_op.results[0].name_hint = f"and_{idx}"
        fn.body.block.add_op(and_op)
        result = and_op.results[0]
    fn.body.block.add_op(ReturnOp(result))
    return fn, helper_names
