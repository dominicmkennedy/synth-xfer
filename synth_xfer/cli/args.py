from argparse import (
    ArgumentDefaultsHelpFormatter,
    ArgumentParser,
    ArgumentTypeError,
    BooleanOptionalAction,
    FileType,
    Namespace,
)
from pathlib import Path

from synth_xfer._util.domain import AbstractDomain
from synth_xfer._util.random import Sampler


def int_tuple(s: str) -> tuple[int, int]:
    try:
        items = s.split(",")
        if len(items) != 2:
            raise ValueError
        return (int(items[0]), int(items[1]))
    except Exception:
        raise ArgumentTypeError(f"Invalid tuple format: '{s}'. Expected format: int,int")


def int_triple(s: str) -> tuple[int, int, int]:
    try:
        items = s.split(",")
        if len(items) != 3:
            raise ValueError
        return (int(items[0]), int(items[1]), int(items[2]))
    except Exception:
        raise ArgumentTypeError(
            f"Invalid tuple format: '{s}'. Expected format: int,int,int"
        )


def int_list(s: str) -> list[int]:
    result: list[int] = []

    for chunk in s.split(","):
        chunk = chunk.strip()
        if not chunk:
            continue

        if "-" in chunk:
            parts = chunk.split("-")
            if len(parts) != 2 or not parts[0] or not parts[1]:
                raise ArgumentTypeError(f"Invalid range: {chunk!r}")

            try:
                start = int(parts[0].strip())
                end = int(parts[1].strip())
            except ValueError:
                raise ArgumentTypeError(f"Invalid range: {chunk!r}")

            if start < 0 or end < 0:
                raise ArgumentTypeError(f"Negative values are not allowed: {chunk!r}")
            if start > end:
                raise ArgumentTypeError(f"Range start must be <= end (got {chunk!r})")

            result.extend(range(start, end + 1))
        else:
            try:
                value = int(chunk)
            except ValueError:
                raise ArgumentTypeError(f"Invalid integer: {chunk!r}")
            if value < 0:
                raise ArgumentTypeError(f"Negative values are not allowed: {chunk!r}")
            result.append(value)

    if not result:
        raise ArgumentTypeError("Empty list of integers")

    return result


def make_sampler_parser(p: ArgumentParser):
    mx = p.add_mutually_exclusive_group(required=False)
    mx.add_argument(
        "-uniform", action="store_true", help="Use uniform sampling (default)"
    )
    mx.add_argument("-normal", action="store_true", help="Use normal sampling")
    mx.add_argument(
        "-skew-left", action="store_true", help="Use skew-normal left sampling"
    )
    mx.add_argument(
        "-skew-right", action="store_true", help="Use skew-normal right sampling"
    )
    mx.add_argument(
        "-bimodal", action="store_true", help="Use bimodal symmetric sampling"
    )

    g_normal = p.add_argument_group("normal options")
    g_normal.add_argument("-sigma", type=float, default=0.15, help="Stddev in unit space")

    g_skew = p.add_argument_group("skew options")
    g_skew.add_argument("-alpha", type=float, default=5.0, help="Skew magnitude (>0)")

    g_bimodal = p.add_argument_group("bimodal options")
    g_bimodal.add_argument(
        "-separation", type=float, default=0.22, help="Peak separation in [0, 0.49]"
    )

    return p


def get_sampler(args: Namespace) -> Sampler:
    if args.normal:
        return Sampler.normal(sigma=args.sigma)
    if args.skew_left:
        return Sampler.skew_left(sigma=args.sigma, alpha=args.alpha)
    if args.skew_right:
        return Sampler.skew_right(sigma=args.sigma, alpha=args.alpha)
    if args.bimodal:
        return Sampler.bimodal(sigma=args.sigma, separation=args.separation)

    return Sampler.uniform()


ALL_OPS = [
    "Abds",
    "Abdu",
    "Add",
    "AddNsw",
    "AddNswNuw",
    "AddNuw",
    "And",
    "Ashr",
    "AshrExact",
    "AvgCeilS",
    "AvgCeilU",
    "AvgFloorS",
    "AvgFloorU",
    "CountLOne",
    "CountLZero",
    "CountROne",
    "CountRZero",
    "Fshl",
    "Fshr",
    "Lshr",
    "LshrExact",
    "Mods",
    "Modu",
    "Mul",
    "MulNsw",
    "MulNswNuw",
    "MulNuw",
    "Nop",
    "Or",
    "PopCount",
    "Rotl",
    "Rotr",
    "SaddSat",
    "Sdiv",
    "SdivExact",
    "Shl",
    "ShlNsw",
    "ShlNswNuw",
    "ShlNuw",
    "Smax",
    "Smin",
    "SmulSat",
    "Square",
    "SshlSat",
    "SsubSat",
    "Sub",
    "SubNsw",
    "SubNswNuw",
    "SubNuw",
    "UaddSat",
    "Udiv",
    "UdivExact",
    "Umax",
    "Umin",
    "UmulSat",
    "UshlSat",
    "UsubSat",
    "Xor",
]


