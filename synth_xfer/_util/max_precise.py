from dataclasses import dataclass
from io import StringIO
from pathlib import Path
import re

from xdsl.context import Context
from xdsl.dialects.arith import Arith
from xdsl.dialects.builtin import Builtin, ModuleOp
from xdsl.dialects.func import Func
from xdsl.dialects.smt import BitVectorType, BoolType, ConstantBoolOp
from xdsl.ir import Operation, SSAValue
from xdsl.transforms.canonicalize import CanonicalizePass
from xdsl_smt.dialects.smt_bitvector_dialect import (
    ConstantOp,
    ExtractOp,
    SgeOp,
    SleOp,
    UgeOp,
    UleOp,
)
from xdsl_smt.dialects.smt_dialect import (
    AssertOp,
    CallOp,
    DeclareConstOp,
    DefineFunOp,
    EqOp,
)
from xdsl_smt.dialects.smt_utils_dialect import FirstOp, PairOp, PairType
from xdsl_smt.dialects.transfer import Transfer
from xdsl_smt.passes.dead_code_elimination import DeadCodeElimination
from xdsl_smt.passes.lower_pairs import LowerPairs
from xdsl_smt.passes.transfer_inline import FunctionCallInline
from xdsl_smt.traits.smt_printer import print_to_smtlib
from xdsl_smt.utils.transfer_function_util import get_argument_instances_with_effect
from z3 import Solver, parse_smt2_string, sat, unknown

from synth_xfer._util.domain import AbstractDomain
from synth_xfer._util.parse_mlir import get_helper_funcs
from synth_xfer._util.verifier import lower_to_smt_module

CmpOp = UleOp | UgeOp | SleOp | SgeOp


