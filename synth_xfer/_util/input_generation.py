from dataclasses import dataclass
from multiprocessing import Pool
import os
from pathlib import Path
from random import Random
from typing import cast

import pandas as pd

from synth_xfer._util.domain import AbstractDomain
from synth_xfer._util.max_precise import RowTask, process_row
from synth_xfer._util.pattern import PatternDag, _load_pattern
from synth_xfer._util.tsv import EnumData, EnumMetaData

_COMMUTATIVE_OPS = {
    "Add",
    "AddNsw",
    "AddNswNuw",
    "AddNuw",
    "And",
    "AvgCeilS",
    "AvgCeilU",
    "AvgFloorS",
    "AvgFloorU",
    "Mul",
    "MulNsw",
    "MulNswNuw",
    "MulNuw",
    "Or",
    "OrDisjoint",
    "Smax",
    "Smin",
    "Umax",
    "Umin",
    "Xor",
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
        self._op_tables_by_bw: dict[int, dict[str, pd.DataFrame]] = {}

    def _is_fully_free_node(self, node_idx: int) -> bool:
        return all(
            operand in self.dag.args for operand in self.dag.nodes[node_idx].operands
        )

    def _build_arg_providers(self) -> dict[str, list[Provider]]:
        providers = {arg: [] for arg in self.dag.args}

        for node_idx, node in enumerate(self.dag.nodes):
            positions_by_arg: dict[str, list[int]] = {}
            for operand_idx, operand in enumerate(node.operands):
                if operand in providers:
                    positions_by_arg.setdefault(operand, []).append(operand_idx)

            for arg, positions in positions_by_arg.items():
                if self._is_fully_free_node(node_idx):
                    operand_indices = tuple(positions)
                elif node.operation in _COMMUTATIVE_OPS:
                    operand_indices = tuple(range(len(node.operands)))
                else:
                    operand_indices = tuple(positions)
                providers[arg].append(
                    Provider(node_idx=node_idx, operand_indices=operand_indices)
                )

        for arg, arg_providers in providers.items():
            if not arg_providers:
                raise ValueError(f"Pattern arg '{arg}' is not used by any operation.")

        return providers

    def _load_op_table(self, op: str, bw: int) -> pd.DataFrame:
        path = self.data_dir / str(self.domain) / f"{op}.tsv"
        if not path.exists():
            raise FileNotFoundError(f"Missing data file '{path}'.")
        with path.open() as f:
            data = EnumData.read_tsv(f)
        frame = cast(pd.DataFrame, data.enumdata[data.enumdata["bw"] == bw].copy())
        if frame.empty:
            raise ValueError(f"No data for op '{op}' at bw={bw}.")
        if "count" not in frame.columns:
            raise ValueError(f"Data for op '{op}' is missing required column 'count'.")

        counts = pd.to_numeric(frame["count"], errors="raise")
        frame["count"] = counts.astype(float)  # type: ignore

        return frame

    def _load_op_tables(self, bw: int) -> dict[str, pd.DataFrame]:
        if bw not in self._op_tables_by_bw:
            ops = {
                self.dag.nodes[provider.node_idx].operation
                for arg_providers in self.providers.values()
                for provider in arg_providers
            }
            self._op_tables_by_bw[bw] = {
                op: self._load_op_table(op, bw) for op in sorted(ops)
            }
        return self._op_tables_by_bw[bw]

    def _sample_weighted_row(
        self, frame: pd.DataFrame, op: str
    ) -> tuple[pd.Series, float]:
        weights = cast(pd.Series, frame["count"]).pow(self.sampling_alpha)
        total_weight = float(weights.sum())
        if total_weight <= 0:
            raise ValueError(f"Sampling weights for op '{op}' sum to zero.")
        positions = list(range(len(frame.index)))
        chosen_pos = self.rng.choices(positions, weights=weights.tolist(), k=1)[0]
        row = cast(pd.Series, frame.iloc[chosen_pos])
        return row, float(weights.iloc[chosen_pos]) / total_weight

    def _sample_provider(
        self, arg: str, provider: Provider, op_tables: dict[str, pd.DataFrame]
    ) -> tuple[dict[str, str], float]:
        node = self.dag.nodes[provider.node_idx]
        row, row_prob = self._sample_weighted_row(
            op_tables[node.operation], node.operation
        )
        if self._is_fully_free_node(provider.node_idx):
            assignments: dict[str, str] = {}
            for operand_idx, operand in enumerate(node.operands):
                if operand in self.dag.args and operand not in assignments:
                    assignments[operand] = str(row[f"arg_{operand_idx}"])
            return assignments, row_prob

        chosen_operand_idx = provider.operand_indices[0]
        operand_prob = 1.0
        if len(provider.operand_indices) > 1:
            chosen_operand_idx = self.rng.choice(list(provider.operand_indices))
            operand_prob = 1.0 / len(provider.operand_indices)
        return {arg: str(row[f"arg_{chosen_operand_idx}"])}, row_prob * operand_prob

    def sample_row(
        self, bw: int, op_tables: dict[str, pd.DataFrame]
    ) -> tuple[tuple[object, ...], float]:
        assigned: dict[str, str] = {}
        proposal_prob = 1.0

        for arg in self.dag.args:
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

        values = tuple(assigned[arg] for arg in self.dag.args)
        return (bw, *values, "(bottom)"), proposal_prob**self.weight_beta

    def sample_rows(self, bw: int, samples: int) -> list[tuple[object, ...]]:
        op_tables = self._load_op_tables(bw)
        rows: list[tuple[object, ...]] = []
        for _ in range(samples):
            row, weight = self.sample_row(bw, op_tables)
            rows.append((*row, weight))
        return rows


def generate_pattern_inputs(
    path: Path,
    domain: AbstractDomain,
    mbw_specs: list[tuple[int, int]],
    hbw_specs: list[tuple[int, int]],
    data_dir: Path,
    rng: Random,
    sampling_alpha: float,
    weight_beta: float,
    timeout: int,
    max_failures: int,
) -> tuple[EnumData, dict[int, int]]:
    dag = _load_pattern(path)
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

    with Pool(processes=max_workers) as pool:
        for bw, samples in sorted(mbw_specs, key=lambda spec: spec[0]):
            rows_for_bw: list[tuple[object, ...]] = []
            seen_args: set[tuple[str, ...]] = set()
            failed_attempts_since_accept = 0
            timeout_counts_by_bw[bw] = 0
            while len(rows_for_bw) < samples:
                batch_rows: list[tuple[tuple[object, ...], tuple[str, ...], float]] = []
                tasks: list[RowTask] = []
                batch_size = min(max_workers, samples - len(rows_for_bw))
                while len(tasks) < batch_size:
                    row, weight = generator.sample_row(bw, generator._load_op_tables(bw))
                    arg_values = tuple(str(value) for value in row[1:-1])
                    if arg_values in seen_args:
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
                            op_path=path,
                            domain=domain,
                            bw=bw,
                            args_str=",".join(arg_values),
                            timeout=timeout,
                        )
                    )

                for result in pool.map(process_row, tasks):
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
            bw_rows.append((*row, weight))
            seen_args.add(key)
            failed_attempts_since_accept = 0
        hbw_rows.extend(bw_rows)
        hbw.append((bw, len(bw_rows), 0))

    metadata = EnumMetaData(
        domain=domain,
        op=f"pattern_{path.stem}",
        arity=len(dag.args),
        seed=None,
        lbw=[],
        mbw=mbw,
        hbw=hbw,
    )

    df = pd.DataFrame.from_records(
        mbw_rows + hbw_rows,
        columns=["bw"] + [f"arg_{i}" for i in range(len(dag.args))] + ["ideal", "weight"],
    )

    return EnumData(metadata, df), timeout_counts_by_bw
