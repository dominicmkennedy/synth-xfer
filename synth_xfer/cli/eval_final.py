from argparse import (
    ArgumentDefaultsHelpFormatter,
    ArgumentParser,
    ArgumentTypeError,
    Namespace,
)
from multiprocessing import Pool
from pathlib import Path

import pandas as pd

from synth_xfer._util.domain import AbstractDomain
from synth_xfer._util.eval import eval_transfer_func, setup_eval
from synth_xfer._util.eval_result import EvalResult
from synth_xfer._util.jit import Jit
from synth_xfer._util.lower import LowerToLLVM
from synth_xfer._util.parse_mlir import get_helper_funcs, parse_mlir_mod, top_as_xfer
from synth_xfer._util.random import Random, Sampler
from synth_xfer.cli.args import get_sampler, make_sampler_parser


def _int_tuple(s: str) -> tuple[int, ...]:
    try:
        items = s.split(",")
        if len(items) == 1:
            return (int(items[0]),)
        elif len(items) == 2:
            return (int(items[0]), int(items[1]))
        elif len(items) == 2:
            return (int(items[0]), int(items[1]), int(items[2]))
        else:
            raise ValueError
    except Exception:
        raise ArgumentTypeError(f"Invalid tuple format: '{s}'. Expected format: int,int")


def _reg_args():
    p = ArgumentParser(prog="eval-final", formatter_class=ArgumentDefaultsHelpFormatter)
    p.add_argument("solution_path", type=Path, help="path to the solution")
    p.add_argument("-random_seed", type=int, help="seed for synthesis")
    p.add_argument("-exact-bw", type=_int_tuple, default=(8, 10000))
    p.add_argument("-norm-bw", type=_int_tuple, default=(64, 2500, 50000))
    make_sampler_parser(p)
    p.add_argument("-o", "--output", type=Path, default=None)

    return p.parse_args()


def _parse_config(config_path: Path) -> tuple[Path, AbstractDomain]:
    transfer_path: Path | None = None
    domain: AbstractDomain | None = None

    with config_path.open("r", encoding="utf-8") as f:
        for line in f:
            if not line.strip() or "|" not in line:
                continue

            key, value = line.split("|", 1)
            key = key.strip()
            value = value.strip()

            if key == "transfer_functions":
                transfer_path = Path(value)

            if key == "domain":
                domain = AbstractDomain[value]

    if transfer_path is None:
        raise ValueError("Missing 'transfer_functions' entry in config.")
    if domain is None:
        raise ValueError("Missing 'domain' entry in config.")

    return transfer_path, domain


def _get_solutions(p: Path) -> list[tuple[Path, Path, AbstractDomain]]:
    assert p.is_dir(), f"soultions path is not a directory: {p}"

    result: list[tuple[Path, Path, AbstractDomain]] = []

    for solution_path in p.rglob("solution.mlir"):
        config_path = solution_path.with_name("config.log")
        assert config_path.is_file(), f"Missing config.log for solution: {solution_path}"
        op_path, domain = _parse_config(config_path)
        result.append((solution_path, op_path, domain))

    return result


def run(
    domain: AbstractDomain,
    lbw: list[int],
    mbw: list[tuple[int, int]],
    hbw: list[tuple[int, int, int]],
    input_path: Path,
    solution_path: Path,
    random_seed: int | None,
    sampler: Sampler,
) -> tuple[EvalResult, EvalResult]:
    all_bws = lbw + [x[0] for x in mbw] + [x[0] for x in hbw]
    helpers = get_helper_funcs(input_path, domain)
    sol_module = parse_mlir_mod(solution_path)

    random = Random(random_seed)
    random_seed = random.randint(0, 1_000_000) if random_seed is None else random_seed

    lowerer = LowerToLLVM(all_bws)
    top_mlir = top_as_xfer(helpers.transfer_func)
    lowerer.add_fn(helpers.meet_func)
    lowerer.add_fn(helpers.get_top_func)
    top_xfer = lowerer.add_fn(top_mlir, shim=True)
    lowerer.add_mod(sol_module, ["solution"])

    jit = Jit()
    jit.add_mod(str(lowerer))
    to_eval = setup_eval(lbw, mbw, hbw, random_seed, helpers, jit, sampler)

    input = {
        bw: (
            to_eval[bw],
            [jit.get_fn_ptr(top_xfer[bw].name), jit.get_fn_ptr(f"solution_{bw}_shim")],
            [],
        )
        for bw in all_bws
    }

    res = eval_transfer_func(input)
    assert len(res) == 2

    return (res[0], res[1])


def _run_wrapper(x: tuple[AbstractDomain, Path, Path, int | None, tuple, Namespace]):
    sampler = get_sampler(x[5])

    return run(
        domain=x[0],
        lbw=x[4][0],
        mbw=x[4][1],
        hbw=x[4][2],
        input_path=x[1],
        solution_path=x[2],
        random_seed=x[3],
        sampler=sampler,
    )


def main() -> None:
    args = _reg_args()
    solutions = _get_solutions(args.solution_path)

    inputs: list[tuple[AbstractDomain, Path, Path, int | None, tuple, Namespace]] = []
    for solution_path, op_path, domain in solutions:
        lbw, mbw, hbw = [], [], []
        if len(args.exact_bw) == 1:
            lbw.append(args.exact_bw)
        elif len(args.exact_bw) == 2:
            mbw.append(args.exact_bw)
        elif len(args.exact_bw) == 3:
            hbw.append(args.exact_bw)

        if len(args.norm_bw) == 1:
            lbw.append(args.norm_bw)
        elif len(args.norm_bw) == 2:
            mbw.append(args.norm_bw)
        elif len(args.norm_bw) == 3:
            hbw.append(args.norm_bw)

        inputs.append(
            (domain, op_path, solution_path, args.random_seed, (lbw, mbw, hbw), args)
        )

    inputs = sorted(inputs, key=lambda x: (x[0].value))

    with Pool() as p:
        data = p.map(_run_wrapper, inputs)

    rows = []
    for (domain, op_path, _, _, _, _), (top_r, synth_r) in zip(inputs, data):
        top_8 = next(x for x in top_r.per_bit_res if x.bitwidth == 8)
        synth_8 = next(x for x in synth_r.per_bit_res if x.bitwidth == 8)
        top_64 = next(x for x in top_r.per_bit_res if x.bitwidth == 64)
        synth_64 = next(x for x in synth_r.per_bit_res if x.bitwidth == 64)

        rows.append(
            {
                "Domain": str(domain),
                "Op": op_path.stem,
                "Top Exact %": top_8.get_exact_prop() * 100.0,
                "Synth Exact %": synth_8.get_exact_prop() * 100.0,
                "Top Norm": top_64.dist,
                "Synth Norm": synth_64.dist,
            }
        )

    df = pd.DataFrame(rows)
    print(f"Exact bw: {args.exact_bw}")
    print(f"Norm bw:  {args.norm_bw}")
    print(df)
    if args.output:
        df.to_csv(args.output)


if __name__ == "__main__":
    main()
