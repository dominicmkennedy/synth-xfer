from functools import singledispatchmethod
from typing import Protocol

from llvmlite import ir
from xdsl.dialects.builtin import IntegerAttr, ModuleOp
from xdsl.dialects.func import CallOp, FuncOp, ReturnOp
from xdsl.ir import Attribute, Operation
from xdsl.irdl import SSAValue
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
    PopCountOp,
    SAddOverflowOp,
    SDivOp,
    SelectOp,
    SetHighBitsOp,
    SetLowBitsOp,
    SetSignBitOp,
    ShlOp,
    SMaxOp,
    SMinOp,
    SMulOverflowOp,
    SRemOp,
    SShlOverflowOp,
    SSubOverflowOp,
    SubOp,
    TransIntegerType,
    UAddOverflowOp,
    UDivOp,
    UMaxOp,
    UMinOp,
    UMulOverflowOp,
    URemOp,
    UShlOverflowOp,
    USubOverflowOp,
    XorOp,
)


def lower_type(typ: Attribute) -> ir.Type:
    if isinstance(typ, TransIntegerType):
        assert isinstance(typ.width, IntegerAttr)
        return ir.IntType(typ.width.value.data)
    elif isinstance(typ, AbstractValueType):
        fields = typ.get_fields()
        assert isinstance(fields[0], TransIntegerType)
        assert isinstance(fields[0].width, IntegerAttr)
        width = fields[0].width.value.data

        assert all(
            isinstance(x, TransIntegerType)
            and isinstance(x.width, IntegerAttr)
            and width == x.width.value.data
            for x in fields
        )

        return ir.ArrayType(ir.IntType(width), len(fields))

    raise ValueError("Unsupported Type", typ)


