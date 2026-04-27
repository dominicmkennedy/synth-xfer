from dataclasses import dataclass
from io import StringIO
from pathlib import Path
import re
from typing import TextIO

import pandas as pd
import yaml

from synth_xfer._util.domain import AbstractDomain
from synth_xfer._util.eval import enum
from synth_xfer._util.parse_mlir import get_helper_funcs
from synth_xfer._util.random import Random, Sampler


@dataclass(frozen=True)
class EnumMetaData:
    domain: AbstractDomain
    op: str
    arity: int
    seed: int | None
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
            seed=None if obj["seed"] is None else int(obj["seed"]),
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


@dataclass
class EnumData:
    metadata: EnumMetaData
    enumdata: pd.DataFrame

    def __post_init__(self) -> None:
        self.enumdata = self._canonicalize_columns(self.enumdata)

    @staticmethod
    def _canonicalize_columns(frame: pd.DataFrame) -> pd.DataFrame:
        columns = list(frame.columns)
        arg_pattern = re.compile(r"arg_(\d+)$")

        if "bw" not in columns:
            raise ValueError("EnumData requires a 'bw' column")

        arg_cols = sorted(
            (
                (int(match.group(1)), col)
                for col in columns
                if (match := arg_pattern.fullmatch(col)) is not None
            ),
            key=lambda item: item[0],
        )
        if not arg_cols:
            raise ValueError("EnumData requires at least one 'arg_N' column")

        ordered = ["bw"]
        ordered.extend(col for _, col in arg_cols)
        if "ideal" in frame.columns:
            ordered.append("ideal")
        if "count" in frame.columns:
            ordered.append("count")
        if "weight" in frame.columns:
            ordered.append("weight")

        seen = set(ordered)
        ordered.extend(col for col in columns if col not in seen)
        return frame.loc[:, ordered]

    @classmethod
    def _prepare_for_write(cls, frame: pd.DataFrame) -> pd.DataFrame:
        out = cls._canonicalize_columns(frame)
        sort_cols = ["bw"]
        ascending = [True]
        if "count" in out.columns:
            sort_cols.append("count")
            ascending.append(False)
        return out.sort_values(
            sort_cols, ascending=ascending, kind="mergesort"
        ).reset_index(drop=True)

    def write_tsv(self, path: Path) -> None:
        frontmatter = f"# ---\n{self.metadata.dump_commented()}\n# ---\n"

        with path.open("w") as f:
            f.write(frontmatter)
            self._prepare_for_write(self.enumdata).to_csv(
                f,
                sep="\t",
                index=False,
                header=True,
                lineterminator="\n",
            )

    def write_tsv_with_comments(self, path: Path, commented_rows: list[str]) -> None:
        frontmatter = f"# ---\n{self.metadata.dump_commented()}\n# ---\n"
        with path.open("w") as f:
            f.write(frontmatter)
            for row in commented_rows:
                f.write(row)
                f.write("\n")
            self._prepare_for_write(self.enumdata).to_csv(
                f,
                sep="\t",
                index=False,
                header=True,
                lineterminator="\n",
            )

    @classmethod
    def read_tsv(cls, f: TextIO) -> "EnumData":
        lines = f.read().splitlines()

        assert lines and lines[0].strip() == "# ---"
        end = next(i for i in range(1, len(lines)) if lines[i].strip() == "# ---")
        metadata = EnumMetaData.parse_commented("\n".join(lines[1:end]))

        data_lines = [line for line in lines[end + 1 :] if not line.startswith("# ")]
        tsv_text = "\n".join(data_lines) + "\n"
        frame = pd.read_csv(StringIO(tsv_text), sep="\t", dtype=str)
        if "bw" in frame.columns:
            frame["bw"] = frame["bw"].astype(int)
        if "count" in frame.columns:
            frame["count"] = frame["count"].astype(int)

        return cls(metadata, frame)


def build_enum_data(
    domain: AbstractDomain,
    op_path: Path,
    lbw: list[int],
    mbw: list[tuple[int, int]],
    hbw: list[tuple[int, int, int]],
    seed: int | None,
    sampler: Sampler,
) -> EnumData:
    helpers = get_helper_funcs(op_path, domain)
    random = Random(seed)
    resolved_seed = random.randint(0, 2**32 - 1) if seed is None else seed
    arity = len(helpers.conc_arg_ty)

    to_eval = enum(lbw, mbw, hbw, resolved_seed, helpers, sampler)

    rows = []
    for bw, xs in to_eval.items():
        for fn_args, ideal in xs:
            rows.append((bw, *fn_args, ideal))

    cols = ["bw"] + [f"arg_{i}" for i in range(arity)] + ["ideal"]
    df = pd.DataFrame.from_records(rows, columns=cols)

    metadata = EnumMetaData(
        domain=domain,
        op=op_path.stem,
        arity=arity,
        seed=resolved_seed,
        lbw=lbw,
        mbw=mbw,
        hbw=hbw,
    )

    return EnumData(metadata, df)


def resolve_dataset_op_path(op: str) -> Path:
    op_input = Path(op)
    if op_input.suffix != ".mlir":
        raise ValueError("Dataset metadata 'op' must be a .mlir path")
    if op_input.is_file():
        return op_input
    repo_path = Path(__file__).resolve().parents[2] / op_input
    if repo_path.is_file():
        return repo_path
    raise FileNotFoundError(f"Could not find mlir op from dataset path: {op_input}")
