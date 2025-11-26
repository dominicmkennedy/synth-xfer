from __future__ import annotations

from abc import ABC, abstractmethod
import io
from typing import Callable

from xdsl.dialects.builtin import ModuleOp
from xdsl.dialects.func import CallOp, FuncOp, ReturnOp

from synth_xfer._util.cond_func import FunctionWithCondition
from synth_xfer._util.dce import dce
from synth_xfer._util.eval_result import EvalResult
from synth_xfer._util.log import get_logger, write_log_file
from synth_xfer._util.parse_mlir import HelperFuncs
from synth_xfer._util.synth_context import SynthesizerContext
from synth_xfer.cli.verify import verify_function


def _rename_functions(lst: list[FunctionWithCondition], prefix: str) -> list[str]:
    func_names: list[str] = []
    for i, func in enumerate(lst):
        func_names.append(prefix + str(i))
        func.set_func_name(func_names[-1])
    return func_names


class SolutionSet(ABC):
    "This class is an abstract class for maintaining solutions. It supports to generate the meet of solutions"

    solutions_size: int
    solutions: list[FunctionWithCondition]
    precise_set: list[FuncOp]
    is_perfect: bool

    """
    list of name of transfer functions
    list of transfer functions
    list of name of base functions
    list of base functions
    """
    eval_func: Callable[
        [list[FunctionWithCondition], list[FunctionWithCondition]], list[EvalResult]
    ]

    def __init__(
        self,
        initial_solutions: list[FunctionWithCondition],
        eval_func: Callable[
            [list[FunctionWithCondition], list[FunctionWithCondition]], list[EvalResult]
        ],
        is_perfect: bool = False,
    ):
        _rename_functions(initial_solutions, "partial_solution_")
        self.solutions = initial_solutions
        self.solutions_size = len(initial_solutions)
        self.eval_func = eval_func
        self.precise_set = []
        self.is_perfect = is_perfect

    def eval_improve(self, transfers: list[FunctionWithCondition]) -> list[EvalResult]:
        return self.eval_func(transfers, self.solutions)

    @abstractmethod
    def construct_new_solution_set(
        self,
        lbw: list[int],
        vbw: list[int],
        new_candidates_sp: list[FunctionWithCondition],
        new_candidates_p: list[FuncOp],
        new_candidates_c: list[FunctionWithCondition],
        # Parameters used by SMT verifier
        helper_funcs: HelperFuncs,
        num_unsound_candidates: int,
    ) -> SolutionSet: ...

    def has_solution(self) -> bool:
        return self.solutions_size != 0

    def generate_solution(self) -> tuple[FuncOp, list[FuncOp]]:
        assert self.has_solution()
        solutions = self.solutions
        result = FuncOp("solution", solutions[0].func.function_type)
        result_type = result.function_type.outputs.data
        part_result: list[CallOp] = []
        part_solution_funcs: list[FuncOp] = []
        for ith, func_with_cond in enumerate(solutions):
            cur_func_name = "partial_solution_" + str(ith)
            func_with_cond.set_func_name(cur_func_name)
            part_solution_funcs.append(func_with_cond.get_function())
            part_result.append(CallOp(cur_func_name, result.args, result_type))
        if len(part_result) == 1:
            result.body.block.add_ops(part_result + [ReturnOp(part_result[-1])])
        else:
            meet_result: list[CallOp] = [
                CallOp(
                    "meet",
                    [part_result[0], part_result[1]],
                    result_type,
                )
            ]
            for i in range(2, len(part_result)):
                meet_result.append(
                    CallOp(
                        "meet",
                        [meet_result[-1], part_result[i]],
                        result_type,
                    )
                )
            result.body.block.add_ops(
                part_result + meet_result + [ReturnOp(meet_result[-1])]
            )
        return result, part_solution_funcs

    def generate_solution_mlir(self) -> ModuleOp:
        final_solution, part_solutions = self.generate_solution()
        function_lst: list[FuncOp] = []
        for sol in self.solutions:
            func_body = dce(sol.func)
            function_lst.append(func_body)
            if sol.cond is not None:
                func_cond = dce(sol.cond)
                function_lst.append(func_cond)

        function_lst += part_solutions
        function_lst.append(final_solution)
        final_module = ModuleOp([])
        final_module.body.block.add_ops(function_lst)
        return final_module


