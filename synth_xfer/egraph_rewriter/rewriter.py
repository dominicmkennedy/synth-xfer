from typing import List

import egglog
from xdsl.dialects.func import FuncOp

from synth_xfer._util.domain import AbstractDomain
from synth_xfer.egraph_rewriter.expr_builder import (
    ExprBuilder,
    build_meet_expr,
    simplify_term,
)
from synth_xfer.egraph_rewriter.expr_to_mlir import ExprToMLIR


def _func_arity(func: FuncOp) -> int:
    return len(func.body.blocks[0].args)


def rewrite_single_function_to_exprs(
    func: FuncOp,
    *,
    domain: AbstractDomain,
    quiet: bool = True,
    timeout: int = 5,
) -> tuple[tuple[egglog.Expr, ...], dict]:
    """
    Rewrite a single transfer function by iterating over all its statements.

    Args:
        func: The function to rewrite.
        domain: Abstract domain whose axioms (if any) should apply.
        quiet: Suppress per-expr logging when True.
        timeout: Maximum number of rewrite passes to run per expression.
    """
    if not quiet:
        function_name = func.sym_name.data
        print(f"Rewriting function: {function_name}")

    expr_builder = ExprBuilder(func)
    expr_builder.build_expr()
    num_args = _func_arity(func)
    rewritten_exprs = []
    for i, expr in enumerate(expr_builder.ret_exprs):
        simplfied, previous_cost, new_cost = simplify_term(
            expr, domain=domain, num_args=num_args, timeout=timeout
        )
        if not quiet:
            print(f"Known{i}: {previous_cost} -> {new_cost}")
        rewritten_exprs.append(simplfied)

    return tuple(rewritten_exprs), expr_builder.cmp_predicates


def rewrite_single_function(
    func: FuncOp,
    *,
    domain: AbstractDomain,
    quiet: bool = True,
    timeout: int = 5,
) -> FuncOp:
    rewritten_exprs, cmp_predicates = rewrite_single_function_to_exprs(
        func, domain=domain, quiet=quiet, timeout=timeout
    )
    converter = ExprToMLIR(func, cmp_predicates=cmp_predicates)
    return converter.convert(rewritten_exprs)


def rewrite_solutions(
    xfer_funcs: List[FuncOp],
    *,
    domain: AbstractDomain,
    quiet: bool = True,
    timeout: int = 5,
) -> list[tuple[FuncOp, tuple[egglog.Expr, ...]]]:
    """
    Rewrite every transfer function in the module.

    Args:
        xfer_funcs: List of transfer functions to rewrite (from postprocessor.py)
        domain: Abstract domain whose axioms (if any) should apply.

    Returns:
        A list of (rewritten_func, exprs) pairs, one per input function.
    """
    if not quiet:
        print(f"Starting rewrite of {len(xfer_funcs)} transfer functions")
        print(f"Found {len(xfer_funcs)} functions to rewrite:")
        for func in xfer_funcs:
            print(f"  - {func.sym_name.data}")

    rewritten: list[tuple[FuncOp, tuple[egglog.Expr, ...]]] = []
    for func in xfer_funcs:
        exprs, cmp_predicates = rewrite_single_function_to_exprs(
            func, domain=domain, quiet=quiet, timeout=timeout
        )
        rewritten_func = ExprToMLIR(func, cmp_predicates=cmp_predicates).convert(exprs)
        rewritten.append((rewritten_func, exprs))
    return rewritten


def rewrite_meet_of_all_functions(
    all_ret_exprs: List[tuple[egglog.Expr, ...]],
    *,
    domain: AbstractDomain,
    num_args: int,
    quiet: bool = True,
) -> None:
    """
    Simplify the meet of return expressions across multiple functions.

    Args:
        all_ret_exprs: List of return expressions from transfer functions.
        domain: Abstract domain whose axioms (if any) should apply.
        num_args: Number of abstract-value arguments shared by the source
            functions; used to instantiate domain-specific axioms.
    """
    if not quiet:
        print(f"Building meet of {len(all_ret_exprs)} functions")
    meet_exprs = build_meet_expr(all_ret_exprs)
    if not quiet:
        print("Done. ")
        for i, expr in enumerate(meet_exprs):
            simplfied, previous_cost, new_cost = simplify_term(
                expr, domain=domain, num_args=num_args
            )
            print(f"Known{i}: {previous_cost} -> {new_cost}")
            print(f"  Before: {expr}")
            print(f"  After:  {simplfied}")
        print("\n")
