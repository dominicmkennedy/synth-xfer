from collections.abc import Iterator
from ctypes import CFUNCTYPE, c_bool, c_int64
from typing import Callable, Protocol, TypeAlias, cast, runtime_checkable

from xdsl.parser import IntegerType, ModuleOp
from xdsl_smt.dialects.transfer import TransIntegerType

from synth_xfer import _eval_engine
from synth_xfer._util.domain import AbstractDomain
from synth_xfer._util.eval_result import CaseExample, EvalResult, PerBitRes
from synth_xfer._util.jit import FnPtr, Jit
from synth_xfer._util.lower import LowerToLLVM
from synth_xfer._util.parse_mlir import HelperFuncs
from synth_xfer._util.random import Sampler


@runtime_checkable
class AbstractValue(Protocol):
    def arity(self) -> int: ...
    def bottom(self) -> "AbstractValue": ...
    def bw(self) -> int: ...
    def distance(self, other: "AbstractValue") -> float: ...
    def norm(self) -> int: ...
    def top(self) -> "AbstractValue": ...
    def __str__(self) -> str: ...


@runtime_checkable
class ArgsVec(Protocol):
    def __len__(self) -> int: ...
    def __getitem__(self, idx: int) -> tuple[AbstractValue, ...]: ...
    def __iter__(self) -> Iterator[tuple[AbstractValue, ...]]: ...


@runtime_checkable
class ToEval(Protocol):
    type EvalRow = tuple[tuple[AbstractValue, ...], AbstractValue]

    def __len__(self) -> int: ...
    def __getitem__(self, idx: int) -> "ToEval.EvalRow": ...
    def __iter__(self) -> Iterator["ToEval.EvalRow"]: ...


@runtime_checkable
class Results(Protocol):
    ExampleTuple: TypeAlias = tuple[tuple[str, ...], str, str, float]

    def __str__(self) -> str: ...
    def get_unsound_examples(self) -> list[list["Results.ExampleTuple"]]: ...
    def get_imprecise_examples(self) -> list[list["Results.ExampleTuple"]]: ...


EvalInput: TypeAlias = tuple[ToEval, list[FnPtr], list[FnPtr]]
EvalInputMap: TypeAlias = dict[int, EvalInput]
RunInputMap: TypeAlias = dict[int, ArgsVec]
RunOutputs: TypeAlias = list[list[AbstractValue]]


def _get_ee_fn_dyn(fn_name: str) -> Callable:
    try:
        ee_fn = getattr(_eval_engine, fn_name)
    except AttributeError as e:
        raise ImportError(
            f"class/function: {fn_name!r} not compiled into eval engine.\n"
            "Add BW, Arity, Domain combination to pyproject.toml and recompile."
        ) from e
    if not callable(ee_fn):
        raise TypeError(
            f"{ee_fn} exists but is not callable (got {type(ee_fn).__name__})"
        )

    return ee_fn


def _get_run_transformer_fn(
    domain: AbstractDomain, bw: int, input_args: ArgsVec
) -> Callable[[ArgsVec, int], list[AbstractValue]]:
    def _run_transformer_engine_name(domain: AbstractDomain, bw: int, arity: int) -> str:
        fn_name = f"run_transformer_{str(domain).lower()}"
        for _ in range(arity + 1):
            fn_name += f"_{bw}"
        return fn_name

    return cast(
        Callable[[ArgsVec, int], list[AbstractValue]],
        _get_ee_fn_dyn(_run_transformer_engine_name(domain, bw, len(input_args[0]))),
    )


def _get_eval_fn(
    to_eval: ToEval,
) -> Callable[[ToEval, list[int], list[int], int, int], Results]:
    def _eval_engine_name(to_eval: ToEval) -> str:
        suffix = to_eval.__class__.__name__.lower()[6:]
        return f"eval_{suffix}"

    return cast(
        Callable[[ToEval, list[int], list[int], int, int], Results],
        _get_ee_fn_dyn(_eval_engine_name(to_eval)),
    )


def _get_eval_pattern_exact_fn(
    to_eval: ToEval,
) -> Callable[[ToEval, list[float], int, int], tuple[float, float]]:
    def _eval_engine_name(to_eval: ToEval) -> str:
        suffix = to_eval.__class__.__name__.lower()[6:]
        return f"eval_pattern_exact_{suffix}"

    return cast(
        Callable[[ToEval, list[float], int, int], tuple[float, float]],
        _get_ee_fn_dyn(_eval_engine_name(to_eval)),
    )


