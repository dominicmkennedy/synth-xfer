from functools import singledispatchmethod
from pathlib import Path
from typing import Callable, Protocol

from llvmlite import ir
from xdsl.context import Context
from xdsl.dialects.arith import AndIOp, Arith, ConstantOp, OrIOp, XOrIOp
from xdsl.dialects.builtin import Builtin, IntegerType, ModuleOp
from xdsl.dialects.func import CallOp, Func, FuncOp, ReturnOp
from xdsl.ir import Attribute, Operation
from xdsl.irdl import SSAValue
from xdsl.parser import Parser
from xdsl_smt.dialects.transfer import (
    AbstractValueType,
    AddOp,
    AndOp,
    AShrOp,
    ClearHighBitsOp,
    ClearLowBitsOp,
    ClearSignBitOp,
    CmpOp,
    Constant,
    CountLOneOp,
    CountLZeroOp,
    CountROneOp,
    CountRZeroOp,
    GetAllOnesOp,
    GetBitWidthOp,
    GetOp,
    GetSignedMaxValueOp,
    GetSignedMinValueOp,
    IsNegativeOp,
    LShrOp,
    MakeOp,
    MulOp,
    NegOp,
    OrOp,
    SAddOverflowOp,
    SDivOp,
    SelectOp,
    SetHighBitsOp,
    SetLowBitsOp,
    SetSignBitOp,
    # USubOverflowOp,
    ShlOp,
    SMaxOp,
    SMinOp,
    SMulOverflowOp,
    SRemOp,
    SShlOverflowOp,
    SubOp,
    # SSubOverflowOp,
    Transfer,
    TransIntegerType,
    TupleType,
    UAddOverflowOp,
    UDivOp,
    UMaxOp,
    UMinOp,
    UMulOverflowOp,
    URemOp,
    UShlOverflowOp,
    XorOp,
)

# TODO need to impl SetHighBitsOp | SetLowBitsOp | ClearHighBitsOp | ClearLowBitsOp


class _IRBuilderOp(Protocol):
    __self__: ir.IRBuilder

    def __call__(
        self, b: ir.IRBuilder, *args: ir.Value, name: str = ""
    ) -> ir.Instruction: ...


# TODO mlir_op map be owned by the lowerer
_mlir_op_to_llvm: dict[type[Operation], _IRBuilderOp] = {  # type: ignore
    # unary
    NegOp: ir.IRBuilder.neg,
    # binary
    AndOp: ir.IRBuilder.and_,
    AndIOp: ir.IRBuilder.and_,
    AddOp: ir.IRBuilder.add,
    OrOp: ir.IRBuilder.or_,
    OrIOp: ir.IRBuilder.or_,
    XorOp: ir.IRBuilder.xor,
    XOrIOp: ir.IRBuilder.xor,
    SubOp: ir.IRBuilder.sub,
    MulOp: ir.IRBuilder.mul,
    UDivOp: ir.IRBuilder.udiv,
    SDivOp: ir.IRBuilder.sdiv,
    URemOp: ir.IRBuilder.urem,
    SRemOp: ir.IRBuilder.srem,
    AShrOp: ir.IRBuilder.ashr,
    LShrOp: ir.IRBuilder.lshr,
    ShlOp: ir.IRBuilder.shl,
    # # ternery
    SelectOp: ir.IRBuilder.select,
    # TODO impl these ops
    # "transfer.set_high_bits": ".setHighBits",
    # "transfer.set_low_bits": ".setLowBits",
    # "transfer.clear_high_bits": ".clearHighBits",
    # "transfer.clear_low_bits": ".clearLowBits",
    # "transfer.set_sign_bit": ".setSignBit",
    # "transfer.clear_sign_bit": ".clearSignBit",
}


