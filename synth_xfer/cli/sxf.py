from pathlib import Path
from time import perf_counter
from typing import TYPE_CHECKING

from synth_xfer._util.cond_func import FunctionWithCondition
from synth_xfer._util.domain import AbstractDomain
from synth_xfer._util.dsl_operators import DslOpSet, load_dsl_ops
from synth_xfer._util.eval import eval_transfer_func, setup_eval
from synth_xfer._util.eval_result import EvalResult
from synth_xfer._util.jit import Jit
from synth_xfer._util.log import get_logger, init_logging, write_log_file
from synth_xfer._util.lower import LowerToLLVM
from synth_xfer._util.mcmc_sampler import setup_mcmc
from synth_xfer._util.one_iter import synthesize_one_iteration
from synth_xfer._util.parse_mlir import HelperFuncs, get_helper_funcs, top_as_xfer
from synth_xfer._util.random import Random, Sampler
from synth_xfer._util.solution_set import EvalFn, UnsizedSolutionSet
from synth_xfer._util.synth_context import SynthesizerContext
from synth_xfer.cli.args import build_parser, get_sampler

if TYPE_CHECKING:
    from synth_xfer._eval_engine import ToEval


def _eval_helper(
    to_eval: dict[int, "ToEval"], bws: list[int], helper_funcs: HelperFuncs
) -> EvalFn:
    def helper(
        xfer: list[FunctionWithCondition],
        base: list[FunctionWithCondition],
    ) -> list[EvalResult]:
        lowerer = LowerToLLVM(bws)
        lowerer.add_fn(helper_funcs.get_top_func)

        if not xfer:
            ret_top_func = FunctionWithCondition(top_as_xfer(helper_funcs.transfer_func))
            ret_top_func.set_func_name("ret_top")
            xfer = [ret_top_func]

        xfer_names = [fc.lower(lowerer.add_fn) for fc in xfer]
        base_names = [fc.lower(lowerer.add_fn) for fc in base]

        xfer_names = {bw: [d[bw] for d in xfer_names] for bw in bws}
        base_names = {bw: [d[bw] for d in base_names] for bw in bws}

        with Jit() as jit:
            jit.add_mod(lowerer)
            xfer_fns = {
                bw: [jit.get_fn_ptr(x) for x in xfer_names[bw]] for bw in xfer_names
            }
            base_fns = {
                bw: [jit.get_fn_ptr(x) for x in base_names[bw]] for bw in base_names
            }

            input = {
                bw: (to_eval[bw], xfer_fns.get(bw, []), base_fns.get(bw, []))
                for bw in to_eval
            }

            results = eval_transfer_func(input)

        return results

    return helper


def _setup_context(
    r: Random, use_full_i1_ops: bool, dsl_ops: DslOpSet | None
) -> SynthesizerContext:
    c = SynthesizerContext(r, dsl_ops=dsl_ops)
    c.set_cmp_flags([0, 6, 7])
    if not use_full_i1_ops and dsl_ops is None:
        c.use_basic_i1_ops()
    return c


