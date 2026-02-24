from dataclasses import dataclass
from pathlib import Path
from typing import Protocol, runtime_checkable

from xdsl.context import Context
from xdsl.dialects.arith import AndIOp, Arith
from xdsl.dialects.builtin import Builtin, ModuleOp, StringAttr
from xdsl.dialects.func import CallOp, Func, FuncOp, ReturnOp
from xdsl.ir import Attribute, Operation
from xdsl.parser import IntegerType, Parser
from xdsl_smt.dialects.transfer import (
    AbstractValueType,
    GetOp,
    MakeOp,
    Transfer,
    TransIntegerType,
)
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
    elif isinstance(mod, FuncOp):
        wrapped = ModuleOp([mod])
        if inline:
            FunctionCallInline(False, get_fns(wrapped)).apply(_ctx, wrapped)
        return wrapped
    else:
        raise ValueError(f"mlir in '{func_name}' is not a ModuleOp")


def get_fns(mod: ModuleOp) -> dict[str, FuncOp]:
    return {x.sym_name.data: x for x in mod.ops if isinstance(x, FuncOp)}


@dataclass
class DomainMLIR:
    top: FuncOp
    meet: FuncOp
    domain_constraint: FuncOp
    instance_constraint: FuncOp

    def __init__(
        self, base_dir: Path, dom: AbstractDomain, prefix: str | None = None
    ) -> None:
        def get_domain_fn(fp: str) -> FuncOp:
            dp = base_dir.joinpath(str(dom), fp)
            func = parse_mlir_func(dp)
            if prefix:
                func.sym_name = StringAttr(f"{prefix}_{func.sym_name.data}")

            return func

        top = get_domain_fn("top.mlir")
        meet = get_domain_fn("meet.mlir")
        domain_constraint = get_domain_fn("get_constraint.mlir")
        instance_constraint = get_domain_fn("get_instance_constraint.mlir")

        self.top = top
        self.meet = meet
        self.domain_constraint = domain_constraint
        self.instance_constraint = instance_constraint


@dataclass
class HelperFuncs:
    conc_ret_ty: TransIntegerType | IntegerType
    conc_arg_ty: tuple[TransIntegerType | IntegerType, ...]
    crt_func: FuncOp
    op_constraint_func: FuncOp | None
    transfer_func: FuncOp
    domain_mlir: dict[AbstractDomain, DomainMLIR]
    top_func: FuncOp
    meet_func: FuncOp
    domain_constraint_func: FuncOp
    instance_constraint_func: FuncOp

    def domain_str(self) -> str:
        return "X".join(d.name for d in self.domain_mlir.keys())

    def all_helper_funcs(self) -> list[FuncOp]:
        if len(self.domain_mlir) == 1:
            d = next(iter(self.domain_mlir.values()))
            return [d.top, d.meet, d.domain_constraint, d.instance_constraint]

        funcs: list[FuncOp] = [
            self.top_func,
            self.meet_func,
            self.domain_constraint_func,
            self.instance_constraint_func,
        ]
        for d in self.domain_mlir.values():
            funcs.extend([d.top, d.meet, d.domain_constraint, d.instance_constraint])

        return funcs


def _build_relational_top(
    per_domain_top: list[FuncOp],
) -> FuncOp:
    assert len(per_domain_top) > 1
    outer_abs_ty = AbstractValueType(
        [fn.function_type.inputs.data[0] for fn in per_domain_top]
    )
    func = FuncOp.from_region("getTop", [outer_abs_ty], [outer_abs_ty])
    block = func.body.block
    arg0 = func.args[0]
    ops: list[Operation] = []
    results = []
    for i, top_fn in enumerate(per_domain_top):
        get_op = GetOp(arg0, i)
        call_op = CallOp(
            top_fn.sym_name.data,
            [get_op.result],
            [top_fn.function_type.outputs.data[0]],
        )
        ops.extend([get_op, call_op])
        results.append(call_op.results[0])
    make_op = MakeOp(results)
    ret_op = ReturnOp(make_op.result)
    block.add_ops(ops + [make_op, ret_op])
    return func


def _build_relational_meet(
    per_domain_meet: list[FuncOp],
) -> FuncOp:
    assert len(per_domain_meet) > 1
    outer_abs_ty = AbstractValueType(
        [fn.function_type.inputs.data[0] for fn in per_domain_meet]
    )
    func = FuncOp.from_region("meet", [outer_abs_ty, outer_abs_ty], [outer_abs_ty])
    block = func.body.block
    arg0, arg1 = func.args
    ops: list[Operation] = []
    results = []
    for i, meet_fn in enumerate(per_domain_meet):
        lhs = GetOp(arg0, i)
        rhs = GetOp(arg1, i)
        call_op = CallOp(
            meet_fn.sym_name.data,
            [lhs.result, rhs.result],
            [meet_fn.function_type.outputs.data[0]],
        )
        ops.extend([lhs, rhs, call_op])
        results.append(call_op.results[0])
    make_op = MakeOp(results)
    ret_op = ReturnOp(make_op.result)
    block.add_ops(ops + [make_op, ret_op])
    return func


