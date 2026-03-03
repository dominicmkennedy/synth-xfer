from argparse import ArgumentParser, Namespace
from dataclasses import dataclass
from io import StringIO
from pathlib import Path
from typing import TextIO

import pandas as pd
import yaml

from synth_xfer._util.domain import AbstractDomain
from synth_xfer._util.eval import enum
from synth_xfer._util.parse_mlir import get_helper_funcs
from synth_xfer._util.random import Random
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


@dataclass(frozen=True)
class EnumMetaData:
    domain: AbstractDomain
    op: str
    arity: int
    seed: int
    lbw: list[int]
    mbw: list[tuple[int, int]]
    hbw: list[tuple[int, int, int]]

    def dump(self) -> str:
        return yaml.safe_dump(
            {
                "domain": str(self.domain),
                "op": self.op,
                "arity": self.arity,
                "seed": self.seed,
                "lbw": self.lbw,
                "mbw": self.mbw,
                "hbw": self.hbw,
            },
            sort_keys=False,
            default_flow_style=None,
        ).rstrip("\n")

    def dump_commented(self) -> str:
        body = self.dump().splitlines()
        return "\n".join("# " + line for line in body)

    @classmethod
    def parse(cls, text: str) -> "EnumMetaData":
        obj = yaml.safe_load(text) or {}

        mbw = [tuple(map(int, t)) for t in obj["mbw"]]
        hbw = [tuple(map(int, t)) for t in obj["hbw"]]
        return cls(
            domain=AbstractDomain[obj["domain"]],
            op=str(obj["op"]),
            arity=int(obj["arity"]),
            seed=int(obj["seed"]),
            lbw=[int(a) for a in obj["lbw"]],
            mbw=[(a, b) for (a, b) in mbw],
            hbw=[(a, b, c) for (a, b, c) in hbw],
        )

    @classmethod
    def parse_commented(cls, commented_text: str) -> "EnumMetaData":
        lines = []
        for ln in commented_text.splitlines():
            assert ln.startswith("# ")
            lines.append(ln[2:])

        return cls.parse("\n".join(lines))


def write_tsv(md: EnumMetaData, to_eval: pd.DataFrame, path: Path):
    frontmatter = f"# ---\n{md.dump_commented()}\n# ---\n"

    with path.open("w") as f:
        f.write(frontmatter)
        to_eval.to_csv(
            f,
            sep="\t",
            index=False,
            header=True,
            lineterminator="\n",
        )


def read_tsv(f: TextIO) -> tuple[EnumMetaData, pd.DataFrame]:
    lines = f.read().splitlines()

    assert lines and lines[0].strip() == "# ---"
    end = next(i for i in range(1, len(lines)) if lines[i].strip() == "# ---")
    md = EnumMetaData.parse_commented("\n".join(lines[1:end]))

    tsv_text = "\n".join(lines[end + 1 :]) + "\n"
    df = pd.read_csv(StringIO(tsv_text), sep="\t")

    return md, df


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

    write_tsv(metadata, df, args.output)


if __name__ == "__main__":
    main()
