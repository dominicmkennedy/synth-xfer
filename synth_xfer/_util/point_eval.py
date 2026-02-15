from ctypes import CFUNCTYPE, c_uint64
from dataclasses import dataclass
from uuid import uuid4

from llvmlite import ir
from xdsl.dialects.func import FuncOp
from xdsl.ir import Attribute
from xdsl.parser import IntegerType
from xdsl_smt.dialects.transfer import AbstractValueType, TransIntegerType

from synth_xfer._util.jit import Jit
from synth_xfer._util.lower import LowerToLLVM


@dataclass(frozen=True)
class TransferShape:
    arg_lane_bits: tuple[tuple[int, ...], ...]
    ret_lane_bits: tuple[int, ...]


def _get_lane_bitwidth(ty: Attribute, bw: int) -> int:
    if isinstance(ty, TransIntegerType):
        bits = bw
    elif isinstance(ty, IntegerType):
        bits = ty.width.data
    else:
        raise TypeError(f"Expected integer lane type, got: {ty}")

    if bits <= 0 or bits > 64:
        raise ValueError(f"Unsupported lane width: {bits} (expected 1..64)")

    return bits


def _get_abst_lane_bits(ty: Attribute, bw: int) -> tuple[int, ...]:
    if not isinstance(ty, AbstractValueType):
        raise TypeError(f"Expected abstract-value type, got: {ty}")

    return tuple(_get_lane_bitwidth(field, bw) for field in ty.get_fields())


def get_transfer_shape(fn: FuncOp, bw: int) -> TransferShape:
    arg_lane_bits = tuple(_get_abst_lane_bits(arg.type, bw) for arg in fn.args)

    outputs = fn.function_type.outputs.data
    if len(outputs) != 1:
        raise ValueError("Point-eval currently supports exactly one return value")
    ret_lane_bits = _get_abst_lane_bits(outputs[0], bw)

    ret_len = len(ret_lane_bits)
    if any(len(x) != ret_len for x in arg_lane_bits):
        raise ValueError(
            "All abstract-value args/return must have the same vector length"
        )

    return TransferShape(arg_lane_bits=arg_lane_bits, ret_lane_bits=ret_lane_bits)


def _mask_to_bits(v: int, bits: int) -> int:
    return v & ((1 << bits) - 1)


def eval_transfer_point(
    fn: FuncOp, bw: int, args: tuple[tuple[int, ...], ...]
) -> tuple[int, ...]:
    shape = get_transfer_shape(fn, bw)

    if len(args) != len(shape.arg_lane_bits):
        raise ValueError(
            f"Expected {len(shape.arg_lane_bits)} arg(s), got {len(args)} arg(s)"
        )

    masked_args: list[int] = []
    for i, (arg_vals, arg_bits) in enumerate(zip(args, shape.arg_lane_bits)):
        if len(arg_vals) != len(arg_bits):
            raise ValueError(
                f"Arg {i} expects {len(arg_bits)} lane(s), got {len(arg_vals)} lane(s)"
            )
        masked_args.extend(
            _mask_to_bits(v, bits) for v, bits in zip(arg_vals, arg_bits, strict=True)
        )

    uniq = uuid4().hex[:12]
    wrapper_prefix = f"point_eval_{fn.sym_name.data}_{bw}_{uniq}"

    lowerer = LowerToLLVM([bw])
    lowered = lowerer.add_fn(fn, shim=True)[bw]
    jit = Jit()
    jit.add_mod(str(lowerer))

    num_args = len(shape.arg_lane_bits)
    num_lanes = len(shape.ret_lane_bits)
    i64 = ir.IntType(64)
    arr_t = ir.ArrayType(i64, num_lanes)

    wrapper_mod = ir.Module(name=wrapper_prefix)
    callee = ir.Function(
        wrapper_mod, ir.FunctionType(arr_t, [arr_t for _ in range(num_args)]), lowered.name
    )

    flat_arg_types = [i64 for _ in range(num_args * num_lanes)]
    for lane in range(num_lanes):
        fn_name = f"{wrapper_prefix}_lane{lane}"
        wrapper = ir.Function(wrapper_mod, ir.FunctionType(i64, flat_arg_types), fn_name)
        builder = ir.IRBuilder(wrapper.append_basic_block("entry"))

        lowered_args = []
        for arg_idx in range(num_args):
            lowered_arg = ir.Constant(arr_t, None)
            for lane_idx in range(num_lanes):
                flat_idx = arg_idx * num_lanes + lane_idx
                lowered_arg = builder.insert_value(
                    lowered_arg, wrapper.args[flat_idx], lane_idx
                )
            lowered_args.append(lowered_arg)

        call_res = builder.call(callee, lowered_args)
        builder.ret(builder.extract_value(call_res, lane))

    jit.add_mod(str(wrapper_mod))

    c_arg_types = [c_uint64 for _ in masked_args]
    lane_res: list[int] = []
    for lane in range(num_lanes):
        lane_fn_name = f"{wrapper_prefix}_lane{lane}"
        lane_fn_ptr = jit.get_fn_ptr(lane_fn_name)
        lane_fn = CFUNCTYPE(c_uint64, *c_arg_types)(lane_fn_ptr)
        lane_val = lane_fn(*masked_args)
        lane_res.append(_mask_to_bits(int(lane_val), shape.ret_lane_bits[lane]))

    return tuple(lane_res)