class LowerToLLVM:
    def __init__(self, name: str = "") -> None:
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
        one_ret_val = len(mlir_fn.function_type.outputs.data) == 1
        trans_ret = isinstance(mlir_fn.function_type.outputs.data[0], TransIntegerType)
        trans_int_args = all(isinstance(x.type, TransIntegerType) for x in mlir_fn.args)

        return one_ret_val and trans_ret and trans_int_args

    @staticmethod
    def is_constraint(mlir_fn: FuncOp) -> bool:
        one_ret_val = len(mlir_fn.function_type.outputs.data) == 1
        ret_bool = lower_type(mlir_fn.function_type.outputs.data[0]) == ir.IntType(1)
        trans_int_args = all(isinstance(x.type, TransIntegerType) for x in mlir_fn.args)

        return one_ret_val and ret_bool and trans_int_args

    @staticmethod
    def is_transfer_fn(mlir_fn: FuncOp) -> bool:
        one_ret_val = len(mlir_fn.function_type.outputs.data) == 1
        ret_is_abst = isinstance(mlir_fn.function_type.outputs.data[0], AbstractValueType)
        abst_args = all(isinstance(x.type, TransIntegerType) for x in mlir_fn.args)

        return one_ret_val and ret_is_abst and abst_args

    def add_fn(self, mlir_fn: FuncOp, shim: bool = False) -> ir.Function:
        fn_name = mlir_fn.sym_name.data
        fn_ret_type = lower_type(mlir_fn.function_type.outputs.data[0])
        fn_arg_types = (lower_type(x.type) for x in mlir_fn.args)
        fn_type = ir.FunctionType(fn_ret_type, fn_arg_types)

        llvm_fn = ir.Function(self.llvm_mod, fn_type, name=fn_name)
        llvm_fn = self.add_attrs(llvm_fn)

        self.fns[fn_name] = _LowerFuncToLLVM(
            mlir_fn, llvm_fn, self.llvm_mod, self.fns, "name_suffix_todo"
        ).llvm_fn

        if shim:
            shimmed_fn = self.shim(mlir_fn, self.fns[fn_name])
            self.fns[f"{fn_name}_shim"] = shimmed_fn

            return shimmed_fn
        else:
            return self.fns[fn_name]

    def add_mod(self, mod: ModuleOp, to_shim: list[str] = []) -> dict[str, ir.Function]:
        fns: dict[str, ir.Function] = {}

        for mlir_func in mod.ops:
            assert isinstance(mlir_func, FuncOp)
            fn_name = mlir_func.sym_name.data
            shim = fn_name in to_shim
            f = self.add_fn(mlir_func, shim=False)
            fns[f.name] = f
            if shim:
                shimmed = self.shim(mlir_func, f)
                fns[shimmed.name] = shimmed

        return fns

    def shim(self, mlir_fn: FuncOp, llvm_fn: ir.Function) -> ir.Function:
        if self.is_concrete_op(mlir_fn):
            return self.shim_conc(mlir_fn, llvm_fn)
        elif self.is_constraint(mlir_fn):
            return self.shim_constraint(mlir_fn, llvm_fn)
        elif self.is_transfer_fn(mlir_fn):
            return self.shim_xfer(mlir_fn, llvm_fn)
        else:
            raise ValueError(
                f"Cannot shim non concrete and non transfer function: {llvm_fn}"
            )

    def shim_constraint(self, mlir_fn: FuncOp, old_fn: ir.Function) -> ir.Function:
        n_args = len(old_fn.function_type.args)
        wide_t = ir.IntType(64)

        fn_name = f"{old_fn.name}_shim"
        shim_ty = ir.FunctionType(wide_t, [wide_t for _ in range(n_args)])
        shim_fn = ir.Function(self.llvm_mod, shim_ty, name=fn_name)
        shim_fn = self.add_attrs(shim_fn)

        entry = shim_fn.append_basic_block(name="entry")
        b = ir.IRBuilder(entry)

        new_args: list[ir.Argument] = []
        for arg, mlir_arg in zip(shim_fn.args, mlir_fn.args):
            arg.name = f"{arg.name}_wide"
            new_args.append(b.trunc(arg, lower_type(mlir_arg.type)))  # type: ignore

        r_n = b.call(old_fn, new_args)
        r64 = b.zext(r_n, wide_t)
        b.ret(r64)

        return shim_fn

    def shim_conc(self, mlir_fn: FuncOp, old_fn: ir.Function) -> ir.Function:
        n_args = len(old_fn.function_type.args)
        wide_t = ir.IntType(64)

        fn_name = f"{old_fn.name}_shim"
        shim_ty = ir.FunctionType(wide_t, [wide_t for _ in range(n_args)])
        shim_fn = ir.Function(self.llvm_mod, shim_ty, name=fn_name)
        shim_fn = self.add_attrs(shim_fn)

        entry = shim_fn.append_basic_block(name="entry")
        b = ir.IRBuilder(entry)

        new_args: list[ir.Argument] = []
        for arg, mlir_arg in zip(shim_fn.args, mlir_fn.args):
            arg.name = f"{arg.name}_wide"
            new_args.append(b.trunc(arg, lower_type(mlir_arg.type)))  # type: ignore

        r_n = b.call(old_fn, new_args)
        b.ret(b.zext(r_n, wide_t))

        return shim_fn

    def shim_xfer(self, mlir_fn: FuncOp, old_fn: ir.Function) -> ir.Function:
        n_args = len(old_fn.function_type.args)
        i64 = ir.IntType(64)

        first_arg = mlir_fn.args[0].type
        assert isinstance(first_arg, AbstractValueType)
        num_abst_fields = len(first_arg.get_fields())

        i64_arr_t = ir.ArrayType(i64, num_abst_fields)

        fn_name = f"{old_fn.name}_shim"
        shim_ty = ir.FunctionType(i64_arr_t, [i64_arr_t for _ in range(n_args)])
        shim_fn = ir.Function(self.llvm_mod, shim_ty, name=fn_name)
        shim_fn = self.add_attrs(shim_fn)

        b = ir.IRBuilder(shim_fn.append_basic_block(name="entry"))

        def to_lane(v, lane_t):
            return b.trunc(v, lane_t)

        def to_i64(v):
            return b.zext(v, i64)

        new_lanes = []
        for arg, mlir_arg in zip(shim_fn.args, mlir_fn.args):
            assert isinstance(mlir_arg.type, AbstractValueType)
            arg_field = mlir_arg.type.get_fields()[0]
            assert isinstance(arg_field, TransIntegerType)
            lane_t = lower_type(arg_field)

            lane_arr_t = ir.ArrayType(lane_t, num_abst_fields)
            new_lane = ir.Constant(lane_arr_t, None)

            new_args = []
            for i in range(num_abst_fields):
                new_args.append(to_lane(b.extract_value(arg, i), lane_t))

            for i in range(num_abst_fields):
                new_lane = b.insert_value(new_lane, new_args[i], i)

            new_lanes.append(new_lane)

        r_n = b.call(old_fn, new_lanes)
        r = ir.Constant(i64_arr_t, None)

        rs = []
        for i in range(num_abst_fields):
            rs.append(to_i64(b.extract_value(r_n, i)))

        for i in range(num_abst_fields):
            r = b.insert_value(r, rs[i], i)

        b.ret(r)

        return shim_fn


