from collections.abc import Sequence
from dataclasses import dataclass, field
from typing import Callable

from xdsl.dialects.builtin import StringAttr
from xdsl.dialects.func import CallOp, FuncOp, ReturnOp
from xdsl.ir import Operation, SSAValue
from xdsl_smt.dialects.transfer import AbstractValueType, GetOp, MakeOp, SelectOp

from synth_xfer._util.dce import dce


def _field_wise_select(
    cond: SSAValue, true_val: SSAValue, false_val: SSAValue
) -> tuple[Sequence[Operation], SSAValue]:
    """Field-wise SelectOp on an AbstractValueType. Returns (ops, result)."""
    assert isinstance(true_val.type, AbstractValueType)
    n = true_val.type.get_num_fields()
    true_elems = [GetOp(true_val, i) for i in range(n)]
    false_elems = [GetOp(false_val, i) for i in range(n)]
    selected = [
        SelectOp(cond, t.result, f.result) for t, f in zip(true_elems, false_elems)
    ]
    make = MakeOp([s.result for s in selected])
    return true_elems + false_elems + selected + [make], make.result


@dataclass
class XferFunc:
    """
    A transfer function f in the form of "f(a) := if (cond) then body(a) else Top"
    """

    body: FuncOp
    cond: FuncOp | None = None

    """
    This name is used in generating the whole function.
    """
    name: str = field(init=False)

    def set_name(self, new_name: str):
        self.name = new_name
        self.body.sym_name = StringAttr(f"{new_name}_body")
        if self.cond is not None:
            self.cond.sym_name = StringAttr(f"{new_name}_cond")

    def __str__(self):
        cond_str = "True\n" if self.cond is None else dce(self.cond)
        return f"Cond:\n{cond_str}\nFunc:{dce(self.body)}"

    def build(self) -> FuncOp:
        """Assemble the full guarded transfer function.

        Emits: f(a) = if cond(a) then body(a) else getTop(a)

        SelectOp doesn't support AbstractValueType, so the select is done
        field-wise via Get/Select/Make.
        """
        # TODO: simplify once SelectOp supports AbstractValueType
        body_name = self.body.sym_name.data
        out_types = self.body.function_type.outputs.data

        fn = FuncOp(self.name, self.body.function_type)
        args = fn.args

        if self.cond is None:
            body_call = CallOp(body_name, args, out_types)
            fn.body.block.add_ops([body_call, ReturnOp(body_call.results[0])])
            return fn

        top_call = CallOp("getTop", [args[0]], out_types)
        body_call = CallOp(body_name, args, out_types)
        cond_call = CallOp(
            self.cond.sym_name.data, args, self.cond.function_type.outputs.data
        )

        select_ops, result = _field_wise_select(
            cond_call.results[0], body_call.results[0], top_call.results[0]
        )
        fn.body.block.add_ops(
            [top_call, body_call, cond_call, *select_ops, ReturnOp(result)]
        )
        return fn

    def lower(self, lowerer: Callable[[FuncOp], dict]) -> dict[int, str]:
        lowerer(self.body)
        lowerer(self.cond) if self.cond else None
        lowered_fns = lowerer(self.build(), shim=True)  # type: ignore
        return {bw: x.name for bw, x in lowered_fns.items()}
