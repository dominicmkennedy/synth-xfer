from dataclasses import dataclass
from multiprocessing import Pool
import os
from pathlib import Path
from random import Random
from typing import cast

import pandas as pd

from synth_xfer._util.domain import AbstractDomain
from synth_xfer._util.max_precise import (
    RowProcessor,
    RowTask,
    check_abs_op_constraint,
)
from synth_xfer._util.parse_mlir import HelperFuncs
from synth_xfer._util.pattern_dsl import ArgRef, PatternDag, PatternOp
from synth_xfer._util.smt_solver import SolverKind
from synth_xfer._util.tsv import EnumData, EnumMetaData

_COMMUTATIVE_OPS = {
    PatternOp.Add,
    PatternOp.AddNsw,
    PatternOp.AddNswNuw,
    PatternOp.AddNuw,
    PatternOp.And,
    PatternOp.Mul,
    PatternOp.MulNsw,
    PatternOp.MulNswNuw,
    PatternOp.MulNuw,
    PatternOp.Or,
    PatternOp.OrDisjoint,
    PatternOp.Smax,
    PatternOp.Smin,
    PatternOp.Umax,
    PatternOp.Umin,
    PatternOp.Xor,
    # SaddSat = "SaddSat"  # TODO add to dialect
    # UaddSat = "UaddSat"  # TODO add to dialect
    # SmulSat = "SmulSat"  # TODO add to dialect
    # UmulSat = "UmulSat"  # TODO add to dialect
}

_OP_FALLBACKS: dict[PatternOp, PatternOp] = {
    PatternOp.AddNsw: PatternOp.Add,
    PatternOp.AddNuw: PatternOp.Add,
    PatternOp.AddNswNuw: PatternOp.Add,
    PatternOp.AshrExact: PatternOp.Ashr,
    PatternOp.LshrExact: PatternOp.Lshr,
    PatternOp.MulNsw: PatternOp.Mul,
    PatternOp.MulNuw: PatternOp.Mul,
    PatternOp.MulNswNuw: PatternOp.Mul,
    PatternOp.OrDisjoint: PatternOp.Or,
    PatternOp.SdivExact: PatternOp.Sdiv,
    PatternOp.ShlNsw: PatternOp.Shl,
    PatternOp.ShlNuw: PatternOp.Shl,
    PatternOp.ShlNswNuw: PatternOp.Shl,
    PatternOp.SubNsw: PatternOp.Sub,
    PatternOp.SubNuw: PatternOp.Sub,
    PatternOp.SubNswNuw: PatternOp.Sub,
    PatternOp.UdivExact: PatternOp.Udiv,
    PatternOp.CountLZeroUndef: PatternOp.CountLZero,
    PatternOp.CountRZeroUndef: PatternOp.CountRZero,
    # PatternOp.AbsUndef: PatternOp.Abs, TODO add
}


@dataclass(frozen=True)
class Provider:
    node_idx: int
    operand_indices: tuple[int, ...]


