from __future__ import annotations

from egglog import EGraph, Expr
from xdsl.dialects.func import FuncOp
from xdsl.ir import Operation
from xdsl.ir.core import SSAValue
from xdsl_smt.dialects.transfer import Constant, GetAllOnesOp, GetOp, MakeOp

from synth_xfer.egraph_rewriter.datatypes import BV, gen_ruleset, mlir_op_to_egraph_op


class ExprBuilder:
    func: FuncOp
    op_to_expr: dict[Operation, Expr]
    arg_index: dict[SSAValue, int]
    ret_exprs: tuple[Expr, ...]

    def __init__(self, _func: FuncOp):
        self.func = _func
        self.op_to_expr = {}
        self.arg_index = {}

    def create_arg_name(self, op: SSAValue, index: int) -> str:
        return f"arg{self.arg_index[op]}_{index}"

    def build_expr(self):
        block = self.func.body.blocks[0]

        for i, arg in enumerate(block.args):
            self.arg_index[arg] = i

        for op in block.ops:
            if isinstance(op, GetOp):
                arg_name = self.create_arg_name(op.operands[0], op.index.value.data)
                self.op_to_expr[op] = BV.var(arg_name)

            if isinstance(op, MakeOp):
                ret_exprs: list[Expr] = []
                for operand in op.operands:
                    assert isinstance(operand.owner, Operation)
                    ret_exprs.append(self.op_to_expr[operand.owner])
                self.ret_exprs = tuple(ret_exprs)
                return

            if isinstance(op, Constant):
                const_value = op.value.value.data
                self.op_to_expr[op] = BV(const_value)

            if isinstance(op, GetAllOnesOp):
                self.op_to_expr[op] = BV(-1)

            if type(op) in mlir_op_to_egraph_op:
                egraph_op = mlir_op_to_egraph_op[type(op)]
                expr_operands = []
                for operand in op.operands:
                    assert isinstance(operand.owner, Operation)
                    expr_operands.append(self.op_to_expr[operand.owner])
                self.op_to_expr[op] = egraph_op(*expr_operands)


def build_meet_expr(all_ret_exprs: list[tuple[Expr, ...]]) -> tuple[Expr, ...]:
    num_rets = len(all_ret_exprs[0])
    meet_exprs: list[BV] = []
    for i in range(num_rets):
        first_expr = all_ret_exprs[0][i]
        assert isinstance(first_expr, BV)
        meet_expr = first_expr
        for exprs in all_ret_exprs[1:]:
            next_expr = exprs[i]
            assert isinstance(next_expr, BV)
            meet_expr = BV.Or(meet_expr, next_expr)
        meet_exprs.append(meet_expr)
    return tuple(meet_exprs)


def simplify_term(expr: Expr) -> tuple[Expr, int, int]:
    egraph = EGraph()
    rules = gen_ruleset()
    expr_to_simplify = egraph.let("expr_to_simplify", expr)
    _, previous_cost = egraph.extract(expr_to_simplify, include_cost=True)
    egraph.run(6, ruleset=rules)
    new_expr, new_cost = egraph.extract(expr_to_simplify, include_cost=True)
    return new_expr, previous_cost, new_cost
