from enum import Enum
from pathlib import Path
from subprocess import PIPE, run

from synth_xfer._eval_engine import enum_low_knownbits_4, eval_knownbits_4
from synth_xfer._util.eval_result import EvalResult, PerBitRes, get_per_bit


class AbstractDomain(Enum):
    KnownBits = "KnownBits", 2
    UConstRange = "UConstRange", 2
    SConstRange = "SConstRange", 2
    IntegerModulo = "IntegerModulo", 6

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
    # domain: AbstractDomain,
    # TODO handle other bws
    # low_bws: list[int],
    # med_bws: list[tuple[int, int]],
    # high_bws: list[tuple[int, int, int]],
    # seed: int,
    # TODO should it be a ptr or an mlir mod?
    conc_op_ptr: int,
    op_con_ptr: int | None,
    # TODO need op con ptr too
):
    return enum_low_knownbits_4(conc_op_ptr, op_con_ptr)


# TODO may want to just pass whole jit in here
def eval_transfer_func(
    to_eval,
    xfers: list[int],
    bases: list[int],
    # domain: AbstractDomain,
) -> list[EvalResult]:
    res = eval_knownbits_4(to_eval, xfers, bases)

    return _parse_engine_output(str(res))


# TODO
def eval_final(
    data_dir: str,
    xfer_name: str,
    xfer_src: str,
    op_name: str,
    helper_srcs: list[str],
    domain: AbstractDomain,
) -> list[EvalResult]:
    engine_path = Path("xdsl_smt").joinpath("eval_engine", "build", "eval_engine")
    if not engine_path.exists():
        raise FileNotFoundError(f"Eval Engine not found at: {engine_path}")

    engine_params = ""
    engine_params += f"{data_dir}\n"
    engine_params += f"{domain}\n"
    engine_params += f"{op_name}\n"
    engine_params += "\n"
    engine_params += f"{[xfer_name]}\n"
    engine_params += "using A::APInt;\n"
    engine_params += "\n".join(helper_srcs + [xfer_src])

    eval_output = run(
        [engine_path],
        input=engine_params,
        text=True,
        stdout=PIPE,
        stderr=PIPE,
    )

    if eval_output.returncode != 0:
        print("EvalEngine failed with this error:")
        print(eval_output.stderr, end="")
        exit(eval_output.returncode)

    return _parse_engine_output(eval_output.stdout)
