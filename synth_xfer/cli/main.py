import logging
from pathlib import Path
from typing import Callable, Literal, cast

from xdsl.context import Context
from xdsl.dialects.arith import Arith
from xdsl.dialects.builtin import Builtin, ModuleOp, StringAttr
from xdsl.dialects.comb import Comb
from xdsl.dialects.func import CallOp, Func, FuncOp, ReturnOp
from xdsl.dialects.hw import HW
from xdsl.parser import Parser
from xdsl_smt.dialects.index_dialect import Index
from xdsl_smt.dialects.smt_bitvector_dialect import SMTBitVectorDialect
from xdsl_smt.dialects.smt_dialect import SMTDialect
from xdsl_smt.dialects.smt_utils_dialect import SMTUtilsDialect
from xdsl_smt.dialects.transfer import AbstractValueType, Transfer, TransIntegerType
from xdsl_smt.passes.transfer_inline import FunctionCallInline

from synth_xfer._util.cond_func import FunctionWithCondition
from synth_xfer._util.dce import TransferDeadCodeElimination
from synth_xfer._util.eval import AbstractDomain, eval_transfer_func, setup_eval
from synth_xfer._util.eval_result import EvalResult
from synth_xfer._util.helper_funcs import HelperFuncs
from synth_xfer._util.log import print_set_of_funcs_to_file, setup_loggers
from synth_xfer._util.one_iter import synthesize_one_iteration
from synth_xfer._util.random import Random
from synth_xfer._util.solution_set import SolutionSet, UnsizedSolutionSet
from synth_xfer._util.synth_context import SynthesizerContext
from synth_xfer.cli.args import build_parser
from synth_xfer.jit import Jit
from synth_xfer.lower_to_llvm import LowerToLLVM

# TODO this should be made local
# TODO I've never seen us use a lot of these dialects, let's try and cut down the list to only what we need
ctx = Context()
ctx.load_dialect(Arith)
ctx.load_dialect(Builtin)
ctx.load_dialect(Func)
ctx.load_dialect(SMTDialect)
ctx.load_dialect(SMTBitVectorDialect)
ctx.load_dialect(SMTUtilsDialect)
ctx.load_dialect(Transfer)
ctx.load_dialect(Index)
ctx.load_dialect(Comb)
ctx.load_dialect(HW)

# TODO removed CPPCLASS, applied_to, and is_forward attrs from my transfer functions
# this seems like it could cause some problems later, esp in the verifyer

# TODO when the new lowerer/jit is incorporated, I should run DCE on it beforehand?
# but maybe not since llvm ir should DCE anyway so idrc


def eliminate_dead_code(func: FuncOp) -> FuncOp:
    """
    WARNING: this function modifies the func passed to it in place!
    """
    TransferDeadCodeElimination().apply(ctx, cast(ModuleOp, func))
    return func


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


# TODO combine this with eval_transfer_func_helper
# TODO type toeval
# TODO removed helper funcs, but do probs need to provide a meet function
# also def need a top fn
# TODO later this will need domain
def _eval_helper(
    to_eval,
    bw: int,
    _domain: AbstractDomain,
    helper_funcs: HelperFuncs,
    ret_top_func: FunctionWithCondition,
    jit: Jit,
) -> Callable[
    [
        list[FunctionWithCondition],
        list[FunctionWithCondition],
    ],
    list[EvalResult],
]:
    def helper(
        transfer: list[FunctionWithCondition],
        base: list[FunctionWithCondition],
    ) -> list[EvalResult]:
        lowerer = LowerToLLVM(bw, "tmp_name")
        top_fn = lowerer.add_fn(helper_funcs.get_top_func)

        if not transfer:
            transfer = [ret_top_func]

        transfer_func_names: list[str] = []
        transfer_func_srcs: list[str] = []
        for fc in transfer:
            caller_str, fn_str, cond_str = fc.get_function_str(
                lambda x: str(lowerer.add_fn(x))
            )
            transfer_func_names.append(fc.func_name)
            transfer_func_srcs.append(
                f"{fn_str}\n{cond_str if cond_str else ''}\n{caller_str}"
            )

        base_func_names: list[str] = []
        base_func_srcs: list[str] = []
        for fc in base:
            caller_str, fn_str, cond_str = fc.get_function_str(
                lambda x: str(lowerer.add_fn(x))
            )
            base_func_names.append(fc.func_name)
            base_func_srcs.append(
                f"{fn_str}\n{cond_str if cond_str else ''}\n{caller_str}"
            )

        # TODO idk if it's a good idea for this function to own a jit,
        # but idk where eles to put it rn
        llvm_src = (
            str(top_fn)
            + "\n"
            + "\n".join(transfer_func_srcs)
            + "\n\n"
            + "\n".join(base_func_srcs)
        )
        jit.add_mod(llvm_src)
        transfer_fn_ptrs = [jit.get_fn_ptr(x) for x in transfer_func_names]
        base_fn_ptrs = [jit.get_fn_ptr(x) for x in base_func_names]

        return eval_transfer_func(
            to_eval,
            transfer_fn_ptrs,
            base_fn_ptrs,
        )

    return helper


