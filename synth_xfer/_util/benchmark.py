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
from synth_xfer.cli.args import get_sampler
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


def _prepare_output_dir(output_dir: Path, *, allow_existing: bool) -> None:
    if output_dir.exists():
        if not output_dir.is_dir():
            raise FileExistsError(f'Output path "{output_dir}" already exists.')
        if not allow_existing:
            raise FileExistsError(f'Output folder "{output_dir}" already exists.')
        return

    output_dir.mkdir(parents=True, exist_ok=False)


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


def _load_arity_config(
    arity_config: object, arity: int
) -> tuple[list[int], list[tuple[int, int]], list[tuple[int, int, int]]]:
    assert isinstance(arity_config, dict)
    arity_cfg = arity_config.get(str(arity), arity_config.get(arity))
    assert isinstance(arity_cfg, dict)

    lbw = [int(x) for x in arity_cfg.get("lbw", [])]
    mbw_raw = _parse_int_tuples(arity_cfg.get("mbw", []), width=2)
    hbw_raw = _parse_int_tuples(arity_cfg.get("hbw", []), width=3)
    mbw = [(int(a), int(b)) for (a, b) in mbw_raw]
    hbw = [(int(a), int(b), int(c)) for (a, b, c) in hbw_raw]
    return lbw, mbw, hbw


def _load_benchmark(config_path: Path) -> list[BenchmarkInput]:
    with config_path.open() as f:
        data = yaml.safe_load(f) or {}

    if not isinstance(data, dict):
        raise TypeError("Benchmark YAML must be a mapping from domain names to config.")

    benchmark: list[BenchmarkInput] = []
    for domain_name, domain_cfg in data.items():
        domain = AbstractDomain[domain_name]
        assert isinstance(domain_cfg, dict)
        patterns = domain_cfg.get("patterns", [])
        assert isinstance(patterns, list)
        arity_cfg = domain_cfg["arity"]

        for pattern_spec in patterns:
            pattern_name = _normalize_benchmark_name(pattern_spec)
            op_path = _resolve_benchmark_input(pattern_name)
            arity = len(get_fns(parse_mlir_mod(op_path))["concrete_op"].args)
            lbw, mbw, hbw = _load_arity_config(arity_cfg, arity=arity)
            benchmark.append(
                BenchmarkInput(
                    name=pattern_name,
                    domain=domain,
                    op_path=op_path,
                    arity=arity,
                    lbw=lbw,
                    mbw=mbw,
                    hbw=hbw,
                )
            )

    return benchmark


def _execute_job(
    bench: BenchmarkInput,
    args: Namespace,
    output_folder: Path,
    *,
    allow_existing: bool,
) -> dict[str, Any]:
    sampler = get_sampler(args)

    print(f"Running {bench.domain} {bench.name}")

    try:
        _prepare_output_dir(output_folder, allow_existing=allow_existing)

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
            seed=args.seed,
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


def _execute_benchmark_job(x: tuple[BenchmarkInput, Namespace]) -> dict[str, Any]:
    bench = x[0]
    args = x[1]
    assert args.output is not None
    return _execute_job(
        bench,
        args,
        args.output / f"{bench.domain}_{bench.name}",
        allow_existing=False,
    )


def run_single_synth(args: Namespace) -> None:
    assert args.op is not None
    assert args.domain is not None

    domain = AbstractDomain[args.domain]
    op_path = Path(args.op)

    bench = BenchmarkInput(
        name=op_path.stem,
        domain=domain,
        op_path=op_path,
        arity=len(get_fns(parse_mlir_mod(op_path))["concrete_op"].args),
        lbw=args.lbw,
        mbw=args.mbw,
        hbw=args.hbw,
    )

    output_folder = (
        Path("outputs", f"{domain}_{op_path.stem}")
        if args.output is None
        else Path(args.output)
    )

    _execute_job(bench, args, output_folder, allow_existing=True)


def run_benchmark(args: Namespace) -> None:
    assert args.benchmark is not None

    benchmark = _load_benchmark(args.benchmark)
    if len(benchmark) == 0:
        raise ValueError("No benchmark selected to eval")

    args.output = Path("outputs") if args.output is None else Path(args.output)
    if not args.output.exists():
        args.output.mkdir(parents=True, exist_ok=True)
    else:
        raise FileExistsError(f'Output folder "{args.output}" already exists.')

    with Pool() as p:
        data = p.map(_execute_benchmark_job, [(bench, args) for bench in benchmark])

    with open(args.output.joinpath("data.json"), "w") as f:
        dump(data, f, indent=2)

    print(dumps(data, indent=2))
