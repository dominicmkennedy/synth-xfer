from argparse import (
    ArgumentDefaultsHelpFormatter,
    ArgumentParser,
    ArgumentTypeError,
    Namespace,
)
from dataclasses import dataclass
from multiprocessing import Pool
from pathlib import Path

import pandas as pd
from xdsl.dialects.func import FuncOp

from synth_xfer._util.domain import AbstractDomain
from synth_xfer._util.eval import eval_transfer_func, setup_eval
from synth_xfer._util.eval_result import EvalResult
from synth_xfer._util.jit import Jit
from synth_xfer._util.lower import LowerToLLVM
from synth_xfer._util.parse_mlir import (
    get_fns,
    get_helper_funcs,
    parse_mlir_mod,
    top_as_xfer,
)
from synth_xfer._util.random import Random, Sampler
from synth_xfer.cli.args import get_sampler, make_sampler_parser


def _int_tuple(s: str) -> tuple[int, ...] | None:
    if s.lower() == "none":
        return None
    try:
        items = s.split(",")
        if len(items) == 1:
            return (int(items[0]),)
        elif len(items) == 2:
            return (int(items[0]), int(items[1]))
        elif len(items) == 3:
            return (int(items[0]), int(items[1]), int(items[2]))
        else:
            raise ValueError
    except Exception:
        raise ArgumentTypeError(
            f"Invalid tuple format: '{s}'. Expected format: int,int or 'none'"
        )


def _reg_args():
    p = ArgumentParser(prog="eval-final", formatter_class=ArgumentDefaultsHelpFormatter)
    p.add_argument(
        "input_path",
        type=Path,
        help="directory of solutions (with config.log) or a single transformer file",
    )
    p.add_argument("--random-seed", type=int, help="seed for synthesis")
    p.add_argument(
        "--exact-bw",
        type=_int_tuple,
        default=(8, 10000),
        help="Exact bitwidths (or 'none' to skip)",
    )
    p.add_argument(
        "--norm-bw",
        type=_int_tuple,
        default=(64, 2500, 50000),
        help="Normalized bitwidths (or 'none' to skip)",
    )
    make_sampler_parser(p)
    p.add_argument("-o", "--output", type=Path, default=None)
    p.add_argument(
        "-d",
        "--domain",
        type=str,
        choices=[str(x) for x in AbstractDomain],
        help="Abstract domain (required for single transformer files)",
    )
    p.add_argument(
        "--op",
        type=Path,
        help="Concrete op MLIR (required for single transformer files)",
    )
    p.add_argument(
        "--xfer-name",
        type=str,
        help="Transformer function name (optional override)",
    )

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
    op_path: Path,
    solution_path: Path,
    xfer_name: str,
    random_seed: int | None,
    sampler: Sampler,
) -> tuple[EvalResult, EvalResult]:
    all_bws = lbw + [x[0] for x in mbw] + [x[0] for x in hbw]
    helpers = get_helper_funcs(op_path, domain)
    sol_module = parse_mlir_mod(solution_path)

    random = Random(random_seed)
    random_seed = random.randint(0, 1_000_000) if random_seed is None else random_seed

    lowerer = LowerToLLVM(all_bws)
    top_mlir = top_as_xfer(helpers.transfer_func)
    lowerer.add_fn(helpers.meet_func)
    lowerer.add_fn(helpers.get_top_func)
    top_xfer = lowerer.add_fn(top_mlir, shim=True)
    lowerer.add_mod(sol_module, [xfer_name])

    to_eval = setup_eval(lbw, mbw, hbw, random_seed, helpers, sampler)
    with Jit() as jit:
        jit.add_mod(lowerer)

        eval_input = {
            bw: (
                to_eval[bw],
                [
                    jit.get_fn_ptr(top_xfer[bw].name),
                    jit.get_fn_ptr(f"{xfer_name}_{bw}_shim"),
                ],
                [],
            )
            for bw in all_bws
        }

        res = eval_transfer_func(eval_input)
        assert len(res) == 2

        return (res[0], res[1])


@dataclass(frozen=True)
class EvalJob:
    domain: AbstractDomain
    op_path: Path
    solution_path: Path
    xfer_name: str
    random_seed: int | None
    bw_args: tuple[list[int], list[tuple[int, int]], list[tuple[int, int, int]]]
    args: Namespace


def _run_job(job: EvalJob) -> tuple[EvalResult, EvalResult]:
    sampler = get_sampler(job.args)

    return run(
        domain=job.domain,
        lbw=job.bw_args[0],
        mbw=job.bw_args[1],
        hbw=job.bw_args[2],
        op_path=job.op_path,
        solution_path=job.solution_path,
        xfer_name=job.xfer_name,
        random_seed=job.random_seed,
        sampler=sampler,
    )


