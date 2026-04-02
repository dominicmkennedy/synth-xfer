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
    load_candidates,
)
from synth_xfer.cli.args import PreparedCandidates, get_sampler, make_sampler_parser

ExactBw: TypeAlias = int | tuple[int, int]
DistBw: TypeAlias = int | tuple[int, int] | tuple[int, int, int]
OutputRow: TypeAlias = tuple[str, str, str, float, float]


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

    p.add_argument(
        "--xfer-file",
        type=Path,
        nargs="+",
        required=True,
        help="Transformer file(s) or solution directory/directories",
    )
    p.add_argument("--xfer-name", type=str, help="Transformer to evaluate")
    p.add_argument("-i", "--input", type=Path, default=None)
    p.add_argument("-o", "--output", type=Path, default=None)
    p.add_argument(
        "--seq-dir", type=Path, help="Sequential transfer directory for pattern eval"
    )
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
        help="Exact workload as 'bw' or 'bw,samples' (default: 8,10000)",
    )
    p.add_argument(
        "--dist-bw",
        type=_parse_dist_bw,
        default=(64, 1000, 100000),
        help=(
            "Distance workload as 'bw', 'bw,samples', or "
            "'bw,lat_samples,crt_samples' (default: 64,10000,100000)"
        ),
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
    if args.input is not None:
        if args.domain is not None or args.op is not None:
            p.error("--input cannot be combined with --domain/--op")
    else:
        if args.domain is None or args.op is None:
            p.error("generated eval requires both --domain and --op")

    return args


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


def _bw(spec: ExactBw | DistBw) -> int:
    return spec[0] if isinstance(spec, tuple) else spec


def _workload_lists(
    exact_bw: ExactBw, dist_bw: DistBw
) -> tuple[list[int], list[tuple[int, int]], list[tuple[int, int, int]]]:
    lbw: list[int] = []
    mbw: list[tuple[int, int]] = []
    hbw: list[tuple[int, int, int]] = []
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


def _resolve_dataset_op_path(data: EnumData) -> Path:
    op_path = (
        Path(__file__).resolve().parents[2]
        / "mlir"
        / "Operations"
        / f"{data.metadata.op}.mlir"
    )
    if not op_path.is_file():
        raise ValueError(f"Could not resolve op file for dataset op {data.metadata.op}")
    return op_path


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
    print(f"{domain} | {op_name}")
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
    for row in rows:
        print(
            f"{row[0]:<{candidate_width}} | "
            f"{row[1]:>{exact_width}.6f} | "
            f"{row[2]:>{dist_width}.6f}"
        )


def _eval_group(group: EvalGroup, args: Namespace) -> list[OutputRow]:
    exact_bw = _bw(args.exact_bw)
    dist_bw = _bw(args.dist_bw)
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


def _dataset_groups(candidates: list[XferCandidate], args: Namespace) -> list[EvalGroup]:
    with args.input.open("r", encoding="utf-8") as f:
        data = EnumData.read_tsv(f)
    op_path = _resolve_dataset_op_path(data)
    return [EvalGroup.from_candidates(data.metadata.domain, op_path, candidates, data)]


def _generate_groups(candidates: list[XferCandidate], args: Namespace) -> list[EvalGroup]:
    grouped: dict[tuple[AbstractDomain, Path], list[XferCandidate]] = {}
    default_domain = AbstractDomain[args.domain]
    for cand in candidates:
        domain = cand.domain if cand.domain is not None else default_domain
        op_path = cand.op_path if cand.op_path is not None else args.op
        if domain is None or op_path is None:
            raise ValueError(
                "Generated eval requires candidate metadata or explicit --domain/--op"
            )
        grouped.setdefault((domain, op_path), []).append(cand)

    lbw, mbw, hbw = _workload_lists(args.exact_bw, args.dist_bw)
    items = list(grouped.items())

    def build_one(
        item: tuple[tuple[AbstractDomain, Path], list[XferCandidate]],
    ) -> EvalGroup:
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
    return [build_one(item) for item in items]


def _run_pattern_placeholder(args: Namespace) -> None:
    mode = "dataset" if args.input is not None else "generated"
    print("Pattern eval not implemented yet.")
    print(f"mode={mode}")
    print(f"xfer_file={[str(path) for path in args.xfer_file]}")
    print(f"xfer_name={args.xfer_name}")
    print(f"input={None if args.input is None else str(args.input)}")
    print(f"domain={args.domain}")
    print(f"op={None if args.op is None else str(args.op)}")
    print(f"seq_dir={args.seq_dir}")
    print(f"exact_bw={args.exact_bw}")
    print(f"dist_bw={args.dist_bw}")
    print(f"seed={args.seed}")
    print(f"unsound_ex={args.unsound_ex}")
    print(f"imprecise_ex={args.imprecise_ex}")


def main() -> None:
    args = _register_parser()

    if args.seq_dir is not None:
        _run_pattern_placeholder(args)
        return

    candidates = load_candidates(
        args.xfer_file,
        args.xfer_name,
        domain=None if args.input is not None else AbstractDomain[args.domain],
        op_path=None if args.input is not None else args.op,
    )

    groups = (
        _dataset_groups(candidates, args)
        if args.input is not None
        else _generate_groups(candidates, args)
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