class PatternInputGenerator:
    def __init__(
        self,
        dag: PatternDag,
        domain: AbstractDomain,
        data_dir: Path,
        rng: Random,
        sampling_alpha: float,
        weight_beta: float,
    ):
        self.dag = dag
        self.domain = domain
        self.data_dir = data_dir
        self.rng = rng
        self.sampling_alpha = sampling_alpha
        self.weight_beta = weight_beta
        self.providers = self._build_arg_providers()
        self._op_tables_by_bw: dict[int, dict[PatternOp, pd.DataFrame]] = {}
        self._warned_fallback_ops: set[tuple[PatternOp, PatternOp]] = set()

    def _is_fully_free_node(self, node_idx: int) -> bool:
        return all(
            isinstance(operand, ArgRef) for operand in self.dag.nodes[node_idx].operands
        )

    def _build_arg_providers(self) -> dict[ArgRef, list[Provider]]:
        providers = {ArgRef(i): [] for i in range(self.dag.num_args)}

        for node_idx, node in enumerate(self.dag.nodes):
            positions_by_arg: dict[ArgRef, list[int]] = {}
            for operand_idx, operand in enumerate(node.operands):
                if operand in providers:
                    positions_by_arg.setdefault(operand, []).append(operand_idx)

            for arg, positions in positions_by_arg.items():
                if self._is_fully_free_node(node_idx):
                    operand_indices = tuple(positions)
                elif node.op in _COMMUTATIVE_OPS:
                    operand_indices = tuple(range(len(node.operands)))
                else:
                    operand_indices = tuple(positions)
                providers[arg].append(
                    Provider(node_idx=node_idx, operand_indices=operand_indices)
                )

        for arg, arg_providers in providers.items():
            if not arg_providers:
                raise ValueError(
                    f"Pattern arg 'arg{arg.index}' is not used by any operation."
                )

        return providers

    def _load_op_table(self, op: PatternOp, bw: int) -> pd.DataFrame:
        path = self.data_dir / str(self.domain) / f"{op.value}.tsv"
        if not path.exists():
            fallback_op = _OP_FALLBACKS.get(op)
            if fallback_op is None:
                raise FileNotFoundError(
                    f"No {self.domain} input data for op '{op.value}'.\nExpected '{path}'."
                )
            fallback_path = self.data_dir / str(self.domain) / f"{fallback_op.value}.tsv"
            if not fallback_path.exists():
                raise FileNotFoundError(
                    f"No {self.domain} input data for op '{op.value}', "
                    f"and fallback op '{fallback_op.value}' also missing.\n"
                    f"Expected '{path}' or '{fallback_path}'."
                )
            warning_key = (op, fallback_op)
            if warning_key not in self._warned_fallback_ops:
                print(
                    f"WARNING: using {fallback_op.value} input data in place of {op.value}"
                )
                self._warned_fallback_ops.add(warning_key)
            path = fallback_path
        with path.open() as f:
            data = EnumData.read_tsv(f)
        frame = cast(pd.DataFrame, data.enumdata[data.enumdata["bw"] == bw].copy())
        if frame.empty:
            raise ValueError(f"No data for op '{op.value}' at bw={bw}.")
        if "count" not in frame.columns:
            raise ValueError(f"Data for op '{op}' is missing required column 'count'.")

        counts = pd.to_numeric(frame["count"], errors="raise")
        frame["count"] = counts.astype(float)  # type: ignore

        return frame

    def _load_op_tables(self, bw: int) -> dict[PatternOp, pd.DataFrame]:
        if bw not in self._op_tables_by_bw:
            ops = {
                self.dag.nodes[provider.node_idx].op
                for arg_providers in self.providers.values()
                for provider in arg_providers
            }
            self._op_tables_by_bw[bw] = {
                op: self._load_op_table(op, bw) for op in sorted(ops)
            }
        return self._op_tables_by_bw[bw]

    def _sample_weighted_row(
        self, frame: pd.DataFrame, op: PatternOp
    ) -> tuple[pd.Series, float]:
        weights = cast(pd.Series, frame["count"]).pow(self.sampling_alpha)
        total_weight = float(weights.sum())
        if total_weight <= 0:
            raise ValueError(f"Sampling weights for op '{op.value}' sum to zero.")
        positions = list(range(len(frame.index)))
        chosen_pos = self.rng.choices(positions, weights=weights.tolist(), k=1)[0]
        row = cast(pd.Series, frame.iloc[chosen_pos])
        return row, float(weights.iloc[chosen_pos]) / total_weight

    def _sample_provider(
        self, arg: ArgRef, provider: Provider, op_tables: dict[PatternOp, pd.DataFrame]
    ) -> tuple[dict[ArgRef, str], float]:
        node = self.dag.nodes[provider.node_idx]
        row, row_prob = self._sample_weighted_row(op_tables[node.op], node.op)
        if self._is_fully_free_node(provider.node_idx):
            assignments: dict[ArgRef, str] = {}
            for operand_idx, operand in enumerate(node.operands):
                if isinstance(operand, ArgRef) and operand not in assignments:
                    assignments[operand] = str(row[f"arg_{operand_idx}"])
            return assignments, row_prob

        chosen_operand_idx = provider.operand_indices[0]
        operand_prob = 1.0
        if len(provider.operand_indices) > 1:
            chosen_operand_idx = self.rng.choice(list(provider.operand_indices))
            operand_prob = 1.0 / len(provider.operand_indices)
        return {arg: str(row[f"arg_{chosen_operand_idx}"])}, row_prob * operand_prob

    def sample_row(
        self, bw: int, op_tables: dict[PatternOp, pd.DataFrame]
    ) -> tuple[tuple[object, ...], float]:
        assigned: dict[ArgRef, str] = {}
        proposal_prob = 1.0

        for i in range(self.dag.num_args):
            arg = ArgRef(i)
            if arg in assigned:
                continue

            providers = self.providers[arg]
            provider = self.rng.choice(providers)
            provider_prob = 1.0 / len(providers)
            sampled_values, sample_prob = self._sample_provider(arg, provider, op_tables)
            proposal_prob *= provider_prob * sample_prob

            for sampled_arg, value in sampled_values.items():
                if sampled_arg not in assigned:
                    assigned[sampled_arg] = value

        values = tuple(assigned[ArgRef(i)] for i in range(self.dag.num_args))
        return (bw, *values, "(bottom)"), proposal_prob**self.weight_beta

    def sample_row_with_ideal(
        self, bw: int, op_tables: dict[PatternOp, pd.DataFrame]
    ) -> tuple[tuple[object, ...], float]:
        if not self.dag.is_op():
            raise ValueError(
                "sample_row_with_ideal is only valid for single-operator patterns."
            )
        node = self.dag.nodes[0]
        frame = op_tables[node.op]
        if "ideal" not in frame.columns:
            raise ValueError(
                f"Data for op '{node.op.value}' is missing required column 'ideal'."
            )
        row, row_prob = self._sample_weighted_row(frame, node.op)
        assignments: dict[ArgRef, str] = {}
        for operand_idx, operand in enumerate(node.operands):
            if isinstance(operand, ArgRef) and operand not in assignments:
                assignments[operand] = str(row[f"arg_{operand_idx}"])
        values = tuple(assignments[ArgRef(i)] for i in range(self.dag.num_args))
        ideal = str(row["ideal"])
        return (bw, *values, ideal), row_prob**self.weight_beta


