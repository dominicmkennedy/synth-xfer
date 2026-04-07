from argparse import (
    ArgumentDefaultsHelpFormatter,
    ArgumentParser,
    BooleanOptionalAction,
    Namespace,
)
from pathlib import Path
from time import perf_counter

from synth_xfer._util.domain import AbstractDomain
from synth_xfer._util.dsl_operators import DslOpSet, load_dsl_ops
from synth_xfer._util.eval import EvalInputMap, ToEval, enum, eval_transfer_func
from synth_xfer._util.eval_result import EvalResult
from synth_xfer._util.jit import Jit
from synth_xfer._util.log import get_logger, write_log_file
from synth_xfer._util.lower import LowerToLLVM
from synth_xfer._util.mcmc_sampler import setup_mcmc
from synth_xfer._util.one_iter import synthesize_one_iteration
from synth_xfer._util.parse_mlir import HelperFuncs, get_helper_funcs, top_as_xfer
from synth_xfer._util.random import Random, Sampler
from synth_xfer._util.solution_set import EvalFn, SolutionSet
from synth_xfer._util.synth_context import SynthesizerContext
from synth_xfer._util.xfer_func import XferFunc
from synth_xfer.cli.args import int_list, int_triple, int_tuple, make_sampler_parser


def _eval_helper(
    to_eval: dict[int, ToEval], bws: list[int], helper_funcs: HelperFuncs
) -> EvalFn:
    def helper(
        xfer: list[XferFunc],
        base: list[XferFunc],
    ) -> list[EvalResult]:
        lowerer = LowerToLLVM(bws)
        lowerer.add_fn(helper_funcs.get_top_func)

        if not xfer:
            ret_top_func = XferFunc(top_as_xfer(helper_funcs.transfer_func))
            ret_top_func.set_name("ret_top")
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

            input: EvalInputMap = {
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
    seed: int | None,
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

    random = Random(seed)
    seed = random.randint(0, 2**32 - 1) if seed is None else seed

    helper_funcs = get_helper_funcs(transformer_file, domain)
    all_bws = lbw + [x[0] for x in mbw] + [x[0] for x in hbw]

    context = _setup_context(random, False, dsl_ops)
    context_weighted = _setup_context(random, False, dsl_ops)
    context_cond = _setup_context(random, True, dsl_ops)

    start_time = perf_counter()
    to_eval = enum(lbw, mbw, hbw, seed, helper_funcs, sampler)
    run_time = perf_counter() - start_time
    logger.perf(f"Enum engine took {run_time:.4f}s")

    eval_fn = _eval_helper(to_eval, all_bws, helper_funcs)
    solution_set = SolutionSet([], optimize=optimize)

    start_time = perf_counter()
    init_cmp_res = solution_set.eval_improve([], eval_fn)[0]
    run_time = perf_counter() - start_time
    logger.perf(f"Init Eval took {run_time:.4f}s")

    init_exact = init_cmp_res.get_exact_prop() * 100
    s = f"Top Solution | Exact {init_exact:.4f}% | Dist {init_cmp_res.dist:.4f} |"
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

        if weighted_dsl:
            context_weighted.weighted = True
            solution_set.learn_weights(context_weighted, eval_fn)

        logger.info(f"Per-BW Results: \n{lbw_mbw_log}\n{hbw_log}\n")
        logger.info(
            f"Iteration {ith_iter}  | Exact {final_exact:.4f}% | Dist {final_cmp_res.dist:.4f} | {solution_set.solutions_size} solutions | {iter_time:.4f}s |"
        )
        print(
            f"Iteration {ith_iter}  | Exact {final_exact:.4f}% | Dist {final_cmp_res.dist:.4f} | {solution_set.solutions_size} solutions | {iter_time:.4f}s |"
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


def _build_arg_parser() -> Namespace:
    p = ArgumentParser(prog="sxf", formatter_class=ArgumentDefaultsHelpFormatter)

    p.add_argument("--op", type=Path, help="path to op or pattern")
    p.add_argument(
        "-d",
        "--domain",
        type=str,
        choices=[str(x) for x in AbstractDomain],
        help="Abstract Domain to evaluate",
    )
    p.add_argument(
        "--benchmark",
        type=Path,
        help="YAML config specifying benchmark inputs and per-arity settings",
    )
    p.add_argument(
        "--dsl-ops",
        type=Path,
        help="Path to DSL op-set JSON (e.g., dsl/ops_set_0.json)",
    )
    p.add_argument("-o", "--output", type=Path, help="Output dir")
    make_sampler_parser(p)
    p.add_argument(
        "--optimize",
        action=BooleanOptionalAction,
        default=False,
        help="Run e-graph-based rewrite optimizer on synthesized candidates",
    )
    p.add_argument("--seed", type=int, help="seed for synthesis")
    p.add_argument(
        "--program-length",
        type=int,
        help="length of one single synthed transformer",
        default=28,
    )
    p.add_argument(
        "--num-steps",
        type=int,
        help="number of mutation steps in one iteration",
        default=1500,
    )
    p.add_argument(
        "--num-mcmc",
        type=int,
        help="number of mcmc processes that run in parallel",
        default=100,
    )
    p.add_argument(
        "--inv-temp",
        type=int,
        help="Inverse temperature for MCMC. The larger the value is, the lower the probability of accepting a program with a higher cost.",
        default=200,
    )
    p.add_argument(
        "--vbw",
        type=int_list,
        default=list(range(4, 65)),
        help="bws to verify at",
    )
    p.add_argument(
        "--lbw",
        nargs="*",
        type=int,
        default=[4],
        help="Low-bitwidths to evaluate exhaustively",
    )
    p.add_argument(
        "--mbw",
        nargs="*",
        type=int_tuple,
        default=[],
        help="Mid-bitwidths to sample abstract values with, but enumerate the concretizations of each of them exhaustively",
    )
    p.add_argument(
        "--hbw",
        nargs="*",
        type=int_triple,
        default=[],
        help="High-bitwidths to sample abstract values with, and sample the concretizations of each of them",
    )
    p.add_argument(
        "--num-iters",
        type=int,
        help="number of iterations for the synthesizer",
        default=10,
    )
    p.add_argument(
        "--no-weighted-dsl",
        dest="weighted_dsl",
        action="store_false",
        help="Disable learning weights for each DSL operation from previous for future iterations",
    )
    p.set_defaults(weighted_dsl=True)
    p.add_argument(
        "--condition-length", type=int, help="length of synthd abduction", default=10
    )
    p.add_argument(
        "--num-abd-procs",
        type=int,
        help="number of mcmc processes used for abduction. Must be less than num_mcmc",
        default=30,
    )
    p.add_argument(
        "--num-unsound-candidates",
        type=int,
        help="number of unsound candidates considered for abduction",
        default=15,
    )
    p.add_argument(
        "--debug",
        action="store_true",
        default=False,
        help="write debug.log to the output directory (default: off)",
    )

    return p.parse_args()


def _validate_args(args: Namespace) -> None:
    has_op = args.op is not None
    has_benchmark = args.benchmark is not None

    if has_op == has_benchmark:
        raise ValueError("Specify exactly one of --op or --benchmark")

    if has_op and args.domain is None:
        raise ValueError("--domain is required when using --op")

    if has_benchmark:
        invalid_flags: list[str] = []
        if args.domain is not None:
            invalid_flags.append("--domain")
        if args.lbw != [4]:
            invalid_flags.append("--lbw")
        if args.mbw != []:
            invalid_flags.append("--mbw")
        if args.hbw != []:
            invalid_flags.append("--hbw")
        if invalid_flags:
            raise ValueError(
                f"{', '.join(invalid_flags)} are only valid with --op, not --benchmark"
            )


def main() -> None:
    from synth_xfer._util.benchmark import run_benchmark, run_single_synth

    args = _build_arg_parser()
    _validate_args(args)

    if args.op is not None:
        run_single_synth(args)
    else:
        run_benchmark(args)


if __name__ == "__main__":
    main()
