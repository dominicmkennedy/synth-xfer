from argparse import Namespace
from json import dump, dumps
from multiprocessing import Pool
from pathlib import Path
from typing import Any

from synth_xfer._util.domain import AbstractDomain
from synth_xfer._util.log import init_logging
from synth_xfer.cli.args import build_parser, get_sampler
from synth_xfer.cli.sxf import run


def synth_run(
    x: tuple[str, AbstractDomain, Path, Namespace],
) -> dict[str, Any]:
    func_name = x[0]
    domain = x[1]
    tf_path = x[2]
    args = x[3]

    sampler = get_sampler(args)

    mab = args.mab
    if (mab):
        print("Multi-armed bandit enabled")
    else:
        print("Multi-armed bandit disabled")


    print(f"Running {domain} {func_name}")

    try:
        output_folder = args.output / f"{domain}_{func_name}"
        output_folder.mkdir()

        logger = init_logging(output_folder, not args.quiet)
        max_len = max(len(k) for k in vars(args))
        logger.config(f"{'transfer_functions':<{max_len}} | {tf_path}")
        [logger.config(f"{k:<{max_len}} | {v}") for k, v in vars(args).items()]

        res = run(
            domain=domain,
            num_programs=args.num_programs,
            total_rounds=args.total_rounds,
            program_length=args.program_length,
            inv_temp=args.inv_temp,
            vbw=args.vbw,
            lbw=args.lbw,
            mbw=args.mbw,
            hbw=args.hbw,
            num_iters=args.num_iters,
            condition_length=args.condition_length,
            num_abd_procs=args.num_abd_procs,
            random_seed=args.random_seed,
            random_number_file=None,
            transformer_file=tf_path,
            dsl_ops_path=args.dsl_ops,
            weighted_dsl=args.weighted_dsl,
            num_unsound_candidates=args.num_unsound_candidates,
            optimize=args.optimize,
            sampler=sampler,
            mab=mab
        )

        return {
            "Domain": str(domain),
            "Function": func_name,
            "Per Bit Result": [
                {
                    "Bitwidth": per_bit_res.bitwidth,
                    "Sound Proportion": per_bit_res.get_sound_prop() * 100,
                    "Exact Proportion": per_bit_res.get_exact_prop() * 100,
                    "Distance": per_bit_res.dist,
                }
                for per_bit_res in res.per_bit_res
            ],
        }
    except Exception as e:
        return {
            "Domain": str(domain),
            "Function": func_name,
            "Notes": f"Run was terminated: {e}",
        }


def main() -> None:
    args = build_parser("benchmark")
    start_dir = Path("mlir") / "Operations"

    if len(args.kb_eval) + len(args.ucr_eval) + len(args.scr_eval) == 0:
        raise ValueError("No benchmarks selected to eval")

    if not args.output.exists():
        args.output.mkdir(parents=True, exist_ok=True)
    else:
        raise FileExistsError(f'Output folder "{args.output}" already exists.')

    kb_inputs = [
        (x, AbstractDomain.KnownBits, start_dir / f"{x}.mlir", args) for x in args.kb_eval
    ]

    ucr_inputs = [
        (x, AbstractDomain.UConstRange, start_dir / f"{x}.mlir", args)
        for x in args.ucr_eval
    ]

    scr_inputs = [
        (x, AbstractDomain.SConstRange, start_dir / f"{x}.mlir", args)
        for x in args.scr_eval
    ]

    with Pool() as p:
        data = p.map(synth_run, kb_inputs + ucr_inputs + scr_inputs)

    with open(args.output.joinpath("data.json"), "w") as f:
        dump(data, f, indent=2)

    print(dumps(data, indent=2))


if __name__ == "__main__":
    main()