# TODO doesn't insert into the ssa map
# TODO these should just be special case lowerings
# TODO rewrite so that they are, this could make them faster
class _OpConstraints:
    def c(self, v: int) -> ir.Constant:
        return ir.Constant(ir.IntType(self.bw), v)

    def rhs_eq_zero(self, b: ir.IRBuilder, _: ir.Value, rhs: ir.Value):
        return b.icmp_unsigned("==", rhs, self.c(0))

    def val_uge_bw(self, b: ir.IRBuilder, _: ir.Value, rhs: ir.Value):
        return b.icmp_unsigned(">=", rhs, self.c(self.bw))

    def ashr_bad_bw_pos(self, b: ir.IRBuilder, lhs: ir.Value, rhs: ir.Value):
        pos = b.icmp_signed(">=", lhs, self.c(0))
        badbw = b.icmp_unsigned(">=", rhs, self.c(self.bw))
        return b.and_(pos, badbw)

    def ashr_bad_bw_neg(self, b: ir.IRBuilder, lhs: ir.Value, rhs: ir.Value):
        neg = b.icmp_signed("<", lhs, self.c(0))
        badbw = b.icmp_unsigned(">=", rhs, self.c(self.bw))
        return b.and_(neg, badbw)

    def sdiv_underflow(self, b: ir.IRBuilder, lhs: ir.Value, rhs: ir.Value):
        int_min = self.c(2 ** (self.bw - 1))
        neg_one = self.c((2**self.bw) - 1)
        lhs_is_min = b.icmp_signed("==", lhs, int_min)
        rhs_is_m1 = b.icmp_signed("==", rhs, neg_one)
        return b.and_(lhs_is_min, rhs_is_m1)

    def sdiv_by_zero_pos(self, b: ir.IRBuilder, lhs: ir.Value, rhs: ir.Value):
        pos = b.icmp_signed(">=", lhs, self.c(0))
        rhs0 = b.icmp_unsigned("==", rhs, self.c(0))
        return b.and_(pos, rhs0)

    def sdiv_by_zero_neg(self, b: ir.IRBuilder, lhs: ir.Value, rhs: ir.Value):
        neg = b.icmp_signed("<", lhs, self.c(0))
        rhs0 = b.icmp_unsigned("==", rhs, self.c(0))
        return b.and_(neg, rhs0)

    def ret_lhs(self, lhs: ir.Value):
        return lhs

    def ret_zero(self, _: ir.Value):
        return self.c(0)

    def ret_one(self, _: ir.Value):
        return self.c(1)

    def ret_ones(self, _: ir.Value):
        return self.c((2**self.bw) - 1)

    def ret_int_min(self, _: ir.Value):
        return self.c(2 ** (self.bw - 1))

    def __init__(self, bw: int):
        self.bw = bw

        self.ops: list[type[Operation]] = [
            ShlOp,
            LShrOp,
            AShrOp,
            UDivOp,
            URemOp,
            SRemOp,
            SDivOp,
        ]

        self.constraints: dict[  # type: ignore
            type[Operation],
            list[
                tuple[
                    Callable[[ir.IRBuilder, ir.Value, ir.Value], ir.Value],
                    Callable[[ir.Value], ir.Value],
                ]
            ],
        ] = {
            ShlOp: [(self.val_uge_bw, self.ret_zero)],
            LShrOp: [(self.val_uge_bw, self.ret_zero)],
            AShrOp: [
                (self.ashr_bad_bw_pos, self.ret_zero),
                (self.ashr_bad_bw_neg, self.ret_ones),
            ],
            UDivOp: [(self.rhs_eq_zero, self.ret_ones)],
            URemOp: [(self.rhs_eq_zero, self.ret_lhs)],
            SRemOp: [(self.rhs_eq_zero, self.ret_lhs)],
            SDivOp: [
                (self.sdiv_underflow, self.ret_int_min),
                (self.sdiv_by_zero_pos, self.ret_ones),
                (self.sdiv_by_zero_neg, self.ret_one),
            ],
        }

    def safe_lower(
        self, b: ir.IRBuilder, op: Operation, lhs: ir.Value, rhs: ir.Value
    ) -> ir.Instruction:
        const_zero = ir.Constant(ir.IntType(self.bw), 0)
        const_one = ir.Constant(ir.IntType(self.bw), 1)
        const_false = ir.Constant(ir.IntType(1), 0)
        const_true = ir.Constant(ir.IntType(1), 1)

        ub_any = const_false
        latched = const_false
        chosen = const_zero

        for pred, default in self.constraints[type(op)]:
            p = pred(b, lhs, rhs)
            ub_any = b.or_(ub_any, p)
            dval = default(lhs)
            take = b.and_(p, b.icmp_unsigned("==", latched, const_false))
            chosen = b.select(take, dval, chosen)
            latched = b.select(p, const_true, latched)

        lhs_safe = b.select(ub_any, const_zero, lhs)
        rhs_safe = b.select(ub_any, const_one, rhs)

        raw_llvm_op = _mlir_op_to_llvm[type(op)]
        raw = raw_llvm_op(b, lhs_safe, rhs_safe)

        return b.select(ub_any, chosen, raw)