def _parse_bw_args(
    exact_bw: tuple[int, ...] | None,
    norm_bw: tuple[int, ...] | None,
) -> tuple[list[int], list[tuple[int, int]], list[tuple[int, int, int]]]:
    lbw: list[int] = []
    mbw: list[tuple[int, int]] = []
    hbw: list[tuple[int, int, int]] = []

    if exact_bw is not None:
        if len(exact_bw) == 1:
            lbw.append(exact_bw[0])
        elif len(exact_bw) == 2:
            mbw.append(exact_bw)
        elif len(exact_bw) == 3:
            raise ValueError("Can't use hbw approx. for exact calculation")

    if norm_bw is not None:
        if len(norm_bw) == 1:
            lbw.append(norm_bw[0])
        elif len(norm_bw) == 2:
            mbw.append(norm_bw)
        elif len(norm_bw) == 3:
            hbw.append(norm_bw)

    return lbw, mbw, hbw


def resolve_xfer_name(
    xfer_fns: dict[str, FuncOp],
    requested_name: str | None,
) -> str:
    if requested_name is not None:
        xfer_name = requested_name
    elif len(xfer_fns) == 1:
        xfer_name = list(xfer_fns.keys())[0]
    else:
        xfer_name = "solution"

    if xfer_name not in xfer_fns:
        raise ValueError(f"Function {xfer_name}, not found in MLIR module")

    return xfer_name


def _make_job(
    domain: AbstractDomain,
    op_path: Path,
    solution_path: Path,
    xfer_name: str,
    args: Namespace,
    bw_args: tuple[list[int], list[tuple[int, int]], list[tuple[int, int, int]]],
) -> EvalJob:
    return EvalJob(
        domain=domain,
        op_path=op_path,
        solution_path=solution_path,
        xfer_name=xfer_name,
        random_seed=args.random_seed,
        bw_args=bw_args,
        args=args,
    )


def main() -> None:
    args = _reg_args()
    input_path = args.input_path
    bw_args = _parse_bw_args(args.exact_bw, args.norm_bw)

    if input_path.is_dir():
        if args.domain or args.op:
            raise ValueError("Don't pass --domain/--op when using a solution dir")

        solutions = _get_solutions(input_path)
        jobs: list[EvalJob] = []
        for solution_path, op_path, domain in solutions:
            sol_module = parse_mlir_mod(solution_path)
            xfer_name = resolve_xfer_name(get_fns(sol_module), args.xfer_name)
            jobs.append(
                _make_job(
                    domain=domain,
                    op_path=op_path,
                    solution_path=solution_path,
                    xfer_name=xfer_name,
                    args=args,
                    bw_args=bw_args,
                )
            )

        jobs = sorted(jobs, key=lambda x: x.domain.value)
    elif input_path.is_file():
        assert args.domain is not None
        domain = AbstractDomain[args.domain]
        sol_module = parse_mlir_mod(input_path)
        xfer_name = resolve_xfer_name(get_fns(sol_module), args.xfer_name)
        jobs = [
            _make_job(
                domain=domain,
                op_path=args.op,
                solution_path=input_path,
                xfer_name=xfer_name,
                args=args,
                bw_args=bw_args,
            )
        ]
    else:
        raise ValueError(f"Input path not found: {input_path}")

    if len(jobs) == 1:
        data = [_run_job(jobs[0])]
    else:
        with Pool() as p:
            data = p.map(_run_job, jobs)

    exact_bw = args.exact_bw[0] if args.exact_bw is not None else None
    norm_bw = args.norm_bw[0] if args.norm_bw is not None else None

    rows = []
    for job, (top_r, synth_r) in zip(jobs, data):
        row = {
            "Domain": str(job.domain),
            "Op": job.op_path.stem,
        }

        if exact_bw is not None:
            top_8 = next(x for x in top_r.per_bit_res if x.bitwidth == exact_bw)
            synth_8 = next(x for x in synth_r.per_bit_res if x.bitwidth == exact_bw)
            row["Top Exact %"] = str(top_8.get_exact_prop() * 100.0)
            row["Synth Exact %"] = str(synth_8.get_exact_prop() * 100.0)

        if norm_bw is not None:
            top_64 = next(x for x in top_r.per_bit_res if x.bitwidth == norm_bw)
            synth_64 = next(x for x in synth_r.per_bit_res if x.bitwidth == norm_bw)
            row["Top Norm"] = str(top_64.dist)
            row["Synth Norm"] = str(synth_64.dist)

        rows.append(row)

    df = pd.DataFrame(rows)
    print(f"Exact bw: {args.exact_bw}")
    print(f"Norm bw:  {args.norm_bw}")
    print(df)
    if args.output:
        df.to_csv(args.output)


if __name__ == "__main__":
    main()