class _LowerFuncToLLVM:
    class _IRBuilderOp(Protocol):
        __self__: ir.IRBuilder

        def __call__(
            self, b: ir.IRBuilder, *args: ir.Value, name: str = ""
        ) -> ir.Instruction: ...

    _llvm_intrinsics: dict[type[Operation], _IRBuilderOp] = {  # type: ignore
        # unary
        NegOp: ir.IRBuilder.not_,
        PopCountOp: ir.IRBuilder.ctpop,
        # binary
        AndOp: ir.IRBuilder.and_,
        AddOp: ir.IRBuilder.add,
        OrOp: ir.IRBuilder.or_,
        XorOp: ir.IRBuilder.xor,
        SubOp: ir.IRBuilder.sub,
        MulOp: ir.IRBuilder.mul,
        # ternery
        SelectOp: ir.IRBuilder.select,
    }

    b: ir.IRBuilder
    ssa_map: dict[SSAValue, ir.Value]
    llvm_fn: ir.Function
    llvm_mod: ir.Module
    fns: dict[str, ir.Function]
    name_suffix: str

    def __init__(
        self,
        mlir_fn: FuncOp,
        llvm_fn: ir.Function,
        llvm_mod: ir.Module,
        fns: dict[str, ir.Function],
        name_suffix: str,
    ) -> None:
        self.name_suffix = name_suffix
        self.fns = fns
        self.llvm_mod = llvm_mod

        self.b = ir.IRBuilder(llvm_fn.append_basic_block(name="entry"))
        self.ssa_map = dict(zip(mlir_fn.args, llvm_fn.args))

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
        llvm_op = self._llvm_intrinsics[type(op)]
        self.ssa_map[op.results[0]] = llvm_op(self.b, *self.operands(op))

    @add_op.register
    def _(self, op: CallOp) -> None:
        res_name = self.result_name(op)
        callee = op.callee.string_value()
        callee = f"{callee}_{self.name_suffix}"

        if callee not in self.fns:
            ret_ty = lower_type(op.results[0].type)
            in_tys = [lower_type(x.type) for x in op.arguments]
            func_ty = ir.FunctionType(ret_ty, in_tys)
            new_fn = ir.Function(self.llvm_mod, func_ty, name=callee)
            self.fns[callee] = new_fn

        fn = self.fns[callee]
        self.ssa_map[op.results[0]] = self.b.call(fn, self.operands(op), name=res_name)

    @add_op.register
    def _(self, op: CountLOneOp | CountLZeroOp) -> None:
        res_name = self.result_name(op)
        false_const = ir.Constant(ir.IntType(1), 0)

        operand = self.operands(op)[0]
        if isinstance(op, CountLOneOp):
            operand = self.b.not_(operand, name=f"{res_name}_not")

        self.ssa_map[op.results[0]] = self.b.ctlz(operand, false_const, name=res_name)  # type: ignore

    @add_op.register
    def _(self, op: CountROneOp | CountRZeroOp) -> None:
        res_name = self.result_name(op)
        false_const = ir.Constant(ir.IntType(1), 0)

        operand = self.operands(op)[0]
        if isinstance(op, CountROneOp):
            operand = self.b.not_(operand, name=f"{res_name}_not")

        self.ssa_map[op.results[0]] = self.b.cttz(operand, false_const, name=res_name)  # type: ignore

    @add_op.register
    def _(
        self,
        op: UAddOverflowOp
        | SAddOverflowOp
        | UMulOverflowOp
        | SMulOverflowOp
        | SSubOverflowOp
        | USubOverflowOp,
    ) -> None:
        res_name = self.result_name(op)
        lhs, rhs = self.operands(op)

        d = {
            UAddOverflowOp: self.b.uadd_with_overflow,
            SAddOverflowOp: self.b.sadd_with_overflow,
            UMulOverflowOp: self.b.umul_with_overflow,
            SMulOverflowOp: self.b.smul_with_overflow,
            USubOverflowOp: self.b.usub_with_overflow,
            SSubOverflowOp: self.b.ssub_with_overflow,
        }

        ov = d[type(op)](lhs, rhs, name=f"{res_name}_ov")
        self.ssa_map[op.results[0]] = self.b.extract_value(ov, 1, name=res_name)

    @add_op.register
    def _(self, op: UShlOverflowOp | SShlOverflowOp) -> None:
        res_name = self.result_name(op)
        lhs, rhs = self.operands(op)

        ty = lower_type(op.result_types[0])
        assert isinstance(ty, ir.IntType)

        bw_const = ir.Constant(ty, ty.width)
        true_const = ir.Constant(ir.IntType(1), 1)
        cmp = self.b.icmp_unsigned(">=", rhs, bw_const, name=f"{res_name}_cmp")

        shl = self.b.shl(lhs, rhs, name=f"{res_name}_shl")
        if isinstance(op, SShlOverflowOp):
            shr = self.b.ashr(shl, rhs, name=f"{res_name}_ashr")
        elif isinstance(op, UShlOverflowOp):
            shr = self.b.lshr(shl, rhs, name=f"{res_name}_ashr")

        ov = self.b.icmp_signed("!=", shr, lhs, name=f"{res_name}_ov")
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

        res = ir.Constant(lower_type(op.results[0].type), None)
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
        | Constant,
    ) -> None:
        ty = lower_type(op.result_types[0])
        assert isinstance(ty, ir.IntType)

        if isinstance(op, GetSignedMaxValueOp):
            val = (2 ** (ty.width - 1)) - 1
        elif isinstance(op, GetSignedMinValueOp):
            val = 2 ** (ty.width - 1)
        elif isinstance(op, GetAllOnesOp):
            val = (2**ty.width) - 1
        elif isinstance(op, GetBitWidthOp):
            val = ty.width
        elif isinstance(op, Constant):
            val: int = op.value.value.data

        self.ssa_map[op.results[0]] = ir.Constant(ty, val)

    @add_op.register
    def _(self, op: UMaxOp | UMinOp | SMaxOp | SMinOp) -> None:
        res_name = self.result_name(op)
        lhs, rhs = self.operands(op)

        if isinstance(op, UMaxOp):
            cmp = self.b.icmp_unsigned(">", lhs, rhs, name=f"{res_name}_cmp")
        elif isinstance(op, UMinOp):
            cmp = self.b.icmp_unsigned("<", lhs, rhs, name=f"{res_name}_cmp")
        elif isinstance(op, SMaxOp):
            cmp = self.b.icmp_signed(">", lhs, rhs, name=f"{res_name}_cmp")
        elif isinstance(op, SMinOp):
            cmp = self.b.icmp_signed("<", lhs, rhs, name=f"{res_name}_cmp")

        self.ssa_map[op.results[0]] = self.b.select(cmp, lhs, rhs, name=res_name)

    @add_op.register
    def _(self, op: IsNegativeOp) -> None:
        oprnd = self.operands(op)[0]
        res_name = self.result_name(op)

        ty = lower_type(op.result_types[0])
        assert isinstance(ty, ir.IntType)

        const_zero = ir.Constant(ty, 0)
        self.ssa_map[op.results[0]] = self.b.icmp_signed(
            "<", oprnd, const_zero, name=res_name
        )

    @add_op.register
    def _(self, op: SetSignBitOp | ClearSignBitOp) -> None:
        oprnd = self.operands(op)[0]
        res_name = self.result_name(op)

        ty = lower_type(op.result_types[0])
        assert isinstance(ty, ir.IntType)

        if isinstance(op, SetSignBitOp):
            mask = ir.Constant(ty, (2 ** (ty.width - 1)))
            self.ssa_map[op.results[0]] = self.b.or_(oprnd, mask, name=res_name)  # type: ignore
        else:
            mask = ir.Constant(ty, ((2 ** (ty.width - 1)) - 1))
            self.ssa_map[op.results[0]] = self.b.and_(oprnd, mask, name=res_name)  # type: ignore

    @add_op.register
    def _(
        self, op: SetHighBitsOp | SetLowBitsOp | ClearHighBitsOp | ClearLowBitsOp
    ) -> None:
        x, n = self.operands(op)
        res_name = self.result_name(op)
        high = isinstance(op, SetHighBitsOp) or isinstance(op, ClearHighBitsOp)

        ty = lower_type(op.result_types[0])
        assert isinstance(ty, ir.IntType)

        allones = ir.Constant(ty, ((2**ty.width) - 1))
        c_zero = ir.Constant(ty, 0)
        c_bw = ir.Constant(ty, ty.width)
        c_bwm1 = ir.Constant(ty, ty.width - 1)

        ge = self.b.icmp_unsigned(">=", n, c_bw, name=f"{res_name}_ge")
        safe_val = c_zero if high else c_bwm1
        safe_n = self.b.select(ge, safe_val, n, name=f"{res_name}_safeN")
        sh_op = self.b.lshr if high else self.b.shl
        sh = sh_op(allones, safe_n, name=f"{res_name}_sh")

        if isinstance(op, SetHighBitsOp) or isinstance(op, SetLowBitsOp):
            inv = self.b.xor(sh, allones, name=f"{res_name}_inv")
            mask = self.b.select(ge, allones, inv, name=f"{res_name}_mask")
            self.ssa_map[op.results[0]] = self.b.or_(x, mask, name=res_name)  # type: ignore
        elif isinstance(op, ClearHighBitsOp) or isinstance(op, ClearLowBitsOp):
            mask = self.b.select(ge, c_zero, sh, name=f"{res_name}_mask")
            self.ssa_map[op.results[0]] = self.b.and_(x, mask, name=res_name)  # type: ignore

    @add_op.register
    def _(self, op: CmpOp) -> None:
        s = self.b.icmp_signed
        us = self.b.icmp_unsigned
        cmp_sign_map = [s, s, s, s, s, s, us, us, us, us]
        cmp_pred_map = ["==", "!=", "<", "<=", ">", ">=", "<", "<=", ">", ">="]

        lhs, rhs = self.operands(op)
        cmp_pred = op.predicate.value.data
        res_name = self.result_name(op)

        self.ssa_map[op.results[0]] = cmp_sign_map[cmp_pred](
            cmp_pred_map[cmp_pred], lhs, rhs, name=res_name
        )

    @add_op.register
    def _(self, op: URemOp | UDivOp) -> None:
        lhs, rhs = self.operands(op)
        res_name = self.result_name(op)

        ty = lower_type(op.result_types[0])
        assert isinstance(ty, ir.IntType)

        zero = ir.Constant(ty, 0)
        one = ir.Constant(ty, 1)
        all_ones = ir.Constant(ty, (2**ty.width) - 1)

        rhs_is_z = self.b.icmp_signed("==", rhs, zero, name=f"{res_name}_rhs_is_zero")
        safe_rhs = self.b.select(rhs_is_z, one, rhs, name=f"{res_name}_safe_rhs")
        if isinstance(op, URemOp):
            raw_op = self.b.urem(lhs, safe_rhs, name=f"{res_name}_raw")
            val = lhs
        elif isinstance(op, UDivOp):
            raw_op = self.b.udiv(lhs, safe_rhs, name=f"{res_name}_raw")
            val = all_ones

        self.ssa_map[op.results[0]] = self.b.select(rhs_is_z, val, raw_op, name=res_name)

    @add_op.register
    def _(self, op: SRemOp | SDivOp) -> None:
        lhs, rhs = self.operands(op)
        res_name = self.result_name(op)

        ty = lower_type(op.result_types[0])
        assert isinstance(ty, ir.IntType)

        zero = ir.Constant(ty, 0)
        one = ir.Constant(ty, 1)
        all_ones = ir.Constant(ty, (2**ty.width) - 1)
        int_min = ir.Constant(ty, (2 ** (ty.width - 1)))

        rhs_0 = self.b.icmp_signed("==", rhs, zero, name=f"{res_name}_rhs_is_zero")

        lhs_is_im = self.b.icmp_signed("==", lhs, int_min, name=f"{res_name}_lhs_is_im")
        rhs_is_m1 = self.b.icmp_signed("==", rhs, all_ones, name=f"{res_name}_rhs_is_m1")
        ov_case = self.b.and_(lhs_is_im, rhs_is_m1, name=f"{res_name}_ov_case")
        ub_case = self.b.or_(rhs_0, ov_case, name=f"{res_name}_ub_case")

        safe_rhs = self.b.select(ub_case, one, rhs, name=f"{res_name}_safe_rhs")
        if isinstance(op, SDivOp):
            raw_sdiv = self.b.sdiv(lhs, safe_rhs, name=f"{res_name}_raw")
            lhs_neg = self.b.icmp_signed("<", lhs, zero, name=f"{res_name}_lhs_is_neg")
            div0_res = self.b.select(lhs_neg, one, all_ones, name=f"{res_name}_div0_res")
            after_div0 = self.b.select(rhs_0, div0_res, raw_sdiv, name=f"{res_name}_div0")
            final = self.b.select(ov_case, int_min, after_div0, name=res_name)
        elif isinstance(op, SRemOp):
            raw_srem = self.b.srem(lhs, safe_rhs, name=f"{res_name}_raw")
            after_div0 = self.b.select(rhs_0, lhs, raw_srem, name=f"{res_name}_div0")
            final = self.b.select(ov_case, zero, after_div0, name=res_name)

        self.ssa_map[op.results[0]] = final

    @add_op.register
    def _(self, op: ShlOp | LShrOp) -> None:
        lhs, rhs = self.operands(op)
        res_name = self.result_name(op)

        ty = lower_type(op.result_types[0])
        assert isinstance(ty, ir.IntType)

        zero = ir.Constant(ty, 0)
        c_bw = ir.Constant(ty, ty.width)

        rhs_ge_bw = self.b.icmp_unsigned(">=", rhs, c_bw, name=f"{res_name}_rhs_ge_bw")
        safe_rhs = self.b.select(rhs_ge_bw, zero, rhs, name=f"{res_name}_safe_rhs")

        if isinstance(op, ShlOp):
            raw_shift = self.b.shl(lhs, safe_rhs, name=f"{res_name}_raw")
        elif isinstance(op, LShrOp):
            raw_shift = self.b.lshr(lhs, safe_rhs, name=f"{res_name}_raw")

        self.ssa_map[op.results[0]] = self.b.select(
            rhs_ge_bw, zero, raw_shift, name=res_name
        )

    @add_op.register
    def _(self, op: AShrOp) -> None:
        lhs, rhs = self.operands(op)
        res_name = self.result_name(op)

        ty = lower_type(op.result_types[0])
        assert isinstance(ty, ir.IntType)

        zero = ir.Constant(ty, 0)
        all_ones = ir.Constant(ty, (2**ty.width) - 1)
        c_bw = ir.Constant(ty, ty.width)

        rhs_ge_bw = self.b.icmp_unsigned(">=", rhs, c_bw, name=f"{res_name}_rhs_ge_bw")
        lhs_is_neg = self.b.icmp_signed("<", lhs, zero, name=f"{res_name}_lhs_is_neg")
        safe_rhs = self.b.select(rhs_ge_bw, zero, rhs, name=f"{res_name}_safe_rhs")
        raw_ashr = self.b.ashr(lhs, safe_rhs, name=f"{res_name}_raw")
        saturated = self.b.select(lhs_is_neg, all_ones, zero, name=f"{res_name}_sat")

        self.ssa_map[op.results[0]] = self.b.select(
            rhs_ge_bw, saturated, raw_ashr, name=res_name
        )