class UnsizedSolutionSet(SolutionSet):
    "This class maintains a list of solutions without a specified size"

    def __init__(
        self,
        initial_solutions: list[FunctionWithCondition],
        eval_func_with_cond: Callable[
            [
                list[FunctionWithCondition],
                list[FunctionWithCondition],
            ],
            list[EvalResult],
        ],
        is_perfect: bool = False,
    ):
        super().__init__(initial_solutions, eval_func_with_cond, is_perfect)

    def handle_inconsistent_result(self, f: FunctionWithCondition):
        str_output = io.StringIO()

        print("module {", file=str_output)
        print(dce(f.func), file=str_output)
        if f.cond is not None:
            print(dce(f.cond), file=str_output)
        print(f.get_function(), file=str_output)
        print("}", file=str_output)

        write_log_file("error.mlir", str_output.getvalue())

        raise Exception("Inconsistent between eval engine and verifier")

    def construct_new_solution_set(
        self,
        lbw: list[int],
        vbw: list[int],
        new_candidates_sp: list[FunctionWithCondition],
        new_candidates_p: list[FuncOp],
        new_candidates_c: list[FunctionWithCondition],
        helper_funcs: HelperFuncs,
        num_unsound_candidates: int,
    ) -> SolutionSet:
        logger = get_logger()
        candidates = self.solutions + new_candidates_sp + new_candidates_c
        _rename_functions(candidates, "part_solution_")

        logger.info(f"Size of new candidates: {len(new_candidates_sp)}")
        logger.info(f"Size of new conditional candidates: {len(new_candidates_c)}")
        logger.info(f"Size of solutions: {len(candidates)}")
        logger.info("Reset solution set...")

        self.solutions = []
        num_cond_solutions = 0

        while len(candidates) > 0:
            result = self.eval_improve(candidates)
            if result[0].get_base_dist() == 0:  # current solution set is already perfect
                break
            cand, max_improve_res = max(
                zip(candidates, result), key=lambda x: x[1].get_potential_improve()
            )
            if max_improve_res.get_potential_improve() == 0:
                break

            body_number = cand.func.attributes["number"]
            cond_number = "None" if cand.cond is None else cand.cond.attributes["number"]

            if (cand in new_candidates_sp) or (cand in new_candidates_c):
                for bw in vbw:
                    is_sound, _ = verify_function(
                        bw, cand.get_function(), [cand.func, cand.cond], helper_funcs, 200
                    )
                    if is_sound is None:
                        logger.info(
                            f"Skip a function of which verification timed out at bw {bw}, body: {body_number}, cond: {cond_number}"
                        )
                        candidates.remove(cand)
                        continue
                    elif not is_sound:
                        logger.info(
                            f"Skip a unsound function at bw {bw}, body: {body_number}, cond: {cond_number}"
                        )
                        if bw in lbw:
                            self.handle_inconsistent_result(cand)
                        candidates.remove(cand)
                        continue

            if cand in new_candidates_sp:
                log_str = "Add a new transformer"
            elif cand in new_candidates_c:
                log_str = "Add a new transformer (cond)"
                num_cond_solutions += 1
            else:
                if cand.cond is None:
                    log_str = "Add a existing transformer"
                else:
                    log_str = "Add a existing transformer (cond)"
                    num_cond_solutions += 1
            from_weighted_dsl = "from_weighted_dsl" in cand.func.attributes
            logger.info(
                f"{log_str}, body: {body_number}, cond: {cond_number}. After adding, Exact: {max_improve_res.get_exact_prop() * 100:.2f}%, Dist: {max_improve_res.get_dist():.2f}, weighted?: {from_weighted_dsl}"
            )
            candidates.remove(cand)
            self.solutions.append(cand)

        logger.info(f"The number of solutions after reseting: {len(self.solutions)}")
        logger.info(f"The number of conditional solutions: {num_cond_solutions}")
        self.solutions_size = len(self.solutions)

        final_result = self.eval_improve([])[0]
        if final_result.get_unsolved_cases() == 0:
            self.is_perfect = True
            return self

        precise_candidates = self.precise_set + new_candidates_p
        precise_candidates_to_eval = [
            FunctionWithCondition(f.clone()) for f in precise_candidates
        ]
        _rename_functions(precise_candidates_to_eval, "precise_candidates_")
        result = self.eval_improve(precise_candidates_to_eval)

        sorted_pairs = sorted(
            zip(precise_candidates, result),
            reverse=True,
            key=lambda x: x[1].get_potential_improve(),
        )
        top_k = sorted_pairs[:num_unsound_candidates]
        logger.info(f"Top {num_unsound_candidates} Precise candidates:")
        self.precise_set = []
        for cand, res in top_k:
            body_number = cand.attributes["number"]
            logger.info(
                f"{body_number}\tunsolved_exact: {res.get_unsolved_exact_prop() * 100:.2f}%, sound: {res.get_sound_prop() * 100:.2f}%, dist_reduce: {res.base_dist:.2f} -> {res.sound_dist:.2f}"
            )
            self.precise_set.append(cand)

        return self

    def learn_weights(self, context: SynthesizerContext):
        "Set weights in context according to the frequencies of each DSL operation that appear in func in solution set"

        logger = get_logger()
        logger.info("Improvement by each individual function")
        learn_form_funcs: list[FuncOp] = []
        for i, sol in enumerate(self.solutions):
            cmp_results: list[EvalResult] = self.eval_func(
                [sol],
                self.solutions[:i] + self.solutions[i + 1 :],
            )
            res = cmp_results[0]
            to_learn = res.get_new_exact_prop() > 0.005
            body_number = sol.func.attributes["number"]
            cond_number = "None" if sol.cond is None else sol.cond.attributes["number"]
            logger.info(
                f"\tbody {body_number}, cond {cond_number} : #exact {res.get_exacts() - res.get_unsolved_exacts()} -> {res.get_exacts()}, dist_improve: {res.get_potential_improve():3f}%, cond?: {self.solutions[i].cond is not None}, learn?: {to_learn}"
            )
            if to_learn:
                learn_form_funcs.append(dce(sol.func))

        freq_of_learn_funcs = SynthesizerContext.count_op_frequency(learn_form_funcs)
        context.update_weights(freq_of_learn_funcs)

        logger.info("Current Weights:")
        for _, weights in context.op_weights.items():
            for key, value in weights.items():
                logger.info(f"\t{key}: {value}")
