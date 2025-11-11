from xdsl.context import Context
from xdsl.dialects.builtin import ModuleOp
from xdsl.dialects.func import FuncOp, ReturnOp
from xdsl.ir import Operation
from xdsl.passes import ModulePass
from xdsl.pattern_rewriter import PatternRewriter, PatternRewriteWalker, RewritePattern


class RemoveTransferDeadPattern(RewritePattern):
    def match_and_rewrite(self, op: Operation, rewriter: PatternRewriter):
        if isinstance(op, ModuleOp) or isinstance(op, FuncOp) or isinstance(op, ReturnOp):
            return None
        if all(len(list(result.uses)) == 0 for result in op.results):
            rewriter.erase_matched_op()


class TransferDeadCodeElimination(ModulePass):
    name = "transfer-dce"

    def apply(self, _ctx: Context, op: ModuleOp):
        walker = PatternRewriteWalker(RemoveTransferDeadPattern(), walk_reverse=True)
        walker.rewrite_module(op)
