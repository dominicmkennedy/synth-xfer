from argparse import Namespace
from dataclasses import dataclass
from json import dump, dumps
from multiprocessing import Pool
from pathlib import Path
from typing import Any

import yaml

from synth_xfer._util.domain import AbstractDomain
from synth_xfer._util.log import init_logging
from synth_xfer._util.parse_mlir import get_fns, parse_mlir_mod
from synth_xfer.cli.args import build_parser, get_sampler
from synth_xfer.cli.sxf import run


@dataclass(frozen=True)
class BenchmarkInput:
    name: str
    domain: AbstractDomain
    op_path: Path
    arity: int
    lbw: list[int]
    mbw: list[tuple[int, int]]
    hbw: list[tuple[int, int, int]]


def _resolve_benchmark_input(name: str) -> Path:
    mlir_dir = Path("mlir")
    candidates = [
        mlir_dir / "Operations" / f"{name}.mlir",
        mlir_dir / "Patterns" / f"{name}.mlir",
    ]
    for candidate in candidates:
        if candidate.exists():
            return candidate
    raise FileNotFoundError(
        f"Could not find benchmark input '{name}' in mlir/Operations or mlir/Patterns"
    )


def _normalize_benchmark_name(value: object) -> str:
    if isinstance(value, int):
        value = f"{value:03d}"
    assert isinstance(value, str)
    return value


def _parse_int_tuples(value: object, width: int) -> list[tuple[int, ...]]:
    assert isinstance(value, list)
    result: list[tuple[int, ...]] = []
    for item in value:
        assert isinstance(item, list) and len(item) == width
        result.append(tuple(int(x) for x in item))
    return result


def _load_bw_config(
    bw_config: object, arity: int
) -> tuple[list[int], list[tuple[int, ...]], list[tuple[int, ...]]]:
    assert isinstance(bw_config, dict)
    arity_cfg = bw_config.get(str(arity), bw_config.get(arity))
    assert isinstance(arity_cfg, dict)

    lbw = [int(x) for x in arity_cfg.get("lbw", [])]
    mbw = _parse_int_tuples(arity_cfg.get("mbw", []), width=2)
    hbw = _parse_int_tuples(arity_cfg.get("hbw", []), width=3)
    return lbw, mbw, hbw


def _load_benchmarks(config_path: Path) -> list[BenchmarkInput]:
    with config_path.open() as f:
        data = yaml.safe_load(f) or {}

    if not isinstance(data, dict):
        raise TypeError("Benchmark YAML must be a mapping from domain names to config.")

    benchmarks: list[BenchmarkInput] = []
    for domain_name, domain_cfg in data.items():
        domain = AbstractDomain[domain_name]
        assert isinstance(domain_cfg, dict)
        patterns = domain_cfg.get("patterns", [])
        assert isinstance(patterns, list)
        bw_cfg = domain_cfg["bw"]

        for pattern_spec in patterns:
            pattern_name = _normalize_benchmark_name(pattern_spec)
            tf_path = _resolve_benchmark_input(pattern_name)
            arity = len(get_fns(parse_mlir_mod(tf_path))["concrete_op"].args)
            lbw, mbw, hbw = _load_bw_config(bw_cfg, arity=arity)
            benchmarks.append(
                BenchmarkInput(
                    name=pattern_name,
                    domain=domain,
                    op_path=tf_path,
                    arity=arity,
                    lbw=lbw,
                    mbw=mbw,  # type: ignore
                    hbw=hbw,  # type: ignore
                )
            )

    return benchmarks


def synth_run(
    x: tuple[BenchmarkInput, Namespace],
) -> dict[str, Any]:
    bench = x[0]
    args = x[1]

    sampler = get_sampler(args)

    print(f"Running {bench.domain} {bench.name}")

    try:
        output_folder = args.output / f"{bench.domain}_{bench.name}"
        output_folder.mkdir()

        logger = init_logging(output_folder, not args.quiet)
        max_len = max(
            len(k)
            for k in [*vars(args), "transfer_functions", "arity", "lbw", "mbw", "hbw"]
        )
        logger.config(f"{'transfer_functions':<{max_len}} | {bench.op_path}")
        logger.config(f"{'arity':<{max_len}} | {bench.arity}")
        logger.config(f"{'lbw':<{max_len}} | {bench.lbw}")
        logger.config(f"{'mbw':<{max_len}} | {bench.mbw}")
        logger.config(f"{'hbw':<{max_len}} | {bench.hbw}")
        [logger.config(f"{k:<{max_len}} | {v}") for k, v in vars(args).items()]

        res = run(
            domain=bench.domain,
            num_mcmc=args.num_mcmc,
            num_steps=args.num_steps,
            program_length=args.program_length,
            inv_temp=args.inv_temp,
            vbw=args.vbw,
            lbw=bench.lbw,
            mbw=bench.mbw,
            hbw=bench.hbw,
            num_iters=args.num_iters,
            condition_length=args.condition_length,
            num_abd_procs=args.num_abd_procs,
            random_seed=args.random_seed,
            random_number_file=None,
            transformer_file=bench.op_path,
            dsl_ops_path=args.dsl_ops,
            weighted_dsl=args.weighted_dsl,
            num_unsound_candidates=args.num_unsound_candidates,
            optimize=args.optimize,
            sampler=sampler,
        )

        return {
            "Domain": str(bench.domain),
            "Function": bench.name,
            "Arity": bench.arity,
            "Transfer Function": str(bench.op_path),
            "lbw": bench.lbw,
            "mbw": [list(item) for item in bench.mbw],
            "hbw": [list(item) for item in bench.hbw],
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
            "Domain": str(bench.domain),
            "Function": bench.name,
            "Arity": bench.arity,
            "Transfer Function": str(bench.op_path),
            "Notes": f"Run was terminated: {e}",
        }


def main() -> None:
    args = build_parser("benchmark")
    benchmarks = _load_benchmarks(args.benchmarks)

    if len(benchmarks) == 0:
        raise ValueError("No benchmarks selected to eval")

    if not args.output.exists():
        args.output.mkdir(parents=True, exist_ok=True)
    else:
        raise FileExistsError(f'Output folder "{args.output}" already exists.')

    with Pool() as p:
        data = p.map(synth_run, [(bench, args) for bench in benchmarks])

    with open(args.output.joinpath("data.json"), "w") as f:
        dump(data, f, indent=2)

    print(dumps(data, indent=2))


if __name__ == "__main__":
    main()
