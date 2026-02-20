from ctypes import CFUNCTYPE, c_bool, c_int64
from typing import TYPE_CHECKING, Callable

from xdsl.parser import IntegerType, ModuleOp
from xdsl_smt.dialects.transfer import TransIntegerType

from synth_xfer import _eval_engine
from synth_xfer._util.domain import AbstractDomain
from synth_xfer._util.eval_result import EvalResult, PerBitRes
from synth_xfer._util.jit import FnPtr, Jit
from synth_xfer._util.lower import LowerToLLVM
from synth_xfer._util.parse_mlir import HelperFuncs
from synth_xfer._util.random import Sampler

if TYPE_CHECKING:
    from synth_xfer._eval_engine import ArgsVec, Results, ToEval


def get_per_bit(a: "Results") -> list[PerBitRes]:
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

    assert len(sound) > 0, "No output from EvalEngine"
    assert (
        len(sound)
        == len(distance)
        == len(exact)
        == len(num_unsolved_exact_cases)
        == len(sound_distance)
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
        )
        for i in range(len(sound))
    ]


def setup_eval(
    lbw: list[int],
    mbw: list[tuple[int, int]],
    hbw: list[tuple[int, int, int]],
    seed: int,
    helper_funcs: HelperFuncs,
    sampler: Sampler,
) -> dict[int, "ToEval"]:
    all_bws = lbw + [x[0] for x in mbw] + [x[0] for x in hbw]
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

        try:
            enum_fn = getattr(_eval_engine, func_name)
        except AttributeError as e:
            raise ImportError(
                f"Function {func_name!r} not compiled into enum engine.\n"
                "Add function to bindings.cpp and recompile the enum engine."
            ) from e
        if not callable(enum_fn):
            raise TypeError(
                f"{func_name} exists but is not callable (got {type(enum_fn).__name__})"
            )

        return enum_fn

    with Jit() as jit:
        jit.add_mod(lowerer)
        low_to_evals: dict[int, "ToEval"] = {
            bw: get_enum_f("low", bw)(
                jit.get_fn_ptr(crt[bw].name).addr,
                jit.get_fn_ptr(op_constraint[bw].name).addr if op_constraint else None,
            )
            for bw in lbw
        }

        mid_to_evals: dict[int, "ToEval"] = {
            bw: get_enum_f("mid", bw)(
                jit.get_fn_ptr(crt[bw].name).addr,
                jit.get_fn_ptr(op_constraint[bw].name).addr if op_constraint else None,
                samples,
                seed,
                sampler.sampler,
            )
            for bw, samples in mbw
        }

        high_to_evals: dict[int, "ToEval"] = {
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


def get_eval_res(per_bits: list[list[PerBitRes]]) -> list[EvalResult]:
    ds: list[list[PerBitRes]] = [[] for _ in range(len(per_bits[0]))]
    for es in per_bits:
        for i, e in enumerate(es):
            ds[i].append(e)

    return [EvalResult(x) for x in ds]


def eval_transfer_func(
    x: dict[int, tuple["ToEval", list[FnPtr], list[FnPtr]]],
) -> list[EvalResult]:
    def get_eval_f(x: "ToEval") -> Callable[["ToEval", list[int], list[int]], "Results"]:
        suffix = x.__class__.__name__.lower()[6:]
        func_name = f"eval_{suffix}"

        try:
            eval_fn = getattr(_eval_engine, func_name)
        except AttributeError as e:
            raise ImportError(
                f"Function {func_name!r} not compiled into eval engine.\n"
                "Add function to bindings.cpp and recompile the eval engine."
            ) from e
        if not callable(eval_fn):
            raise TypeError(
                f"{func_name} exists but is not callable (got {type(eval_fn).__name__})"
            )
        return eval_fn

    per_bits = []
    for to_eval, xs, bs in x.values():
        xs_addrs = [x.addr for x in xs]
        bs_addrs = [b.addr for b in bs]
        per_bits.append(get_per_bit(get_eval_f(to_eval)(to_eval, xs_addrs, bs_addrs)))

    return get_eval_res(per_bits)


def parse_to_run_inputs(
    domain: AbstractDomain, bw: int, arity: int, inputs: list[tuple[str, ...]]
) -> "ArgsVec":
    cls_name = f"Args{domain}"
    for _ in range(arity):
        cls_name += f"_{bw}"

    try:
        args_cls = getattr(_eval_engine, cls_name)
    except AttributeError as e:
        raise ImportError(
            f"Args class: {cls_name!r} not compiled into eval engine.\n"
            "Add Args to bindings.cpp and recompile the eval engine."
        ) from e
    if not callable(args_cls):
        raise TypeError(
            f"{cls_name} exists but is not callable (got {type(args_cls).__name__})"
        )

    return args_cls(inputs)


def eval_to_run(
    domain: AbstractDomain, bw: int, arity: int, inputs: "ArgsVec", fn_ptr: FnPtr
):
    fn_name = f"run_transformer_{str(domain).lower()}"
    for _ in range(arity + 1):
        fn_name += f"_{bw}"

    try:
        run_fn = getattr(_eval_engine, fn_name)
    except AttributeError as e:
        raise ImportError(
            f"run function: {fn_name!r} not compiled into eval engine.\n"
            "Add run function to bindings.cpp and recompile the eval engine."
        ) from e
    if not callable(run_fn):
        raise TypeError(
            f"{run_fn} exists but is not callable (got {type(run_fn).__name__})"
        )

    return run_fn(inputs, fn_ptr.addr)


def run_xfer_fn(
    domain: AbstractDomain,
    bw: int,
    input: list[tuple[str, ...]],
    mlir_mod: ModuleOp,
    xfer_name: str,
):
    arity = len(input[0])
    input_args = parse_to_run_inputs(domain, bw, arity, input)

    lowerer = LowerToLLVM([bw])
    lowerer.add_mod(mlir_mod, [xfer_name])

    with Jit() as jit:
        jit.add_mod(lowerer)
        fn_ptr = jit.get_fn_ptr(f"{xfer_name}_{bw}_shim")
        outputs = eval_to_run(domain, bw, arity, input_args, fn_ptr)

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
