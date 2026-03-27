from dataclasses import dataclass
from io import StringIO
from pathlib import Path
from typing import TextIO

import pandas as pd
import yaml

from synth_xfer._util.domain import AbstractDomain


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


@dataclass(frozen=True)
class EnumData:
    metadata: EnumMetaData
    enumdata: pd.DataFrame

    def write_tsv(self, path: Path) -> None:
        frontmatter = f"# ---\n{self.metadata.dump_commented()}\n# ---\n"

        with path.open("w") as f:
            f.write(frontmatter)
            self.enumdata.to_csv(
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
        frame = pd.read_csv(StringIO(tsv_text), sep="\t")

        return cls(metadata, frame)
