from pathlib import Path

from synth_xfer._eval_engine import enum_low_knownbits_4, eval_knownbits_4
from synth_xfer._util.eval_result import get_per_bit
from synth_xfer.jit import Jit, LowerToLLVM, parse_mlir_funcs

# TODO make another file to store perfect xfers
# TODO make tests for lowering of mlir to llvmir and shiming etc
# TODO test domain ops like meet, join, get_instance constraint etc.
# TODO add tests for enum_mid and enum_high

KB_AND = """
"func.func"() ({
  ^0(%lhs : !transfer.abs_value<[!transfer.integer, !transfer.integer]>, %rhs : !transfer.abs_value<[!transfer.integer, !transfer.integer]>):
    %lhs0 = "transfer.get"(%lhs) {index = 0} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %lhs1 = "transfer.get"(%lhs) {index = 1} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %rhs0 = "transfer.get"(%rhs) {index = 0} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %rhs1 = "transfer.get"(%rhs) {index = 1} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %res0 = "transfer.or"(%lhs0, %rhs0) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %res1 = "transfer.and"(%lhs1, %rhs1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %r = "transfer.make"(%res0, %res1) : (!transfer.integer, !transfer.integer) -> !transfer.abs_value<[!transfer.integer, !transfer.integer]>
    "func.return"(%r) : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> ()
}) {"sym_name" = "kb_and", "function_type" = (!transfer.abs_value<[!transfer.integer, !transfer.integer]>, !transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.abs_value<[!transfer.integer, !transfer.integer]>} : () -> ()
"""

KB_OR = """
"func.func"() ({
  ^0(%lhs : !transfer.abs_value<[!transfer.integer, !transfer.integer]>, %rhs : !transfer.abs_value<[!transfer.integer, !transfer.integer]>):
    %lhs0 = "transfer.get"(%lhs) {index = 0} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %lhs1 = "transfer.get"(%lhs) {index = 1} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %rhs0 = "transfer.get"(%rhs) {index = 0} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %rhs1 = "transfer.get"(%rhs) {index = 1} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %res0 = "transfer.and"(%lhs0, %rhs0) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %res1 = "transfer.or"(%lhs1, %rhs1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %r = "transfer.make"(%res0, %res1) : (!transfer.integer, !transfer.integer) -> !transfer.abs_value<[!transfer.integer, !transfer.integer]>
    "func.return"(%r) : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> ()
}) {"sym_name" = "kb_or", "function_type" = (!transfer.abs_value<[!transfer.integer, !transfer.integer]>, !transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.abs_value<[!transfer.integer, !transfer.integer]>} : () -> ()
"""

KB_XOR = """
"func.func"() ({
  ^0(%lhs : !transfer.abs_value<[!transfer.integer, !transfer.integer]>, %rhs : !transfer.abs_value<[!transfer.integer, !transfer.integer]>):
    %lhs0 = "transfer.get"(%lhs) {index = 0} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %lhs1 = "transfer.get"(%lhs) {index = 1} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %rhs0 = "transfer.get"(%rhs) {index = 0} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %rhs1 = "transfer.get"(%rhs) {index = 1} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %and0s = "transfer.and"(%lhs0, %rhs0) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %and1s = "transfer.and"(%lhs1, %rhs1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %and01 = "transfer.and"(%lhs0, %rhs1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %and10 = "transfer.and"(%lhs1, %rhs0) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %res0 = "transfer.or"(%and0s, %and1s) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %res1 = "transfer.or"(%and01, %and10) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %r = "transfer.make"(%res0, %res1) : (!transfer.integer, !transfer.integer) -> !transfer.abs_value<[!transfer.integer, !transfer.integer]>
    "func.return"(%r) : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> ()
}) {"sym_name" = "kb_xor", "function_type" = (!transfer.abs_value<[!transfer.integer, !transfer.integer]>, !transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.abs_value<[!transfer.integer, !transfer.integer]>} : () -> ()
"""


# TODO fix
# import importlib
# import pytest
# @pytest.mark.parametrize(
#     "module_name",
#     [
#         "synth_xfer._eval_engine",
#         "synth_xfer._eval_engine.eval_knownbits_4",
#         "synth_xfer._eval_engine.enum_low_knownbits_4",
#     ],
# )
# def test_imports(module_name):
#     "Make sure the eval engine built corectly"
#     # TODO update with all mods from eval engine
#
#     try:
#         importlib.import_module(module_name)
#     except ImportError as e:
#         pytest.fail(f"Failed to import {module_name}: {e}")


def test_files():
    "Users must have these files on their system for our tool to work"

    assert Path("mlir").is_dir()
    assert Path("mlir", "Operations").is_dir()
    assert Path("mlir", "Operations", "And.mlir").is_file()
    assert Path("mlir", "Operations", "Or.mlir").is_file()
    assert Path("mlir", "Operations", "Xor.mlir").is_file()


