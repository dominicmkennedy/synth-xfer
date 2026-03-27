from argparse import ArgumentParser, Namespace
from contextlib import nullcontext
from dataclasses import dataclass
from io import StringIO
from pathlib import Path
from sys import stdin, stdout
from typing import Any, Callable

import pandas as pd
from xdsl.dialects.builtin import ModuleOp

from synth_xfer._util.domain import AbstractDomain
from synth_xfer._util.eval import (
    eval_transfer_func,
    parse_to_run_inputs,
    run_xfer_fns,
)
from synth_xfer._util.eval_result import EvalResult, PerBitRes
from synth_xfer._util.jit import Jit
from synth_xfer._util.lower import LowerToLLVM
from synth_xfer._util.parse_mlir import get_helper_funcs, top_as_xfer
from synth_xfer._util.tsv import EnumData, build_enum_data
from synth_xfer._util.xfer_data import (
    XferCandidate,
    enumdata_to_inputs,
    load_candidates,
    parse_enum_df,
    parse_eval_df,
)
from synth_xfer.cli.args import get_sampler, int_triple, int_tuple, make_sampler_parser


@dataclass(frozen=True)
class PreparedCandidates:
    arity: int
    labels: list[str]
    xfer_names: list[str]
    merged_mod: ModuleOp


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
    p.add_argument("--eval", action="store_true", help="Evaluate transformer(s)")

    p.add_argument("--bw", type=int, help="Bitwidth for stdin apply mode")
    p.add_argument(
        "-d",
        "--domain",
        type=str,
        choices=[str(x) for x in AbstractDomain],
        help="Abstract Domain",
    )
    p.add_argument("--op", type=Path, help="Concrete op for generated eval mode")
    p.add_argument(
        "--lbw",
        nargs="*",
        type=int,
        default=[],
        help="Low-bitwidths to evaluate exhaustively",
    )
    p.add_argument(
        "--mbw",
        nargs="*",
        type=int_tuple,
        default=[],
        help="Mid-bitwidth eval settings",
    )
    p.add_argument(
        "--hbw",
        nargs="*",
        type=int_triple,
        default=[],
        help="High-bitwidth eval settings",
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


def _has_sampler_tuning(args: Namespace) -> bool:
    sampler_flags = [
        args.uniform,
        args.normal,
        args.skew_left,
        args.skew_right,
        args.bimodal,
    ]
    return any(
        sampler_flags
        + [
            args.sigma != 0.15,
            args.alpha != 5.0,
            args.separation != 0.22,
        ]
    )


def _has_generated_workload_args(args: Namespace) -> bool:
    return any(
        [
            args.domain is not None,
            args.op is not None,
            bool(args.lbw),
            bool(args.mbw),
            bool(args.hbw),
            args.seed is not None,
            _has_sampler_tuning(args),
        ]
    )


def _validate_input_mode(args: Namespace, p: ArgumentParser) -> None:
    if args.input is not None:
        if args.bw is not None:
            p.error("--bw cannot be used with --input")
        if _has_generated_workload_args(args):
            p.error(
                "--input cannot be combined with generated-workload flags like "
                "--domain/--op/--lbw/--mbw/--hbw/--seed or sampler options"
            )


def _validate_eval_mode(args: Namespace, p: ArgumentParser) -> None:
    if args.input is not None:
        return
    if args.domain is None and args.op is not None:
        p.error("--op requires --domain in generated eval mode")
    if args.domain is not None and args.op is None:
        p.error("--domain requires --op in generated eval mode")
    if args.domain is not None and args.op is not None and not (args.lbw or args.mbw or args.hbw):
        p.error("generated eval requires at least one of --lbw/--mbw/--hbw")


def _validate_apply_mode(args: Namespace, p: ArgumentParser) -> None:
    if args.bw is None or args.domain is None:
        p.error("both --bw and --domain are required with no --input")
    if args.op is not None or args.lbw or args.mbw or args.hbw or args.seed is not None:
        p.error("--op/--lbw/--mbw/--hbw/--seed are only valid with --eval and no --input")
    if _has_sampler_tuning(args):
        p.error("sampler options are only valid with --eval and no --input")
    if args.unsound_ex != 0 or args.imprecise_ex != 0:
        p.error("--unsound-ex/--imprecise-ex are only valid with --eval")


def _validate_args(args: Namespace, p: ArgumentParser) -> None:
    _validate_input_mode(args, p)
    if args.input is not None:
        return
    if args.eval:
        _validate_eval_mode(args, p)
    else:
        _validate_apply_mode(args, p)


def _candidate_keys(candidates: list[XferCandidate]) -> list[str]:
    seen: dict[str, int] = {}
    result: list[str] = []

    for cand in candidates:
        base = cand.solution_path.parent.name
        if cand.solution_path.name != "solution.mlir":
            base = cand.solution_path.stem
        if not base:
            base = cand.xfer_name

        count = seen.get(base, 0)
        seen[base] = count + 1
        result.append(base if count == 0 else f"{base}_{count + 1}")

    return result


def _ensure_same_arity(candidates: list[XferCandidate]) -> int:
    arities = {cand.arity for cand in candidates}
    if len(arities) != 1:
        raise ValueError(f"All candidates must have the same arity, got: {sorted(arities)}")
    return next(iter(arities))


def _prepare_candidates(candidates: list[XferCandidate]) -> PreparedCandidates:
    return PreparedCandidates(
        arity=_ensure_same_arity(candidates),
        labels=_candidate_keys(candidates),
        xfer_names=[cand.xfer_name for cand in candidates],
        merged_mod=ModuleOp([op.clone() for cand in candidates for op in cand.mlir_mod.ops]),
    )


def _domain_arg(args: Namespace) -> AbstractDomain | None:
    return None if args.domain is None else AbstractDomain[args.domain]


def _check_domain(candidates: list[XferCandidate], domain: AbstractDomain) -> None:
    bad = [
        cand.label
        for cand in candidates
        if cand.domain is not None and cand.domain != domain
    ]
    if bad:
        raise ValueError(f"Candidate domains do not match workload domain {domain}: {bad}")


def _parse_stdin_inputs(args: Namespace, arity: int):
    assert args.bw is not None
    assert args.domain is not None
    domain = AbstractDomain[args.domain]
    df = pd.read_csv(StringIO(stdin.read()), sep="\t")
    in_strs = [tuple(x) for x in df.astype(str).itertuples(index=False, name=None)]
    to_eval = {args.bw: parse_to_run_inputs(domain, args.bw, arity, in_strs)}
    return domain, to_eval, df


def _run_apply(
    prepared: PreparedCandidates,
    domain: AbstractDomain,
    to_eval: dict[int, Any],
    df: pd.DataFrame,
    output: Path | None,
) -> None:
    run_outputs = run_xfer_fns(
        domain,
        to_eval,
        prepared.merged_mod,
        prepared.xfer_names,
    )

    out_df = df.copy()
    if len(prepared.labels) == 1:
        outputs = run_outputs[0]
        out_df["output"] = outputs
        out_df["size"] = [x.size() for x in outputs]
    else:
        for i, key in enumerate(prepared.labels):
            outputs = run_outputs[i]
            out_df[f"{key}_output"] = outputs
            out_df[f"{key}_size"] = [x.size() for x in outputs]

    out_ctx = nullcontext(stdout) if output is None else output.open("w")
    with out_ctx as out_f:
        if output is None:
            with pd.option_context("display.max_rows", None, "display.max_columns", None):
                print(out_df.to_string(index=False), file=out_f)
        else:
            out_df.to_csv(out_f, sep="\t", index=False)


def _format_eval_rows(
    domain: AbstractDomain,
    op_name: str | None,
    candidate_label: str,
    result: EvalResult,
) -> list[dict[str, str | int | float]]:
    rows: list[dict[str, str | int | float]] = []
    for res in result.per_bit_res:
        rows.append(
            {
                "Domain": str(domain),
                "Op": "" if op_name is None else op_name,
                "Candidate": candidate_label,
                "Bitwidth": res.bitwidth,
                "Cases": res.all_cases,
                "Sound %": res.get_sound_prop() * 100.0,
                "Exact %": res.get_exact_prop() * 100.0,
                "Dist": res.dist,
                "Base Dist": res.base_dist,
                "Sound Dist": res.sound_dist,
            }
        )
    return rows


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


def _eval_with_lowerer(
    to_eval: dict[int, Any],
    lowerer: LowerToLLVM,
    xfer_names: list[str],
    unsound_ex: int,
    imprecise_ex: int,
    extra_ptrs: Callable[[Jit, int], list[Any]] | None = None,
) -> list[EvalResult]:
    with Jit() as jit:
        jit.add_mod(lowerer)
        eval_input = {
            bw: (
                values,
                ([] if extra_ptrs is None else extra_ptrs(jit, bw))
                + [jit.get_fn_ptr(f"{xfer_name}_{bw}_shim") for xfer_name in xfer_names],
                [],
            )
            for bw, values in to_eval.items()
        }
        return eval_transfer_func(
            eval_input, unsound_ex=unsound_ex, imprecise_ex=imprecise_ex
        )


def _run_eval_from_dataset(
    prepared: PreparedCandidates,
    candidates: list[XferCandidate],
    data: EnumData,
    output: Path | None,
    unsound_ex: int,
    imprecise_ex: int,
) -> None:
    if prepared.arity != data.metadata.arity:
        raise ValueError(
            f"Candidate arity {prepared.arity} does not match dataset arity {data.metadata.arity}"
        )

    domain = data.metadata.domain
    to_eval = enumdata_to_inputs(data, parse_eval_df)
    _check_domain(candidates, domain)

    lowerer = LowerToLLVM(list(to_eval.keys()))
    for cand in candidates:
        lowerer.add_mod(cand.mlir_mod, [cand.xfer_name])

    results = _eval_with_lowerer(
        to_eval,
        lowerer,
        prepared.xfer_names,
        unsound_ex,
        imprecise_ex,
    )

    rows = []
    for i, result in enumerate(results):
        rows.extend(
            _format_eval_rows(domain, data.metadata.op, prepared.labels[i], result)
        )

    df = pd.DataFrame(rows)
    print(df.to_string(index=False))
    if output is not None:
        df.to_csv(output, index=False)

    for i, result in enumerate(results):
        _print_examples(
            prepared.labels[i],
            result.per_bit_res,
            show_unsound=unsound_ex > 0,
            show_imprecise=imprecise_ex > 0,
        )


def _run_eval_generated_group(
    prepared: PreparedCandidates,
    candidates: list[XferCandidate],
    domain: AbstractDomain,
    op_path: Path,
    args: Namespace,
) -> tuple[pd.DataFrame, list[tuple[str, list[PerBitRes]]]]:
    generated = build_enum_data(
        domain=domain,
        op_path=op_path,
        lbw=args.lbw,
        mbw=args.mbw,
        hbw=args.hbw,
        seed=args.seed,
        sampler=get_sampler(args),
    )

    if prepared.arity != generated.metadata.arity:
        raise ValueError(
            f"Candidate arity {prepared.arity} does not match generated arity {generated.metadata.arity}"
        )

    to_eval = enumdata_to_inputs(generated, parse_eval_df)
    _check_domain(candidates, domain)

    helpers = get_helper_funcs(op_path, domain)
    top_mlir = top_as_xfer(helpers.transfer_func)

    lowerer = LowerToLLVM(list(to_eval.keys()))
    lowerer.add_fn(helpers.meet_func)
    lowerer.add_fn(helpers.get_top_func)
    top_xfer = lowerer.add_fn(top_mlir, shim=True)
    for cand in candidates:
        lowerer.add_mod(cand.mlir_mod, [cand.xfer_name])

    results = _eval_with_lowerer(
        to_eval,
        lowerer,
        prepared.xfer_names,
        args.unsound_ex,
        args.imprecise_ex,
        extra_ptrs=lambda jit, bw: [jit.get_fn_ptr(top_xfer[bw].name)],
    )

    rows = _format_eval_rows(domain, op_path.stem, "top", results[0])
    examples: list[tuple[str, list[PerBitRes]]] = []
    for i, result in enumerate(results[1:]):
        label = prepared.labels[i]
        rows.extend(_format_eval_rows(domain, op_path.stem, label, result))
        examples.append((label, result.per_bit_res))

    return pd.DataFrame(rows), examples


def _group_generated_candidates(
    candidates: list[XferCandidate],
    args: Namespace,
) -> dict[tuple[AbstractDomain, Path], list[XferCandidate]]:
    groups: dict[tuple[AbstractDomain, Path], list[XferCandidate]] = {}
    default_domain = _domain_arg(args)

    for cand in candidates:
        domain = cand.domain if cand.domain is not None else default_domain
        op_path = cand.op_path if cand.op_path is not None else args.op
        if domain is None or op_path is None:
            raise ValueError(
                "Generated eval requires candidate metadata or explicit --domain/--op"
            )
        groups.setdefault((domain, op_path), []).append(cand)

    return groups


def _run_eval_generated(candidates: list[XferCandidate], args: Namespace) -> None:
    if not (args.lbw or args.mbw or args.hbw):
        raise ValueError("Generated eval requires at least one of --lbw/--mbw/--hbw")

    frames = []
    all_examples: list[tuple[str, list[PerBitRes]]] = []
    for (domain, op_path), grouped_candidates in _group_generated_candidates(
        candidates, args
    ).items():
        prepared = _prepare_candidates(grouped_candidates)
        frame, examples = _run_eval_generated_group(
            prepared, grouped_candidates, domain, op_path, args
        )
        frames.append(frame)
        all_examples.extend(examples)

    df = pd.concat(frames, ignore_index=True) if frames else pd.DataFrame()
    print(df.to_string(index=False))
    if args.output is not None:
        df.to_csv(args.output, index=False)

    for label, per_bit_res in all_examples:
        _print_examples(
            label,
            per_bit_res,
            show_unsound=args.unsound_ex > 0,
            show_imprecise=args.imprecise_ex > 0,
        )


def main() -> None:
    args = _register_parser()
    candidates = load_candidates(
        args.xfer_file,
        args.xfer_name,
        domain=_domain_arg(args),
        op_path=args.op,
    )
    prepared = _prepare_candidates(candidates)

    if args.eval:
        if args.input is not None:
            with args.input.open("r", encoding="utf-8") as f:
                data = EnumData.read_tsv(f)
            _run_eval_from_dataset(
                prepared,
                candidates,
                data,
                args.output,
                args.unsound_ex,
                args.imprecise_ex,
            )
        else:
            _run_eval_generated(candidates, args)
        return

    if args.input is not None:
        with args.input.open("r", encoding="utf-8") as f:
            data = EnumData.read_tsv(f)
        if prepared.arity != data.metadata.arity:
            raise ValueError(
                f"Candidate arity {prepared.arity} does not match dataset arity {data.metadata.arity}"
            )
        domain = data.metadata.domain
        to_eval = enumdata_to_inputs(data, parse_enum_df)
        df = data.enumdata
        _check_domain(candidates, domain)
    else:
        domain, to_eval, df = _parse_stdin_inputs(args, prepared.arity)
        _check_domain(candidates, domain)

    _run_apply(prepared, domain, to_eval, df, args.output)


if __name__ == "__main__":
    main()
