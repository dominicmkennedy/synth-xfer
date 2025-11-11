from dataclasses import dataclass

from xdsl.dialects.func import FuncOp


# TODO give this class some helpers to lower it's members to MLIR/jit
@dataclass
class HelperFuncs:
    crt_func: FuncOp
    instance_constraint_func: FuncOp
    domain_constraint_func: FuncOp
    op_constraint_func: FuncOp | None
    get_top_func: FuncOp
    transfer_func: FuncOp
    meet_func: FuncOp
