from dataclasses import dataclass
from pathlib import Path
from typing import Protocol, runtime_checkable

from xdsl.context import Context
from xdsl.dialects.arith import Arith
from xdsl.dialects.builtin import Builtin, ModuleOp
from xdsl.dialects.func import CallOp, Func, FuncOp, ReturnOp
from xdsl.ir import Attribute, Operation
from xdsl.parser import IntegerType, Parser
from xdsl_smt.dialects.transfer import AbstractValueType, Transfer, TransIntegerType
from xdsl_smt.passes.transfer_inline import FunctionCallInline

from synth_xfer._util.domain import AbstractDomain

_ctx = Context()
_ctx.load_dialect(Arith)
_ctx.load_dialect(Builtin)
_ctx.load_dialect(Func)
_ctx.load_dialect(Transfer)


@runtime_checkable
class _Readable(Protocol):
    @property
    def name(self) -> str: ...

    def read_text(self) -> str: ...


def parse_mlir(p: _Readable) -> Operation:
    func_str = p if isinstance(p, str) else p.read_text()
    func_name = "<text>" if isinstance(p, str) else p.name

    return Parser(_ctx, func_str, func_name).parse_op()


def parse_mlir_func(p: _Readable) -> FuncOp:
    func_name = "<text>" if isinstance(p, str) else p.name
    mod = parse_mlir(p)

    if isinstance(mod, FuncOp):
        return mod
    else:
        raise ValueError(f"mlir in '{func_name}' is not a FuncOp")


def parse_mlir_mod(p: _Readable, inline: bool = False) -> ModuleOp:
    func_name = "<text>" if isinstance(p, str) else p.name
    mod = parse_mlir(p)

    if isinstance(mod, ModuleOp):
        if inline:
            FunctionCallInline(False, get_fns(mod)).apply(_ctx, mod)

        return mod
    else:
        raise ValueError(f"mlir in '{func_name}' is not a ModuleOp")


def get_fns(mod: ModuleOp) -> dict[str, FuncOp]:
    return {x.sym_name.data: x for x in mod.ops if isinstance(x, FuncOp)}


@dataclass
class HelperFuncs:
    conc_ret_ty: TransIntegerType | IntegerType
    conc_arg_ty: tuple[TransIntegerType | IntegerType, ...]
    domain: AbstractDomain
    crt_func: FuncOp
    instance_constraint_func: FuncOp
    domain_constraint_func: FuncOp
    op_constraint_func: FuncOp | None
    get_top_func: FuncOp
    transfer_func: FuncOp
    meet_func: FuncOp


def get_helper_funcs(p: Path, d: AbstractDomain) -> HelperFuncs:
    mod = parse_mlir_mod(p, inline=True)
    fns = get_fns(mod)

    assert "concrete_op" in fns
    crt_func = fns["concrete_op"]
    op_con_fn = fns.get("op_constraint", None)

    assert len(crt_func.function_type.outputs.data) == 1

    def get_ty(x: Attribute):
        assert isinstance(x, TransIntegerType) or isinstance(x, IntegerType)
        return x

    def make_abst_ty(x: Attribute):
        return AbstractValueType([x for _ in range(d.vec_size)])

    crt_ret_ty = get_ty(crt_func.function_type.outputs.data[0])
    crt_arg_ty = tuple(get_ty(x.type) for x in crt_func.args)

    # TODO xfer fn is only ever used as a type to construct a top fn
    xfer_ret = [make_abst_ty(crt_ret_ty)]
    xfer_args = [make_abst_ty(x.type) for x in crt_func.args]
    xfer_fn = FuncOp.from_region("empty_transformer", xfer_args, xfer_ret)

    def get_domain_fns(fp: str) -> FuncOp:
        dp = p.resolve().parent.parent.joinpath(str(d), fp)
        return parse_mlir_func(dp)

    top = get_domain_fns("top.mlir")
    meet = get_domain_fns("meet.mlir")
    constraint = get_domain_fns("get_constraint.mlir")
    instance_constraint = get_domain_fns("get_instance_constraint.mlir")

    return HelperFuncs(
        conc_ret_ty=crt_ret_ty,
        conc_arg_ty=crt_arg_ty,
        domain=d,
        crt_func=crt_func,
        instance_constraint_func=instance_constraint,
        domain_constraint_func=constraint,
        op_constraint_func=op_con_fn,
        get_top_func=top,
        transfer_func=xfer_fn,
        meet_func=meet,
    )


def top_as_xfer(transfer: FuncOp) -> FuncOp:
    func = FuncOp("top_transfer_function", transfer.function_type)
    block = func.body.block
    args = func.args

    call_top_op = CallOp("getTop", [args[0]], func.function_type.outputs.data)
    assert len(call_top_op.results) == 1
    top_res = call_top_op.results[0]
    return_op = ReturnOp(top_res)
    block.add_ops([call_top_op, return_op])
    return func
