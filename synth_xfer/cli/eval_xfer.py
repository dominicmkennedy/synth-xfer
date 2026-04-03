from argparse import ArgumentParser, ArgumentTypeError, Namespace
from concurrent.futures import ThreadPoolExecutor
from dataclasses import dataclass
from pathlib import Path
from typing import TypeAlias

import pandas as pd

from synth_xfer._util.domain import AbstractDomain
from synth_xfer._util.eval import eval_transfer_func
from synth_xfer._util.eval_result import PerBitRes
from synth_xfer._util.jit import Jit
from synth_xfer._util.lower import LowerToLLVM
from synth_xfer._util.parse_mlir import get_helper_funcs, top_as_xfer
from synth_xfer._util.tsv import EnumData, build_enum_data
from synth_xfer._util.xfer_data import (
    XferCandidate,
    enumdata_to_eval_inputs,
    load_file_candidates,
    load_solution_dir_candidates,
)
from synth_xfer.cli.args import PreparedCandidates, get_sampler, make_sampler_parser

ExactBw: TypeAlias = int | tuple[int, int]
DistBw: TypeAlias = int | tuple[int, int] | tuple[int, int, int]
OutputRow: TypeAlias = tuple[str, str, str, float, float]
GroupItem: TypeAlias = tuple[tuple[AbstractDomain, Path], list[XferCandidate]]


@dataclass(frozen=True)
class EvalGroup:
    domain: AbstractDomain
    op_path: Path
    candidates: list[XferCandidate]
    prepared: PreparedCandidates
    data: EnumData

    @classmethod
    def from_candidates(
        cls,
        domain: AbstractDomain,
        op_path: Path,
        candidates: list[XferCandidate],
        data: EnumData,
    ) -> "EvalGroup":
        return cls(
            domain=domain,
            op_path=op_path,
            candidates=candidates,
            prepared=PreparedCandidates.from_candidates(candidates),
            data=data,
        )


def _register_parser() -> Namespace:
    p = ArgumentParser()
    xfer_group = p.add_mutually_exclusive_group(required=True)

    xfer_group.add_argument(
        "--xfer-file",
        type=Path,
        nargs="+",
        help="Transformer MLIR file(s)",
    )
    xfer_group.add_argument(
        "--solution-dir",
        type=Path,
        help="Path to sxf solution directory",
    )
    p.add_argument(
        "--xfer-name", type=str, help="Name of transformer function to evaluate"
    )
    p.add_argument("-i", "--input", type=Path, default=None)
    p.add_argument("-o", "--output", type=Path, default=None)
    p.add_argument(
        "-d",
        "--domain",
        type=str,
        choices=[str(x) for x in AbstractDomain],
        help="Abstract Domain",
    )
    p.add_argument("--op", type=Path, help="Concrete op for generated eval mode")
    p.add_argument(
        "--exact-bw",
        type=_parse_exact_bw,
        default=(8, 1000),
        help="Exact bw to eval as 'bw' or 'bw,samples'",
    )
    p.add_argument(
        "--dist-bw",
        type=_parse_dist_bw,
        default=(64, 1000, 100000),
        help=("dist bw to eval 'bw', 'bw,samples', or 'bw,lat_samples,crt_samples'"),
    )
    p.add_argument("--seed", type=int, help="Evaluation seed")
    p.add_argument(
        "--unsound-ex",
        type=int,
        default=0,
        help="Maximum unsound examples to collect",
    )
    p.add_argument(
        "--imprecise-ex",
        type=int,
        default=0,
        help="Maximum imprecise examples to collect",
    )
    make_sampler_parser(p)

    args = p.parse_args()
    _validate_args(args, p)

    return args


def _validate_args(args: Namespace, p: ArgumentParser):
    if args.input is not None:
        if args.solution_dir is not None:
            p.error("--solution-dir cannot be combined with --input")
        if args.domain is not None or args.op is not None:
            p.error("--input cannot be combined with --domain/--op")
    else:
        if args.solution_dir is not None:
            if args.domain is not None or args.op is not None:
                p.error(
                    "--solution-dir cannot be combined with --domain/--op; "
                    "candidate metadata comes from config.log"
                )
        elif args.domain is None or args.op is None:
            p.error("generated eval with --xfer-file requires both --domain and --op")

    if args.xfer_file is not None:
        for f in args.xfer_file:
            if not f.is_file():
                p.error(f"--xfer-file expects files, got: {f}")
    elif args.solution_dir is not None:
        if not args.solution_dir.is_dir():
            p.error(f"--solution-dir expects a directory, got: {args.solution_dir}")