def build_parser(prog: str) -> Namespace:
    p = ArgumentParser(prog=prog, formatter_class=ArgumentDefaultsHelpFormatter)

    if prog == "synth_xfer":
        p.add_argument("transfer_functions", type=Path, help="path to transfer function")
        p.add_argument("-random_file", type=FileType("r"), help="file for preset rng")
        p.add_argument(
            "-domain",
            type=str,
            choices=[str(x) for x in AbstractDomain],
            required=True,
            help="Abstract Domain to evaluate",
        )

    p.add_argument(
        "-dsl_ops",
        type=Path,
        help="Path to DSL op-set JSON (e.g., dsl/ops_set_0.json)",
    )

    if prog == "benchmark":
        p.add_argument(
            "-kb-eval",
            nargs="*",
            choices=ALL_OPS,
            default=[],
            help=f"Zero or more items from: {', '.join(ALL_OPS)}",
        )
        p.add_argument(
            "-ucr-eval",
            nargs="*",
            choices=ALL_OPS,
            default=[],
            help=f"Zero or more items from: {', '.join(ALL_OPS)}",
        )
        p.add_argument(
            "-scr-eval",
            nargs="*",
            choices=ALL_OPS,
            default=[],
            help=f"Zero or more items from: {', '.join(ALL_OPS)}",
        )

    output_dir = Path("outputs") if prog == "benchmark" else None
    p.add_argument("-o", "--output", type=Path, help="Output dir", default=output_dir)
    make_sampler_parser(p)
    p.add_argument(
        "-optimize",
        action=BooleanOptionalAction,
        default=False,
        help="Run e-graph-based rewrite optimizer on synthesized candidates",
    )
    p.add_argument("-random_seed", type=int, help="seed for synthesis")
    p.add_argument(
        "-program_length",
        type=int,
        help="length of synthed program",
        default=28,
    )
    p.add_argument(
        "-total_rounds",
        type=int,
        help="number of rounds the synthesizer should run",
        default=1500,
    )
    p.add_argument(
        "-num_programs",
        type=int,
        help="number of programs that run every round",
        default=100,
    )
    p.add_argument(
        "-inv_temp",
        type=int,
        help="Inverse temperature for MCMC. The larger the value is, the lower the probability of accepting a program with a higher cost.",
        default=200,
    )
    p.add_argument(
        "-vbw",
        type=int_list,
        default=list(range(4, 65)),
        help="bws to verify at",
    )
    p.add_argument(
        "-lbw",
        nargs="*",
        type=int,
        default=[4],
        help="Bitwidths to evaluate exhaustively",
    )
    p.add_argument(
        "-mbw",
        nargs="*",
        type=int_tuple,
        default=[],
        help="Bitwidths to evaluate sampled lattice elements exhaustively",
    )
    p.add_argument(
        "-hbw",
        nargs="*",
        type=int_triple,
        default=[],
        help="Bitwidths to sample the lattice and abstract values with",
    )
    p.add_argument(
        "-num_iters",
        type=int,
        help="number of iterations for the synthesizer",
        default=10,
    )
    p.add_argument(
        "-no_weighted_dsl",
        dest="weighted_dsl",
        action="store_false",
        help="Disable learning weights for each DSL operation from previous for future iterations",
    )
    p.set_defaults(weighted_dsl=True)
    p.add_argument(
        "-condition_length", type=int, help="length of synthd abduction", default=10
    )
    p.add_argument(
        "-num_abd_procs",
        type=int,
        help="number of mcmc processes used for abduction. Must be less than num_programs",
        default=30,
    )
    p.add_argument(
        "-num_unsound_candidates",
        type=int,
        help="number of unsound candidates considered for abduction",
        default=15,
    )
    p.add_argument("-quiet", action="store_true")
    p.add_argument("-mab", action="store_true", help="Enable multi-armed bandit mutation")

    return p.parse_args()
