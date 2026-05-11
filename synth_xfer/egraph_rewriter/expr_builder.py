from __future__ import annotations

import time

from egglog import EGraph, Expr
from egglog.declarations import CallDecl, TypedExprDecl
from xdsl.dialects.arith import ConstantOp as ArithConstantOp
from xdsl.dialects.builtin import IntegerAttr, IntegerType
from xdsl.dialects.func import FuncOp, ReturnOp
from xdsl.ir import Block, Operation
from xdsl.ir.core import SSAValue
from xdsl_smt.dialects.transfer import (
    AbstractValueType,
    CmpOp as TransferCmpOp,
    Constant,
    GetAllOnesOp,
    GetOp,
    MakeOp,
)

from synth_xfer._util.domain import AbstractDomain
from synth_xfer.egraph_rewriter.datatypes import (
    BV,
    Bool,
    cmp_predicate_to_fn,
    gen_ruleset,
    make_absvalue,
    mlir_op_to_egraph_op,
)


class ExprBuilder:
    func: FuncOp
    op_to_expr: dict[Operation, Expr]
    arg_index: dict[SSAValue, int]
    ret_expr: Expr
    cmp_predicates: dict[CallDecl, int]

    def __init__(self, _func: FuncOp):
        self.func = _func
        self.op_to_expr = {}
        self.arg_index = {}
        self.cmp_predicates = {}

    def create_arg_name(self, op: SSAValue, index: int) -> str:
        return f"arg{self.arg_index[op]}_{index}"

    def build_expr(self):
        block = self.func.body.blocks[0]

        for i, arg in enumerate(block.args):
            self.arg_index[arg] = i

        for op in block.ops:
            if isinstance(op, ReturnOp):
                if len(op.operands) != 1:
                    raise ValueError(
                        f"Expected exactly one return operand, got {len(op.operands)}"
                    )
                ret_value = op.operands[0]
                producer = ret_value.owner
                if isinstance(producer, Block):
                    # Returning a block argument directly (pure passthrough).
                    # Synthesize an AbsValue from its fields so the joint expr
                    # has the AbsValue.makeN shape ExprToMLIR expects.
                    if not isinstance(ret_value.type, AbstractValueType):
                        raise ValueError(
                            "ReturnOp returning a non-AbstractValueType block "
                            f"argument is unsupported: type={ret_value.type}"
                        )
                    arg_idx = self.arg_index[ret_value]
                    n_fields = len(ret_value.type.get_fields())
                    field_exprs: list[Expr] = [
                        BV.var(f"arg{arg_idx}_{i}") for i in range(n_fields)
                    ]
                    self.ret_expr = make_absvalue(*field_exprs)
                    return
                if not isinstance(producer, Operation) or producer not in self.op_to_expr:
                    raise ValueError(
                        f"ReturnOp's operand is produced by an unsupported source: "
                        f"{type(producer).__name__}"
                    )
                self.ret_expr = self.op_to_expr[producer]
                return

            if isinstance(op, GetOp):
                arg_name = self.create_arg_name(op.operands[0], op.index.value.data)
                self.op_to_expr[op] = BV.var(arg_name)

            if isinstance(op, MakeOp):
                field_exprs: list[Expr] = []
                for operand in op.operands:
                    assert isinstance(operand.owner, Operation)
                    field_exprs.append(self.op_to_expr[operand.owner])
                self.op_to_expr[op] = make_absvalue(*field_exprs)

            if isinstance(op, Constant):
                const_value = op.value.value.data
                self.op_to_expr[op] = BV(const_value)

            if isinstance(op, ArithConstantOp):
                result_type = op.results[0].type
                if (
                    isinstance(result_type, IntegerType)
                    and result_type.width.data == 1
                    and isinstance(op.value, IntegerAttr)
                ):
                    self.op_to_expr[op] = (
                        Bool.true() if op.value.value.data != 0 else Bool.false()
                    )
                # non-i1 arith.constant is currently unsupported and intentionally
                # left out of op_to_expr; downstream consumers will raise a clear
                # KeyError if they reference it.

            if isinstance(op, GetAllOnesOp):
                self.op_to_expr[op] = BV(-1)

            if isinstance(op, TransferCmpOp):
                pred = op.predicate.value.data
                assert pred in cmp_predicate_to_fn
                expr_operands = []
                for operand in op.operands:
                    assert isinstance(operand.owner, Operation)
                    expr_operands.append(self.op_to_expr[operand.owner])
                expr = cmp_predicate_to_fn[pred](*expr_operands)
                typed_expr = getattr(expr, "__egg_typed_expr__", None)
                if not isinstance(typed_expr, TypedExprDecl):
                    raise TypeError(
                        "Expected expression to have a TypedExprDecl at '__egg_typed_expr__'"
                    )
                call = typed_expr.expr
                assert isinstance(call, CallDecl)
                self.cmp_predicates[call] = pred
                self.op_to_expr[op] = expr
                continue

            if type(op) in mlir_op_to_egraph_op:
                egraph_op = mlir_op_to_egraph_op[type(op)]
                expr_operands = []
                for operand in op.operands:
                    assert isinstance(operand.owner, Operation)
                    expr_operands.append(self.op_to_expr[operand.owner])
                self.op_to_expr[op] = egraph_op(*expr_operands)


def simplify_term(
    expr: Expr,
    *,
    domain: AbstractDomain,
    num_args: int,
    max_iterations: int,
    step_time_limit_seconds: float,
) -> tuple[Expr, int, int]:
    """
    Simplify ``expr`` via egglog saturation.

    Args:
        max_iterations: Hard upper bound on the number of saturation passes.
        step_time_limit_seconds: Maximum wall-clock seconds for a single
            iteration. Egglog cannot be interrupted mid-iteration, so the check
            happens after each ``egraph.run(1)`` returns: if that iteration
            exceeded the budget, no further iterations are started (the egraph
            has grown enough that the next iteration is expected to be at least
            as slow).
    """
    egraph = EGraph()
    rules = gen_ruleset(domain, num_args)
    expr_to_simplify = egraph.let("expr_to_simplify", expr)
    _, previous_cost = egraph.extract(expr_to_simplify, include_cost=True)

    start = time.monotonic()
    for i in range(max_iterations):
        iter_start = time.monotonic()
        report = egraph.run(1, ruleset=rules)
        now = time.monotonic()
        iter_dt = now - iter_start
        elapsed = now - start
        print(
            f"Iteration {i + 1}: {iter_dt:.3f}s "
            f"(elapsed {elapsed:.3f}s, updated={report.updated})"
        )
        if not report.updated:
            break  # saturated -- further iterations would do nothing
        if iter_dt >= step_time_limit_seconds:
            break

    new_expr, new_cost = egraph.extract(expr_to_simplify, include_cost=True)
    return new_expr, previous_cost, new_cost