def _parse_exact_bw(s: str) -> ExactBw:
    parts = [int(x.strip()) for x in s.split(",") if x.strip()]
    if len(parts) == 1:
        return parts[0]
    if len(parts) == 2:
        return (parts[0], parts[1])
    raise ArgumentTypeError(
        f"Invalid --exact-bw format: {s!r}. Expected 'bw' or 'bw,samples'"
    )


def _parse_dist_bw(s: str) -> DistBw:
    parts = [int(x.strip()) for x in s.split(",") if x.strip()]
    if len(parts) == 1:
        return parts[0]
    if len(parts) == 2:
        return (parts[0], parts[1])
    if len(parts) == 3:
        return (parts[0], parts[1], parts[2])
    raise ArgumentTypeError(
        f"Invalid --dist-bw format: {s!r}. Expected 'bw', 'bw,samples', "
        "or 'bw,lat_samples,crt_samples'"
    )


def _workload_lists(
    exact_bw: ExactBw, dist_bw: DistBw
) -> tuple[list[int], list[tuple[int, int]], list[tuple[int, int, int]]]:
    lbw, mbw, hbw = [], [], []
    for spec in (exact_bw, dist_bw):
        if isinstance(spec, int):
            if spec not in lbw:
                lbw.append(spec)
        elif len(spec) == 2:
            if spec not in mbw:
                mbw.append(spec)
        else:
            if spec not in hbw:
                hbw.append(spec)

    return lbw, mbw, hbw


def _print_examples(
    label: str,
    per_bit_res: list[PerBitRes],
    show_unsound: bool,
    show_imprecise: bool,
) -> None:
    found_unsound = False
    found_imprecise = False

    for bit_res in per_bit_res:
        if show_unsound and bit_res.unsound_examples:
            found_unsound = True
            print(
                f"\nUNSOUND EXAMPLES [{label} @ {bit_res.bitwidth}-bit]"
                f" ({len(bit_res.unsound_examples)}):"
            )
            for ex in bit_res.unsound_examples:
                print(ex.to_str(show_dist=False))

        if show_imprecise and bit_res.imprecise_examples:
            found_imprecise = True
            print(
                f"\nIMPRECISE EXAMPLES [{label} @ {bit_res.bitwidth}-bit]"
                f" ({len(bit_res.imprecise_examples)}):"
            )
            for ex in bit_res.imprecise_examples:
                print(ex.to_str())

    if show_unsound and not found_unsound:
        print(f"\nUNSOUND EXAMPLES [{label}]: none")
    if show_imprecise and not found_imprecise:
        print(f"IMPRECISE EXAMPLES [{label}]: none")


def _print_summary(
    domain: AbstractDomain, op_name: str, rows: list[tuple[str, float, float]]
) -> None:
    print(f"{domain} {op_name}")
    candidate_width = max(len("Candidate"), *(len(row[0]) for row in rows))
    exact_header = "Exact %"
    exact_width = max(len(exact_header), *(len(f"{row[1]:.6f}") for row in rows))
    dist_header = "Dist"
    dist_width = max(len(dist_header), *(len(f"{row[2]:.6f}") for row in rows))
    print(
        f"{'Candidate':<{candidate_width}} | "
        f"{exact_header:>{exact_width}} | "
        f"{dist_header:>{dist_width}}"
    )
    print(f"{'-' * candidate_width}-|-{'-' * exact_width}-|-{'-' * dist_width}")
    for row in rows:
        print(
            f"{row[0]:<{candidate_width}} | "
            f"{row[1]:>{exact_width}.6f} | "
            f"{row[2]:>{dist_width}.6f}"
        )
    print("")


