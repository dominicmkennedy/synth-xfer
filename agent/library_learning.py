"""High-level library learning workflow orchestration.

This module intentionally keeps implementation details as TODOs.
"""

from dataclasses import dataclass
from pathlib import Path


@dataclass
class SynthesisTask:
    """Concrete synthesis task for one operator/program file."""

    op_file: str
    op_name: str


@dataclass
class SynthesisResult:
    """High-level synthesis output for one task."""

    task: SynthesisTask
    solution_text: str
    transformer_path: Path
    eval_summary: str | None = None


@dataclass
class LibraryState:
    """Current learned library state passed to synthesis prompts."""

    version: int
    functions_text: str


def load_initial_library(library_file: Path | None) -> LibraryState:
    """Load initial library text for round 0.

    TODO: Parse and structure a real library representation.
    """
    if library_file is None:
        return LibraryState(version=0, functions_text="TODO")
    return LibraryState(version=0, functions_text=library_file.read_text())


def synth_phase(
    tasks: list[SynthesisTask],
    library: LibraryState,
    run_single_task,
) -> list[SynthesisResult]:
    """Run synthesis agent over tasks using current library.

    TODO: Add batching, retries, scheduling, and richer telemetry.
    """
    results: list[SynthesisResult] = []
    for task in tasks:
        result = run_single_task(task, library)
        results.append(result)
    return results


def learn_phase(
    previous_library: LibraryState,
    synthesis_results: list[SynthesisResult],
) -> LibraryState:
    """Learn an improved library from solved tasks.

    TODO: Implement extraction/mining and quality gating.
    """
    _ = synthesis_results
    return LibraryState(
        version=previous_library.version + 1,
        functions_text=previous_library.functions_text,
    )


def run_library_learning_loop(
    tasks: list[SynthesisTask],
    num_rounds: int,
    initial_library: LibraryState,
    run_single_task,
) -> tuple[LibraryState, list[SynthesisResult]]:
    """Top-level loop: synthesize tasks, then improve library.

    `num_rounds=0` means one synthesis-only pass with no library update.

    TODO: Add train/eval split, regression checks, and promotion logic.
    """
    library = initial_library
    latest_results: list[SynthesisResult] = []

    # Round 0 is synthesis-only (single-shot equivalent).
    for round_idx in range(num_rounds + 1):
        latest_results = synth_phase(tasks, library, run_single_task)
        if round_idx < num_rounds:
            library = learn_phase(library, latest_results)

    return library, latest_results