def test_lowerings():
    BW = 4
    crt_and_p = Path("mlir", "Operations", "And.mlir")
    crt_or_p = Path("mlir", "Operations", "Or.mlir")
    crt_xor_p = Path("mlir", "Operations", "Xor.mlir")

    crt_and_mlir = parse_mlir_funcs(crt_and_p)[0]
    crt_or_mlir = parse_mlir_funcs(crt_or_p)[0]
    crt_xor_mlir = parse_mlir_funcs(crt_xor_p)[0]
    xfr_and_mlir = parse_mlir_funcs(KB_AND)[0]
    xfr_or_mlir = parse_mlir_funcs(KB_OR)[0]
    xfr_xor_mlir = parse_mlir_funcs(KB_XOR)[0]

    lowerer = LowerToLLVM(BW, "testing_mod")

    crt_and = lowerer.add_fn(crt_and_mlir, "crt_and", True)
    crt_or = lowerer.add_fn(crt_or_mlir, "crt_or", True)
    crt_xor = lowerer.add_fn(crt_xor_mlir, "crt_xor", True)
    xfr_and = lowerer.add_fn(xfr_and_mlir, None, True)
    xfr_or = lowerer.add_fn(xfr_or_mlir, None, True)
    xfr_xor = lowerer.add_fn(xfr_xor_mlir, None, True)

    jit = Jit(lowerer)

    crt_and_ptr = jit.get_fn_ptr(crt_and)
    crt_or_ptr = jit.get_fn_ptr(crt_or)
    crt_xor_ptr = jit.get_fn_ptr(crt_xor)
    xfr_and_ptr = jit.get_fn_ptr(xfr_and)
    xfr_or_ptr = jit.get_fn_ptr(xfr_or)
    xfr_xor_ptr = jit.get_fn_ptr(xfr_xor)

    to_eval_and = enum_low_knownbits_4(crt_and_ptr)
    to_eval_or = enum_low_knownbits_4(crt_or_ptr)
    to_eval_xor = enum_low_knownbits_4(crt_xor_ptr)

    and_res = eval_knownbits_4(to_eval_and, [xfr_and_ptr, xfr_or_ptr, xfr_xor_ptr], [])
    or_res = eval_knownbits_4(to_eval_or, [xfr_and_ptr, xfr_or_ptr, xfr_xor_ptr], [])
    xor_res = eval_knownbits_4(to_eval_xor, [xfr_and_ptr, xfr_or_ptr, xfr_xor_ptr], [])
    
    and_per_bit = get_per_bit(and_res)
    assert len(and_per_bit) == 3
    assert str(and_per_bit[0]).strip() == "bw: 4  all: 6561  s: 6561  e: 6561  uall: 6480  ue: 6480  dis: 0       bdis: 4374.0  sdis: 0"
    assert str(and_per_bit[1]).strip() == "bw: 4  all: 6561  s: 625   e: 81    uall: 6480  ue: 80    dis: 5832    bdis: 4374.0  sdis: 4124"
    assert str(and_per_bit[2]).strip() == "bw: 4  all: 6561  s: 1296  e: 256   uall: 6480  ue: 175   dis: 5832    bdis: 4374.0  sdis: 4158"
    
    or_per_bit = get_per_bit(or_res)
    assert len(or_per_bit) == 3
    assert str(or_per_bit[0]).strip() == "bw: 4  all: 6561  s: 625   e: 81    uall: 6480  ue: 80    dis: 5832    bdis: 4374.0  sdis: 4124"
    assert str(or_per_bit[1]).strip() == "bw: 4  all: 6561  s: 6561  e: 6561  uall: 6480  ue: 6480  dis: 0       bdis: 4374.0  sdis: 0"
    assert str(or_per_bit[2]).strip() == "bw: 4  all: 6561  s: 4096  e: 1296  uall: 6480  ue: 1215  dis: 2916    bdis: 4374.0  sdis: 2838"
    
    xor_per_bit = get_per_bit(xor_res)
    assert len(xor_per_bit) == 3
    assert str(xor_per_bit[0]).strip() == "bw: 4  all: 6561  s: 256   e: 256   uall: 5936  ue: 175   dis: 5832    bdis: 2916.0  sdis: 2852"
    assert str(xor_per_bit[1]).strip() == "bw: 4  all: 6561  s: 1296  e: 1296  uall: 5936  ue: 1215  dis: 2916    bdis: 2916.0  sdis: 2268"
    assert str(xor_per_bit[2]).strip() == "bw: 4  all: 6561  s: 6561  e: 6561  uall: 5936  ue: 5936  dis: 0       bdis: 2916.0  sdis: 0"
