from typing import TYPE_CHECKING, Callable, cast

from synth_xfer._eval_engine import (
    ToEvalAntiRange4,
    ToEvalAntiRange8,
    ToEvalAntiRange16,
    ToEvalAntiRange32,
    ToEvalAntiRange64,
    ToEvalKnownBits4,
    ToEvalKnownBits8,
    ToEvalKnownBits16,
    ToEvalKnownBits32,
    ToEvalKnownBits64,
    ToEvalUConstRange4,
    ToEvalUConstRange8,
    ToEvalUConstRange16,
    ToEvalUConstRange32,
    ToEvalUConstRange64,
    enum_low_antirange_4,
    enum_low_antirange_8,
    enum_low_antirange_16,
    enum_low_antirange_32,
    enum_low_antirange_64,
    enum_low_knownbits_4,
    enum_low_knownbits_8,
    enum_low_knownbits_16,
    enum_low_knownbits_32,
    enum_low_knownbits_64,
    enum_low_uconstrange_4,
    enum_low_uconstrange_8,
    enum_low_uconstrange_16,
    enum_low_uconstrange_32,
    enum_low_uconstrange_64,
    enum_mid_antirange_4,
    enum_mid_antirange_8,
    enum_mid_antirange_16,
    enum_mid_antirange_32,
    enum_mid_antirange_64,
    enum_mid_knownbits_4,
    enum_mid_knownbits_8,
    enum_mid_knownbits_16,
    enum_mid_knownbits_32,
    enum_mid_knownbits_64,
    enum_mid_uconstrange_4,
    enum_mid_uconstrange_8,
    enum_mid_uconstrange_16,
    enum_mid_uconstrange_32,
    enum_mid_uconstrange_64,
    eval_antirange_4,
    eval_antirange_8,
    eval_antirange_16,
    eval_antirange_32,
    eval_antirange_64,
    eval_knownbits_4,
    eval_knownbits_8,
    eval_knownbits_16,
    eval_knownbits_32,
    eval_knownbits_64,
    eval_uconstrange_4,
    eval_uconstrange_8,
    eval_uconstrange_16,
    eval_uconstrange_32,
    eval_uconstrange_64,
)
from synth_xfer._util.domain import AbstractDomain
from synth_xfer._util.eval_result import EvalResult, PerBitRes, get_per_bit
from synth_xfer._util.jit import Jit
from synth_xfer._util.lower import LowerToLLVM
from synth_xfer._util.parse_mlir import HelperFuncs

if TYPE_CHECKING:
    from synth_xfer._eval_engine import BW, Results, ToEval


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
        (AbstractDomain.AntiRange, 4): enum_low_antirange_4,
        (AbstractDomain.AntiRange, 8): enum_low_antirange_8,
        (AbstractDomain.AntiRange, 16): enum_low_antirange_16,
        (AbstractDomain.AntiRange, 32): enum_low_antirange_32,
        (AbstractDomain.AntiRange, 64): enum_low_antirange_64,
        (AbstractDomain.UConstRange, 4): enum_low_uconstrange_4,
        (AbstractDomain.UConstRange, 8): enum_low_uconstrange_8,
        (AbstractDomain.UConstRange, 16): enum_low_uconstrange_16,
        (AbstractDomain.UConstRange, 32): enum_low_uconstrange_32,
        (AbstractDomain.UConstRange, 64): enum_low_uconstrange_64,
        (AbstractDomain.KnownBits, 4): enum_low_knownbits_4,
        (AbstractDomain.KnownBits, 8): enum_low_knownbits_8,
        (AbstractDomain.KnownBits, 16): enum_low_knownbits_16,
        (AbstractDomain.KnownBits, 32): enum_low_knownbits_32,
        (AbstractDomain.KnownBits, 64): enum_low_knownbits_64,
    }

    mid_fns: dict[
        tuple[AbstractDomain, BW], Callable[[int, int | None, int, int], "ToEval"]
    ] = {
        (AbstractDomain.AntiRange, 4): enum_mid_antirange_4,
        (AbstractDomain.AntiRange, 8): enum_mid_antirange_8,
        (AbstractDomain.AntiRange, 16): enum_mid_antirange_16,
        (AbstractDomain.AntiRange, 32): enum_mid_antirange_32,
        (AbstractDomain.AntiRange, 64): enum_mid_antirange_64,
        (AbstractDomain.UConstRange, 4): enum_mid_uconstrange_4,
        (AbstractDomain.UConstRange, 8): enum_mid_uconstrange_8,
        (AbstractDomain.UConstRange, 16): enum_mid_uconstrange_16,
        (AbstractDomain.UConstRange, 32): enum_mid_uconstrange_32,
        (AbstractDomain.UConstRange, 64): enum_mid_uconstrange_64,
        (AbstractDomain.KnownBits, 4): enum_mid_knownbits_4,
        (AbstractDomain.KnownBits, 8): enum_mid_knownbits_8,
        (AbstractDomain.KnownBits, 16): enum_mid_knownbits_16,
        (AbstractDomain.KnownBits, 32): enum_mid_knownbits_32,
        (AbstractDomain.KnownBits, 64): enum_mid_knownbits_64,
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
        ToEvalAntiRange4: cast(EvalFn, eval_antirange_4),
        ToEvalAntiRange8: cast(EvalFn, eval_antirange_8),
        ToEvalAntiRange16: cast(EvalFn, eval_antirange_16),
        ToEvalAntiRange32: cast(EvalFn, eval_antirange_32),
        ToEvalAntiRange64: cast(EvalFn, eval_antirange_64),
        ToEvalUConstRange4: cast(EvalFn, eval_uconstrange_4),
        ToEvalUConstRange8: cast(EvalFn, eval_uconstrange_8),
        ToEvalUConstRange16: cast(EvalFn, eval_uconstrange_16),
        ToEvalUConstRange32: cast(EvalFn, eval_uconstrange_32),
        ToEvalUConstRange64: cast(EvalFn, eval_uconstrange_64),
    }
    res = d[type(to_eval)](to_eval, xfers, bases)

    return _parse_engine_output(str(res))
