from pathlib import Path

from xdsl.dialects.func import CallOp, FuncOp, ReturnOp

from agent.util import (
    EvalArgs,
    LibraryState,
    _format_eval_examples_for_agent,
    _get_xfer_name,
    _run_eval,
    format_result,
    merge_library_text,
    rename_xfer,
)
from synth_xfer._util.domain import AbstractDomain
from synth_xfer._util.eval_result import EvalResult
from synth_xfer._util.parse_mlir import get_fns, parse_mlir_func, parse_mlir_mod


class AgentSolutionSet:
    """Lightweight solution set for use by the agent, operating on MLIR strings."""

    solutions: list[str]
    library: LibraryState
    domain: AbstractDomain
    _base_result_cache: EvalResult | None

    def __init__(self, library: LibraryState, domain: AbstractDomain) -> None:
        self.solutions = []
        self.library = library
        self.domain = domain
        self._base_result_cache = None

    def eval_improve(
        self, new_sol: str, eval_args: EvalArgs, no_previous: bool = False
    ) -> tuple[str, EvalResult | None]:
        """Evaluate new_sol against existing base solutions.
        Returns:
            (summary, upd_result) where summary is the formatted comparison text.
        """
        try:
            upd_result = _run_eval(
                xfer=[new_sol],
                base=self.solutions,
                lib=[self.library.functions_text],
                eval_args=eval_args,
            )
            upd_res = format_result(upd_result) + _format_eval_examples_for_agent(
                upd_result, eval_args.domain
            )
            if no_previous:
                return upd_res, upd_result
            base_res = self.eval_base(eval_args)
            return f"Previous: {base_res}\n Updated: {upd_res}", upd_result
        except Exception as e:
            return f"error: {str(e)}", None

    def eval_base(self, eval_args: EvalArgs) -> str:
        """Evaluate existing solutions with top as the candidate. Returns summary string."""
        if self._base_result_cache is None:
            self._base_result_cache = _run_eval(
                xfer=[],
                base=self.solutions,
                lib=[self.library.functions_text],
                eval_args=eval_args,
            )
        return format_result(self._base_result_cache)

    def upd_solution(self, new_sol: str) -> None:
        old_name = _get_xfer_name(new_sol)
        new_name = f"{old_name}_{len(self.solutions)}"
        self.solutions += [rename_xfer(new_sol, new_name)]
        self._base_result_cache = None

    def build_final_solution(self) -> str:
        """Build one final module with library funcs, partial solutions, meet, and solution."""
        if not self.solutions:
            raise ValueError("Cannot build final solution: solution set is empty")

        partial_solutions: list[str] = []
        for i, solution in enumerate(self.solutions):
            partial_name = f"partial_solution_{i}"
            partial_solutions.append(rename_xfer(solution, partial_name))

        combined_module = ""
        if self.library.functions_text:
            combined_module = merge_library_text(
                combined_module, self.library.functions_text
            )
        for solution in partial_solutions:
            combined_module = merge_library_text(combined_module, solution)

        module = parse_mlir_mod(combined_module)
        fns = get_fns(module)

        if "meet" not in fns:
            meet_path = (
                Path(__file__).resolve().parent.parent
                / "mlir"
                / self.domain.name
                / "meet.mlir"
            )
            module.body.block.add_ops([parse_mlir_func(meet_path)])
            fns = get_fns(module)

        if "meet" not in fns:
            raise ValueError("Missing meet function in final combined module")

        if "partial_solution_0" not in fns:
            raise ValueError("Missing partial_solution_0 after parsing combined module")

        base_sig = fns["partial_solution_0"].function_type
        for i in range(1, len(partial_solutions)):
            name = f"partial_solution_{i}"
            if name not in fns:
                raise ValueError(f"Missing {name} after parsing combined module")
            if fns[name].function_type != base_sig:
                raise ValueError(
                    f"Mismatched signature for {name}; all partial solutions must share one function type"
                )

        result = FuncOp("solution", base_sig)
        result_type = result.function_type.outputs.data

        part_result: list[CallOp] = []
        for i in range(len(partial_solutions)):
            part_result.append(CallOp(f"partial_solution_{i}", result.args, result_type))

        if len(part_result) == 1:
            result.body.block.add_ops(part_result + [ReturnOp(part_result[-1])])
        else:
            meet_result: list[CallOp] = [
                CallOp("meet", [part_result[0], part_result[1]], result_type)
            ]
            for i in range(2, len(part_result)):
                meet_result.append(
                    CallOp("meet", [meet_result[-1], part_result[i]], result_type)
                )
            result.body.block.add_ops(
                part_result + meet_result + [ReturnOp(meet_result[-1])]
            )

        module.body.block.add_ops([result])
        return str(module)
