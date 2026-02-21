from argparse import ArgumentParser, Namespace
from pathlib import Path
from time import perf_counter
from typing import cast

from xdsl.dialects.func import FuncOp
from xdsl.parser import ModuleOp

from synth_xfer._util.domain import AbstractDomain
from synth_xfer._util.eval import run_concrete_fn
from synth_xfer._util.parse_mlir import (
    HelperFuncs,
    get_fns,
    get_helper_funcs,
    parse_mlir_mod,
)
from synth_xfer._util.verifier import (
    BVCounterexampleModel,
    SMTSolverName,
    verify_transfer_function,
)
from synth_xfer.cli.args import int_list
from synth_xfer.cli.eval_final import resolve_xfer_name
from synth_xfer.cli.run_xfer import run_xfer_fn


def verify_function(
    bw: int,
    func: FuncOp,
    xfer_helpers: list[FuncOp | None],
    helper_funcs: HelperFuncs,
    timeout: int,
    solver_name: SMTSolverName = "z3",
) -> tuple[bool | None, BVCounterexampleModel | None]:
    xfer_helpers += [
        helper_funcs.get_top_func,
        helper_funcs.instance_constraint_func,
        helper_funcs.domain_constraint_func,
        helper_funcs.op_constraint_func,
        helper_funcs.meet_func,
    ]
    helpers = [x for x in xfer_helpers if x is not None]

    return verify_transfer_function(
        func, helper_funcs.crt_func, helpers, bw, timeout, solver_name
    )


def _register_parser() -> Namespace:
    p = ArgumentParser()

    p.add_argument(
        "--bw",
        type=int_list,
        required=True,
        help="Bitwidth range (e.g. `-bw 4`, `-bw 4-64` or `-bw 4,8,16`)",
    )

    p.add_argument(
        "-d",
        "--domain",
        type=str,
        choices=[str(x) for x in AbstractDomain],
        required=True,
        help="Abstract Domain to evaluate",
    )

    p.add_argument("--op", type=Path, required=True, help="Concrete op")
    p.add_argument("--xfer-file", type=Path, required=True, help="Transformer file")
    p.add_argument("--xfer-name", type=str, help="Transformer to verify")
    p.add_argument("--timeout", type=int, default=30, help="SMT solver timeout")
    p.add_argument(
        "--solver",
        type=str,
        choices=["z3", "cvc5"],
        default="z3",
        help="SMT backend to use",
    )
    p.add_argument(
        "--continue-unsound",
        action="store_true",
        help="Continue after hitting an unsound bw",
    )
    p.add_argument(
        "--continue-timeout", action="store_true", help="Continue after a timeout"
    )
    p.add_argument(
        "--no-exec", action="store_true", help="Don't execute for counterexample"
    )

    return p.parse_args()


def _parse_counter_example(
    model: BVCounterexampleModel, domain: AbstractDomain, bw: int, func_arity: int
) -> tuple[list[int], list[str]]:
    # TODO doesn't support all domains yet.
    assert domain.vec_size == 2
    abst0_args: dict[int, int] = {}
    abst1_args: dict[int, int] = {}
    conc_args: dict[int, int] = {}

    for var_name, var_val in model:

        if var_name == "$const_first":
            abst0_args[0] = var_val
        elif var_name == "$const_second_first":
            abst1_args[0] = var_val

        elif var_name.startswith("$const_first_"):
            number = int(var_name.split("$const_first_")[1])

            if number >= func_arity - 1:
                arg_number = number - (func_arity - 1)
                conc_args[arg_number] = var_val
            else:
                arg_number = number + 1
                abst0_args[arg_number] = var_val
        elif var_name.startswith("$const_second_first_"):
            number = int(var_name.split("$const_second_first_")[1])
            abst1_args[number + 1] = var_val
        else:
            continue

    assert len(abst0_args) == func_arity
    assert len(abst1_args) == func_arity
    assert len(conc_args) == func_arity

    abst_args = [
        _bv_ref_to_abst_str(domain, bw, (arg0, abst1_args[num]))
        for num, arg0 in sorted(abst0_args.items())
    ]

    return [v for _, v in sorted(conc_args.items())], abst_args


def _format_concrete(x: int, domain: AbstractDomain, bw: int) -> str:
    if domain == AbstractDomain.KnownBits:
        return bin(x)[2:].zfill(bw)
    if domain == AbstractDomain.UConstRange:
        return str(x)
    if domain == AbstractDomain.SConstRange:
        sign_bit = 1 << (bw - 1)
        if x & sign_bit:
            return str(x - (1 << bw))
        return str(x)
    raise ValueError(f"Unsupported domain: {domain}")


