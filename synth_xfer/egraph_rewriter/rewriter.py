from typing import List

import egglog
from xdsl.dialects.func import FuncOp

from synth_xfer.egraph_rewriter.expr_builder import (
    ExprBuilder,
    build_meet_expr,
    simplify_term,
)
from synth_xfer.egraph_rewriter.expr_to_mlir import ExprToMLIR


def rewrite_single_function_to_exprs(
    func: FuncOp, *, quiet: bool = True
) -> tuple[tuple[egglog.Expr, ...], dict]:
    """
    Rewrite a single transfer function by iterating over all its statements.
    This function specifically handles functions ending with "_body" or "_cond".
    Prints the expressions without returning anything.

    Args:
        func: The function to rewrite (should end with "_body" or "_cond")
    """
    if not quiet:
        function_name = func.sym_name.data
        print(f"Rewriting function: {function_name}")

    expr_builder = ExprBuilder(func)
    expr_builder.build_expr()
    rewritten_exprs = []
    for i, expr in enumerate(expr_builder.ret_exprs):
        simplfied, previous_cost, new_cost = simplify_term(expr)
        if not quiet:
            print(f"Known{i}: {previous_cost} -> {new_cost}")
            # print(f"  Before: {expr}")
            # print(f"  After:  {simplfied}")
        rewritten_exprs.append(simplfied)

    return tuple(rewritten_exprs), expr_builder.cmp_predicates


def rewrite_single_function(func: FuncOp, *, quiet: bool = True) -> FuncOp:
    rewritten_exprs, cmp_predicates = rewrite_single_function_to_exprs(func, quiet=quiet)

    # Emit the original MLIR for reference
    print("Original MLIR:")
    print(func)

    converter = ExprToMLIR(func, cmp_predicates=cmp_predicates)
    rewritten_func = converter.convert(rewritten_exprs)
    # Emit the rewritten MLIR for inspection
    print("Rewritten MLIR:")
    print(f"{rewritten_func}\n")
    return rewritten_func


def should_rewrite_function(func: FuncOp) -> bool:
    """
    Check if a function should be rewritten based on its name.
    Only functions ending with "_body" or "_cond" should be rewritten.
    """
    function_name = func.sym_name.data
    return function_name.endswith("_body") or function_name.endswith("_cond")


def rewrite_transfer_functions(
    xfer_funcs: List[FuncOp], *, quiet: bool = True
) -> list[tuple[egglog.Expr, ...]]:
    """
    Rewrite transfer functions provided by postprocessor.py.
    Only functions ending with "_body" or "_cond" will be rewritten.

    Args:
        xfer_funcs: List of transfer functions to rewrite (from postprocessor.py)
    """
    if not quiet:
        print(f"Starting rewrite of {len(xfer_funcs)} transfer functions")

    # Filter functions to only include those ending with "_body" or "_cond"
    functions_to_rewrite = [func for func in xfer_funcs if should_rewrite_function(func)]
    if not quiet:
        print(
            f"Found {len(functions_to_rewrite)} functions to rewrite (ending with '_body' or '_cond'):"
        )
        for func in functions_to_rewrite:
            print(f"  - {func.sym_name.data}")

    # Rewrite the functions we want to process
    rewritten_funcs = []
    for func in functions_to_rewrite:
        exprs, _ = rewrite_single_function_to_exprs(func, quiet=quiet)
        rewritten_funcs.append(exprs)
    return rewritten_funcs


def rewrite_meet_of_all_functions(
    all_ret_exprs: List[tuple[egglog.Expr, ...]], *, quiet: bool = True
) -> None:
    """
    Process meet expressions for functions ending with "_body".

    Args:
        all_ret_exprs: List of return expressions from transfer functions
    """
    if not quiet:
        print(f"Building meet of {len(all_ret_exprs)} functions")
    meet_exprs = build_meet_expr(all_ret_exprs)
    if not quiet:
        print("Done. ")
        for i, expr in enumerate(meet_exprs):
            simplfied, previous_cost, new_cost = simplify_term(expr)
            print(f"Known{i}: {previous_cost} -> {new_cost}")
            print(f"  Before: {expr}")
            print(f"  After:  {simplfied}")
        print("\n")
