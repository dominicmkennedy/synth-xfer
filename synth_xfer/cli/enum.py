from argparse import ArgumentParser, Namespace
from pathlib import Path

from synth_xfer._util.domain import AbstractDomain
from synth_xfer._util.tsv import build_enum_data
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
    build_enum_data(
        domain=AbstractDomain[args.domain],
        op_path=args.op,
        lbw=args.lbw,
        mbw=args.mbw,
        hbw=args.hbw,
        seed=args.seed,
        sampler=get_sampler(args),
    ).write_tsv(args.output)


if __name__ == "__main__":
    main()