# TODO this should go into a diff file
def parse_mlir_funcs(p: Path | str) -> list[FuncOp]:
    ctx = Context()
    ctx.load_dialect(Arith)
    ctx.load_dialect(Builtin)
    ctx.load_dialect(Func)
    ctx.load_dialect(Transfer)

    func_str = p if isinstance(p, str) else p.read_text()
    func_name = "<text>" if isinstance(p, str) else p.name

    mod = Parser(ctx, func_str, func_name).parse_op()

    if isinstance(mod, ModuleOp):
        return [x for x in mod.ops if isinstance(x, FuncOp)]
    elif isinstance(mod, FuncOp):
        return [mod]
    else:
        raise ValueError(f"mlir in '{func_name}' is neither a ModuleOp, nor a FuncOp")


def lower_type(typ: Attribute, bw: int) -> ir.Type:
    # TODO only works for arity 2 domains (no IM)
    if isinstance(typ, TransIntegerType):
        return ir.IntType(bw)
    elif isinstance(typ, IntegerType):
        return ir.IntType(typ.width.data)
    elif isinstance(typ, AbstractValueType) or isinstance(typ, TupleType):
        fields = typ.get_fields()
        sub_type = lower_type(fields[0], bw)

        for other_type in fields:
            assert lower_type(other_type, bw) == sub_type

        return ir.ArrayType(sub_type, len(fields))

    raise ValueError("Unsupported Type", typ)


