from dataclasses import dataclass
from pathlib import Path
from typing import Callable

import pandas as pd
from xdsl.dialects.builtin import ModuleOp, StringAttr, SymbolRefAttr
from xdsl.dialects.func import CallOp, FuncOp

from synth_xfer._util.domain import AbstractDomain
from synth_xfer._util.eval import (
    ArgsVec,
    RunInputMap,
    ToEval,
    parse_to_eval_inputs,
    parse_to_run_inputs,
)
from synth_xfer._util.parse_mlir import HelperFuncs, get_fns, parse_mlir_mod
from synth_xfer._util.tsv import EnumData


def resolve_xfer_name(
    xfer_fns: dict[str, FuncOp],
    requested_name: str | None,
) -> str:
    if requested_name is not None:
        xfer_name = requested_name
    elif len(xfer_fns) == 1:
        xfer_name = list(xfer_fns.keys())[0]
    else:
        xfer_name = "solution"

    if xfer_name not in xfer_fns:
        raise ValueError(f"Function {xfer_name}, not found in MLIR module")

    return xfer_name


@dataclass(frozen=True)
class XferCandidate:
    label: str
    solution_path: Path
    mlir_mod: ModuleOp
    xfer_name: str
    arity: int

    @classmethod
    def load(
        cls,
        solution_path: Path,
        requested_name: str | None,
        namespace: str,
    ) -> "XferCandidate":
        raw_mod = parse_mlir_mod(solution_path)
        raw_fns = get_fns(raw_mod)
        xfer_name = resolve_xfer_name(raw_fns, requested_name)
        mlir_mod = namespace_module(raw_mod, namespace)
        xfer_name = f"{namespace}_{xfer_name}"
        xfer_fns = get_fns(mlir_mod)

        return cls(
            label=str(solution_path.parent)
            if solution_path.name == "solution.mlir"
            else str(solution_path),
            solution_path=solution_path,
            mlir_mod=mlir_mod,
            xfer_name=xfer_name,
            arity=len(xfer_fns[xfer_name].args),
        )


@dataclass(frozen=True)
class PreparedCandidates:
    arity: int
    labels: list[str]
    xfer_names: list[str]
    merged_mod: ModuleOp

    @classmethod
    def from_candidates(cls, candidates: list[XferCandidate]) -> "PreparedCandidates":
        def candidate_keys(candidates: list[XferCandidate]) -> list[str]:
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

        def ensure_same_arity(candidates: list[XferCandidate]) -> int:
            arities = {cand.arity for cand in candidates}
            if len(arities) != 1:
                raise ValueError(
                    f"All candidates must have the same arity, got: {sorted(arities)}"
                )
            return next(iter(arities))

        return cls(
            arity=ensure_same_arity(candidates),
            labels=candidate_keys(candidates),
            xfer_names=[cand.xfer_name for cand in candidates],
            merged_mod=ModuleOp(
                [op.clone() for cand in candidates for op in cand.mlir_mod.ops]
            ),
        )


def namespace_module(mod: ModuleOp, prefix: str) -> ModuleOp:
    cloned = mod.clone()
    rename_map: dict[str, str] = {}

    for op in cloned.ops:
        assert isinstance(op, FuncOp)
        old_name = op.sym_name.data
        new_name = f"{prefix}_{old_name}"
        op.sym_name = StringAttr(new_name)
        rename_map[old_name] = new_name

    for op in cloned.walk():
        if isinstance(op, CallOp):
            callee = op.callee.string_value()
            if callee in rename_map:
                op.callee = SymbolRefAttr(rename_map[callee])

    return cloned


def prepare_exec_module(mod: ModuleOp, helpers: HelperFuncs) -> ModuleOp:
    # Modifies `mod` in place by adding missing domain helpers needed for JIT
    existing = get_fns(mod)
    helper_defs = (
        helpers.get_top_func,
        helpers.meet_func,
    )

    for helper in helper_defs:
        if helper is not None and helper.sym_name.data not in existing:
            mod.body.block.add_op(helper.clone())
            existing[helper.sym_name.data] = helper

    return mod


