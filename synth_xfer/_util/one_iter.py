from time import perf_counter

from xdsl.dialects.builtin import StringAttr
from xdsl.dialects.func import FuncOp

from synth_xfer._util.cond_func import FunctionWithCondition
from synth_xfer._util.cost_model import decide
from synth_xfer._util.eval_result import EvalResult
from synth_xfer._util.log import get_logger
from synth_xfer._util.mcmc_sampler import MCMCSampler
from synth_xfer._util.parse_mlir import HelperFuncs
from synth_xfer._util.random import Random
from synth_xfer._util.solution_set import EvalFn, SolutionSet


def _build_eval_list(
    mcmc_proposals: list[FuncOp],
    sp: range,
    p: range,
    c: range,
    prec_func_after_distribute: list[FuncOp],
) -> list[FunctionWithCondition]:
    """
    build the parameters of eval_transfer_func
    input:
    mcmc_proposals =  [ ..mcmc_sp.. , ..mcmc_p.. , ..mcmc_c.. ]
    output:
    funcs          =  [ ..mcmc_sp.. , ..mcmc_p.. ,..prec_set..]
    conds          =  [  nothing    ,  nothing   , ..mcmc_c.. ]
    """
    lst: list[FunctionWithCondition] = []
    for i in sp:
        fwc = FunctionWithCondition(mcmc_proposals[i].clone())
        fwc.set_func_name(f"{mcmc_proposals[i].sym_name.data}{i}")
        lst.append(fwc)
    for i in p:
        fwc = FunctionWithCondition(mcmc_proposals[i].clone())
        fwc.set_func_name(f"{mcmc_proposals[i].sym_name.data}{i}")
        lst.append(fwc)
    for i in c:
        prec_func = prec_func_after_distribute[i - c.start].clone()
        fwc = FunctionWithCondition(prec_func, mcmc_proposals[i].clone())
        fwc.set_func_name(f"{prec_func.sym_name.data}_abd_{i}")
        lst.append(fwc)

    return lst