def _ideal_is_top(i: str, bw: int, domain: AbstractDomain) -> bool:
    if domain == AbstractDomain.KnownBits:
        return i == bw * "?"
    if domain == AbstractDomain.UConstRange:
        return i == f"[0, {2**bw - 1}]"
    if domain == AbstractDomain.SConstRange:
        return i == f"[{-(2 ** (bw - 1))}, {2 ** (bw - 1) - 1}]"

    raise NotImplementedError


def generate_pattern_inputs(
    dag: PatternDag,
    domain: AbstractDomain,
    mbw_specs: list[tuple[int, int]],
    hbw_specs: list[tuple[int, int]],
    data_dir: Path,
    rng: Random,
    sampling_alpha: float,
    weight_beta: float,
    timeout: int,
    max_failures: int,
    solver_kind: SolverKind,
    enforce_abs_op_constraint: bool = False,
) -> tuple[EnumData, dict[int, int]]:
    if enforce_abs_op_constraint:
        enforce_abs_op_constraint = (
            HelperFuncs(dag, domain).abs_op_constraint_func is not None
        )
    generator = PatternInputGenerator(
        dag=dag,
        domain=domain,
        data_dir=data_dir,
        rng=rng,
        sampling_alpha=sampling_alpha,
        weight_beta=weight_beta,
    )

    mbw_rows: list[tuple[object, ...]] = []
    hbw_rows: list[tuple[object, ...]] = []
    mbw: list[tuple[int, int]] = []
    hbw: list[tuple[int, int, int]] = []
    timeout_counts_by_bw: dict[int, int] = {}
    max_workers = os.cpu_count() or 1

    if dag.is_op():
        for bw, samples in sorted(mbw_specs, key=lambda spec: spec[0]):
            rows_for_bw: list[tuple[object, ...]] = []
            seen_args: set[tuple[str, ...]] = set()
            failed_attempts_since_accept = 0
            timeout_counts_by_bw[bw] = 0
            op_tables = generator._load_op_tables(bw)
            while len(rows_for_bw) < samples:
                row, weight = generator.sample_row_with_ideal(bw, op_tables)
                arg_values = tuple(str(value) for value in row[1:-1])
                ideal = str(row[-1])

                if arg_values in seen_args:
                    failed_attempts_since_accept += 1
                    if failed_attempts_since_accept >= max_failures:
                        raise ValueError(
                            f"Failed to add a new row for bw={bw} after {max_failures} "
                            "consecutive rejected attempts due to duplicates or timeouts."
                        )
                    continue

                if enforce_abs_op_constraint and not check_abs_op_constraint(
                    dag, domain, bw, arg_values, timeout, solver_kind
                ):
                    seen_args.add(arg_values)
                    failed_attempts_since_accept += 1
                    if failed_attempts_since_accept >= max_failures:
                        raise ValueError(
                            f"Failed to add a new row for bw={bw} after {max_failures} "
                            "consecutive rejected attempts due to duplicates or timeouts."
                        )
                    continue

                if _ideal_is_top(ideal, bw, domain):
                    seen_args.add(arg_values)
                    continue

                rows_for_bw.append((row[0], *arg_values, ideal, weight))
                seen_args.add(arg_values)
                failed_attempts_since_accept = 0

            mbw_rows.extend(rows_for_bw)
            mbw.append((bw, len(rows_for_bw)))
    else:
        with Pool(processes=max_workers) as pool:
            processor = RowProcessor(dag, domain, timeout, solver_kind)
            for bw, samples in sorted(mbw_specs, key=lambda spec: spec[0]):
                rows_for_bw: list[tuple[object, ...]] = []
                seen_args: set[tuple[str, ...]] = set()
                failed_attempts_since_accept = 0
                timeout_counts_by_bw[bw] = 0
                while len(rows_for_bw) < samples:
                    batch_rows: list[
                        tuple[tuple[object, ...], tuple[str, ...], float]
                    ] = []
                    tasks: list[RowTask] = []
                    batch_size = min(max_workers, samples - len(rows_for_bw))
                    while len(tasks) < batch_size:
                        row, weight = generator.sample_row(
                            bw, generator._load_op_tables(bw)
                        )
                        arg_values = tuple(str(value) for value in row[1:-1])
                        if arg_values in seen_args:
                            failed_attempts_since_accept += 1
                            if failed_attempts_since_accept >= max_failures:
                                raise ValueError(
                                    f"Failed to add a new row for bw={bw} after {max_failures} "
                                    "consecutive rejected attempts due to duplicates or timeouts."
                                )
                            continue

                        if enforce_abs_op_constraint and not check_abs_op_constraint(
                            dag, domain, bw, arg_values, timeout, solver_kind
                        ):
                            seen_args.add(arg_values)
                            failed_attempts_since_accept += 1
                            if failed_attempts_since_accept >= max_failures:
                                raise ValueError(
                                    f"Failed to add a new row for bw={bw} after {max_failures} "
                                    "consecutive rejected attempts due to duplicates or timeouts."
                                )
                            continue

                        batch_rows.append((row, arg_values, weight))
                        tasks.append(
                            RowTask(
                                index=len(tasks),
                                bw=bw,
                                args=arg_values,
                            )
                        )

                    for result in pool.map(processor, tasks):
                        row, arg_values, weight = batch_rows[result.index]
                        if result.timed_out:
                            timeout_counts_by_bw[bw] += 1
                            failed_attempts_since_accept += 1
                            if failed_attempts_since_accept >= max_failures:
                                raise ValueError(
                                    f"Failed to add a new row for bw={bw} after {max_failures} "
                                    "consecutive rejected attempts due to duplicates or timeouts."
                                )
                            continue

                        if arg_values in seen_args:
                            failed_attempts_since_accept += 1
                            if failed_attempts_since_accept >= max_failures:
                                raise ValueError(
                                    f"Failed to add a new row for bw={bw} after {max_failures} "
                                    "consecutive rejected attempts due to duplicates or timeouts."
                                )
                            continue

                        assert result.ideal is not None

                        if _ideal_is_top(result.ideal, bw, domain):
                            seen_args.add(arg_values)
                            continue

                        rows_for_bw.append((row[0], *arg_values, result.ideal, weight))
                        seen_args.add(arg_values)
                        failed_attempts_since_accept = 0
                        if len(rows_for_bw) >= samples:
                            break

                mbw_rows.extend(rows_for_bw)
                mbw.append((bw, len(rows_for_bw)))

    for bw, samples in sorted(hbw_specs, key=lambda spec: spec[0]):
        seen_args: set[tuple[str, ...]] = set()
        bw_rows: list[tuple[object, ...]] = []
        failed_attempts_since_accept = 0
        while len(bw_rows) < samples:
            row, weight = generator.sample_row(bw, generator._load_op_tables(bw))
            arg_values = row[1:-1]
            key = tuple(str(value) for value in arg_values)
            if key in seen_args:
                failed_attempts_since_accept += 1
                if failed_attempts_since_accept >= max_failures:
                    raise ValueError(
                        f"Failed to add a new row for bw={bw} after {max_failures} "
                        "consecutive rejected attempts due to duplicates or timeouts."
                    )
                continue

            if enforce_abs_op_constraint and not check_abs_op_constraint(
                dag, domain, bw, key, timeout, solver_kind
            ):
                seen_args.add(key)
                failed_attempts_since_accept += 1
                if failed_attempts_since_accept >= max_failures:
                    raise ValueError(
                        f"Failed to add a new row for bw={bw} after {max_failures} "
                        "consecutive rejected attempts due to duplicates or timeouts."
                    )
                continue

            bw_rows.append((*row, weight))
            seen_args.add(key)
            failed_attempts_since_accept = 0
        hbw_rows.extend(bw_rows)
        hbw.append((bw, len(bw_rows), 0))

    metadata = EnumMetaData(
        domain=domain,
        op=dag,
        arity=dag.num_args,
        seed=None,
        lbw=[],
        mbw=mbw,
        hbw=hbw,
    )

    df = pd.DataFrame.from_records(
        mbw_rows + hbw_rows,
        columns=["bw"] + [f"arg_{i}" for i in range(dag.num_args)] + ["ideal", "weight"],
    )

    return EnumData(metadata, df), timeout_counts_by_bw