def _save_solution(solution_module: ModuleOp, outputs_folder: Path):
    with open(outputs_folder.joinpath("solution.mlir"), "w") as fout:
        print(solution_module, file=fout)


def _get_module(p: Path) -> ModuleOp:
    with open(p, "r") as f:
        mod = Parser(ctx, f.read(), p.name).parse_op()
        assert isinstance(mod, ModuleOp)

    return mod


def _get_helper_funcs(mod: ModuleOp, p: Path, d: AbstractDomain) -> HelperFuncs:
    # TODO only takes the abst domain to know how many fields should be in

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


def _get_base_xfers(module: ModuleOp) -> list[FunctionWithCondition]:
    def is_base_function(func: FuncOp) -> bool:
        return func.sym_name.data.startswith("part_solution_")

    base_bodys: dict[str, FuncOp] = {}
    base_conds: dict[str, FuncOp] = {}
    base_transfers: list[FunctionWithCondition] = []

    fs = [x for x in module.ops if isinstance(x, FuncOp) and is_base_function(x)]
    for func in fs:
        func_name = func.sym_name.data
        if func_name.endswith("_body"):
            main_name = func_name[: -len("_body")]
            if main_name in base_conds:
                body = func
                cond = base_conds.pop(main_name)
                body.attributes["number"] = StringAttr("init")
                cond.attributes["number"] = StringAttr("init")
                base_transfers.append(FunctionWithCondition(body, cond))
            else:
                base_bodys[main_name] = func
        elif func_name.endswith("_cond"):
            main_name = func_name[: -len("_cond")]
            if main_name in base_bodys:
                body = base_bodys.pop(main_name)
                cond = func
                body.attributes["number"] = StringAttr("init")
                cond.attributes["number"] = StringAttr("init")
                base_transfers.append(FunctionWithCondition(body, func))
            else:
                base_conds[main_name] = func

    assert len(base_conds) == 0
    for _, func in base_bodys.items():
        func.attributes["number"] = StringAttr("init")
        base_transfers.append(FunctionWithCondition(func))

    return base_transfers


def _setup_context(r: Random, use_full_i1_ops: bool) -> SynthesizerContext:
    c = SynthesizerContext(r)
    c.set_cmp_flags([0, 6, 7])
    if not use_full_i1_ops:
        c.use_basic_i1_ops()
    return c


