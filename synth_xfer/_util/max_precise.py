from dataclasses import dataclass, field
from io import StringIO
from pathlib import Path
import re

from xdsl.context import Context
from xdsl.dialects.arith import Arith
from xdsl.dialects.builtin import Builtin, ModuleOp
from xdsl.dialects.func import Func
from xdsl.dialects.smt import ConstantBoolOp
from xdsl.ir import Operation, OpResult
from xdsl.transforms.canonicalize import CanonicalizePass
from xdsl_smt.dialects.smt_bitvector_dialect import ConstantOp
from xdsl_smt.dialects.smt_dialect import (
    AssertOp,
    CallOp,
    DeclareConstOp,
    DefineFunOp,
    EqOp,
)
from xdsl_smt.dialects.smt_utils_dialect import FirstOp, PairOp
from xdsl_smt.dialects.transfer import Transfer
from xdsl_smt.passes.dead_code_elimination import DeadCodeElimination
from xdsl_smt.passes.lower_pairs import LowerPairs
from xdsl_smt.passes.transfer_inline import FunctionCallInline
from xdsl_smt.traits.smt_printer import print_to_smtlib
from xdsl_smt.utils.transfer_function_util import get_argument_instances_with_effect
from z3 import (
    UGE,
    ULE,
    BitVec,
    BitVecRef,
    BitVecVal,
    BoolRef,
    Extract,
    Solver,
    parse_smt2_string,
    sat,
    unknown,
)

from synth_xfer._util.domain import AbstractDomain
from synth_xfer._util.parse_mlir import get_helper_funcs
from synth_xfer._util.verifier import lower_to_smt_module

_CTX: Context | None = None


def _get_ctx() -> Context:
    global _CTX
    if _CTX is None:
        ctx = Context()
        ctx.load_dialect(Arith)
        ctx.load_dialect(Builtin)
        ctx.load_dialect(Func)
        ctx.load_dialect(Transfer)
        _CTX = ctx
    return _CTX


def _get_abst_val(arg: str, domain: AbstractDomain, bw: int) -> tuple[int, int] | None:
    if arg == "(bottom)":
        return None

    def kb_str_to_vals(arg: str) -> tuple[int, int]:
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

        return kb_str_to_vals(arg)
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


@dataclass
class MaxPreciseQueryBuilder:
    domain: AbstractDomain
    bitwidth: int
    abstract_arg_values: list[tuple[int, int]]
    instance_constraint: DefineFunOp
    concrete_op: DefineFunOp
    op_constraint: DefineFunOp | None
    _const_false: ConstantBoolOp = field(init=False, repr=False)

    def _input_vars(self) -> list[DeclareConstOp]:
        input_vars = [
            x
            for x in get_argument_instances_with_effect(self.concrete_op, {})
            if isinstance(x, DeclareConstOp)
        ]
        assert len(input_vars) + 1 == len(self.concrete_op.func_type.inputs)
        return input_vars

    def _get_op_constraint(self, inputs: list[DeclareConstOp]) -> list[Operation]:
        if self.op_constraint is None:
            return []

        const_i1 = ConstantOp.from_int_value(1, 1)
        pair_op = PairOp(const_i1.res, self._const_false.result)
        pair_res_op = PairOp(pair_op.res, self._const_false.result)
        call_op = CallOp(self.op_constraint.ret, inputs + [self._const_false.result])
        eq_op = EqOp(pair_res_op.res, call_op.res[0])
        assert_op = AssertOp(eq_op.res)
        return [const_i1, pair_op, pair_res_op, call_op, eq_op, assert_op]

    def _to_pair_value(self, val_list: list[ConstantOp]) -> tuple[list[PairOp], OpResult]:
        last_val = self._const_false.result
        result: list[PairOp] = []
        for val in val_list[::-1]:
            result.append(PairOp(val.res, last_val))
            last_val = result[-1].res
        return result, result[-1].res

    def _abstract_values(self) -> tuple[list[Operation], list[OpResult]]:
        ops: list[Operation] = []
        values: list[OpResult] = []
        for abst_bv in self.abstract_arg_values:
            constant_ops = [
                ConstantOp.from_int_value(x % (2**self.bitwidth), self.bitwidth)
                for x in abst_bv
            ]
            pair_ops, pair_value = self._to_pair_value(constant_ops)
            ops += constant_ops + pair_ops
            values.append(pair_value)
        return ops, values

    def _get_in_constraint(
        self,
        abstract_inputs: list[OpResult],
        inputs: list[DeclareConstOp],
    ) -> list[Operation]:
        result: list[Operation] = []
        constant_i1 = ConstantOp.from_int_value(1, 1)
        pair_op = PairOp(constant_i1.res, self._const_false.result)
        pair_res_op = PairOp(pair_op.res, self._const_false.result)
        for abstract_input, concrete_input in zip(abstract_inputs, inputs):
            call_op = CallOp(
                self.instance_constraint.ret,
                [abstract_input, concrete_input, self._const_false.result],
            )
            eq_op = EqOp(pair_res_op.res, call_op.res[0])
            assert_op = AssertOp(eq_op.res)

            result += [call_op, eq_op, assert_op]
        return [constant_i1, pair_op, pair_res_op] + result

    def build(self) -> ModuleOp:
        input_arguments = self._input_vars()
        self._const_false = ConstantBoolOp(False)

        abstract_ops, abstract_inputs = self._abstract_values()
        op_constraint = self._get_op_constraint(input_arguments)
        concrete_call = CallOp(self.concrete_op.ret, input_arguments)
        concrete_result = FirstOp(concrete_call.res[0])

        result_var = DeclareConstOp(concrete_result.res.type)
        result_var.res.name_hint = "result"
        result_eq = EqOp(result_var.res, concrete_result.res)
        result_assert = AssertOp(result_eq.res)

        return ModuleOp(
            input_arguments
            + [self._const_false]
            + abstract_ops
            + op_constraint
            + self._get_in_constraint(abstract_inputs, input_arguments)
            + [concrete_call, concrete_result, result_var, result_eq, result_assert]
        )