class LowerToLLVM:
    def __init__(self, bw: int, name: str) -> None:
        self.bw = bw
        self.llvm_mod = ir.Module(name=name)
        self.fns: dict[str, ir.Function] = {}

    def __str__(self) -> str:
        return str(self.llvm_mod)

    @staticmethod
    def add_attrs(fn: ir.Function) -> ir.Function:
        fn.attributes.add("nounwind")
        fn.attributes.add("alwaysinline")
        fn.attributes.add("readnone")
        fn.attributes.add("norecurse")

        return fn

    @staticmethod
    def is_concrete_op(mlir_fn: FuncOp) -> bool:
        fn_ret_type = lower_type(mlir_fn.function_type.outputs.data[0], 64)
        fn_arg_types = tuple(lower_type(x.type, 64) for x in mlir_fn.args)

        i64 = ir.IntType(64)
        ret_match = fn_ret_type == i64
        arg_match = fn_arg_types == (i64, i64)

        return ret_match and arg_match

    @staticmethod
    def is_transfer_fn(mlir_fn: FuncOp) -> bool:
        fn_ret_type = lower_type(mlir_fn.function_type.outputs.data[0], 64)
        fn_arg_types = tuple(lower_type(x.type, 64) for x in mlir_fn.args)

        i64 = ir.IntType(64)
        abst = ir.ArrayType(i64, 2)
        ret_match = fn_ret_type == abst
        arg_match = fn_arg_types == (abst, abst)

        return ret_match and arg_match

    def add_fn(
        self, mlir_fn: FuncOp, fn_name: str | None = None, shim: bool = False
    ) -> ir.Function:
        fn_name = fn_name if fn_name else mlir_fn.sym_name.data
        fn_ret_type = lower_type(mlir_fn.function_type.outputs.data[0], self.bw)
        fn_arg_types = (lower_type(x.type, self.bw) for x in mlir_fn.args)

        fn_type = ir.FunctionType(fn_ret_type, fn_arg_types)
        llvm_fn = ir.Function(self.llvm_mod, fn_type, name=fn_name)
        llvm_fn = self.add_attrs(llvm_fn)

        self.fns[fn_name] = _LowerFuncToLLVM(mlir_fn, llvm_fn, self.fns, self.bw).llvm_fn

        # TODO factor out this out into a class shim function
        if shim and self.is_concrete_op(mlir_fn):
            return self.shim_conc(self.fns[fn_name])
        elif shim and self.is_transfer_fn(mlir_fn):
            return self.shim_xfer(self.fns[fn_name])
        elif shim:
            raise ValueError(
                f"Cannot shim non concrete and non transfer function {fn_name}"
            )

        return self.fns[fn_name]

    def add_fns(self, fns: list[FuncOp]) -> list[ir.Function]:
        return [self.add_fn(x) for x in fns]

    def shim_conc(self, old_fn: ir.Function) -> ir.Function:
        lane_t = ir.IntType(self.bw)
        wide_t = ir.IntType(64)

        fn_name = f"{old_fn.name}_shim"
        shim_ty = ir.FunctionType(wide_t, [wide_t, wide_t])
        shim_fn = ir.Function(self.llvm_mod, shim_ty, name=fn_name)
        shim_fn = self.add_attrs(shim_fn)

        entry = shim_fn.append_basic_block(name="entry")
        b = ir.IRBuilder(entry)

        a64, b64 = shim_fn.args
        a64.name = "a64"
        b64.name = "b64"

        a_n = a64 if self.bw == 64 else b.trunc(a64, lane_t)
        b_n = b64 if self.bw == 64 else b.trunc(b64, lane_t)
        r_n = b.call(old_fn, [a_n, b_n])
        r64 = r_n if self.bw == 64 else b.zext(r_n, wide_t)
        b.ret(r64)

        return shim_fn

    def shim_xfer(self, old_fn: ir.Function) -> ir.Function:
        lane_t = ir.IntType(self.bw)
        i64 = ir.IntType(64)
        lane_arr_t = ir.ArrayType(lane_t, 2)
        i64_arr_t = ir.ArrayType(i64, 2)

        fn_name = f"{old_fn.name}_shim"
        shim_ty = ir.FunctionType(i64_arr_t, [i64_arr_t, i64_arr_t])
        shim_fn = ir.Function(self.llvm_mod, shim_ty, name=fn_name)
        shim_fn = self.add_attrs(shim_fn)

        b = ir.IRBuilder(shim_fn.append_basic_block(name="entry"))
        a64, b64 = shim_fn.args

        def to_lane(v):
            return v if self.bw == 64 else b.trunc(v, lane_t)

        a0 = to_lane(b.extract_value(a64, 0))
        a1 = to_lane(b.extract_value(a64, 1))
        b0 = to_lane(b.extract_value(b64, 0))
        b1 = to_lane(b.extract_value(b64, 1))

        empty_arr = ir.Constant(lane_arr_t, None)
        a_n = b.insert_value(empty_arr, a0, 0)
        a_n = b.insert_value(a_n, a1, 1)
        b_n = b.insert_value(empty_arr, b0, 0)
        b_n = b.insert_value(b_n, b1, 1)

        def to_i64(v):
            return v if self.bw == 64 else b.zext(v, i64)

        r_n = b.call(old_fn, [a_n, b_n])
        r0 = to_i64(b.extract_value(r_n, 0))
        r1 = to_i64(b.extract_value(r_n, 1))

        empty_i64_arr = ir.Constant(i64_arr_t, None)
        r = b.insert_value(empty_i64_arr, r0, 0)
        r = b.insert_value(r, r1, 1)
        b.ret(r)

        return shim_fn