def _bv_ref_to_abst_str(
    domain: AbstractDomain, bw: int, abst_bv: tuple[int, int]
) -> str:
    if domain == AbstractDomain.KnownBits:
        known_zeros = bin(abst_bv[0])[2:].zfill(bw)
        known_ones = bin(abst_bv[1])[2:].zfill(bw)
        abst_val_str = ""
        for zero, one in zip(known_zeros, known_ones):
            if zero == "0" and one == "0":
                abst_val_str += "?"
            elif zero == "0" and one == "1":
                abst_val_str += "1"
            elif zero == "1" and one == "0":
                abst_val_str += "0"
            else:
                abst_val_str = "(bottom)"
                break
    elif domain == AbstractDomain.UConstRange:
        abst_val_str = f"[{abst_bv[0]}, {abst_bv[1]}]"
    elif domain == AbstractDomain.SConstRange:
        abst_val_str = f"[{_signed_from_bv(abst_bv[0], bw)}, {_signed_from_bv(abst_bv[1], bw)}]"
    else:
        raise ValueError(f"Unsupported domain: {domain}")

    return abst_val_str


def _signed_from_bv(value: int, bw: int) -> int:
    sign_bit = 1 << (bw - 1)
    return value - (1 << bw) if value & sign_bit else value


def _print_counterexample(
    op_name: str,
    model: BVCounterexampleModel,
    bw: int,
    domain: AbstractDomain,
    mlir_mod: ModuleOp,
    xfer_name: str,
    helper_funcs: HelperFuncs,
    no_exec: bool,
):
    assert isinstance(model, BVCounterexampleModel)
    func_arity = len(helper_funcs.crt_func.args)
    conc_args, abst_args = _parse_counter_example(model, domain, bw, func_arity)
    conc_args_str = [_format_concrete(x, domain, bw) for x in conc_args]
    if no_exec:
        abst_output = None
        conc_output = None
    else:
        abst_output = run_xfer_fn(domain, bw, [tuple(abst_args)], mlir_mod, xfer_name)[0]  # type: ignore
        conc_output = run_concrete_fn(helper_funcs, bw, [tuple(conc_args)])[0]
        conc_output = (
            _format_concrete(conc_output, domain, bw)
            if isinstance(conc_output, int)
            else conc_output
        )

    print(f"Concrete Execution: {op_name}(", end="")
    print(", ".join(conc_args_str), end="")
    if conc_output:
        print(f") -> {conc_output}")
    else:
        print(")")
    print(f"Abstract Execution: {op_name}(", end="")
    print(", ".join(map(str, abst_args)), end="")
    if abst_output:
        print(f") -> {abst_output}")
        print(f"ERROR: {conc_output} not in {abst_output}")
    else:
        print(")")


def main() -> None:
    args = _register_parser()
    solver_name = cast(SMTSolverName, args.solver)
    domain = AbstractDomain[args.domain]
    mlir_mod = parse_mlir_mod(args.xfer_file)
    xfer_fns = get_fns(mlir_mod)
    xfer_name = resolve_xfer_name(xfer_fns, args.xfer_name)

    xfer_fn = xfer_fns[xfer_name]
    del xfer_fns[xfer_name]
    helper_funcs = get_helper_funcs(args.op, domain)

    for bw in args.bw:
        start_time = perf_counter()
        is_sound, model = verify_function(
            bw,
            xfer_fn,
            list(xfer_fns.values()),
            helper_funcs,
            args.timeout,
            solver_name,
        )
        run_time = perf_counter() - start_time

        if is_sound is None:
            if args.continue_timeout:
                print(f"{bw:<2} bits | timeout | took {args.timeout}s")
            else:
                print(
                    f"Verifier TIMEOUT at {bw}-bits.\nTimeout was {args.timeout} second."
                )
                break
        elif is_sound:
            print(f"{bw:<2} bits | sound   | took {run_time:.4f}s")
        else:
            print("-----------------------------------------------------")
            print(f"Verifier UNSOUND at {bw}-bits. Took {run_time:.4f}s.")
            print("Counterexample:")

            assert isinstance(model, BVCounterexampleModel)
            _print_counterexample(
                str(args.op.stem),
                model,
                bw,
                domain,
                mlir_mod,
                xfer_name,
                helper_funcs,
                args.no_exec,
            )

            if not args.continue_unsound:
                break


if __name__ == "__main__":
    main()
