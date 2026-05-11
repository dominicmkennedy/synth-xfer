from typing import List

import egglog
from xdsl.dialects.func import CallOp, FuncOp

from synth_xfer._util.domain import AbstractDomain
from synth_xfer.egraph_rewriter.expr_builder import ExprBuilder, simplify_term
from synth_xfer.egraph_rewriter.expr_to_mlir import ExprToMLIR


def _func_arity(func: FuncOp) -> int:
    return len(func.body.blocks[0].args)


def _has_call_op(func: FuncOp) -> bool:
    return any(isinstance(op, CallOp) for op in func.body.walk())


def rewrite_single_function_to_exprs(
    func: FuncOp,
    *,
    domain: AbstractDomain,
    quiet: bool = True,
    max_iterations: int,
    step_time_limit_seconds: float,
) -> tuple[egglog.Expr, dict]:
    """
    Rewrite a single transfer function as one joint AbsValue expression.

    Args:
        func: The function to rewrite.
        domain: Abstract domain whose axioms (if any) should apply.
        quiet: Suppress per-function logging when True.
        max_iterations: Hard upper bound on the number of saturation passes.
        step_time_limit_seconds: Per-iteration wall-clock cap. After any
            single iteration exceeds this budget, no further iterations are
            started (the egraph is large enough that the next iteration is
            expected to be at least as slow).

    Returns:
        A pair of (simplified joint expression, cmp_predicates).
    """
    print(f"Rewriting function {func.sym_name.data} ...")

    expr_builder = ExprBuilder(func)
    expr_builder.build_expr()

    simplified, previous_cost, new_cost = simplify_term(
        expr_builder.ret_expr,
        domain=domain,
        num_args=_func_arity(func),
        max_iterations=max_iterations,
        step_time_limit_seconds=step_time_limit_seconds,
    )
    if not quiet:
        print(f"Expanded AST Size: {previous_cost} -> {new_cost}")

    return simplified, expr_builder.cmp_predicates


def rewrite_single_function(
    func: FuncOp,
    *,
    domain: AbstractDomain,
    quiet: bool = True,
    max_iterations: int,
    step_time_limit_seconds: float,
) -> FuncOp:
    joint, cmp_predicates = rewrite_single_function_to_exprs(
        func,
        domain=domain,
        quiet=quiet,
        max_iterations=max_iterations,
        step_time_limit_seconds=step_time_limit_seconds,
    )
    return ExprToMLIR(func, cmp_predicates=cmp_predicates).convert(joint)


def rewrite_solutions(
    xfer_funcs: List[FuncOp],
    *,
    domain: AbstractDomain,
    quiet: bool = True,
    max_iterations: int,
    step_time_limit_seconds: float,
) -> list[FuncOp]:
    """
    Rewrite every transfer function in the module.

    Args:
        xfer_funcs: List of transfer functions to rewrite (from postprocessor.py)
        domain: Abstract domain whose axioms (if any) should apply.
        max_iterations: Hard upper bound on the number of saturation passes per
            function.
        step_time_limit_seconds: Per-iteration wall-clock cap (see
            ``rewrite_single_function_to_exprs``).

    Returns:
        A list of rewritten functions, one per input function.
    """
    plain_funcs = [f for f in xfer_funcs if not _has_call_op(f)]
    skipped = [f for f in xfer_funcs if _has_call_op(f)]

    if skipped:
        print(
            f"Skipping {len(skipped)} function(s) containing func.call "
            "(only plain functions are supported); they will be passed "
            "through unchanged:"
        )
        for func in skipped:
            print(f"  - {func.sym_name.data}")
    print(f"Found {len(plain_funcs)} functions to rewrite:")
    for func in plain_funcs:
        print(f"  - {func.sym_name.data}")

    rewritten_by_id: dict[int, FuncOp] = {}
    for func in plain_funcs:
        joint, cmp_predicates = rewrite_single_function_to_exprs(
            func,
            domain=domain,
            quiet=quiet,
            max_iterations=max_iterations,
            step_time_limit_seconds=step_time_limit_seconds,
        )
        rewritten_by_id[id(func)] = ExprToMLIR(
            func, cmp_predicates=cmp_predicates
        ).convert(joint)

    return [rewritten_by_id.get(id(func), func.clone()) for func in xfer_funcs]