class _LowerFuncToLLVM:
    bw: int
    b: ir.IRBuilder
    ssa_map: dict[SSAValue, ir.Value]
    llvm_fn: ir.Function
    fns: dict[str, ir.Function]

    def __init__(
        self, mlir_fn: FuncOp, llvm_fn: ir.Function, fns: dict[str, ir.Function], bw: int
    ) -> None:
        self.bw = bw
        self.fns = fns

        self.b = ir.IRBuilder(llvm_fn.append_basic_block(name="entry"))
        self.ssa_map = dict(zip(mlir_fn.args, llvm_fn.args))  # type: ignore

        [self.add_op(op) for op in mlir_fn.walk() if not isinstance(op, FuncOp)]

        self.llvm_fn = llvm_fn

    def __str__(self) -> str:
        return str(self.llvm_fn)

    @staticmethod
    def result_name(op: Operation) -> str:
        ret_val = op.results[0].name_hint
        if ret_val is None:
            ret_val = f"idx_{op.results[0].index}"

        return ret_val

    def operands(self, op: Operation) -> tuple[ir.Value, ...]:
        return tuple(self.ssa_map[x] for x in op.operands)

    @singledispatchmethod
    def add_op(self, _: Operation) -> None:
        pass

    @add_op.register
    def _(self, op: Operation) -> None:
        llvm_op = _mlir_op_to_llvm[type(op)]

        constraints = _OpConstraints(self.bw)

        if type(op) in constraints.ops:
            self.ssa_map[op.results[0]] = constraints.safe_lower(
                self.b, op, self.operands(op)[0], self.operands(op)[1]
            )
        else:
            self.ssa_map[op.results[0]] = llvm_op(self.b, *self.operands(op))

    @add_op.register
    def _(self, op: CallOp) -> None:
        res_name = self.result_name(op)
        callee = op.callee.string_value()
        fn = self.fns[callee]

        self.ssa_map[op.results[0]] = self.b.call(fn, self.operands(op), name=res_name)

    @add_op.register
    def _(self, op: CountLOneOp | CountLZeroOp) -> None:
        res_name = self.result_name(op)
        true_const = ir.Constant(ir.IntType(1), 1)

        operand = self.operands(op)[0]
        if isinstance(op, CountLOneOp):
            operand = self.b.not_(operand, name=f"{res_name}_not")

        self.ssa_map[op.results[0]] = self.b.ctlz(operand, true_const, name=res_name)  # type: ignore

    @add_op.register
    def _(self, op: CountROneOp | CountRZeroOp) -> None:
        res_name = self.result_name(op)
        true_const = ir.Constant(ir.IntType(1), 1)

        operand = self.operands(op)[0]
        if isinstance(op, CountROneOp):
            operand = self.b.not_(operand, name=f"{res_name}_not")

        self.ssa_map[op.results[0]] = self.b.cttz(operand, true_const, name=res_name)  # type: ignore

    @add_op.register
    def _(
        self,
        op: UAddOverflowOp | SAddOverflowOp | UMulOverflowOp | SMulOverflowOp,
        # | USubOverflowOp
        # | SSubOverflowOp,
    ) -> None:
        res_name = self.result_name(op)
        oprands = self.operands(op)

        d = {
            UAddOverflowOp: self.b.uadd_with_overflow,
            SAddOverflowOp: self.b.sadd_with_overflow,
            UMulOverflowOp: self.b.umul_with_overflow,
            SMulOverflowOp: self.b.smul_with_overflow,
            # USubOverflowOp: self.b.usub_with_overflow,
            # SSubOverflowOp: self.b.ssub_with_overflow,
        }

        ov = d[type(op)](oprands[0], oprands[1], name=f"{res_name}_ov")
        self.ssa_map[op.results[0]] = self.b.extract_value(ov, 1, name=res_name)

    @add_op.register
    def _(self, op: UShlOverflowOp | SShlOverflowOp) -> None:
        res_name = self.result_name(op)
        oprnds = self.operands(op)

        bw_const = ir.Constant(ir.IntType(self.bw), self.bw)
        true_const = ir.Constant(ir.IntType(1), 1)
        cmp = self.b.icmp_unsigned(">=", oprnds[0], bw_const, name=f"{res_name}_cmp")

        shl = self.b.shl(oprnds[0], oprnds[1], name=f"{res_name}_shl")
        if isinstance(op, SShlOverflowOp):
            shr = self.b.ashr(shl, oprnds[1], name=f"{res_name}_ashr")
        elif isinstance(op, UShlOverflowOp):
            shr = self.b.lshr(shl, oprnds[1], name=f"{res_name}_ashr")

        ov = self.b.icmp_signed("!=", shr, oprnds[0], name=f"{res_name}_ov")
        self.ssa_map[op.results[0]] = self.b.select(
            cmp, true_const, ov, name=f"{res_name}_ov"
        )

    @add_op.register
    def _(self, op: GetOp) -> None:
        idx: int = op.attributes["index"].value.data  # type: ignore
        res_name = self.result_name(op)
        self.ssa_map[op.results[0]] = self.b.extract_value(
            self.operands(op)[0], idx, name=res_name
        )

    @add_op.register
    def _(self, op: MakeOp) -> None:
        res_name = self.result_name(op)

        res = ir.Constant(lower_type(op.results[0].type, self.bw), None)
        for i, oprnd in enumerate(self.operands(op)):
            res = self.b.insert_value(res, oprnd, i, name=res_name)

        self.ssa_map[op.results[0]] = res

    @add_op.register
    def _(self, op: ReturnOp) -> None:
        self.b.ret(self.operands(op)[0])

    @add_op.register
    def _(
        self,
        op: GetSignedMaxValueOp
        | GetSignedMinValueOp
        | GetAllOnesOp
        | GetBitWidthOp
        | Constant
        | ConstantOp,
    ) -> None:
        if isinstance(op, GetSignedMaxValueOp):
            val = (2 ** (self.bw - 1)) - 1
        elif isinstance(op, GetSignedMinValueOp):
            val = 2 ** (self.bw - 1)
        elif isinstance(op, GetAllOnesOp):
            val = (2**self.bw) - 1
        elif isinstance(op, GetBitWidthOp):
            val = self.bw
        elif isinstance(op, Constant) or isinstance(op, ConstantOp):
            val: int = op.value.value.data  # type: ignore

        self.ssa_map[op.results[0]] = ir.Constant(ir.IntType(self.bw), val)

    @add_op.register
    def _(self, op: UMaxOp | UMinOp | SMaxOp | SMinOp) -> None:
        oprnds = self.operands(op)
        res_name = self.result_name(op)

        if isinstance(op, UMaxOp):
            cmp = self.b.icmp_unsigned(">", oprnds[0], oprnds[1], name=f"{res_name}_cmp")
        elif isinstance(op, UMinOp):
            cmp = self.b.icmp_unsigned("<", oprnds[0], oprnds[1], name=f"{res_name}_cmp")
        elif isinstance(op, SMaxOp):
            cmp = self.b.icmp_signed(">", oprnds[0], oprnds[1], name=f"{res_name}_cmp")
        elif isinstance(op, SMinOp):
            cmp = self.b.icmp_signed("<", oprnds[0], oprnds[1], name=f"{res_name}_cmp")

        self.ssa_map[op.results[0]] = self.b.select(
            cmp, oprnds[0], oprnds[1], name=res_name
        )

    @add_op.register
    def _(self, op: IsNegativeOp) -> None:
        oprnds = self.operands(op)
        res_name = self.result_name(op)

        const_zero = ir.Constant(ir.IntType(self.bw), 0)
        self.ssa_map[op.results[0]] = self.b.icmp_signed(
            "<", oprnds[0], const_zero, name=res_name
        )

    @add_op.register
    def _(self, op: SetSignBitOp | ClearSignBitOp) -> None:
        oprnds = self.operands(op)
        res_name = self.result_name(op)

        if isinstance(op, SetSignBitOp):
            mask = ir.Constant(ir.IntType(self.bw), (2 ** (self.bw - 1)))
            self.ssa_map[op.results[0]] = self.b.or_(oprnds[0], mask, name=res_name)  # type: ignore
        else:
            mask = ir.Constant(ir.IntType(self.bw), ((2 ** (self.bw - 1)) - 1))
            self.ssa_map[op.results[0]] = self.b.and_(oprnds[0], mask, name=res_name)  # type: ignore

    @add_op.register
    def _(
        self, op: SetHighBitsOp | SetLowBitsOp | ClearHighBitsOp | ClearLowBitsOp
    ) -> None:
        oprnds = self.operands(op)
        res_name = self.result_name(op)

        # TODO
        self.ssa_map[op.results[0]] = oprnds[0]

    @add_op.register
    def _(self, op: CmpOp) -> None:
        s = self.b.icmp_signed
        us = self.b.icmp_unsigned
        cmp_sign_map = [s, s, s, s, s, s, us, us, us, us]
        cmp_pred_map = ["==", "!=", "<", "<=", ">", ">=", "<", "<=", ">", ">="]

        oprnds = self.operands(op)
        cmp_pred = op.predicate.value.data
        res_name = self.result_name(op)

        self.ssa_map[op.results[0]] = cmp_sign_map[cmp_pred](
            cmp_pred_map[cmp_pred], oprnds[0], oprnds[1], name=res_name
        )
