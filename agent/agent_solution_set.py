from agent.util import (
    EvalArgs,
    LibraryState,
    _format_eval_examples_for_agent,
    _get_xfer_name,
    _run_eval,
    rename_xfer,
)
from synth_xfer._util.eval_result import EvalResult


class AgentSolutionSet:
    """Lightweight solution set for use by the agent, operating on MLIR strings."""

    solutions: list[str]
    library: LibraryState
    _base_result_cache: EvalResult | None

    def __init__(self, library: LibraryState) -> None:
        self.solutions = []
        self.library = library
        self._base_result_cache = None

    @staticmethod
    def _format_result(result: EvalResult) -> str:
        return (
            f"Sound %: {result.get_sound_prop() * 100:.2f}, "
            f"Exact %: {result.get_exact_prop() * 100:.2f}, "
            f"Dist: {result.sound_dist:.4f}"
        )

    def eval_improve(
        self, new_sol: str, eval_args: EvalArgs, no_previous: bool = False
    ) -> str:
        """Evaluate new_sol against existing base solutions. Returns summary string."""
        upd_result = _run_eval(
            xfer=[new_sol],
            base=self.solutions,
            lib=[self.library.functions_text],
            eval_args=eval_args,
        )
        upd_res = self._format_result(upd_result) + _format_eval_examples_for_agent(
            upd_result, eval_args.domain
        )
        if no_previous:
            return upd_res
        base_res = self.eval_base(eval_args)
        return f"Previous: {base_res}\n Updated: {upd_res}"

    def eval_base(self, eval_args: EvalArgs) -> str:
        """Evaluate existing solutions with top as the candidate. Returns summary string."""
        if self._base_result_cache is None:
            self._base_result_cache = _run_eval(
                xfer=[],
                base=self.solutions,
                lib=[self.library.functions_text],
                eval_args=eval_args,
            )
        return self._format_result(self._base_result_cache)

    def upd_solution(self, new_sol: str) -> None:
        old_name = _get_xfer_name(new_sol)
        new_name = f"{old_name}_{len(self.solutions)}"
        self.solutions += [rename_xfer(new_sol, new_name)]
        self._base_result_cache = None
