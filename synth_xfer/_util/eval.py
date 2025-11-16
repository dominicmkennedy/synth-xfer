from enum import Enum
from typing import TYPE_CHECKING, Callable, cast

from synth_xfer._eval_engine import (
    ToEvalConstRange4,
    ToEvalConstRange8,
    ToEvalConstRange16,
    ToEvalConstRange32,
    ToEvalConstRange64,
    ToEvalKnownBits4,
    ToEvalKnownBits8,
    ToEvalKnownBits16,
    ToEvalKnownBits32,
    ToEvalKnownBits64,
    enum_low_constrange_4,
    enum_low_constrange_8,
    enum_low_constrange_16,
    enum_low_constrange_32,
    enum_low_constrange_64,
    enum_low_knownbits_4,
    enum_low_knownbits_8,
    enum_low_knownbits_16,
    enum_low_knownbits_32,
    enum_low_knownbits_64,
    enum_mid_constrange_4,
    enum_mid_constrange_8,
    enum_mid_constrange_16,
    enum_mid_constrange_32,
    enum_mid_constrange_64,
    enum_mid_knownbits_4,
    enum_mid_knownbits_8,
    enum_mid_knownbits_16,
    enum_mid_knownbits_32,
    enum_mid_knownbits_64,
    eval_constrange_4,
    eval_constrange_8,
    eval_constrange_16,
    eval_constrange_32,
    eval_constrange_64,
    eval_knownbits_4,
    eval_knownbits_8,
    eval_knownbits_16,
    eval_knownbits_32,
    eval_knownbits_64,
)
from synth_xfer._util.eval_result import EvalResult, PerBitRes, get_per_bit
from synth_xfer._util.helper_funcs import HelperFuncs
from synth_xfer.jit import Jit
from synth_xfer.lower_to_llvm import LowerToLLVM

if TYPE_CHECKING:
    from synth_xfer._eval_engine import BW, Results, ToEval


class AbstractDomain(Enum):
    KnownBits = "KnownBits", 2
    ConstRange = "ConstRange", 2
    # TODO impl
    # SConstRange = "SConstRange", 2
    # IntegerModulo = "IntegerModulo", 6

    vec_size: int

    def __new__(
        cls,
        value: str,
        vec_size: int,
    ):
        obj = object.__new__(cls)
        obj._value_ = value
        obj.vec_size = vec_size
        return obj

    def __str__(self) -> str:
        return self.name


def _parse_engine_output(output: str) -> list[EvalResult]:
    bw_evals = output.split("---\n")
    bw_evals.reverse()
    per_bits = [get_per_bit(x) for x in bw_evals if x != ""]

    ds: list[list[PerBitRes]] = [[] for _ in range(len(per_bits[0]))]
    for es in per_bits:
        for i, e in enumerate(es):
            ds[i].append(e)

    return [EvalResult(x) for x in ds]


def setup_eval(
    bw: "BW",
    samples: int | None,
    seed: int,
    helper_funcs: HelperFuncs,
    domain: AbstractDomain,
    jit: Jit,
) -> "ToEval":
    lowerer = LowerToLLVM(bw)
    crt = lowerer.add_fn(helper_funcs.crt_func, shim=True)
    op_constraint = (
        lowerer.add_fn(helper_funcs.op_constraint_func, shim=True)
        if helper_funcs.op_constraint_func
        else None
    )

    jit.add_mod(str(lowerer))
    concrete_fn_ptr = jit.get_fn_ptr(crt.name)
    constraint_fn_ptr = jit.get_fn_ptr(op_constraint.name) if op_constraint else None

    low_fns: dict[tuple[AbstractDomain, BW], Callable[[int, int | None], "ToEval"]] = {
        (AbstractDomain.KnownBits, 4): enum_low_knownbits_4,
        (AbstractDomain.KnownBits, 8): enum_low_knownbits_8,
        (AbstractDomain.KnownBits, 16): enum_low_knownbits_16,
        (AbstractDomain.KnownBits, 32): enum_low_knownbits_32,
        (AbstractDomain.KnownBits, 64): enum_low_knownbits_64,
        (AbstractDomain.ConstRange, 4): enum_low_constrange_4,
        (AbstractDomain.ConstRange, 8): enum_low_constrange_8,
        (AbstractDomain.ConstRange, 16): enum_low_constrange_16,
        (AbstractDomain.ConstRange, 32): enum_low_constrange_32,
        (AbstractDomain.ConstRange, 64): enum_low_constrange_64,
    }

    mid_fns: dict[
        tuple[AbstractDomain, BW], Callable[[int, int | None, int, int], "ToEval"]
    ] = {
        (AbstractDomain.KnownBits, 4): enum_mid_knownbits_4,
        (AbstractDomain.KnownBits, 8): enum_mid_knownbits_8,
        (AbstractDomain.KnownBits, 16): enum_mid_knownbits_16,
        (AbstractDomain.KnownBits, 32): enum_mid_knownbits_32,
        (AbstractDomain.KnownBits, 64): enum_mid_knownbits_64,
        (AbstractDomain.ConstRange, 4): enum_mid_constrange_4,
        (AbstractDomain.ConstRange, 8): enum_mid_constrange_8,
        (AbstractDomain.ConstRange, 16): enum_mid_constrange_16,
        (AbstractDomain.ConstRange, 32): enum_mid_constrange_32,
        (AbstractDomain.ConstRange, 64): enum_mid_constrange_64,
    }

    if samples:
        return mid_fns[domain, bw](concrete_fn_ptr, constraint_fn_ptr, samples, seed)
    else:
        return low_fns[domain, bw](concrete_fn_ptr, constraint_fn_ptr)


EvalFn = Callable[["ToEval", list[int], list[int]], "Results"]


# TODO may want to just pass whole jit in here
def eval_transfer_func(
    to_eval: "ToEval",
    xfers: list[int],
    bases: list[int],
) -> list[EvalResult]:
    d: dict[type[ToEval], EvalFn] = {
        ToEvalKnownBits4: cast(EvalFn, eval_knownbits_4),
        ToEvalKnownBits8: cast(EvalFn, eval_knownbits_8),
        ToEvalKnownBits16: cast(EvalFn, eval_knownbits_16),
        ToEvalKnownBits32: cast(EvalFn, eval_knownbits_32),
        ToEvalKnownBits64: cast(EvalFn, eval_knownbits_64),
        ToEvalConstRange4: cast(EvalFn, eval_constrange_4),
        ToEvalConstRange8: cast(EvalFn, eval_constrange_8),
        ToEvalConstRange16: cast(EvalFn, eval_constrange_16),
        ToEvalConstRange32: cast(EvalFn, eval_constrange_32),
        ToEvalConstRange64: cast(EvalFn, eval_constrange_64),
    }
    res = d[type(to_eval)](to_eval, xfers, bases)

    return _parse_engine_output(str(res))