def synthesize_one_iteration(
    ith_iter: int,
    random: Random,
    solution_set: SolutionSet,
    helper_funcs: HelperFuncs,
    eval_func: EvalFn,
    inv_temp: int,
    num_unsound_candidates: int,
    ranges: tuple[range, range, range],
    mcmc_samplers: list[MCMCSampler],
    prec_set: list[FuncOp],
    lbw: list[int],
    vbw: list[int],
) -> SolutionSet:
    "Given ith_iter, performs num_steps mcmc sampling"

    iter_start_time = perf_counter()
    logger = get_logger()

    eval_total = 0.0
    sample_total = 0.0
    decide_total = 0.0

    sp_range, p_range, c_range = ranges
    num_mcmc = len(sp_range) + len(p_range) + len(c_range)
    program_length = mcmc_samplers[0].length
    num_steps = mcmc_samplers[0].total_steps
    transfers = [spl.get_current() for spl in mcmc_samplers]
    func_with_cond_lst = _build_eval_list(transfers, sp_range, p_range, c_range, prec_set)

    cmp_results = solution_set.eval_improve(func_with_cond_lst, eval_func)

    for i, cmp in enumerate(cmp_results):
        mcmc_samplers[i].current_cmp = cmp

    cost_data = [[spl.compute_current_cost()] for spl in mcmc_samplers]

    # These 3 lists store "good" transformers during the search
    sound_most_improve_tfs: list[tuple[FuncOp, EvalResult, int]] = []
    most_improve_tfs: list[tuple[FuncOp, EvalResult, int]] = []
    for i, spl in enumerate(mcmc_samplers):
        init_tf = spl.current.func.clone()
        init_tf.attributes["number"] = StringAttr(f"{ith_iter}_{0}_{i}")
        sound_most_improve_tfs.append((init_tf, spl.current_cmp, 0))
        most_improve_tfs.append((init_tf, spl.current_cmp, 0))

    # MCMC start
    logger.info(
        f"Iter {ith_iter}: Start {num_mcmc - len(c_range)} MCMC to sampling programs of length {program_length}."
        f"Start {len(c_range)} MCMC to sample abductions. Each one is run for {num_steps} steps..."
    )

    for rnd in range(num_steps):
        s = perf_counter()
        transfers = [spl.sample_next().get_current() for spl in mcmc_samplers]
        func_with_cond_lst = _build_eval_list(
            transfers, sp_range, p_range, c_range, prec_set
        )
        sample_total += perf_counter() - s

        s = perf_counter()
        cmp_results = solution_set.eval_improve(func_with_cond_lst, eval_func)
        eval_total += perf_counter() - s

        s = perf_counter()
        for i, (spl, res) in enumerate(zip(mcmc_samplers, cmp_results)):
            proposed_cost = spl.compute_cost(res)
            current_cost = spl.compute_current_cost()
            decision = decide(random.random(), inv_temp, current_cost, proposed_cost)
            if decision:
                spl.accept_proposed(res)
                cloned_func = spl.current.func.clone()
                cloned_func.attributes["number"] = StringAttr(f"{ith_iter}_{rnd}_{i}")
                tmp_tuple = (cloned_func, res, rnd)
                # Update sound_most_exact_tfs
                if (
                    res.is_sound()
                    and res.get_potential_improve()
                    > sound_most_improve_tfs[i][1].get_potential_improve()
                ):
                    sound_most_improve_tfs[i] = tmp_tuple
                # Update most_exact_tfs
                if (
                    res.get_unsolved_exacts()
                    > most_improve_tfs[i][1].get_unsolved_exacts()
                ):
                    most_improve_tfs[i] = tmp_tuple

            else:
                spl.reject_proposed()

        for i, spl in enumerate(mcmc_samplers):
            res_cost = spl.compute_current_cost()
            sound_prop = spl.current_cmp.get_sound_prop() * 100
            exact_prop = spl.current_cmp.get_unsolved_exact_prop() * 100
            base_dis = spl.current_cmp.get_base_dist()
            new_dis = spl.current_cmp.get_sound_dist()
            logger.debug(
                f"{ith_iter}_{rnd}_{i}\t{sound_prop:.2f}%\t{exact_prop:.2f}%\t{base_dis:.2f}->{new_dis:.2f}\t{res_cost:.3f}"
            )
            cost_data[i].append(res_cost)

        decide_total += perf_counter() - s

        # Print the current best result every K rounds
        if rnd % 250 == 100 or rnd == num_steps - 1:
            logger.debug("Sound transformers with most exact outputs:")
            for i in range(num_mcmc):
                res = sound_most_improve_tfs[i][1]
                if res.is_sound():
                    logger.debug(f"{i}_{sound_most_improve_tfs[i][2]}\n{res}")
            logger.debug("Transformers with most unsolved exact outputs:")
            for i in range(num_mcmc):
                logger.debug(f"{i}_{most_improve_tfs[i][2]}\n{most_improve_tfs[i][1]}")

    candidates_sp: list[FunctionWithCondition] = []
    candidates_p: list[FuncOp] = []
    candidates_c: list[FunctionWithCondition] = []
    for i in list(sp_range) + list(p_range):
        if (
            sound_most_improve_tfs[i][1].is_sound()
            and sound_most_improve_tfs[i][1].get_potential_improve() > 0
        ):
            candidates_sp.append(FunctionWithCondition(sound_most_improve_tfs[i][0]))
        if (
            not most_improve_tfs[i][1].is_sound()
            and most_improve_tfs[i][1].get_unsolved_exacts() > 0
        ):
            candidates_p.append(most_improve_tfs[i][0])
    for i in c_range:
        if (
            sound_most_improve_tfs[i][1].is_sound()
            and sound_most_improve_tfs[i][1].get_potential_improve() > 0
        ):
            candidates_c.append(
                FunctionWithCondition(
                    prec_set[i - len(sp_range) - len(p_range)],
                    sound_most_improve_tfs[i][0],
                )
            )

    verif_start_time = perf_counter()
    new_solution_set = solution_set.construct_new_solution_set(
        lbw,
        vbw,
        candidates_sp,
        candidates_p,
        candidates_c,
        helper_funcs,
        num_unsound_candidates,
        eval_func,
    )
    verif_time = perf_counter() - verif_start_time
    iter_time = perf_counter() - iter_start_time

    def perf_str(x: float) -> str:
        return f"{x:.4f}s | avg {x / num_steps:.4f}s | {100 * x / iter_time:.2f}%"

    logger.perf(f"Iter {ith_iter} took {iter_time:.4f}s")
    logger.perf("\tEval took     | " + perf_str(eval_total))
    logger.perf("\tSampling took | " + perf_str(sample_total))
    logger.perf("\tDeciding took | " + perf_str(decide_total))
    logger.perf("\tVerif took    | " + perf_str(verif_time))

    return new_solution_set
