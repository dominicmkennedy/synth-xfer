from dataclasses import dataclass, field
from typing import Callable

from xdsl.dialects.builtin import StringAttr, i1
from xdsl.dialects.func import CallOp, FuncOp, ReturnOp
from xdsl_smt.dialects.transfer import AbstractValueType, GetOp, MakeOp, SelectOp

from synth_xfer._util.dce import dce


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

    # TODO rewrite this function
    def build(self) -> FuncOp:
        """
        Because select operation only works on TransferIntegertype, so we have to decouple all result obtained from getTop
        and call_body
        The whole function first get top and get all its elements
        Next, it calls body and get all its element
        Finally, it selects element by the condition and returns it

        TODO: Add select support on AbstractValues, so this function can be simplified.
        """

        fn = FuncOp(self.name, self.body.function_type)
        args = fn.args

        if self.cond is None:
            call_op = CallOp(
                self.body.sym_name.data, args, self.body.function_type.outputs.data
            )
            assert len(call_op.results) == 1
            call_res = call_op.results[0]
            return_op = ReturnOp(call_res)
            fn.body.block.add_ops([call_op, return_op])
            return fn

        top_call = CallOp("getTop", [args[0]], self.body.function_type.outputs.data)
        assert len(top_call.results) == 1
        top_res = top_call.results[0]
        top_res_type = top_res.type

        top_elems: list[GetOp] = []
        assert isinstance(top_res_type, AbstractValueType)
        for i in range(top_res_type.get_num_fields()):
            top_elems.append(GetOp(top_res, i))

        body_call = CallOp(
            self.body.sym_name.data, args, self.body.function_type.outputs.data
        )
        assert len(body_call.results) == 1
        body_res = body_call.results[0]
        body_res_type = body_res.type

        body_elems: list[GetOp] = []
        assert body_res_type == top_res_type
        for i in range(top_res_type.get_num_fields()):
            body_elems.append(GetOp(body_res, i))

        selected_elems: list[SelectOp] = []
        cond_call = CallOp(
            self.cond.sym_name.data, args, self.cond.function_type.outputs.data
        )
        assert len(cond_call.results) == 1
        cond_res = cond_call.results[0]

        assert cond_res.type == i1
        for top_elem, body_elem in zip(top_elems, body_elems):
            selected_elems.append(SelectOp(cond_res, body_elem.result, top_elem.result))

        make_op = MakeOp([sel.result for sel in selected_elems])
        return_op = ReturnOp(make_op)
        fn.body.block.add_ops(
            [top_call]
            + top_elems
            + [body_call]
            + body_elems
            + [cond_call]
            + selected_elems
            + [make_op, return_op]
        )
        return fn

    def lower(self, lowerer: Callable[[FuncOp], dict]) -> dict[int, str]:
        lowerer(self.body)
        lowerer(self.cond) if self.cond else None
        lowered_fns = lowerer(self.build(), shim=True)  # type: ignore
        return {bw: x.name for bw, x in lowered_fns.items()}
