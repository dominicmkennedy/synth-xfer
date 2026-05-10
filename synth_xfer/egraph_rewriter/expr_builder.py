from __future__ import annotations

from egglog import EGraph, Expr
from egglog.declarations import CallDecl, TypedExprDecl
from xdsl.dialects.func import FuncOp, ReturnOp
from xdsl.ir import Operation
from xdsl.ir.core import SSAValue
from xdsl_smt.dialects.transfer import (
    CmpOp as TransferCmpOp,
    Constant,
    GetAllOnesOp,
    GetOp,
    MakeOp,
)

from synth_xfer._util.domain import AbstractDomain
from synth_xfer.egraph_rewriter.datatypes import (
    BV,
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
                producer = op.operands[0].owner
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
) -> tuple[Expr, int, int]:
    egraph = EGraph()
    rules = gen_ruleset(domain, num_args)
    expr_to_simplify = egraph.let("expr_to_simplify", expr)
    _, previous_cost = egraph.extract(expr_to_simplify, include_cost=True)
    # _ = egraph.run(max_iterations, ruleset=rules)
    _ = egraph.run(1, ruleset=rules)
    new_expr, new_cost = egraph.extract(expr_to_simplify, include_cost=True)
    return new_expr, previous_cost, new_cost
