from pathlib import Path
from time import perf_counter
from typing import TYPE_CHECKING, Callable

from xdsl.context import Context
from xdsl.dialects.arith import Arith
from xdsl.dialects.builtin import Builtin, ModuleOp
from xdsl.dialects.func import CallOp, Func, FuncOp, ReturnOp
from xdsl.parser import Parser
from xdsl_smt.dialects.transfer import AbstractValueType, Transfer, TransIntegerType
from xdsl_smt.passes.transfer_inline import FunctionCallInline

from synth_xfer._util.cond_func import FunctionWithCondition
from synth_xfer._util.eval import AbstractDomain, eval_transfer_func, setup_eval
from synth_xfer._util.eval_result import EvalResult
from synth_xfer._util.helper_funcs import HelperFuncs
from synth_xfer._util.log import get_logger, init_logging, write_log_file
from synth_xfer._util.mcmc_sampler import setup_mcmc
from synth_xfer._util.one_iter import synthesize_one_iteration
from synth_xfer._util.random import Random
from synth_xfer._util.solution_set import UnsizedSolutionSet
from synth_xfer._util.synth_context import SynthesizerContext
from synth_xfer.cli.args import build_parser
from synth_xfer.jit import Jit
from synth_xfer.lower_to_llvm import LowerToLLVM

if TYPE_CHECKING:
    from synth_xfer._eval_engine import BW, ToEval


# TODO weird func
def _construct_top_func(transfer: FuncOp) -> FuncOp:
    func = FuncOp("top_transfer_function", transfer.function_type)
    block = func.body.block
    args = func.args

    call_top_op = CallOp("getTop", [args[0]], func.function_type.outputs.data)
    assert len(call_top_op.results) == 1
    top_res = call_top_op.results[0]
    return_op = ReturnOp(top_res)
    block.add_ops([call_top_op, return_op])
    return func


def _eval_helper(
    to_eval: "ToEval",
    bw: "BW",
    helper_funcs: HelperFuncs,
    jit: Jit,
) -> Callable[
    [list[FunctionWithCondition], list[FunctionWithCondition]],
    list[EvalResult],
]:
    def helper(
        transfer: list[FunctionWithCondition],
        base: list[FunctionWithCondition],
    ) -> list[EvalResult]:
        lowerer = LowerToLLVM(bw)
        lowerer.add_fn(helper_funcs.get_top_func)

        if not transfer:
            ret_top_func = FunctionWithCondition(
                _construct_top_func(helper_funcs.transfer_func)
            )
            ret_top_func.set_func_name("ret_top")
            transfer = [ret_top_func]

        [fc.lower(lowerer.add_fn) for fc in transfer]
        [fc.lower(lowerer.add_fn) for fc in base]

        jit.add_mod(str(lowerer))
        transfer_fn_ptrs = [jit.get_fn_ptr(x.func_name) for x in transfer]
        base_fn_ptrs = [jit.get_fn_ptr(x.func_name) for x in base]

        return eval_transfer_func(to_eval, transfer_fn_ptrs, base_fn_ptrs)

    return helper


def _get_helper_funcs(p: Path, d: AbstractDomain) -> HelperFuncs:
    ctx = Context()
    ctx.load_dialect(Arith)
    ctx.load_dialect(Builtin)
    ctx.load_dialect(Func)
    ctx.load_dialect(Transfer)

    with open(p, "r") as f:
        mod = Parser(ctx, f.read(), p.name).parse_op()
        assert isinstance(mod, ModuleOp)

    fns = {x.sym_name.data: x for x in mod.ops if isinstance(x, FuncOp)}
    FunctionCallInline(False, fns).apply(ctx, mod)

    assert "concrete_op" in fns
    crt_func = fns["concrete_op"]
    op_con_fn = fns.get("op_constraint", None)

    ty = AbstractValueType([TransIntegerType() for _ in range(d.vec_size)])
    # this is very slightly diff then the one in niceToMeetYou so if there's a bug, check there
    xfer_func = FuncOp.from_region("empty_transformer", [ty, ty], [ty])
    mod.body.block.add_op(xfer_func)

    # TODO this is a kinda bad hack
    def get_domain_fns(fp: str) -> FuncOp:
        dp = p.resolve().parent.parent.joinpath(str(d), fp)
        with open(dp, "r") as f:
            fn = Parser(ctx, f.read(), f.name).parse_op()
            assert isinstance(fn, FuncOp)

        return fn

    top = get_domain_fns("top.mlir")
    meet = get_domain_fns("meet.mlir")
    constraint = get_domain_fns("get_constraint.mlir")
    instance_constraint = get_domain_fns("get_instance_constraint.mlir")

    return HelperFuncs(
        crt_func=crt_func,
        instance_constraint_func=instance_constraint,
        domain_constraint_func=constraint,
        op_constraint_func=op_con_fn,
        get_top_func=top,
        transfer_func=xfer_func,
        meet_func=meet,
    )


def _setup_context(r: Random, use_full_i1_ops: bool) -> SynthesizerContext:
    c = SynthesizerContext(r)
    c.set_cmp_flags([0, 6, 7])
    if not use_full_i1_ops:
        c.use_basic_i1_ops()
    return c


