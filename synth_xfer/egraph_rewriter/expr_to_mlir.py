from __future__ import annotations

from typing import Any, Dict, Mapping, Sequence, Tuple

from egglog import Expr
from egglog.declarations import (
    CallDecl,
    ClassMethodRef,
    InitRef,
    LitDecl,
    MethodRef,
    TypedExprDecl,
)
from xdsl.dialects.func import FuncOp, ReturnOp
from xdsl.ir.core import SSAValue
from xdsl_smt.dialects.transfer import (
    AbstractValueType,
    BinOp,
    CmpOp,
    Constant,
    GetAllOnesOp,
    GetOp,
    MakeOp,
    SelectOp,
    UnaryOp,
)

from synth_xfer.egraph_rewriter.datatypes import cmp_predicate_to_fn, mlir_op_to_egraph_op


def _build_op_maps() -> tuple[Mapping[str, type], Mapping[str, type]]:
    """
    Build unary/binary maps directly from the mlir->egraph mapping so we stay
    consistent when either side changes.
    """
    unary: Dict[str, type] = {}
    binary: Dict[str, type] = {}
    for op_cls, func in mlir_op_to_egraph_op.items():
        ref: Any = getattr(func, "__egg_ref__", None)
        if ref is None:
            raise ValueError(f"Missing __egg_ref__ on {func}")
        name = (
            ref.method_name if hasattr(ref, "method_name") else getattr(ref, "name", None)
        )
        if not isinstance(name, str):
            raise ValueError(f"Cannot resolve function name for {func}")
        if op_cls is SelectOp:
            continue
        if issubclass(op_cls, BinOp):
            binary[name] = op_cls
            continue
        if issubclass(op_cls, UnaryOp):
            unary[name] = op_cls
            continue
        raise ValueError(f"Cannot classify op {op_cls} for egraph function '{name}'.")
    return unary, binary


UNARY_OPS, BINARY_OPS = _build_op_maps()
CMP_NAME_TO_PRED: Dict[str, int] = {
    (
        ref.method_name
        if hasattr(ref := getattr(fn, "__egg_ref__", None), "method_name")
        else getattr(ref, "name", None)  # type: ignore[misc]
    ): pred
    for pred, fn in cmp_predicate_to_fn.items()
    if hasattr(fn, "__egg_ref__")
}


