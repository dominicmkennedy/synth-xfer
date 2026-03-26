from argparse import ArgumentParser, Namespace
from pathlib import Path

import pandas as pd

from synth_xfer._util.domain import AbstractDomain
from synth_xfer._util.eval import enum
from synth_xfer._util.parse_mlir import get_helper_funcs
from synth_xfer._util.random import Random
from synth_xfer._util.tsv import EnumData, EnumMetaData
from synth_xfer.cli.args import get_sampler, int_triple, int_tuple, make_sampler_parser


def _register_parser() -> Namespace:
    p = ArgumentParser()

    p.add_argument("-o", "--output", type=Path, required=True)
    p.add_argument("--op", type=Path, help="path to concrete operation")
    p.add_argument(
        "-d",
        "--domain",
        type=str,
        choices=[str(x) for x in AbstractDomain],
        required=True,
        help="Abstract Domain",
    )
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
        help="Mid-bitwidths to sample abstract values with, but enumerate the concretizations of each of them exhaustively",
    )
    p.add_argument(
        "--hbw",
        nargs="*",
        type=int_triple,
        default=[],
        help="High-bitwidths to sample abstract values with, and sample the concretizations of each of them",
    )
    p.add_argument("--seed", type=int, help="Enum seed")
    make_sampler_parser(p)

    return p.parse_args()


def main() -> None:
    args = _register_parser()

    sampler = get_sampler(args)
    domain = AbstractDomain[args.domain]
    helpers = get_helper_funcs(args.op, domain)
    random = Random(args.seed)
    seed = random.randint(0, 2**32 - 1) if args.seed is None else args.seed
    arity = len(helpers.conc_arg_ty)

    to_eval = enum(args.lbw, args.mbw, args.hbw, seed, helpers, sampler)

    rows = []
    for bw, xs in to_eval.items():
        for fn_args, ideal in xs:
            rows.append((bw, *fn_args, ideal))

    cols = ["bw"] + [f"arg_{i}" for i in range(arity)] + ["ideal"]
    df = pd.DataFrame.from_records(rows, columns=cols)

    metadata = EnumMetaData(
        domain=domain,
        op=args.op.stem,
        arity=arity,
        seed=seed,
        lbw=args.lbw,
        mbw=args.mbw,
        hbw=args.hbw,
    )

    EnumData(metadata, df).write_tsv(args.output)


if __name__ == "__main__":
    main()