@dataclass(frozen=True)
class PreparedQuery:
    solver: Solver
    result: BitVecRef
    timeout: int

    @classmethod
    def from_module(
        cls, ctx: Context, smt_mod: ModuleOp, bitwidth: int, timeout: int
    ) -> "PreparedQuery":
        module = smt_mod.clone()
        FunctionCallInline(True, {}).apply(ctx, module)
        LowerPairs().apply(ctx, module)
        CanonicalizePass().apply(ctx, module)
        DeadCodeElimination().apply(ctx, module)
        stream = StringIO()
        print_to_smtlib(module, stream)

        solver = Solver()
        solver.set(timeout=timeout * 1000)
        solver.add(parse_smt2_string(stream.getvalue()))
        return cls(solver=solver, result=BitVec("$result", bitwidth), timeout=timeout)

    def is_sat(self) -> bool:
        result = self.solver.check()
        if result == unknown:
            raise TimeoutError()
        return result == sat

    def check(self, probe: BoolRef) -> bool:
        self.solver.push()
        try:
            self.solver.add(probe)
            result = self.solver.check()
        finally:
            self.solver.pop()

        if result == unknown:
            raise TimeoutError()
        return result == sat

    def bv_val(self, val: int) -> BitVecRef:
        return BitVecVal(val, self.result.size())


@dataclass(frozen=True)
class ComputeMaxPrecise:
    query: PreparedQuery
    bitwidth: int

    def compute(self) -> str:
        raise NotImplementedError


@dataclass(frozen=True)
class KnownBitsMaxPrecise(ComputeMaxPrecise):
    def check_ith_bit(self, ith: int) -> str | None:
        ith_bit = Extract(ith, ith, self.query.result)
        probe_z = ith_bit == BitVecVal(0, 1)
        probe_o = ith_bit == BitVecVal(1, 1)
        assert isinstance(probe_z, BoolRef)
        assert isinstance(probe_o, BoolRef)
        can_be_z = self.query.check(probe_z)
        can_be_o = self.query.check(probe_o)
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
    def _can_be_leq(self, val: int) -> bool:
        return self.query.check(self._cmp_leq(self.query.result, val))

    def _can_be_geq(self, val: int) -> bool:
        return self.query.check(self._cmp_geq(self.query.result, val))

    def _cmp_leq(self, concrete_res: BitVecRef, val: int) -> BoolRef:
        raise NotImplementedError

    def _cmp_geq(self, concrete_res: BitVecRef, val: int) -> BoolRef:
        raise NotImplementedError

    def min_value(self) -> int:
        raise NotImplementedError

    def max_value(self) -> int:
        raise NotImplementedError

    def format_result(self, lower_bound: int, upper_bound: int) -> str:
        raise NotImplementedError

    def lower_bound(self) -> int | None:
        if not self.query.is_sat():
            return None

        lo, hi = self.min_value(), self.max_value()
        while lo < hi:
            mid = (lo + hi) // 2
            if self._can_be_leq(mid):
                hi = mid
            else:
                lo = mid + 1
        return lo

    def upper_bound(self, lower_bound: int) -> int:
        lo, hi = lower_bound, self.max_value()
        while lo < hi:
            mid = (lo + hi + 1) // 2
            if self._can_be_geq(mid):
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
    def _cmp_leq(self, concrete_res: BitVecRef, val: int) -> BoolRef:
        return ULE(concrete_res, self.query.bv_val(val))

    def _cmp_geq(self, concrete_res: BitVecRef, val: int) -> BoolRef:
        return UGE(concrete_res, self.query.bv_val(val))

    def min_value(self) -> int:
        return 0

    def max_value(self) -> int:
        return 2**self.bitwidth - 1

    def format_result(self, lower_bound: int, upper_bound: int) -> str:
        return f"[{lower_bound}, {upper_bound}]"


@dataclass(frozen=True)
class SConstRangeMaxPrecise(IntervalMaxPrecise):
    def _cmp_leq(self, concrete_res: BitVecRef, val: int) -> BoolRef:
        return concrete_res <= self.query.bv_val(val)

    def _cmp_geq(self, concrete_res: BitVecRef, val: int) -> BoolRef:
        return concrete_res >= self.query.bv_val(val)

    def min_value(self) -> int:
        return -(2**self.bitwidth // 2)

    def max_value(self) -> int:
        return (2**self.bitwidth // 2) - 1

    def format_result(self, lower_bound: int, upper_bound: int) -> str:
        return f"[{lower_bound}, {upper_bound}]"


def _get_max_precise_computer(
    domain: AbstractDomain, query: PreparedQuery, bw: int
) -> ComputeMaxPrecise:
    if domain == AbstractDomain.KnownBits:
        return KnownBitsMaxPrecise(query, bw)
    if domain == AbstractDomain.UConstRange:
        return UConstRangeMaxPrecise(query, bw)
    if domain == AbstractDomain.SConstRange:
        return SConstRangeMaxPrecise(query, bw)

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
    ctx = _get_ctx()

    hlprs = get_helper_funcs(op_path, domain)
    parsed_args = [_get_abst_val(arg, domain, bw) for arg in args]
    if any(arg is None for arg in parsed_args):
        return "(bottom)"
    abst_arg_values = [arg for arg in parsed_args if arg is not None]

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

    query = PreparedQuery.from_module(ctx, smt_mod, bw, timeout)
    computer = _get_max_precise_computer(domain, query, bw)
    return computer.compute()