def _parse_config(config_path: Path) -> tuple[Path, AbstractDomain]:
    transfer_path: Path | None = None
    domain: AbstractDomain | None = None

    with config_path.open("r", encoding="utf-8") as f:
        for line in f:
            if not line.strip() or "|" not in line:
                continue

            key, value = line.split("|", 1)
            key = key.strip()
            value = value.strip()

            if key == "transfer_functions":
                transfer_path = Path(value)

            if key == "domain":
                domain = AbstractDomain[value]

    if transfer_path is None:
        print(config_path)
        raise ValueError("Missing 'transfer_functions' entry in config.")
    if domain is None:
        raise ValueError("Missing 'domain' entry in config.")

    return transfer_path, domain


def load_file_candidates(
    xfer_paths: list[Path],
    requested_name: str | None,
) -> list[XferCandidate]:
    candidates: list[XferCandidate] = []
    for i, xfer_path in enumerate(xfer_paths):
        candidates.append(
            XferCandidate.load(
                xfer_path,
                requested_name,
                namespace=f"cand{i}",
            )
        )

    return candidates


def load_solution_dir_candidates(
    solutions: Path,
) -> dict[tuple[AbstractDomain, Path], list[XferCandidate]]:
    candidates: dict[tuple[AbstractDomain, Path], list[XferCandidate]] = {}
    solution_paths = sorted(solutions.rglob("solution.mlir"))

    for i, solution_path in enumerate(solution_paths):
        config_path = solution_path.with_name("config.log")
        if not config_path.is_file():
            raise ValueError(f"Missing config.log for solution: {solution_path}")
        cfg_op_path, cfg_domain = _parse_config(config_path)
        candidates.setdefault((cfg_domain, cfg_op_path), []).append(
            XferCandidate.load(
                solution_path,
                None,
                namespace=f"cand{i}",
            )
        )

    return candidates


def parse_enum_df(
    df: pd.DataFrame, domain: AbstractDomain, arity: int, bw: int
) -> ArgsVec:
    if all(f"arg_{i}" in df.columns for i in range(arity)):
        df = df[[f"arg_{i}" for i in range(arity)]]  # type: ignore
    else:
        raise ValueError(f"Input header missing columns, for {arity}-ary transformer")

    in_strs = [tuple(x) for x in df.astype(str).itertuples(index=False, name=None)]

    return parse_to_run_inputs(domain, bw, arity, in_strs)


def parse_eval_df(
    df: pd.DataFrame, domain: AbstractDomain, arity: int, bw: int
) -> ToEval:
    if all(f"arg_{i}" in df.columns for i in range(arity)) and "ideal" in df.columns:
        args = (
            df[[f"arg_{i}" for i in range(arity)]]
            .astype(str)
            .itertuples(index=False, name=None)
        )
        ret = df[["ideal"]].astype(str).itertuples(index=False, name=None)
    else:
        raise ValueError(f"Input header missing columns, for {arity}-ary transformer")

    in_strs = [(tuple(x), y[0]) for x, y in zip(args, ret)]

    return parse_to_eval_inputs(domain, bw, arity, in_strs)


def _enumdata_to_inputs(
    data: EnumData,
    parse_fn: Callable[[pd.DataFrame, AbstractDomain, int, int], object],
) -> dict[int, object]:
    return {
        bw: parse_fn(v, data.metadata.domain, data.metadata.arity, bw)  # type: ignore
        for bw, v in data.enumdata.groupby("bw")
    }


def enumdata_to_run_inputs(data: EnumData) -> RunInputMap:
    return _enumdata_to_inputs(data, parse_enum_df)  # type: ignore


def enumdata_to_eval_inputs(data: EnumData) -> dict[int, ToEval]:
    return _enumdata_to_inputs(data, parse_eval_df)  # type: ignore