def _get_eval_pattern_norm_fn(
    to_run: ArgsVec,
) -> Callable[[ArgsVec, list[float], int, int], tuple[float, float]]:
    def _eval_engine_name(to_run: ArgsVec) -> str:
        suffix = to_run.__class__.__name__.lower()[4:]
        return f"eval_pattern_norm_{suffix}"

    return cast(
        Callable[[ArgsVec, list[float], int, int], tuple[float, float]],
        _get_ee_fn_dyn(_eval_engine_name(to_run)),
    )


def get_per_bit(a: Results) -> list[PerBitRes]:
    x = str(a).split("\n")

    def get[T](in_str: str, to_match: str, parser: Callable[[str], T]) -> T:
        og_str, to_parse = in_str.split(":")

        assert og_str.strip() == to_match

        return parser(to_parse)

    def get_ints(s: str) -> list[int]:
        return eval(s)

    def get_floats(s: str) -> list[float]:
        return eval(s)

    bw = get(x[0], "bw", int)
    num_cases = get(x[1], "num cases", int)
    num_unsolved_cases = get(x[2], "num unsolved", int)
    base_distance = get(x[3], "base distance", float)
    sound = get(x[4], "num sound", get_ints)
    distance = get(x[5], "distance", get_floats)
    exact = get(x[6], "num exact", get_ints)
    num_unsolved_exact_cases = get(x[7], "num unsolved exact", get_ints)
    sound_distance = get(x[8], "sound distance", get_floats)

    unsound_examples = a.get_unsound_examples()
    imprecise_examples = a.get_imprecise_examples()

    assert len(sound) > 0, "No output from EvalEngine"
    assert (
        len(sound)
        == len(distance)
        == len(exact)
        == len(num_unsolved_exact_cases)
        == len(sound_distance)
        == len(unsound_examples)
        == len(imprecise_examples)
    ), "EvalEngine output mismatch"

    return [
        PerBitRes(
            all_cases=num_cases,
            sounds=sound[i],
            exacts=exact[i],
            dist=distance[i],
            unsolved_cases=num_unsolved_cases,
            unsolved_exacts=num_unsolved_exact_cases[i],
            base_dist=base_distance,
            sound_dist=sound_distance[i],
            bitwidth=bw,
            unsound_examples=[CaseExample(*ex) for ex in unsound_examples[i]],
            imprecise_examples=[CaseExample(*ex) for ex in imprecise_examples[i]],
        )
        for i in range(len(sound))
    ]


def enum(
    lbw: list[int],
    mbw: list[tuple[int, int]],
    hbw: list[tuple[int, int, int]],
    seed: int,
    helper_funcs: HelperFuncs,
    sampler: Sampler,
) -> dict[int, ToEval]:
    all_bws = list(set(lbw + [x[0] for x in mbw] + [x[0] for x in hbw]))
    lowerer = LowerToLLVM(all_bws)
    crt = lowerer.add_fn(helper_funcs.crt_func, shim=True)
    op_constraint = (
        lowerer.add_fn(helper_funcs.op_constraint_func, shim=True)
        if helper_funcs.op_constraint_func
        else None
    )

    def get_bw(x: TransIntegerType | IntegerType, bw: int):
        return bw if isinstance(x, TransIntegerType) else x.width.data

    def get_enum_f(level: str, bw: int) -> Callable:
        domain_str = str(helper_funcs.domain).lower()
        ret_bw = get_bw(helper_funcs.conc_ret_ty, bw)
        arg_bws = [str(get_bw(x, bw)) for x in helper_funcs.conc_arg_ty]
        arg_str = "_".join(arg_bws)
        func_name = f"enum_{level}_{domain_str}_{ret_bw}_{arg_str}"

        return _get_ee_fn_dyn(func_name)

    with Jit() as jit:
        jit.add_mod(lowerer)
        low_to_evals: dict[int, ToEval] = {
            bw: get_enum_f("low", bw)(
                jit.get_fn_ptr(crt[bw].name).addr,
                jit.get_fn_ptr(op_constraint[bw].name).addr if op_constraint else None,
            )
            for bw in lbw
        }

        mid_to_evals: dict[int, ToEval] = {
            bw: get_enum_f("mid", bw)(
                jit.get_fn_ptr(crt[bw].name).addr,
                jit.get_fn_ptr(op_constraint[bw].name).addr if op_constraint else None,
                samples,
                seed,
                sampler.sampler,
            )
            for bw, samples in mbw
        }

        high_to_evals: dict[int, ToEval] = {
            bw: get_enum_f("high", bw)(
                jit.get_fn_ptr(crt[bw].name).addr,
                jit.get_fn_ptr(op_constraint[bw].name).addr if op_constraint else None,
                lat_samples,
                crt_samples,
                seed,
                sampler.sampler,
            )
            for bw, lat_samples, crt_samples in hbw
        }

    return low_to_evals | mid_to_evals | high_to_evals


