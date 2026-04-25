from __future__ import annotations

import io
from typing import Callable, TypeAlias

from xdsl.dialects.builtin import ModuleOp
from xdsl.dialects.func import CallOp, FuncOp, ReturnOp

from synth_xfer._util.dce import dce
from synth_xfer._util.eval_result import EvalResult
from synth_xfer._util.log import get_logger, write_log_file
from synth_xfer._util.parse_mlir import HelperFuncs
from synth_xfer._util.smt_solver import SolverKind
from synth_xfer._util.synth_context import SynthesizerContext
from synth_xfer._util.xfer_func import XferFunc
from synth_xfer.cli.verify import verify_function
from synth_xfer.egraph_rewriter.rewriter import rewrite_single_function


def _rename_functions(lst: list[XferFunc], prefix: str) -> list[str]:
    func_names: list[str] = []
    for i, func in enumerate(lst):
        func_names.append(prefix + str(i))
        func.set_name(func_names[-1])
    return func_names


EvalFn: TypeAlias = Callable[[list[XferFunc], list[XferFunc]], list[EvalResult]]


class SolutionSet:
    "Maintains solutions and supports generating the meet of solutions."

    solutions_size: int
    solutions: list[XferFunc]
    precise_set: list[FuncOp]
    is_perfect: bool

    """
    list of name of transfer functions
    list of transfer functions
    list of name of base functions
    list of base functions
    """
    optimize: bool

    def __init__(
        self,
        initial_solutions: list[XferFunc],
        is_perfect: bool = False,
        optimize: bool = True,
    ):
        _rename_functions(initial_solutions, "partial_solution_")
        self.solutions = initial_solutions
        self.solutions_size = len(initial_solutions)
        self.precise_set = []
        self.is_perfect = is_perfect
        self.optimize = optimize

    def eval_improve(
        self,
        transfers: list[XferFunc],
        eval_func: EvalFn,
    ) -> list[EvalResult]:
        return eval_func(transfers, self.solutions)

    def has_solution(self) -> bool:
        return self.solutions_size != 0

    def generate_solution(self) -> tuple[FuncOp, list[FuncOp]]:
        assert self.has_solution()
        solutions = self.solutions
        result = FuncOp("solution", solutions[0].body.function_type)
        result_type = result.function_type.outputs.data
        part_result: list[CallOp] = []
        part_solution_funcs: list[FuncOp] = []
        for ith, func_with_cond in enumerate(solutions):
            cur_func_name = "partial_solution_" + str(ith)
            func_with_cond.set_name(cur_func_name)
            part_solution_funcs.append(func_with_cond.build())
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
            func_body = dce(sol.body)
            function_lst.append(func_body)
            if sol.cond is not None:
                func_cond = dce(sol.cond)
                function_lst.append(func_cond)

        function_lst += part_solutions
        function_lst.append(final_solution)
        final_module = ModuleOp([])
        final_module.body.block.add_ops(function_lst)
        return final_module

    def handle_inconsistent_result(self, f: XferFunc):
        str_output = io.StringIO()

        print("module {", file=str_output)
        print(dce(f.body), file=str_output)
        if f.cond is not None:
            print(dce(f.cond), file=str_output)
        print(f.build(), file=str_output)
        print("}", file=str_output)

        write_log_file("error.mlir", str_output.getvalue())

        raise Exception("Inconsistent between eval engine and verifier")

    def handle_unsound_rewrite(self, original: XferFunc, rewritten: XferFunc):
        str_output = io.StringIO()

        print("module {", file=str_output)
        print(original.body, file=str_output)
        if original.cond is not None:
            print(original.cond, file=str_output)
        # print(original.build(), file=str_output)
        print("// After rewrite:", file=str_output)
        print(rewritten.body, file=str_output)
        if rewritten.cond is not None:
            print(rewritten.cond, file=str_output)
        # print(rewritten.build(), file=str_output)
        print("}", file=str_output)

        write_log_file("error_rewrite.mlir", str_output.getvalue())

        raise Exception("Inconsistent Rewrite")

    def construct_new_solution_set(
        self,
        lbw: list[int],
        vbw: list[int],
        new_candidates_sp: list[XferFunc],
        new_candidates_p: list[FuncOp],
        new_candidates_c: list[XferFunc],
        helper_funcs: HelperFuncs,
        num_unsound_candidates: int,
        eval_func: EvalFn,
        solver_kind: SolverKind,
    ) -> SolutionSet:
        logger = get_logger()
        candidates = self.solutions + new_candidates_sp + new_candidates_c
        _rename_functions(candidates, "part_solution_")

        logger.info(
            f"Candidates: {len(new_candidates_sp)} new, {len(new_candidates_c)} new conditional,"
            f" {len(self.solutions)} existing  →  {len(candidates)} total"
        )
        logger.info("Resetting solution set...")

        self.solutions = []
        num_cond_solutions = 0

        while len(candidates) > 0:
            result = self.eval_improve(candidates, eval_func)
            if result[0].get_base_dist() == 0:  # current solution set is already perfect
                break
            cand, max_improve_res = max(
                zip(candidates, result), key=lambda x: x[1].get_potential_improve()
            )
            if max_improve_res.get_potential_improve() == 0:
                break

            body_number = cand.body.attributes["number"]
            cond_number = "None" if cand.cond is None else cand.cond.attributes["number"]

            def _verify_and_maybe_remove(
                candidate: XferFunc,
            ) -> XferFunc | None:
                """Return True if candidate was removed due to verification failure/timeouts."""

                def _rewrite(candidate: XferFunc) -> XferFunc:
                    if not self.optimize:
                        return candidate
                    rwt_func = rewrite_single_function(
                        dce(candidate.body), quiet=True, timeout=5
                    )
                    # Todo: support rewriting condition functions later
                    # rwt_cond = rewrite_single_function(candidate.cond) if candidate.cond is not None else None
                    rwt_cond = candidate.cond
                    rewritten = XferFunc(rwt_func, rwt_cond)
                    rewritten.set_name(candidate.name)
                    return rewritten

                def _verify_once(
                    bw: int,
                    original: XferFunc,
                    rewritten: XferFunc,
                ) -> bool:
                    is_sound, _ = verify_function(
                        bw,
                        original.build(),
                        [original.body, original.cond],
                        helper_funcs,
                        200,
                        solver_kind,
                    )
                    if is_sound is None:
                        logger.info(
                            f"\tVerification timed out at bw {bw} (body: {body_number}, cond: {cond_number}) — skipping"
                        )
                        return False
                    if not is_sound:
                        logger.info(
                            f"\tUnsound at bw {bw} (body: {body_number}, cond: {cond_number}) — skipping"
                        )
                        if bw in lbw:
                            self.handle_inconsistent_result(original)
                        return False
                    if self.optimize:
                        is_sound_rwt, _ = verify_function(
                            bw,
                            rewritten.build(),
                            [rewritten.body, rewritten.cond],
                            helper_funcs,
                            200,
                            solver_kind,
                        )
                        if is_sound != is_sound_rwt:
                            logger.info(
                                f"\tInconsistent rewrite at bw {bw}, body: {body_number}, cond: {cond_number} (original: {is_sound}, rewritten: {is_sound_rwt})"
                            )
                            self.handle_unsound_rewrite(original, rewritten)

                    return True

                if (candidate in new_candidates_sp) or (candidate in new_candidates_c):
                    rewritten = _rewrite(candidate)
                    for bw in vbw:
                        if not _verify_once(bw, candidate, rewritten):
                            candidates.remove(candidate)
                            return None
                    return rewritten
                return candidate

            def _log_str_and_cond(candidate: XferFunc) -> tuple[str, bool]:
                if candidate in new_candidates_sp:
                    return "new", False
                if candidate in new_candidates_c:
                    return "new (cond)", True
                if candidate.cond is None:
                    return "existing", False
                return "existing (cond)", True

            cand_to_be_added = _verify_and_maybe_remove(cand)
            if cand_to_be_added is None:
                continue

            log_str, is_cond = _log_str_and_cond(cand)
            if is_cond:
                num_cond_solutions += 1
            weighted_tag = (
                " [weighted]" if "from_weighted_dsl" in cand.body.attributes else ""
            )
            logger.info(
                f"\t+ {log_str} (body: {body_number}, cond: {cond_number})"
                f"  →  exact: {max_improve_res.get_exact_prop() * 100:.2f}%, dist: {max_improve_res.get_dist():.2f}{weighted_tag}"
            )
            candidates.remove(cand)
            self.solutions.append(cand_to_be_added)

        logger.info(
            f"Solutions after resetting: {len(self.solutions)} ({num_cond_solutions} conditional)"
        )
        self.solutions_size = len(self.solutions)

        final_result = self.eval_improve([], eval_func)[0]
        if final_result.get_unsolved_cases() == 0:
            self.is_perfect = True
            return self

        precise_candidates = self.precise_set + new_candidates_p
        precise_candidates_to_eval = [XferFunc(f.clone()) for f in precise_candidates]
        _rename_functions(precise_candidates_to_eval, "precise_candidates_")
        result = self.eval_improve(precise_candidates_to_eval, eval_func)

        sorted_pairs = sorted(
            zip(precise_candidates, result),
            reverse=True,
            key=lambda x: x[1].get_potential_improve(),
        )
        top_k = sorted_pairs[:num_unsound_candidates]
        logger.info(f"Top {num_unsound_candidates} unsound candidates:")
        self.precise_set = []
        for cand, res in top_k:
            body_number = cand.attributes["number"]
            logger.info(
                f"\t{body_number}  exact: {res.get_unsolved_exact_prop() * 100:.2f}%  sound: {res.get_sound_prop() * 100:.2f}%  dist: {res.base_dist:.2f} → {res.sound_dist:.2f}"
            )
            self.precise_set.append(cand)

        return self

    def learn_weights(
        self,
        context: SynthesizerContext,
        eval_func: EvalFn,
    ):
        "Set weights in context according to the frequencies of each DSL operation that appear in func in solution set"

        logger = get_logger()
        logger.info("Per-solution contribution:")
        learn_form_funcs: list[FuncOp] = []
        for i, sol in enumerate(self.solutions):
            cmp_results: list[EvalResult] = eval_func(
                [sol], self.solutions[:i] + self.solutions[i + 1 :]
            )
            res = cmp_results[0]
            to_learn = res.get_new_exact_prop() > 0.005
            body_number = sol.body.attributes["number"]
            cond_number = "None" if sol.cond is None else sol.cond.attributes["number"]
            cond_tag = " [cond]" if self.solutions[i].cond is not None else ""
            learn_tag = " [to_learn]" if to_learn else ""
            logger.info(
                f"\tbody {body_number}, cond {cond_number}{cond_tag}"
                f"  exact: {res.get_exacts() - res.get_unsolved_exacts()} → {res.get_exacts()}"
                f"  dist_improve: {res.get_potential_improve():.4f}%{learn_tag}"
            )
            if to_learn:
                learn_form_funcs.append(dce(sol.body))

        freq_of_learn_funcs = SynthesizerContext.count_op_frequency(learn_form_funcs)
        context.update_weights(freq_of_learn_funcs)

        for _, weights in context.op_weights.items():
            pairs = "  ".join(
                f"{k.__name__.removesuffix('Op')}:{v}"
                for k, v in sorted(weights.items(), key=lambda x: -x[1])
            )
            logger.info(f"Weights: {pairs}")