def _build_relational_constraint(
    name: str,
    per_domain_fn: list[FuncOp],
) -> FuncOp:
    assert len(per_domain_fn) > 1
    arity = len(per_domain_fn[0].function_type.inputs.data)
    assert arity in (1, 2)
    for fn in per_domain_fn[1:]:
        assert len(fn.function_type.inputs.data) == arity
    outer_abs_ty = AbstractValueType(
        [fn.function_type.inputs.data[0] for fn in per_domain_fn]
    )
    if arity == 1:
        func = FuncOp.from_region(name, [outer_abs_ty], [IntegerType(1)])
        inst_arg = None
    else:
        inst_ty = per_domain_fn[0].function_type.inputs.data[1]
        func = FuncOp.from_region(name, [outer_abs_ty, inst_ty], [IntegerType(1)])
        inst_arg = func.args[1]
    block = func.body.block
    arg0 = func.args[0]
    ops: list[Operation] = []
    bool_results = []
    for i, con_fn in enumerate(per_domain_fn):
        inner = GetOp(arg0, i)
        if inst_arg is None:
            call_op = CallOp(
                con_fn.sym_name.data,
                [inner.result],
                [con_fn.function_type.outputs.data[0]],
            )
        else:
            call_op = CallOp(
                con_fn.sym_name.data,
                [inner.result, inst_arg],
                [con_fn.function_type.outputs.data[0]],
            )
        ops.extend([inner, call_op])
        bool_results.append(call_op.results[0])
    assert len(bool_results) > 0
    combined = bool_results[0]
    for nxt in bool_results[1:]:
        and_op = AndIOp(combined, nxt)
        ops.append(and_op)
        combined = and_op.result
    ret_op = ReturnOp(combined)
    block.add_ops(ops + [ret_op])
    return func


def get_helper_funcs(p: Path, d: AbstractDomain | list[AbstractDomain]) -> HelperFuncs:
    if isinstance(d, AbstractDomain):
        domains = [d]
    else:
        domains = sorted(set(d), key=lambda x: x.name)

    mod = parse_mlir_mod(p, inline=True)
    fns = get_fns(mod)

    assert "concrete_op" in fns
    crt_func = fns["concrete_op"]
    op_con_fn = fns.get("op_constraint", None)

    def get_crt_ty(x: Attribute):
        assert isinstance(x, TransIntegerType) or isinstance(x, IntegerType)
        return x

    assert len(crt_func.function_type.outputs.data) == 1
    crt_ret_ty = get_crt_ty(crt_func.function_type.outputs.data[0])
    crt_arg_ty = tuple(get_crt_ty(x.type) for x in crt_func.args)

    def make_single_domain_abs_ty(
        d: AbstractDomain, concrete_ty: Attribute
    ) -> AbstractValueType:
        if d.const_bw is None:
            return AbstractValueType([concrete_ty for _ in range(d.vec_size)])
        return AbstractValueType([IntegerType(d.const_bw) for _ in range(d.vec_size)])

    def make_relational_abs_ty(concrete_ty: Attribute) -> AbstractValueType:
        inner_abs: list[Attribute] = [
            make_single_domain_abs_ty(d, concrete_ty) for d in domains
        ]
        return AbstractValueType(inner_abs)

    def make_abst_ty(x: Attribute):
        if len(domains) == 1:
            return make_single_domain_abs_ty(domains[0], x)
        return make_relational_abs_ty(x)

    # TODO xfer fn is only ever used as a type to construct a top fn
    xfer_ret = [make_abst_ty(crt_ret_ty)]
    xfer_args = [make_abst_ty(x.type) for x in crt_func.args]
    xfer_fn = FuncOp.from_region("empty_transformer", xfer_args, xfer_ret)

    domain_mlir: dict[AbstractDomain, DomainMLIR] = {}
    base_dir = p.resolve().parent.parent
    for dom in domains:
        prefix = None if len(domains) == 1 else str(dom)
        domain_mlir[dom] = DomainMLIR(base_dir, dom, prefix=prefix)

    if len(domains) == 1:
        composed_top = domain_mlir[domains[0]].top
        composed_meet = domain_mlir[domains[0]].meet
        composed_domain_constraint = domain_mlir[domains[0]].domain_constraint
        composed_instance_constraint = domain_mlir[domains[0]].instance_constraint
    else:
        composed_top = _build_relational_top([domain_mlir[d].top for d in domains])
        composed_meet = _build_relational_meet([domain_mlir[d].meet for d in domains])
        composed_domain_constraint = _build_relational_constraint(
            "getConstraint", [domain_mlir[d].domain_constraint for d in domains]
        )
        composed_instance_constraint = _build_relational_constraint(
            "getInstanceConstraint",
            [domain_mlir[d].instance_constraint for d in domains],
        )

    return HelperFuncs(
        conc_ret_ty=crt_ret_ty,
        conc_arg_ty=crt_arg_ty,
        crt_func=crt_func,
        op_constraint_func=op_con_fn,
        transfer_func=xfer_fn,
        domain_mlir=domain_mlir,
        top_func=composed_top,
        meet_func=composed_meet,
        domain_constraint_func=composed_domain_constraint,
        instance_constraint_func=composed_instance_constraint,
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