class ExprToMLIR:
    """
    Convert the optimized egglog expressions back into a func.func in the
    transfer dialect.
    """

    unary_ops: Mapping[str, type] = UNARY_OPS
    binary_ops: Mapping[str, type] = BINARY_OPS

    def __init__(
        self,
        func: FuncOp,
        new_name: str | None = None,
        cmp_predicates: Mapping[CallDecl, int] | None = None,
    ):
        self.original_func = func
        self.func = FuncOp.from_region(
            new_name or func.sym_name.data,
            func.function_type.inputs.data,
            func.function_type.outputs.data,
        )
        # Preserve custom attributes from the original function (except the symbol name).
        for key, val in func.attributes.items():
            if key == "sym_name":
                continue
            self.func.attributes[key] = val
        self.block = self.func.body.blocks[0]

        self.var_cache: Dict[str, SSAValue] = {}
        self.expr_cache: Dict[object, SSAValue] = {}
        self.default_scalar_type = self._derive_scalar_type()
        self._const_witness: SSAValue | None = None
        # cmp_predicates is kept for backward compatibility but is no longer needed
        # now that each comparison predicate maps to its own BV function.
        self.cmp_predicates: Mapping[CallDecl, int] = cmp_predicates or {}

    def convert(self, ret_exprs: Sequence[Expr]) -> FuncOp:
        self._verify_return_arity(ret_exprs)
        results: list[SSAValue] = []
        for expr in ret_exprs:
            typed_expr = getattr(expr, "__egg_typed_expr__", None)
            if not isinstance(typed_expr, TypedExprDecl):
                raise TypeError(
                    "Expected expression to have a TypedExprDecl at '__egg_typed_expr__'"
                )
            results.append(self._convert_decl(typed_expr))

        make_op = MakeOp(results)
        self.block.add_op(make_op)
        self.block.add_op(ReturnOp(make_op.result))
        return self.func

    def _derive_scalar_type(self):
        out_types = self.original_func.function_type.outputs.data
        if out_types and isinstance(out_types[0], AbstractValueType):
            fields = out_types[0].get_fields()
            if fields:
                return fields[0]

        for arg in self.original_func.args:
            if isinstance(arg.type, AbstractValueType):
                fields = arg.type.get_fields()
                if fields:
                    return fields[0]

        raise ValueError("Cannot determine scalar type from function signature.")

    def _parse_var_name(self, name: str) -> Tuple[int, int]:
        if not name.startswith("arg"):
            raise ValueError(f"Unsupported variable name '{name}'")
        try:
            arg_part, idx_part = name[3:].split("_", 1)
            return int(arg_part), int(idx_part)
        except Exception as exc:  # noqa: BLE001
            raise ValueError(f"Malformed variable name '{name}'") from exc

    def _get_var(self, name: str) -> SSAValue:
        if name in self.var_cache:
            return self.var_cache[name]

        arg_idx, field_idx = self._parse_var_name(name)
        arg_list = list(self.block.args)
        if arg_idx >= len(arg_list):
            raise IndexError(f"Argument {arg_idx} not found in function arguments.")

        get_op = GetOp(arg_list[arg_idx], field_idx)
        self.block.add_op(get_op)
        self.var_cache[name] = get_op.result
        return get_op.result

    def _get_const_witness(self) -> SSAValue:
        if self._const_witness is not None:
            return self._const_witness

        for val in self.var_cache.values():
            if val.type == self.default_scalar_type:
                self._const_witness = val
                return val

        candidate: SSAValue | None = None
        for arg_idx, arg in enumerate(self.block.args):
            if isinstance(arg.type, AbstractValueType):
                for idx, ty in enumerate(arg.type.get_fields()):
                    if ty == self.default_scalar_type:
                        get_op = GetOp(arg, idx)
                        self.block.add_op(get_op)
                        candidate = get_op.result
                        self.var_cache.setdefault(f"arg{arg_idx}_{idx}", candidate)
                        break
            if candidate is not None:
                break

        if candidate is not None:
            self._const_witness = candidate
            return candidate

        raise ValueError("Failed to synthesize a constant witness value.")

    def _verify_return_arity(self, ret_exprs: Sequence[Expr]) -> None:
        outputs = self.original_func.function_type.outputs.data
        if not outputs or not isinstance(outputs[0], AbstractValueType):
            raise ValueError("Expected function to return an AbstractValueType.")

        if len(outputs) != 1:
            raise ValueError("Only single-result functions are supported.")

        expected = len(outputs[0].get_fields())
        if expected != len(ret_exprs):
            raise ValueError(
                f"Return arity mismatch: expected {expected}, got {len(ret_exprs)}."
            )

    def _create_constant(self, value: int) -> SSAValue:
        witness = self._get_const_witness()
        if value == -1:
            all_ones = GetAllOnesOp(witness)
            self.block.add_op(all_ones)
            return all_ones.result
        const_op = Constant(witness, value)
        self.block.add_op(const_op)
        return const_op.result

    def _convert_decl(self, decl: TypedExprDecl) -> SSAValue:
        node = decl.expr
        if node in self.expr_cache:
            return self.expr_cache[node]

        if isinstance(node, LitDecl):
            if not isinstance(node.value, int):
                raise TypeError(
                    f"Literal for Constant must be int, got {type(node.value)}"
                )
            res = self._create_constant(node.value)
        elif isinstance(node, CallDecl):
            res = self._convert_call(node)
        else:
            raise ValueError(f"Unsupported expression node {type(node)}")

        self.expr_cache[node] = res
        return res

    def _convert_call(self, call: CallDecl) -> SSAValue:
        callable = call.callable

        if isinstance(callable, ClassMethodRef) and callable.method_name == "var":
            lit = call.args[0].expr
            assert isinstance(lit, LitDecl)
            if not isinstance(lit.value, str):
                raise TypeError(
                    f"Variable literal should be a string, got {type(lit.value)}"
                )
            return self._get_var(lit.value)

        if isinstance(callable, InitRef):
            lit = call.args[0].expr
            assert isinstance(lit, LitDecl)
            if not isinstance(lit.value, int):
                raise TypeError(
                    f"Literal for Constant must be int, got {type(lit.value)}"
                )
            return self._create_constant(lit.value)

        operands = [self._convert_decl(arg) for arg in call.args]

        method_name = (
            callable.method_name
            if isinstance(callable, (ClassMethodRef, MethodRef))
            else None
        )
        if method_name is None:
            raise ValueError(f"Unsupported callable in expression: {callable}")

        if method_name == "ite":
            assert len(operands) == 3
            op = SelectOp(operands[0], operands[1], operands[2])
        elif method_name in CMP_NAME_TO_PRED:
            assert len(operands) == 2
            pred = CMP_NAME_TO_PRED[method_name]
            op = CmpOp(operands[0], operands[1], pred)
        elif method_name in self.unary_ops:
            assert len(operands) == 1
            op_cls = self.unary_ops[method_name]
            op = op_cls(operands[0])
        elif method_name in self.binary_ops:
            assert len(operands) == 2
            op_cls = self.binary_ops[method_name]
            op = op_cls(operands[0], operands[1])
        else:
            raise ValueError(f"Unsupported BV operation '{method_name}'")

        self.block.add_op(op)
        return op.result