def run(
    domain: AbstractDomain,
    num_programs: int,
    total_rounds: int,
    program_length: int,
    inv_temp: int,
    bw: "BW",
    samples: int | None,
    num_iters: int,
    condition_length: int,
    num_abd_procs: int,
    random_seed: int | None,
    random_number_file: str | None,
    transformer_file: Path,
    weighted_dsl: bool,
    num_unsound_candidates: int,
):
    logger = get_logger()
    jit = Jit()

    # TODO fix evalresult
    lbw, mbw = (set(), set({bw})) if samples else (set({bw}), set())
    EvalResult.init_bw_settings(lbw, mbw, set())

    logger.debug("Round_ID\tSound%\tUExact%\tDisReduce\tCost")

    random = Random(random_seed)
    random_seed = random.randint(0, 1_000_000) if random_seed is None else random_seed
    if random_number_file is not None:
        random.read_from_file(random_number_file)

    helper_funcs = _get_helper_funcs(transformer_file, domain)

    start_time = perf_counter()
    to_eval = setup_eval(bw, samples, random_seed, helper_funcs, domain, jit)
    run_time = perf_counter() - start_time
    logger.perf(f"Enum engine took {run_time:.4f}s")

    solution_eval_func = _eval_helper(to_eval, bw, helper_funcs, jit)
    solution_set = UnsizedSolutionSet([], solution_eval_func)

    context = _setup_context(random, False)
    context_weighted = _setup_context(random, False)
    context_cond = _setup_context(random, True)

    start_time = perf_counter()
    init_cmp_res = solution_set.eval_improve([])[0]
    run_time = perf_counter() - start_time
    logger.perf(f"Init Eval took {run_time:.4f}s")

    init_exact = init_cmp_res.get_exact_prop() * 100
    s = f"Top Solution | Exact {init_exact:.4f}% |"
    logger.info(s)
    print(s)

    current_prog_len = program_length
    current_total_rounds = total_rounds
    current_num_abd_procs = num_abd_procs
    for ith_iter in range(num_iters):
        iter_start = perf_counter()
        # gradually increase the program length
        current_prog_len += (program_length - current_prog_len) // (num_iters - ith_iter)
        current_total_rounds += (total_rounds - current_total_rounds) // (
            num_iters - ith_iter
        )
        current_num_abd_procs += (num_abd_procs - current_num_abd_procs) // (
            num_iters - ith_iter
        )

        if weighted_dsl:
            assert isinstance(solution_set, UnsizedSolutionSet)
            context_weighted.weighted = True
            solution_set.learn_weights(context_weighted)

        mcmc_samplers, prec_set, ranges = setup_mcmc(
            helper_funcs.transfer_func,
            solution_set.precise_set,
            current_num_abd_procs,
            num_programs,
            context,
            context_weighted,
            context_cond,
            current_prog_len,
            current_total_rounds,
            condition_length,
        )

        solution_set = synthesize_one_iteration(
            ith_iter,
            random,
            solution_set,
            helper_funcs,
            inv_temp,
            num_unsound_candidates,
            ranges,
            mcmc_samplers,
            prec_set,
            bw,
        )

        write_log_file(
            f"iter{ith_iter}.mlir", "\n".join(map(str, solution_set.solutions))
        )

        final_cmp_res = solution_set.eval_improve([])[0]
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
            f"""Iter {ith_iter} Finished. Result of Current Solution: \n{lbw_mbw_log}\n{hbw_log}\n"""
        )

        if solution_set.is_perfect:
            print("Found a perfect solution")
            break

    # Eval last solution:
    if not solution_set.has_solution():
        raise Exception("Found no solutions")
    solution_module = solution_set.generate_solution_mlir()
    write_log_file("solution.mlir", solution_module)

    lowerer = LowerToLLVM(bw)
    lowerer.add_fn(helper_funcs.meet_func)
    lowerer.add_fn(helper_funcs.get_top_func)
    lowerer.add_mod(solution_module, ["solution"])
    jit.add_mod(str(lowerer))
    solution_ptr = jit.get_fn_ptr("solution_shim")
    solution_result = eval_transfer_func(to_eval, [solution_ptr], [])[0]

    solution_exact = solution_result.get_exact_prop() * 100
    print(
        f"Final Soln   | Exact {solution_exact:.4f}% | {solution_set.solutions_size} solutions |"
    )


def main() -> None:
    args = build_parser("synth_transfer")

    if not args.outputs_folder.is_dir():
        args.outputs_folder.mkdir()

    logger = init_logging(args.outputs_folder, not args.quiet)
    max_len = max(len(k) for k in vars(args))
    [logger.config(f"{k:<{max_len}} | {v}") for k, v in vars(args).items()]

    run(
        domain=AbstractDomain[args.domain],
        num_programs=args.num_programs,
        total_rounds=args.total_rounds,
        program_length=args.program_length,
        inv_temp=args.inv_temp,
        bw=args.bw,
        samples=args.samples,
        num_iters=args.num_iters,
        condition_length=args.condition_length,
        num_abd_procs=args.num_abd_procs,
        random_seed=args.random_seed,
        random_number_file=args.random_file,
        transformer_file=args.transfer_functions,
        weighted_dsl=args.weighted_dsl,
        num_unsound_candidates=args.num_unsound_candidates,
    )