def run(
    domain: AbstractDomain,
    num_mcmc: int,
    num_steps: int,
    program_length: int,
    inv_temp: int,
    vbw: list[int],
    lbw: list[int],
    mbw: list[tuple[int, int]],
    hbw: list[tuple[int, int, int]],
    num_iters: int,
    condition_length: int,
    num_abd_procs: int,
    random_seed: int | None,
    random_number_file: str | None,
    transformer_file: Path,
    dsl_ops_path: Path | None,
    weighted_dsl: bool,
    num_unsound_candidates: int,
    optimize: bool,
    sampler: Sampler,
) -> EvalResult:
    logger = get_logger()
    dsl_ops: DslOpSet | None = load_dsl_ops(dsl_ops_path) if dsl_ops_path else None

    EvalResult.init_bw_settings(
        set(lbw), set([t[0] for t in mbw]), set([t[0] for t in hbw])
    )

    logger.debug("Round_ID\tSound%\tUExact%\tDisReduce\tCost")

    random = Random(random_seed)
    random_seed = random.randint(0, 1_000_000) if random_seed is None else random_seed
    if random_number_file is not None:
        random.read_from_file(random_number_file)

    helper_funcs = get_helper_funcs(transformer_file, domain)
    all_bws = lbw + [x[0] for x in mbw] + [x[0] for x in hbw]

    context = _setup_context(random, False, dsl_ops)
    context_weighted = _setup_context(random, False, dsl_ops)
    context_cond = _setup_context(random, True, dsl_ops)

    start_time = perf_counter()
    to_eval = setup_eval(lbw, mbw, hbw, random_seed, helper_funcs, sampler)
    run_time = perf_counter() - start_time
    logger.perf(f"Enum engine took {run_time:.4f}s")

    eval_fn = _eval_helper(to_eval, all_bws, helper_funcs)
    solution_set = UnsizedSolutionSet([], optimize=optimize)

    start_time = perf_counter()
    init_cmp_res = solution_set.eval_improve([], eval_fn)[0]
    run_time = perf_counter() - start_time
    logger.perf(f"Init Eval took {run_time:.4f}s")

    init_exact = init_cmp_res.get_exact_prop() * 100
    s = f"Top Solution | Exact {init_exact:.4f}% |"
    logger.info(s)
    print(s)

    current_prog_len = program_length
    current_num_steps = num_steps
    current_num_abd_procs = num_abd_procs
    for ith_iter in range(num_iters):
        iter_start = perf_counter()
        # gradually increase the program length
        current_prog_len += (program_length - current_prog_len) // (num_iters - ith_iter)
        current_num_steps += (num_steps - current_num_steps) // (num_iters - ith_iter)
        current_num_abd_procs += (num_abd_procs - current_num_abd_procs) // (
            num_iters - ith_iter
        )

        if weighted_dsl:
            assert isinstance(solution_set, UnsizedSolutionSet)
            context_weighted.weighted = True
            solution_set.learn_weights(context_weighted, eval_fn)

        mcmc_samplers, prec_set, ranges = setup_mcmc(
            helper_funcs.transfer_func,
            solution_set.precise_set,
            current_num_abd_procs,
            num_mcmc,
            context,
            context_weighted,
            context_cond,
            current_prog_len,
            current_num_steps,
            condition_length,
        )

        solution_set = synthesize_one_iteration(
            ith_iter,
            random,
            solution_set,
            helper_funcs,
            eval_fn,
            inv_temp,
            num_unsound_candidates,
            ranges,
            mcmc_samplers,
            prec_set,
            lbw,
            vbw,
        )

        write_log_file(
            f"iter{ith_iter}.mlir", "\n".join(map(str, solution_set.solutions))
        )

        final_cmp_res = solution_set.eval_improve([], eval_fn)[0]
        lbw_mbw_log = "\n".join(
            f"bw: {res.bitwidth}, dist: {res.dist:.2f}, exact%: {res.get_exact_prop() * 100:.4f}"
            for res in final_cmp_res.get_low_med_res()
        )
        hbw_log = "\n".join(
            f"bw: {res.bitwidth}, dist: {res.dist:.2f}"
            for res in final_cmp_res.get_high_res()
        )

        iter_time = perf_counter() - iter_start
        final_exact = final_cmp_res.get_exact_prop() * 100
        print(
            f"Iteration {ith_iter}  | Exact {final_exact:.4f}% | {solution_set.solutions_size} solutions | {iter_time:.4f}s |"
        )

        logger.info(
            f"Iter {ith_iter} Finished. Result of Current Solution: \n{lbw_mbw_log}\n{hbw_log}\n"
        )

        if solution_set.is_perfect:
            print("Found a perfect solution")
            break

    # Eval last solution:
    if not solution_set.has_solution():
        raise Exception("Found no solutions")
    solution_module = solution_set.generate_solution_mlir()
    write_log_file("solution.mlir", solution_module)

    lowerer = LowerToLLVM(all_bws)
    lowerer.add_fn(helper_funcs.meet_func)
    lowerer.add_fn(helper_funcs.get_top_func)
    lowerer.add_mod(solution_module, ["solution"])

    with Jit() as jit:
        jit.add_mod(lowerer)
        sol_ptrs = {bw: jit.get_fn_ptr(f"solution_{bw}_shim") for bw in all_bws}
        sol_to_eval = {bw: (to_eval[bw], [sol_ptrs[bw]], []) for bw in all_bws}
        solution_result = eval_transfer_func(sol_to_eval)[0]

    solution_exact = solution_result.get_exact_prop() * 100
    print(
        f"Final Soln   | Exact {solution_exact:.4f}% | {solution_set.solutions_size} solutions |"
    )

    return solution_result


def main() -> None:
    args = build_parser("synth_xfer")

    domain = AbstractDomain[args.domain]
    op_path = Path(args.transfer_function)

    if args.output is None:
        outputs_folder = Path("outputs", f"{domain}_{op_path.stem}")
    else:
        outputs_folder = Path(args.output)

    if not outputs_folder.is_dir():
        outputs_folder.mkdir(parents=True)

    sampler = get_sampler(args)

    logger = init_logging(outputs_folder, not args.quiet)
    max_len = max(len(k) for k in vars(args))
    [logger.config(f"{k:<{max_len}} | {v}") for k, v in vars(args).items()]

    run(
        domain=domain,
        num_mcmc=args.num_mcmc,
        num_steps=args.num_steps,
        program_length=args.program_length,
        inv_temp=args.inv_temp,
        vbw=args.vbw,
        lbw=args.lbw,
        mbw=args.mbw,
        hbw=args.hbw,
        num_iters=args.num_iters,
        condition_length=args.condition_length,
        num_abd_procs=args.num_abd_procs,
        random_seed=args.random_seed,
        random_number_file=args.random_file,
        transformer_file=op_path,
        dsl_ops_path=args.dsl_ops,
        weighted_dsl=args.weighted_dsl,
        num_unsound_candidates=args.num_unsound_candidates,
        optimize=args.optimize,
        sampler=sampler,
    )