def run(
    logger: logging.Logger,
    domain: AbstractDomain,
    num_programs: int,
    total_rounds: int,
    program_length: int,
    inv_temp: int,
    bw: Literal[4] | Literal[8] | Literal[16] | Literal[32] | Literal[64],
    samples: int | None,
    num_iters: int,
    condition_length: int,
    num_abd_procs: int,
    random_seed: int | None,
    random_number_file: str | None,
    transformer_file: Path,
    weighted_dsl: bool,
    num_unsound_candidates: int,
    outputs_folder: Path,
) -> EvalResult:
    # TODO jit object needs to be alive for the runtime of this function (or else it'll be free'd and we'll segfault)
    # So it's important who owns it, etc. we'll have run own it for right now

    # TODO move this check into arg parsing
    assert bw == 4 or bw == 8 or bw == 16 or bw == 32 or bw == 64

    # TODO maybe change the llvm module name
    lowerer = LowerToLLVM(bw, "synth_xfer_mod")
    jit = Jit()

    # TODO fix evalresult
    EvalResult.init_bw_settings(set({4}), set(), set())

    logger.debug("Round_ID\tSound%\tUExact%\tDisReduce\tCost")

    random = Random(random_seed)
    random_seed = random.randint(0, 1_000_000) if random_seed is None else random_seed
    if random_number_file is not None:
        random.read_from_file(random_number_file)

    context = _setup_context(random, False)
    context_weighted = _setup_context(random, False)
    context_cond = _setup_context(random, True)

    module = _get_module(transformer_file)
    helper_funcs = _get_helper_funcs(module, transformer_file, domain)
    base_transfers = _get_base_xfers(module)

    ret_top_func = FunctionWithCondition(_construct_top_func(helper_funcs.transfer_func))
    ret_top_func.set_func_name("ret_top")

    # TODO need auto shiming
    crt = lowerer.add_fn(helper_funcs.crt_func)
    new_crt = lowerer.shim_conc(crt)
    # TODO give op con func to setup eval
    _ = (
        lowerer.add_fn(helper_funcs.op_constraint_func, shim=True)
        if helper_funcs.op_constraint_func
        else None
    )

    jit.add_mod(str(crt) + str(new_crt))
    crt_fn_ptr = jit.get_fn_ptr(new_crt.name)

    # TODO need to select domain and bw here
    # but will just hardcode to kb_4 for now
    to_eval = setup_eval(crt_fn_ptr, None)

    solution_eval_func = _eval_helper(
        to_eval, bw, domain, helper_funcs, ret_top_func, jit
    )

    solution_set: SolutionSet = UnsizedSolutionSet(
        base_transfers,
        solution_eval_func,
        logger,
        eliminate_dead_code,
    )

    # eval the initial solutions in the solution set
    init_cmp_res = solution_set.eval_improve([])[0]
    init_sound = init_cmp_res.get_sound_prop() * 100
    init_exact = init_cmp_res.get_exact_prop() * 100
    logger.info(f"Initial Solution. Sound:{init_sound:.4f}% Exact: {init_exact:.4f}%")
    print(f"init_solution\t{init_sound:.4f}%\t{init_exact:.4f}%")

    current_prog_len = program_length
    current_total_rounds = total_rounds
    current_num_abd_procs = num_abd_procs
    for ith_iter in range(num_iters):
        # gradually increase the program length
        current_prog_len += (program_length - current_prog_len) // (num_iters - ith_iter)
        current_total_rounds += (total_rounds - current_total_rounds) // (
            num_iters - ith_iter
        )
        current_num_abd_procs += (num_abd_procs - current_num_abd_procs) // (
            num_iters - ith_iter
        )

        print(f"Iteration {ith_iter} starts...")

        if weighted_dsl:
            assert isinstance(solution_set, UnsizedSolutionSet)
            context_weighted.weighted = True
            solution_set.learn_weights(context_weighted)

        solution_set = synthesize_one_iteration(
            ith_iter,
            context,
            context_weighted,
            context_cond,
            random,
            solution_set,
            logger,
            helper_funcs,
            ctx,
            num_programs,
            current_prog_len,
            condition_length,
            current_num_abd_procs,
            current_total_rounds,
            inv_temp,
            num_unsound_candidates,
            bw,
        )

        print_set_of_funcs_to_file(
            [f.to_str(eliminate_dead_code) for f in solution_set.solutions],
            ith_iter,
            outputs_folder,
        )

        final_cmp_res = solution_set.eval_improve([])
        lbw_mbw_log = "\n".join(
            f"bw: {res.bitwidth}, dist: {res.dist:.2f}, exact%: {res.get_exact_prop() * 100:.4f}"
            for res in final_cmp_res[0].get_low_med_res()
        )
        hbw_log = "\n".join(
            f"bw: {res.bitwidth}, dist: {res.dist:.2f}"
            for res in final_cmp_res[0].get_high_res()
        )
        logger.info(
            f"""Iter {ith_iter} Finished. Result of Current Solution: \n{lbw_mbw_log}\n{hbw_log}\n"""
        )

        print(
            f"Iteration {ith_iter} finished. Exact: {final_cmp_res[0].get_exact_prop() * 100:.4f}%, Size of the solution set: {solution_set.solutions_size}"
        )

        if solution_set.is_perfect:
            print("Found a perfect solution")
            break

    # Eval last solution:
    if not solution_set.has_solution():
        raise Exception("Found no solutions")
    solution_module = solution_set.generate_solution_mlir()
    _save_solution(solution_module, outputs_folder)
    # TODO solution_str should be a fn ptr to the solution func to eval

    solution_result = eval_transfer_func(to_eval, [solution_str], [])[0]
    solution_sound = solution_result.get_sound_prop() * 100
    solution_exact = solution_result.get_exact_prop() * 100
    print(f"last_solution\t{solution_sound:.2f}%\t{solution_exact:.2f}%")

    return solution_result


def main() -> None:
    args = build_parser("synth_transfer")

    if not args.outputs_folder.is_dir():
        args.outputs_folder.mkdir()

    logger = setup_loggers(args.outputs_folder, not args.quiet)
    [logger.info(f"{k}: {v}") for k, v in vars(args).items()]

    run(
        logger=logger,
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
        outputs_folder=args.outputs_folder,
    )