def _get_abst_val(arg: str, domain: AbstractDomain, bw: int) -> tuple[int, int]:
    def _kb_str_to_vals(arg: str) -> tuple[int, int]:
        known_z, known_o = 0, 0

        for ch in arg:
            if ch == "0":
                known_z |= 1
            elif ch == "1":
                known_o |= 1
            known_z <<= 1
            known_o <<= 1

        known_z >>= 1
        known_o >>= 1
        return known_z, known_o

    if domain == AbstractDomain.KnownBits:
        if len(arg) != bw:
            raise ValueError(f"arg len: {len(arg)} != bitwidth: {bw}")

        return _kb_str_to_vals(arg)
    if domain == AbstractDomain.UConstRange:
        m = re.match(r"^\[(\d+), (\d+)\]$", arg)
        if not m or not m.group(1).isnumeric() or not m.group(2).isnumeric():
            raise ValueError(f"arg: {arg} is malformed")
        else:
            lb, ub = int(m.group(1)), int(m.group(2))
            if lb < 0 or lb >= 2**bw or ub < 0 or ub >= 2**bw or lb > ub:
                raise ValueError(f"arg: {arg} out of range")

        return lb, ub
    if domain == AbstractDomain.SConstRange:
        imin = -(2**bw // 2)
        imax = (2**bw // 2) - 1
        m = re.match(r"^\[(-?\d+), (-?\d+)\]$", arg)
        if not m:
            raise ValueError(f"arg: {arg} is malformed")
        else:
            lb, ub = int(m.group(1)), int(m.group(2))
            if lb < imin or lb > imax or ub < imin or ub > imax or lb > ub:
                raise ValueError(f"arg: {arg} out of range")
        return lb, ub

    raise NotImplementedError(f"Max precise not implemented for {domain} yet")


def _to_bv_const(val: int, bitwidth: int) -> ConstantOp:
    return ConstantOp.from_int_value(val % (2**bitwidth), bitwidth)


@dataclass(frozen=True)
class MaxPreciseQueryBuilder:
    domain: AbstractDomain
    bitwidth: int
    abstract_arg_values: list[tuple[int, int]]
    instance_constraint: DefineFunOp
    concrete_op: DefineFunOp
    op_constraint: DefineFunOp | None
    false = ConstantBoolOp(False)

    def _input_vars(self) -> list[DeclareConstOp]:
        input_vars = [
            x
            for x in get_argument_instances_with_effect(self.concrete_op, {})
            if isinstance(x, DeclareConstOp)
        ]
        assert len(input_vars) + 1 == len(self.concrete_op.func_type.inputs)
        return input_vars

    def _abstract_vars(self, inputs: list[DeclareConstOp]) -> list[DeclareConstOp]:
        arity = len(inputs)
        conc_ty = inputs[0].res.type
        assert isinstance(conc_ty, BitVectorType)

        abstract_type = BoolType()
        for _ in range(self.domain.vec_size):
            abstract_type = PairType(conc_ty, abstract_type)

        return [DeclareConstOp(abstract_type) for _ in range(arity)]

    def _get_op_constraint(self, inputs: list[DeclareConstOp]) -> list[Operation]:
        if self.op_constraint is None:
            return []

        const_i1 = ConstantOp.from_int_value(1, 1)
        pair_op = PairOp(const_i1.res, self.false.result)
        pair_res_op = PairOp(pair_op.res, self.false.result)
        call_op = CallOp(self.op_constraint.ret, inputs + [self.false.result])
        eq_op = EqOp(pair_res_op.res, call_op.res[0])
        assert_op = AssertOp(eq_op.res)

        return [const_i1, self.false, pair_op, pair_res_op, call_op, eq_op, assert_op]

    def _to_pair_op(self, val_list: list[ConstantOp]) -> list[PairOp]:
        last_val = self.false.result
        result: list[PairOp] = []
        for val in val_list[::-1]:
            result.append(PairOp(val.res, last_val))
            last_val = result[-1].res

        return result

    def _get_abst_constraint(self, abst_arg_tys: list[DeclareConstOp]) -> list[Operation]:
        result: list[Operation] = []
        for abst_bv, abst_arg_type in zip(self.abstract_arg_values, abst_arg_tys):
            constant_ops = [_to_bv_const(x, self.bitwidth) for x in abst_bv]
            pair_op = self._to_pair_op(constant_ops)
            eq_op = EqOp(pair_op[-1].res, abst_arg_type.res)
            assert_op = AssertOp(eq_op.res)
            result += constant_ops + pair_op + [eq_op, assert_op]

        return result

    def _get_in_constraint(
        self, abstract_inputs: list[DeclareConstOp], inputs: list[DeclareConstOp]
    ) -> list[Operation]:
        result: list[Operation] = []
        constant_i1 = ConstantOp.from_int_value(1, 1)
        pair_op = PairOp(constant_i1.res, self.false.result)
        pair_res_op = PairOp(pair_op.res, self.false.result)
        for abstract_input, concrete_input in zip(abstract_inputs, inputs):
            call_op = CallOp(
                self.instance_constraint.ret,
                [abstract_input, concrete_input, self.false.result],
            )
            eq_op = EqOp(pair_res_op.res, call_op.res[0])
            assert_op = AssertOp(eq_op.res)

            result += [call_op, eq_op, assert_op]
        return [constant_i1, self.false, pair_op, pair_res_op] + result

    def build(self) -> ModuleOp:
        input_arguments = self._input_vars()
        abstract_inputs = self._abstract_vars(input_arguments)
        op_constraint = self._get_op_constraint(input_arguments)

        return ModuleOp(
            input_arguments
            + abstract_inputs
            + self._get_abst_constraint(abstract_inputs)
            + op_constraint
            + self._get_in_constraint(abstract_inputs, input_arguments)
            + [CallOp(self.concrete_op.ret, input_arguments)]
        )


@dataclass(frozen=True)
class ComputeMaxPrecise:
    ctx: Context
    timeout: int
    verify_module: ModuleOp
    bitwidth: int

    def _make_z3_call(self, module: ModuleOp) -> bool:
        FunctionCallInline(True, {}).apply(self.ctx, module)
        LowerPairs().apply(self.ctx, module)
        CanonicalizePass().apply(self.ctx, module)
        DeadCodeElimination().apply(self.ctx, module)
        stream = StringIO()
        print_to_smtlib(module, stream)

        solver = Solver()
        solver.set(timeout=self.timeout * 1000)
        solver.add(parse_smt2_string(stream.getvalue()))

        result = solver.check()
        if result == unknown:
            raise TimeoutError()
        return result == sat

    def _get_concrete_result(self, module: ModuleOp) -> FirstOp:
        block = module.body.block
        concrete_res = block.last_op
        assert isinstance(concrete_res, CallOp)
        first_op = FirstOp(concrete_res.res[0])
        block.add_op(first_op)
        return first_op

    def compute(self) -> str:
        raise NotImplementedError


@dataclass(frozen=True)
class KnownBitsMaxPrecise(ComputeMaxPrecise):
    def _ith_bit_is(self, module: ModuleOp, ith_bit: int, bit_val: int) -> bool:
        concrete_res = self._get_concrete_result(module)
        ith_bit_op = ExtractOp(concrete_res.res, ith_bit, ith_bit)
        const_bv_op = ConstantOp.from_int_value(bit_val, 1)
        eq_op = EqOp(ith_bit_op.res, const_bv_op.res)
        assert_op = AssertOp(eq_op.res)
        module.body.block.add_ops([ith_bit_op, const_bv_op, eq_op, assert_op])
        return self._make_z3_call(module)

    def check_ith_bit(self, ith: int) -> str | None:
        can_be_z = self._ith_bit_is(self.verify_module.clone(), ith, 0)
        can_be_o = self._ith_bit_is(self.verify_module.clone(), ith, 1)
        if can_be_o and can_be_z:
            return "?"
        if (not can_be_z) and (not can_be_o):
            return None
        if not can_be_z:
            return "1"
        if not can_be_o:
            return "0"
        raise AssertionError("unreachable")

    def compute(self) -> str:
        result = ""
        for i in range(self.bitwidth):
            ith_result = self.check_ith_bit(i)
            if ith_result is None:
                return "(bottom)"
            result = ith_result + result
        return result


@dataclass(frozen=True)
class IntervalMaxPrecise(ComputeMaxPrecise):
    def _can_be_leq(self, module: ModuleOp, val: int) -> bool:
        concrete_res = self._get_concrete_result(module)
        const_bv_op, cmp_op = self._cmp_leq(concrete_res.res, val)
        assert_op = AssertOp(cmp_op.res)
        module.body.block.add_ops([const_bv_op, cmp_op, assert_op])
        return self._make_z3_call(module)

    def _can_be_geq(self, module: ModuleOp, val: int) -> bool:
        concrete_res = self._get_concrete_result(module)
        const_bv_op, cmp_op = self._cmp_geq(concrete_res.res, val)
        assert_op = AssertOp(cmp_op.res)
        module.body.block.add_ops([const_bv_op, cmp_op, assert_op])
        return self._make_z3_call(module)

    def _cmp_leq(self, concrete_res: SSAValue, val: int) -> tuple[ConstantOp, CmpOp]:
        raise NotImplementedError

    def _cmp_geq(self, concrete_res: SSAValue, val: int) -> tuple[ConstantOp, CmpOp]:
        raise NotImplementedError

    def min_value(self) -> int:
        raise NotImplementedError

    def max_value(self) -> int:
        raise NotImplementedError

    def format_result(self, lower_bound: int, upper_bound: int) -> str:
        raise NotImplementedError

    def lower_bound(self) -> int | None:
        if not self._make_z3_call(self.verify_module.clone()):
            return None

        lo, hi = self.min_value(), self.max_value()
        while lo < hi:
            mid = (lo + hi) // 2
            if self._can_be_leq(self.verify_module.clone(), mid):
                hi = mid
            else:
                lo = mid + 1
        return lo

    def upper_bound(self, lower_bound: int) -> int:
        lo, hi = lower_bound, self.max_value()
        while lo < hi:
            mid = (lo + hi + 1) // 2
            if self._can_be_geq(self.verify_module.clone(), mid):
                lo = mid
            else:
                hi = mid - 1
        return lo

    def compute(self) -> str:
        lower_bound = self.lower_bound()
        if lower_bound is None:
            return "(bottom)"
        return self.format_result(lower_bound, self.upper_bound(lower_bound))


@dataclass(frozen=True)
class UConstRangeMaxPrecise(IntervalMaxPrecise):
    def _cmp_leq(self, concrete_res: SSAValue, val: int) -> tuple[ConstantOp, CmpOp]:
        const_bv_op = _to_bv_const(val, self.bitwidth)
        cmp_op = UleOp(concrete_res, const_bv_op.res)
        return const_bv_op, cmp_op

    def _cmp_geq(self, concrete_res: SSAValue, val: int) -> tuple[ConstantOp, CmpOp]:
        const_bv_op = _to_bv_const(val, self.bitwidth)
        cmp_op = UgeOp(concrete_res, const_bv_op.res)
        return const_bv_op, cmp_op

    def min_value(self) -> int:
        return 0

    def max_value(self) -> int:
        return 2**self.bitwidth - 1

    def format_result(self, lower_bound: int, upper_bound: int) -> str:
        return f"[{lower_bound}, {upper_bound}]"


@dataclass(frozen=True)
class SConstRangeMaxPrecise(IntervalMaxPrecise):
    def _cmp_leq(self, concrete_res: SSAValue, val: int) -> tuple[ConstantOp, CmpOp]:
        const_bv_op = _to_bv_const(val, self.bitwidth)
        cmp_op = SleOp(concrete_res, const_bv_op.res)
        return const_bv_op, cmp_op

    def _cmp_geq(self, concrete_res: SSAValue, val: int) -> tuple[ConstantOp, CmpOp]:
        const_bv_op = _to_bv_const(val, self.bitwidth)
        cmp_op = SgeOp(concrete_res, const_bv_op.res)
        return const_bv_op, cmp_op

    def min_value(self) -> int:
        return -(2**self.bitwidth // 2)

    def max_value(self) -> int:
        return (2**self.bitwidth // 2) - 1

    def format_result(self, lower_bound: int, upper_bound: int) -> str:
        return f"[{lower_bound}, {upper_bound}]"


def _get_max_precise_computer(
    domain: AbstractDomain,
    ctx: Context,
    timeout: int,
    smt_mod: ModuleOp,
    bw: int,
) -> ComputeMaxPrecise:
    if domain == AbstractDomain.KnownBits:
        return KnownBitsMaxPrecise(ctx, timeout, smt_mod, bw)
    if domain == AbstractDomain.UConstRange:
        return UConstRangeMaxPrecise(ctx, timeout, smt_mod, bw)
    if domain == AbstractDomain.SConstRange:
        return SConstRangeMaxPrecise(ctx, timeout, smt_mod, bw)

    raise NotImplementedError(f"Max precise not implemented for {domain}")


@dataclass(frozen=True)
class RowTask:
    index: int
    bw: int
    args: tuple[str, ...]


@dataclass(frozen=True)
class RowResult:
    index: int
    ideal: str | None = None
    timed_out: bool = False


@dataclass(frozen=True)
class RowProcessor:
    op_path: Path
    domain: AbstractDomain
    timeout: int

    def __call__(self, task: RowTask) -> RowResult:
        try:
            return RowResult(
                index=task.index,
                ideal=compute_max_precise(
                    self.op_path, self.domain, task.bw, task.args, self.timeout
                ),
            )
        except TimeoutError:
            return RowResult(index=task.index, timed_out=True)


def compute_max_precise(
    op_path: Path,
    domain: AbstractDomain,
    bw: int,
    args: tuple[str, ...],
    timeout: int,
) -> str:
    ctx = Context()
    ctx.load_dialect(Arith)
    ctx.load_dialect(Builtin)
    ctx.load_dialect(Func)
    ctx.load_dialect(Transfer)

    hlprs = get_helper_funcs(op_path, domain)
    abst_arg_values = [_get_abst_val(arg, domain, bw) for arg in args]

    fns = [hlprs.instance_constraint_func, hlprs.crt_func, hlprs.op_constraint_func]
    lower_to_smt_module(m := ModuleOp([x.clone() for x in fns if x is not None]), bw, ctx)
    m_ops = iter(m.ops)
    instance_constraint = next(m_ops)
    concrete_op = next(m_ops)
    op_constraint = next(m_ops, None)
    assert isinstance(instance_constraint, DefineFunOp)
    assert isinstance(concrete_op, DefineFunOp)
    assert isinstance(op_constraint, DefineFunOp) or op_constraint is None

    smt_mod = MaxPreciseQueryBuilder(
        domain=domain,
        bitwidth=bw,
        abstract_arg_values=abst_arg_values,
        instance_constraint=instance_constraint,
        concrete_op=concrete_op,
        op_constraint=op_constraint,
    ).build()

    computer = _get_max_precise_computer(domain, ctx, timeout, smt_mod, bw)
    return computer.compute()