def get_eval_res(
    per_bits: list[list[PerBitRes]], low_and_med_bw: set[int]
) -> list[EvalResult]:
    ds: list[list[PerBitRes]] = [[] for _ in range(len(per_bits[0]))]
    for es in per_bits:
        for i, e in enumerate(es):
            ds[i].append(e)

    return [EvalResult(x, low_and_med_bw) for x in ds]


def eval_transfer_func(
    x: EvalInputMap,
    low_and_med_bw: set[int],
    unsound_ex: int = 0,
    imprecise_ex: int = 0,
) -> list[EvalResult]:
    per_bits = []
    for to_eval, xs, bs in x.values():
        xs_addrs = [x.addr for x in xs]
        bs_addrs = [b.addr for b in bs]
        result = _get_eval_fn(to_eval)(
            to_eval, xs_addrs, bs_addrs, unsound_ex, imprecise_ex
        )
        per_bits.append(get_per_bit(result))

    return get_eval_res(per_bits, low_and_med_bw)


def parse_to_run_inputs(
    domain: AbstractDomain, bw: int, arity: int, inputs: list[tuple[str, ...]]
) -> ArgsVec:
    cls_name = f"Args{domain}"
    for _ in range(arity):
        cls_name += f"_{bw}"

    to_run_cls = _get_ee_fn_dyn(cls_name)

    return to_run_cls(inputs)


def parse_to_eval_inputs(
    domain: AbstractDomain, bw: int, arity: int, inputs: list[tuple[tuple[str, ...], str]]
) -> ToEval:
    cls_name = f"ToEval{domain}"
    for _ in range(arity + 1):
        cls_name += f"_{bw}"

    to_eval_cls = _get_ee_fn_dyn(cls_name)

    return to_eval_cls(inputs)


def eval_pattern_exact(
    to_eval: ToEval, weights: list[float], sequential: FnPtr, composite: FnPtr
) -> tuple[float, float]:
    return _get_eval_pattern_exact_fn(to_eval)(
        to_eval, weights, sequential.addr, composite.addr
    )


def eval_pattern_norm(
    to_run: ArgsVec, weights: list[float], sequential: FnPtr, composite: FnPtr
) -> tuple[float, float]:
    return _get_eval_pattern_norm_fn(to_run)(
        to_run, weights, sequential.addr, composite.addr
    )


def run_xfer_fns(
    domain: AbstractDomain,
    to_eval: RunInputMap,
    mlir_mod: ModuleOp,
    xfer_names: list[str],
) -> RunOutputs:
    lowerer = LowerToLLVM(list(to_eval.keys()))
    lowerer.add_mod(mlir_mod, xfer_names)
    outputs: RunOutputs = [[] for _ in xfer_names]

    with Jit() as jit:
        jit.add_mod(lowerer)
        for bw, input_args in to_eval.items():
            run_fn = _get_run_transformer_fn(domain, bw, input_args)

            for i, xfer_name in enumerate(xfer_names):
                fn_ptr = jit.get_fn_ptr(f"{xfer_name}_{bw}_shim")
                outputs[i].extend(run_fn(input_args, fn_ptr.addr))

    return outputs


def run_concrete_fn(
    helper_funcs: HelperFuncs, bw: int, args: list[tuple[int, ...]]
) -> list[int | None]:
    lowerer = LowerToLLVM([bw])
    crt = lowerer.add_fn(helper_funcs.crt_func, shim=True)
    op_constraint = (
        lowerer.add_fn(helper_funcs.op_constraint_func, shim=True)
        if helper_funcs.op_constraint_func
        else None
    )

    arity = len(args[0])
    conc_op_type = CFUNCTYPE(c_int64, *(c_int64 for _ in range(arity)))
    op_con_type = CFUNCTYPE(c_bool, *(c_int64 for _ in range(arity)))

    results: list[int | None] = []

    with Jit() as jit:
        jit.add_mod(lowerer)
        conc_op_fn = conc_op_type(jit.get_fn_ptr(crt[bw].name).addr)
        op_con_fn = (
            op_con_type(jit.get_fn_ptr(op_constraint[bw].name).addr)
            if op_constraint
            else None
        )

        for x in args:
            if not op_con_fn or op_con_fn(*x):
                results.append(conc_op_fn(*x))

            results.append(None)

    return results