def _eval_group(group: EvalGroup, args: Namespace) -> list[OutputRow]:
    exact_bw = args.exact_bw[0] if isinstance(args.exact_bw, tuple) else args.exact_bw
    dist_bw = args.dist_bw[0] if isinstance(args.dist_bw, tuple) else args.dist_bw
    to_eval = enumdata_to_eval_inputs(group.data)

    if exact_bw not in to_eval:
        raise ValueError(f"Dataset does not contain bw={exact_bw} for exact scoring")
    if dist_bw not in to_eval:
        raise ValueError(f"Dataset does not contain bw={dist_bw} for dist scoring")

    selected_to_eval = {exact_bw: to_eval[exact_bw]}
    if dist_bw != exact_bw:
        selected_to_eval[dist_bw] = to_eval[dist_bw]

    helpers = get_helper_funcs(group.op_path, group.domain)
    top_mlir = top_as_xfer(helpers.transfer_func)
    lowerer = LowerToLLVM(list(selected_to_eval))
    lowerer.add_fn(helpers.meet_func)
    lowerer.add_fn(helpers.get_top_func)
    top_xfer = lowerer.add_fn(top_mlir, shim=True)
    for cand in group.candidates:
        lowerer.add_mod(cand.mlir_mod, [cand.xfer_name])

    with Jit() as jit:
        jit.add_mod(lowerer)
        results = eval_transfer_func(
            {
                bw: (
                    values,
                    [jit.get_fn_ptr(top_xfer[bw].name)]
                    + [
                        jit.get_fn_ptr(f"{x}_{bw}_shim")
                        for x in group.prepared.xfer_names
                    ],
                    [],
                )
                for bw, values in selected_to_eval.items()
            },
            unsound_ex=args.unsound_ex,
            imprecise_ex=args.imprecise_ex,
        )

    labels = ["top", *group.prepared.labels]
    rows: list[tuple[str, float, float]] = []
    for label, result in zip(labels, results):
        exact_per_bit = next(x for x in result.per_bit_res if x.bitwidth == exact_bw)
        dist_per_bit = next(x for x in result.per_bit_res if x.bitwidth == dist_bw)
        rows.append((label, exact_per_bit.get_exact_prop() * 100.0, dist_per_bit.dist))

    _print_summary(group.domain, group.data.metadata.op, rows)
    output_rows = [
        (str(group.domain), group.data.metadata.op, label, exact, dist)
        for label, exact, dist in rows
    ]

    for i, label in enumerate(labels):
        per_bits = [next(x for x in results[i].per_bit_res if x.bitwidth == exact_bw)]
        if dist_bw != exact_bw:
            per_bits.append(
                next(x for x in results[i].per_bit_res if x.bitwidth == dist_bw)
            )
        _print_examples(
            label,
            per_bits,
            show_unsound=args.unsound_ex > 0,
            show_imprecise=args.imprecise_ex > 0,
        )

    return output_rows


def _dataset_groups(candidates: list[XferCandidate], args: Namespace) -> EvalGroup:
    with args.input.open("r") as f:
        data = EnumData.read_tsv(f)

    mlir_dir = Path(__file__).resolve().parents[2] / "mlir"
    mid_dir = "Patterns" if str(data.metadata.op).isnumeric() else "Operations"
    fname = f"{data.metadata.op}.mlir"
    op_path = mlir_dir / mid_dir / fname

    if not op_path.is_file():
        raise FileNotFoundError(f"Could not find mlir op: {op_path}")
    return EvalGroup.from_candidates(data.metadata.domain, op_path, candidates, data)


def _build_generated_groups(items: list[GroupItem], args: Namespace) -> list[EvalGroup]:
    lbw, mbw, hbw = _workload_lists(args.exact_bw, args.dist_bw)

    def build_one(item: GroupItem) -> EvalGroup:
        (domain, op_path), group_cands = item
        data = build_enum_data(
            domain=domain,
            op_path=op_path,
            lbw=lbw,
            mbw=mbw,
            hbw=hbw,
            seed=args.seed,
            sampler=get_sampler(args),
        )
        return EvalGroup.from_candidates(domain, op_path, group_cands, data)

    if len(items) > 1:
        with ThreadPoolExecutor(max_workers=len(items)) as pool:
            return list(pool.map(build_one, items))

    return [build_one(items[0])]


def main() -> None:
    args = _register_parser()

    if args.solution_dir is not None:
        if not args.solution_dir.is_dir():
            raise ValueError(f"Solution directory not found: {args.solution_dir}")
        if args.xfer_name is not None:
            raise ValueError("--xfer-name cannot be used with --solution-dir")

        groups = _build_generated_groups(
            list(load_solution_dir_candidates(args.solution_dir).items()),
            args,
        )
    else:
        assert args.xfer_file is not None
        candidates = load_file_candidates(
            args.xfer_file,
            args.xfer_name,
        )
        groups = (
            [_dataset_groups(candidates, args)]
            if args.input is not None
            else _build_generated_groups(
                [((AbstractDomain[args.domain], args.op), candidates)],
                args,
            )
        )

    output_rows: list[OutputRow] = []
    for group in groups:
        output_rows.extend(_eval_group(group, args))

    if args.output is not None:
        pd.DataFrame(
            output_rows,
            columns=["Domain", "Op", "Candidate", "Exact %", "Dist"],
        ).to_csv(args.output, index=False)


if __name__ == "__main__":
    main()
