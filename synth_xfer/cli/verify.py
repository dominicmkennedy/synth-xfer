from argparse import ArgumentParser, Namespace
from pathlib import Path
from time import perf_counter

from xdsl.dialects.func import FuncOp
from z3 import BitVecNumRef, FuncDeclRef, ModelRef

from synth_xfer._util.domain import AbstractDomain
from synth_xfer._util.parse_mlir import (
    HelperFuncs,
    get_fns,
    get_helper_funcs,
    parse_mlir_mod,
)
from synth_xfer._util.verifier import verify_transfer_function
from synth_xfer.cli.args import int_list
from synth_xfer.cli.eval_final import resolve_xfer_name


def verify_function(
    bw: int,
    func: FuncOp,
    xfer_helpers: list[FuncOp | None],
    helper_funcs: HelperFuncs,
    timeout: int,
) -> tuple[bool | None, ModelRef | None]:
    xfer_helpers += [
        helper_funcs.get_top_func,
        helper_funcs.instance_constraint_func,
        helper_funcs.domain_constraint_func,
        helper_funcs.op_constraint_func,
        helper_funcs.meet_func,
    ]
    helpers = [x for x in xfer_helpers if x is not None]

    return verify_transfer_function(func, helper_funcs.crt_func, helpers, bw, timeout)


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
    p.add_argument("--timeout", type=int, default=30, help="z3 timeout")
    p.add_argument(
        "--continue-unsound",
        action="store_true",
        help="Continue after hitting an unsound bw",
    )
    p.add_argument(
        "--continue-timeout", action="store_true", help="Continue after a timeout"
    )
    # TODO
    # p.add_argument(
    #     "--no-exec", action="store_true", help="Don't execute unsound models"
    # )

    return p.parse_args()


def parse_counter_example(
    model: ModelRef, domain: AbstractDomain, bw: int
) -> tuple[dict[int, int], dict[int, str]]:
    # TODO doesn't support all domains yet.
    assert domain.vec_size == 2

    func_arity = len(model) // 3
    abst0_args: dict[int, BitVecNumRef] = {}
    abst1_args: dict[int, BitVecNumRef] = {}
    conc_args: dict[int, int] = {}

    for var_ref in model:
        var_name = str(var_ref)
        var_val = model[var_ref]
        assert isinstance(var_ref, FuncDeclRef)
        assert isinstance(var_val, BitVecNumRef)

        if var_name == "$const_first":
            abst0_args[0] = var_val
        elif var_name == "$const_second_first":
            abst1_args[0] = var_val

        elif var_name.startswith("$const_first_"):
            number = int(var_name.split("$const_first_")[1])

            if number >= func_arity - 1:
                arg_number = number - (func_arity - 1)
                conc_args[arg_number] = var_val.as_long()
            else:
                arg_number = number + 1
                abst0_args[arg_number] = var_val
        elif var_name.startswith("$const_second_first_"):
            number = int(var_name.split("$const_second_first_")[1])
            abst1_args[number + 1] = var_val
        else:
            raise ValueError(f"Unexpected var name: {var_name}")

    assert len(abst0_args) == func_arity
    assert len(abst1_args) == func_arity
    assert len(conc_args) == func_arity

    abst_args = {
        num: bv_ref_to_abst_str(domain, bw, (arg0, abst1_args[num]))
        for num, arg0 in abst0_args.items()
    }

    return dict(sorted(conc_args.items())), dict(sorted(abst_args.items()))


def bv_ref_to_abst_str(
    domain: AbstractDomain, bw: int, abst_bv: tuple[BitVecNumRef, BitVecNumRef]
) -> str:
    if domain == AbstractDomain.KnownBits:
        known_zeros = bin(abst_bv[0].as_long())[2:].zfill(bw)
        known_ones = bin(abst_bv[1].as_long())[2:].zfill(bw)
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
        abst_val_str = f"[{abst_bv[0].as_long()}, {abst_bv[1].as_long()}]"
    elif domain == AbstractDomain.SConstRange:
        abst_val_str = f"[{abst_bv[0].as_signed_long()}, {abst_bv[1].as_signed_long()}]"
    else:
        raise ValueError(f"Unsupported domain: {domain}")

    return abst_val_str


def main() -> None:
    args = _register_parser()
    domain = AbstractDomain[args.domain]
    xfer_fns = get_fns(parse_mlir_mod(args.xfer_file))
    xfer_name = resolve_xfer_name(xfer_fns, args.xfer_name)

    xfer_fn = xfer_fns[xfer_name]
    del xfer_fns[xfer_name]
    helper_funcs = get_helper_funcs(args.op, domain)

    for bw in args.bw:
        start_time = perf_counter()
        is_sound, model = verify_function(
            bw, xfer_fn, list(xfer_fns.values()), helper_funcs, args.timeout
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

            op_name = str(args.op.stem)
            assert isinstance(model, ModelRef)
            conc_args, abst_args = parse_counter_example(model, domain, bw)

            print(f"Concrete: {op_name}(", end="")
            print(", ".join(map(str, conc_args.values())), end="")
            print(")")
            print(f"Abstract: {op_name}(", end="")
            print(", ".join(map(str, abst_args.values())), end="")
            print(")")

            if not args.continue_unsound:
                break


if __name__ == "__main__":
    main()
