## Task: Extract a reusable library from KnownBits transfer functions

You are given a set of synthesized KnownBits transfer functions in MLIR. Your goal is to identify reusable sub-computations across them and factor these out as named helper functions in a library module.

## Background: KnownBits representation

Each abstract value is a 2-element container `!transfer.abs_value<[!transfer.integer, !transfer.integer]>`:
- element **0**: known-zero mask — a bit set here means that bit is definitely 0
- element **1**: known-one mask — a bit set here means that bit is definitely 1

The complement of known-zero gives the "maybe-one" mask; the complement of known-one gives the "maybe-zero" mask.

## Synthesized transfer functions (inputs)


builtin.module {
  func.func @partial_solution_0_body(%0 : !transfer.abs_value<[!transfer.integer, !transfer.integer]>, %1 : !transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.abs_value<[!transfer.integer, !transfer.integer]> attributes {from_weighted_dsl, number = "0_264_38"} {
    %2 = "transfer.get"(%0) {index = 0 : index} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %3 = "transfer.get"(%0) {index = 1 : index} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %4 = "transfer.get"(%1) {index = 0 : index} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %5 = "transfer.get"(%1) {index = 1 : index} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %6 = "transfer.constant"(%5) {value = 0 : index} : (!transfer.integer) -> !transfer.integer
    %7 = "transfer.get_bit_width"(%5) : (!transfer.integer) -> !transfer.integer
    %8 = "transfer.cmp"(%7, %4) {predicate = 6 : index} : (!transfer.integer, !transfer.integer) -> i1
    %9 = "transfer.shl"(%2, %7) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %10 = "transfer.select"(%8, %2, %6) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %11 = "transfer.countr_one"(%7) : (!transfer.integer) -> !transfer.integer
    %12 = "transfer.neg"(%11) : (!transfer.integer) -> !transfer.integer
    %13 = "transfer.set_sign_bit"(%9) : (!transfer.integer) -> !transfer.integer
    %14 = "transfer.select"(%8, %3, %10) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %15 = "transfer.smax"(%5, %14) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %16 = "transfer.umin"(%12, %15) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %17 = "transfer.and"(%10, %13) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %18 = "transfer.make"(%17, %16) : (!transfer.integer, !transfer.integer) -> !transfer.abs_value<[!transfer.integer, !transfer.integer]>
    func.return %18 : !transfer.abs_value<[!transfer.integer, !transfer.integer]>
  }
  func.func @partial_solution_1_body(%0 : !transfer.abs_value<[!transfer.integer, !transfer.integer]>, %1 : !transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.abs_value<[!transfer.integer, !transfer.integer]> attributes {from_weighted_dsl, number = "0_289_20"} {
    %2 = "transfer.get"(%0) {index = 0 : index} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %3 = "transfer.get"(%1) {index = 0 : index} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %4 = "transfer.get"(%1) {index = 1 : index} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %5 = "transfer.constant"(%4) {value = 0 : index} : (!transfer.integer) -> !transfer.integer
    %6 = "transfer.constant"(%4) {value = 1 : index} : (!transfer.integer) -> !transfer.integer
    %7 = "transfer.get_bit_width"(%4) : (!transfer.integer) -> !transfer.integer
    %8 = "transfer.cmp"(%7, %2) {predicate = 6 : index} : (!transfer.integer, !transfer.integer) -> i1
    %9 = "transfer.lshr"(%6, %7) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %10 = "transfer.umax"(%4, %3) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %11 = "transfer.smin"(%4, %10) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %12 = "transfer.set_sign_bit"(%5) : (!transfer.integer) -> !transfer.integer
    %13 = "transfer.select"(%8, %12, %9) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %14 = "transfer.clear_sign_bit"(%4) : (!transfer.integer) -> !transfer.integer
    %15 = "transfer.and"(%11, %13) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %16 = "transfer.make"(%15, %14) : (!transfer.integer, !transfer.integer) -> !transfer.abs_value<[!transfer.integer, !transfer.integer]>
    func.return %16 : !transfer.abs_value<[!transfer.integer, !transfer.integer]>
  }
  func.func @partial_solution_1_cond(%0 : !transfer.abs_value<[!transfer.integer, !transfer.integer]>, %1 : !transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> i1 attributes {number = "1_238_39"} {
    %2 = "transfer.get"(%0) {index = 0 : index} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %3 = "transfer.get"(%1) {index = 0 : index} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %4 = "transfer.get"(%1) {index = 1 : index} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %5 = "transfer.get_all_ones"(%4) : (!transfer.integer) -> !transfer.integer
    %6 = "transfer.urem"(%4, %2) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %7 = "transfer.cmp"(%6, %3) {predicate = 6 : index} : (!transfer.integer, !transfer.integer) -> i1
    %8 = "transfer.cmp"(%4, %5) {predicate = 6 : index} : (!transfer.integer, !transfer.integer) -> i1
    %9 = "transfer.cmp"(%6, %3) {predicate = 7 : index} : (!transfer.integer, !transfer.integer) -> i1
    %10 = arith.andi %9, %7 : i1
    %11 = arith.xori %10, %8 : i1
    func.return %11 : i1
  }
  func.func @partial_solution_2_body(%0 : !transfer.abs_value<[!transfer.integer, !transfer.integer]>, %1 : !transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.abs_value<[!transfer.integer, !transfer.integer]> attributes {number = "0_39_3"} {
    %2 = "transfer.get"(%0) {index = 0 : index} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %3 = "transfer.get"(%0) {index = 1 : index} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %4 = "transfer.get"(%1) {index = 1 : index} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %5 = "transfer.constant"(%4) {value = 0 : index} : (!transfer.integer) -> !transfer.integer
    %6 = "transfer.constant"(%4) {value = 1 : index} : (!transfer.integer) -> !transfer.integer
    %7 = "transfer.get_all_ones"(%4) : (!transfer.integer) -> !transfer.integer
    %8 = "transfer.get_bit_width"(%4) : (!transfer.integer) -> !transfer.integer
    %9 = "transfer.cmp"(%7, %2) {predicate = 6 : index} : (!transfer.integer, !transfer.integer) -> i1
    %10 = "transfer.clear_high_bits"(%2, %8) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %11 = "transfer.select"(%9, %5, %6) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %12 = "transfer.mul"(%10, %4) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %13 = "transfer.clear_sign_bit"(%3) : (!transfer.integer) -> !transfer.integer
    %14 = "transfer.shl"(%13, %12) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %15 = "transfer.countl_one"(%11) : (!transfer.integer) -> !transfer.integer
    %16 = "transfer.make"(%15, %14) : (!transfer.integer, !transfer.integer) -> !transfer.abs_value<[!transfer.integer, !transfer.integer]>
    func.return %16 : !transfer.abs_value<[!transfer.integer, !transfer.integer]>
  }
  func.func @partial_solution_2_cond(%0 : !transfer.abs_value<[!transfer.integer, !transfer.integer]>, %1 : !transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> i1 attributes {number = "1_221_22"} {
    %2 = "transfer.get"(%0) {index = 0 : index} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %3 = "transfer.neg"(%2) : (!transfer.integer) -> !transfer.integer
    %4 = "transfer.cmp"(%2, %3) {predicate = 7 : index} : (!transfer.integer, !transfer.integer) -> i1
    %5 = arith.ori %4, %4 : i1
    %6 = arith.xori %5, %4 : i1
    %7 = arith.xori %4, %6 : i1
    func.return %7 : i1
  }
  func.func @partial_solution_3_body(%0 : !transfer.abs_value<[!transfer.integer, !transfer.integer]>, %1 : !transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.abs_value<[!transfer.integer, !transfer.integer]> attributes {number = "0_181_8"} {
    %2 = "transfer.get"(%0) {index = 0 : index} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %3 = "transfer.get"(%0) {index = 1 : index} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %4 = "transfer.get"(%1) {index = 1 : index} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %5 = "transfer.constant"(%4) {value = 1 : index} : (!transfer.integer) -> !transfer.integer
    %6 = "transfer.get_bit_width"(%4) : (!transfer.integer) -> !transfer.integer
    %7 = "transfer.xor"(%2, %5) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %8 = "transfer.clear_sign_bit"(%4) : (!transfer.integer) -> !transfer.integer
    %9 = "transfer.shl"(%6, %7) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %10 = "transfer.countl_one"(%9) : (!transfer.integer) -> !transfer.integer
    %11 = "transfer.clear_sign_bit"(%10) : (!transfer.integer) -> !transfer.integer
    %12 = "transfer.or"(%4, %3) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %13 = "transfer.smax"(%12, %8) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %14 = "transfer.clear_high_bits"(%13, %11) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %15 = "transfer.set_sign_bit"(%10) : (!transfer.integer) -> !transfer.integer
    %16 = "transfer.make"(%15, %14) : (!transfer.integer, !transfer.integer) -> !transfer.abs_value<[!transfer.integer, !transfer.integer]>
    func.return %16 : !transfer.abs_value<[!transfer.integer, !transfer.integer]>
  }
  func.func @partial_solution_4_body(%0 : !transfer.abs_value<[!transfer.integer, !transfer.integer]>, %1 : !transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.abs_value<[!transfer.integer, !transfer.integer]> attributes {number = "0_219_17"} {
    %2 = "transfer.get"(%0) {index = 1 : index} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %3 = "transfer.get"(%1) {index = 0 : index} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %4 = "transfer.get"(%1) {index = 1 : index} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %5 = "transfer.constant"(%4) {value = 0 : index} : (!transfer.integer) -> !transfer.integer
    %6 = "transfer.get_bit_width"(%4) : (!transfer.integer) -> !transfer.integer
    %7 = "transfer.set_sign_bit"(%5) : (!transfer.integer) -> !transfer.integer
    %8 = "transfer.umax"(%3, %7) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %9 = "transfer.srem"(%5, %3) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %10 = "transfer.smax"(%8, %3) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %11 = "transfer.lshr"(%2, %6) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %12 = "transfer.udiv"(%3, %9) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %13 = "transfer.urem"(%11, %5) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %14 = "transfer.set_sign_bit"(%13) : (!transfer.integer) -> !transfer.integer
    %15 = "transfer.umin"(%12, %4) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %16 = "transfer.and"(%10, %14) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %17 = "transfer.make"(%16, %15) : (!transfer.integer, !transfer.integer) -> !transfer.abs_value<[!transfer.integer, !transfer.integer]>
    func.return %17 : !transfer.abs_value<[!transfer.integer, !transfer.integer]>
  }
  func.func @partial_solution_4_cond(%0 : !transfer.abs_value<[!transfer.integer, !transfer.integer]>, %1 : !transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> i1 attributes {number = "1_111_18"} {
    %2 = "transfer.get"(%0) {index = 1 : index} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %3 = "transfer.get"(%1) {index = 0 : index} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %4 = "transfer.cmp"(%3, %2) {predicate = 6 : index} : (!transfer.integer, !transfer.integer) -> i1
    %5 = arith.ori %4, %4 : i1
    %6 = arith.andi %5, %4 : i1
    func.return %6 : i1
  }
  func.func @partial_solution_5_body(%0 : !transfer.abs_value<[!transfer.integer, !transfer.integer]>, %1 : !transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.abs_value<[!transfer.integer, !transfer.integer]> attributes {from_weighted_dsl, number = "0_285_37"} {
    %2 = "transfer.get"(%0) {index = 0 : index} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %3 = "transfer.get"(%0) {index = 1 : index} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %4 = "transfer.get"(%1) {index = 0 : index} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %5 = "transfer.get"(%1) {index = 1 : index} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %6 = "transfer.constant"(%5) {value = 1 : index} : (!transfer.integer) -> !transfer.integer
    %7 = "transfer.get_bit_width"(%5) : (!transfer.integer) -> !transfer.integer
    %8 = "transfer.neg"(%2) : (!transfer.integer) -> !transfer.integer
    %9 = "transfer.countl_zero"(%8) : (!transfer.integer) -> !transfer.integer
    %10 = "transfer.add"(%2, %9) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %11 = "transfer.countr_zero"(%10) : (!transfer.integer) -> !transfer.integer
    %12 = "transfer.smin"(%4, %8) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %13 = "transfer.set_low_bits"(%7, %11) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %14 = "transfer.clear_high_bits"(%3, %6) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %15 = "transfer.clear_low_bits"(%12, %6) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %16 = "transfer.clear_high_bits"(%11, %13) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %17 = "transfer.umax"(%16, %14) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %18 = "transfer.and"(%15, %2) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %19 = "transfer.make"(%18, %17) : (!transfer.integer, !transfer.integer) -> !transfer.abs_value<[!transfer.integer, !transfer.integer]>
    func.return %19 : !transfer.abs_value<[!transfer.integer, !transfer.integer]>
  }
  func.func @partial_solution_5_cond(%0 : !transfer.abs_value<[!transfer.integer, !transfer.integer]>, %1 : !transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> i1 attributes {number = "1_30_11"} {
    %2 = "transfer.get"(%0) {index = 0 : index} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %3 = "transfer.get"(%0) {index = 1 : index} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %4 = "transfer.ashr"(%3, %3) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %5 = "transfer.cmp"(%2, %4) {predicate = 0 : index} : (!transfer.integer, !transfer.integer) -> i1
    %6 = arith.ori %5, %5 : i1
    %7 = arith.xori %5, %6 : i1
    %8 = arith.xori %7, %6 : i1
    func.return %8 : i1
  }
  func.func @partial_solution_0(%0 : !transfer.abs_value<[!transfer.integer, !transfer.integer]>, %1 : !transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.abs_value<[!transfer.integer, !transfer.integer]> {
    %2 = func.call @partial_solution_0_body(%0, %1) : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>, !transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.abs_value<[!transfer.integer, !transfer.integer]>
    func.return %2 : !transfer.abs_value<[!transfer.integer, !transfer.integer]>
  }
  func.func @partial_solution_1(%0 : !transfer.abs_value<[!transfer.integer, !transfer.integer]>, %1 : !transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.abs_value<[!transfer.integer, !transfer.integer]> {
    %2 = func.call @getTop(%0) : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.abs_value<[!transfer.integer, !transfer.integer]>
    %3 = "transfer.get"(%2) {index = 0 : index} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %4 = "transfer.get"(%2) {index = 1 : index} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %5 = func.call @partial_solution_1_body(%0, %1) : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>, !transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.abs_value<[!transfer.integer, !transfer.integer]>
    %6 = "transfer.get"(%5) {index = 0 : index} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %7 = "transfer.get"(%5) {index = 1 : index} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %8 = func.call @partial_solution_1_cond(%0, %1) : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>, !transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> i1
    %9 = "transfer.select"(%8, %6, %3) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %10 = "transfer.select"(%8, %7, %4) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %11 = "transfer.make"(%9, %10) : (!transfer.integer, !transfer.integer) -> !transfer.abs_value<[!transfer.integer, !transfer.integer]>
    func.return %11 : !transfer.abs_value<[!transfer.integer, !transfer.integer]>
  }
  func.func @partial_solution_2(%0 : !transfer.abs_value<[!transfer.integer, !transfer.integer]>, %1 : !transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.abs_value<[!transfer.integer, !transfer.integer]> {
    %2 = func.call @getTop(%0) : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.abs_value<[!transfer.integer, !transfer.integer]>
    %3 = "transfer.get"(%2) {index = 0 : index} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %4 = "transfer.get"(%2) {index = 1 : index} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %5 = func.call @partial_solution_2_body(%0, %1) : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>, !transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.abs_value<[!transfer.integer, !transfer.integer]>
    %6 = "transfer.get"(%5) {index = 0 : index} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %7 = "transfer.get"(%5) {index = 1 : index} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %8 = func.call @partial_solution_2_cond(%0, %1) : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>, !transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> i1
    %9 = "transfer.select"(%8, %6, %3) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %10 = "transfer.select"(%8, %7, %4) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %11 = "transfer.make"(%9, %10) : (!transfer.integer, !transfer.integer) -> !transfer.abs_value<[!transfer.integer, !transfer.integer]>
    func.return %11 : !transfer.abs_value<[!transfer.integer, !transfer.integer]>
  }
  func.func @partial_solution_3(%0 : !transfer.abs_value<[!transfer.integer, !transfer.integer]>, %1 : !transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.abs_value<[!transfer.integer, !transfer.integer]> {
    %2 = func.call @partial_solution_3_body(%0, %1) : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>, !transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.abs_value<[!transfer.integer, !transfer.integer]>
    func.return %2 : !transfer.abs_value<[!transfer.integer, !transfer.integer]>
  }
  func.func @partial_solution_4(%0 : !transfer.abs_value<[!transfer.integer, !transfer.integer]>, %1 : !transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.abs_value<[!transfer.integer, !transfer.integer]> {
    %2 = func.call @getTop(%0) : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.abs_value<[!transfer.integer, !transfer.integer]>
    %3 = "transfer.get"(%2) {index = 0 : index} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %4 = "transfer.get"(%2) {index = 1 : index} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %5 = func.call @partial_solution_4_body(%0, %1) : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>, !transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.abs_value<[!transfer.integer, !transfer.integer]>
    %6 = "transfer.get"(%5) {index = 0 : index} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %7 = "transfer.get"(%5) {index = 1 : index} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %8 = func.call @partial_solution_4_cond(%0, %1) : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>, !transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> i1
    %9 = "transfer.select"(%8, %6, %3) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %10 = "transfer.select"(%8, %7, %4) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %11 = "transfer.make"(%9, %10) : (!transfer.integer, !transfer.integer) -> !transfer.abs_value<[!transfer.integer, !transfer.integer]>
    func.return %11 : !transfer.abs_value<[!transfer.integer, !transfer.integer]>
  }
  func.func @partial_solution_5(%0 : !transfer.abs_value<[!transfer.integer, !transfer.integer]>, %1 : !transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.abs_value<[!transfer.integer, !transfer.integer]> {
    %2 = func.call @getTop(%0) : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.abs_value<[!transfer.integer, !transfer.integer]>
    %3 = "transfer.get"(%2) {index = 0 : index} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %4 = "transfer.get"(%2) {index = 1 : index} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %5 = func.call @partial_solution_5_body(%0, %1) : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>, !transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.abs_value<[!transfer.integer, !transfer.integer]>
    %6 = "transfer.get"(%5) {index = 0 : index} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %7 = "transfer.get"(%5) {index = 1 : index} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %8 = func.call @partial_solution_5_cond(%0, %1) : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>, !transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> i1
    %9 = "transfer.select"(%8, %6, %3) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %10 = "transfer.select"(%8, %7, %4) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %11 = "transfer.make"(%9, %10) : (!transfer.integer, !transfer.integer) -> !transfer.abs_value<[!transfer.integer, !transfer.integer]>
    func.return %11 : !transfer.abs_value<[!transfer.integer, !transfer.integer]>
  }
  func.func @solution(%0 : !transfer.abs_value<[!transfer.integer, !transfer.integer]>, %1 : !transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.abs_value<[!transfer.integer, !transfer.integer]> {
    %2 = func.call @partial_solution_0(%0, %1) : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>, !transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.abs_value<[!transfer.integer, !transfer.integer]>
    %3 = func.call @partial_solution_1(%0, %1) : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>, !transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.abs_value<[!transfer.integer, !transfer.integer]>
    %4 = func.call @partial_solution_2(%0, %1) : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>, !transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.abs_value<[!transfer.integer, !transfer.integer]>
    %5 = func.call @partial_solution_3(%0, %1) : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>, !transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.abs_value<[!transfer.integer, !transfer.integer]>
    %6 = func.call @partial_solution_4(%0, %1) : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>, !transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.abs_value<[!transfer.integer, !transfer.integer]>
    %7 = func.call @partial_solution_5(%0, %1) : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>, !transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.abs_value<[!transfer.integer, !transfer.integer]>
    %8 = func.call @meet(%2, %3) : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>, !transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.abs_value<[!transfer.integer, !transfer.integer]>
    %9 = func.call @meet(%8, %4) : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>, !transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.abs_value<[!transfer.integer, !transfer.integer]>
    %10 = func.call @meet(%9, %5) : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>, !transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.abs_value<[!transfer.integer, !transfer.integer]>
    %11 = func.call @meet(%10, %6) : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>, !transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.abs_value<[!transfer.integer, !transfer.integer]>
    %12 = func.call @meet(%11, %7) : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>, !transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.abs_value<[!transfer.integer, !transfer.integer]>
    func.return %12 : !transfer.abs_value<[!transfer.integer, !transfer.integer]>
  }
  func.func @b_partial_solution_0_body(%0 : !transfer.abs_value<[!transfer.integer, !transfer.integer]>, %1 : !transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.abs_value<[!transfer.integer, !transfer.integer]> attributes {number = "0_95_8"} {
    %2 = "transfer.get"(%0) {index = 1 : index} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %3 = "transfer.get"(%1) {index = 1 : index} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %4 = "transfer.constant"(%3) {value = 1 : index} : (!transfer.integer) -> !transfer.integer
    %5 = "transfer.get_bit_width"(%3) : (!transfer.integer) -> !transfer.integer
    %6 = "transfer.udiv"(%3, %4) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %7 = "transfer.popcount"(%2) : (!transfer.integer) -> !transfer.integer
    %8 = "transfer.clear_sign_bit"(%2) : (!transfer.integer) -> !transfer.integer
    %9 = "transfer.clear_high_bits"(%3, %7) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %10 = "transfer.countl_zero"(%5) : (!transfer.integer) -> !transfer.integer
    %11 = "transfer.shl"(%3, %9) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %12 = "transfer.smax"(%6, %8) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %13 = "transfer.srem"(%11, %10) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %14 = "transfer.make"(%13, %12) : (!transfer.integer, !transfer.integer) -> !transfer.abs_value<[!transfer.integer, !transfer.integer]>
    func.return %14 : !transfer.abs_value<[!transfer.integer, !transfer.integer]>
  }
  func.func @b_partial_solution_0_cond(%0 : !transfer.abs_value<[!transfer.integer, !transfer.integer]>, %1 : !transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> i1 attributes {number = "1_96_44"} {
    %2 = "transfer.get"(%0) {index = 0 : index} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %3 = "transfer.get"(%1) {index = 0 : index} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %4 = "transfer.get"(%1) {index = 1 : index} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %5 = "transfer.get_all_ones"(%4) : (!transfer.integer) -> !transfer.integer
    %6 = "transfer.clear_sign_bit"(%5) : (!transfer.integer) -> !transfer.integer
    %7 = "transfer.cmp"(%3, %6) {predicate = 7 : index} : (!transfer.integer, !transfer.integer) -> i1
    %8 = "transfer.cmp"(%3, %2) {predicate = 6 : index} : (!transfer.integer, !transfer.integer) -> i1
    %9 = arith.andi %8, %7 : i1
    %10 = "transfer.umin"(%6, %3) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %11 = "transfer.cmp"(%2, %10) {predicate = 6 : index} : (!transfer.integer, !transfer.integer) -> i1
    %12 = arith.xori %11, %9 : i1
    func.return %12 : i1
  }
  func.func @b_partial_solution_1_body(%0 : !transfer.abs_value<[!transfer.integer, !transfer.integer]>, %1 : !transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.abs_value<[!transfer.integer, !transfer.integer]> attributes {number = "1_155_3"} {
    %2 = "transfer.get"(%0) {index = 1 : index} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %3 = "transfer.get"(%1) {index = 1 : index} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %4 = "transfer.constant"(%3) {value = 0 : index} : (!transfer.integer) -> !transfer.integer
    %5 = "transfer.get_all_ones"(%3) : (!transfer.integer) -> !transfer.integer
    %6 = "transfer.get_bit_width"(%3) : (!transfer.integer) -> !transfer.integer
    %7 = "transfer.mul"(%5, %5) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %8 = "transfer.umax"(%2, %2) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %9 = "transfer.smin"(%7, %5) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %10 = "transfer.or"(%6, %9) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %11 = "transfer.and"(%10, %3) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %12 = "transfer.cmp"(%5, %9) {predicate = 7 : index} : (!transfer.integer, !transfer.integer) -> i1
    %13 = "transfer.select"(%12, %8, %6) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %14 = "transfer.smax"(%11, %13) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %15 = "transfer.set_sign_bit"(%4) : (!transfer.integer) -> !transfer.integer
    %16 = "transfer.make"(%15, %14) : (!transfer.integer, !transfer.integer) -> !transfer.abs_value<[!transfer.integer, !transfer.integer]>
    func.return %16 : !transfer.abs_value<[!transfer.integer, !transfer.integer]>
  }
  func.func @b_partial_solution_2_body(%0 : !transfer.abs_value<[!transfer.integer, !transfer.integer]>, %1 : !transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.abs_value<[!transfer.integer, !transfer.integer]> attributes {from_weighted_dsl, number = "0_125_41"} {
    %2 = "transfer.get"(%1) {index = 0 : index} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %3 = "transfer.get"(%1) {index = 1 : index} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %4 = "transfer.lshr"(%2, %2) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %5 = "transfer.clear_sign_bit"(%3) : (!transfer.integer) -> !transfer.integer
    %6 = "transfer.smin"(%4, %2) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %7 = "transfer.make"(%6, %5) : (!transfer.integer, !transfer.integer) -> !transfer.abs_value<[!transfer.integer, !transfer.integer]>
    func.return %7 : !transfer.abs_value<[!transfer.integer, !transfer.integer]>
  }
  func.func @b_partial_solution_2_cond(%0 : !transfer.abs_value<[!transfer.integer, !transfer.integer]>, %1 : !transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> i1 attributes {number = "1_69_22"} {
    %2 = "transfer.get"(%1) {index = 0 : index} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %3 = "transfer.get"(%1) {index = 1 : index} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %4 = "transfer.constant"(%3) {value = 1 : index} : (!transfer.integer) -> !transfer.integer
    %5 = "transfer.get_bit_width"(%3) : (!transfer.integer) -> !transfer.integer
    %6 = "transfer.smax"(%5, %2) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %7 = "transfer.sdiv"(%2, %4) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %8 = "transfer.cmp"(%7, %6) {predicate = 7 : index} : (!transfer.integer, !transfer.integer) -> i1
    func.return %8 : i1
  }
  func.func @b_partial_solution_3_body(%0 : !transfer.abs_value<[!transfer.integer, !transfer.integer]>, %1 : !transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.abs_value<[!transfer.integer, !transfer.integer]> attributes {number = "0_187_4"} {
    %2 = "transfer.get"(%0) {index = 0 : index} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %3 = "transfer.get"(%1) {index = 0 : index} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %4 = "transfer.get"(%1) {index = 1 : index} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %5 = "transfer.constant"(%4) {value = 1 : index} : (!transfer.integer) -> !transfer.integer
    %6 = "transfer.get_all_ones"(%4) : (!transfer.integer) -> !transfer.integer
    %7 = "transfer.get_bit_width"(%4) : (!transfer.integer) -> !transfer.integer
    %8 = "transfer.clear_high_bits"(%6, %5) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %9 = "transfer.neg"(%8) : (!transfer.integer) -> !transfer.integer
    %10 = "transfer.set_low_bits"(%4, %3) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %11 = "transfer.add"(%10, %2) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %12 = "transfer.ashr"(%5, %7) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %13 = "transfer.add"(%9, %12) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %14 = "transfer.and"(%2, %13) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %15 = "transfer.ashr"(%8, %12) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %16 = "transfer.smin"(%14, %11) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %17 = "transfer.make"(%16, %15) : (!transfer.integer, !transfer.integer) -> !transfer.abs_value<[!transfer.integer, !transfer.integer]>
    func.return %17 : !transfer.abs_value<[!transfer.integer, !transfer.integer]>
  }
  func.func @b_partial_solution_0(%0 : !transfer.abs_value<[!transfer.integer, !transfer.integer]>, %1 : !transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.abs_value<[!transfer.integer, !transfer.integer]> {
    %2 = func.call @getTop(%0) : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.abs_value<[!transfer.integer, !transfer.integer]>
    %3 = "transfer.get"(%2) {index = 0 : index} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %4 = "transfer.get"(%2) {index = 1 : index} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %5 = func.call @b_partial_solution_0_body(%0, %1) : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>, !transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.abs_value<[!transfer.integer, !transfer.integer]>
    %6 = "transfer.get"(%5) {index = 0 : index} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %7 = "transfer.get"(%5) {index = 1 : index} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %8 = func.call @b_partial_solution_0_cond(%0, %1) : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>, !transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> i1
    %9 = "transfer.select"(%8, %6, %3) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %10 = "transfer.select"(%8, %7, %4) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %11 = "transfer.make"(%9, %10) : (!transfer.integer, !transfer.integer) -> !transfer.abs_value<[!transfer.integer, !transfer.integer]>
    func.return %11 : !transfer.abs_value<[!transfer.integer, !transfer.integer]>
  }
  func.func @b_partial_solution_1(%0 : !transfer.abs_value<[!transfer.integer, !transfer.integer]>, %1 : !transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.abs_value<[!transfer.integer, !transfer.integer]> {
    %2 = func.call @b_partial_solution_1_body(%0, %1) : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>, !transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.abs_value<[!transfer.integer, !transfer.integer]>
    func.return %2 : !transfer.abs_value<[!transfer.integer, !transfer.integer]>
  }
  func.func @b_partial_solution_2(%0 : !transfer.abs_value<[!transfer.integer, !transfer.integer]>, %1 : !transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.abs_value<[!transfer.integer, !transfer.integer]> {
    %2 = func.call @getTop(%0) : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.abs_value<[!transfer.integer, !transfer.integer]>
    %3 = "transfer.get"(%2) {index = 0 : index} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %4 = "transfer.get"(%2) {index = 1 : index} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %5 = func.call @b_partial_solution_2_body(%0, %1) : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>, !transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.abs_value<[!transfer.integer, !transfer.integer]>
    %6 = "transfer.get"(%5) {index = 0 : index} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %7 = "transfer.get"(%5) {index = 1 : index} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %8 = func.call @b_partial_solution_2_cond(%0, %1) : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>, !transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> i1
    %9 = "transfer.select"(%8, %6, %3) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %10 = "transfer.select"(%8, %7, %4) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %11 = "transfer.make"(%9, %10) : (!transfer.integer, !transfer.integer) -> !transfer.abs_value<[!transfer.integer, !transfer.integer]>
    func.return %11 : !transfer.abs_value<[!transfer.integer, !transfer.integer]>
  }
  func.func @b_partial_solution_3(%0 : !transfer.abs_value<[!transfer.integer, !transfer.integer]>, %1 : !transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.abs_value<[!transfer.integer, !transfer.integer]> {
    %2 = func.call @b_partial_solution_3_body(%0, %1) : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>, !transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.abs_value<[!transfer.integer, !transfer.integer]>
    func.return %2 : !transfer.abs_value<[!transfer.integer, !transfer.integer]>
  }
  func.func @b_solution(%0 : !transfer.abs_value<[!transfer.integer, !transfer.integer]>, %1 : !transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.abs_value<[!transfer.integer, !transfer.integer]> {
    %2 = func.call @b_partial_solution_0(%0, %1) : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>, !transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.abs_value<[!transfer.integer, !transfer.integer]>
    %3 = func.call @b_partial_solution_1(%0, %1) : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>, !transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.abs_value<[!transfer.integer, !transfer.integer]>
    %4 = func.call @b_partial_solution_2(%0, %1) : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>, !transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.abs_value<[!transfer.integer, !transfer.integer]>
    %5 = func.call @b_partial_solution_3(%0, %1) : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>, !transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.abs_value<[!transfer.integer, !transfer.integer]>
    %6 = func.call @meet(%2, %3) : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>, !transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.abs_value<[!transfer.integer, !transfer.integer]>
    %7 = func.call @meet(%6, %4) : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>, !transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.abs_value<[!transfer.integer, !transfer.integer]>
    %8 = func.call @meet(%7, %5) : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>, !transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.abs_value<[!transfer.integer, !transfer.integer]>
    func.return %8 : !transfer.abs_value<[!transfer.integer, !transfer.integer]>
  }
  func.func @c_partial_solution_0_body(%0 : !transfer.abs_value<[!transfer.integer, !transfer.integer]>, %1 : !transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.abs_value<[!transfer.integer, !transfer.integer]> attributes {number = "0_267_19"} {
    %2 = "transfer.get"(%0) {index = 0 : index} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %3 = "transfer.get"(%0) {index = 1 : index} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %4 = "transfer.get"(%1) {index = 0 : index} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %5 = "transfer.get"(%1) {index = 1 : index} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %6 = "transfer.constant"(%5) {value = 0 : index} : (!transfer.integer) -> !transfer.integer
    %7 = "transfer.constant"(%5) {value = 1 : index} : (!transfer.integer) -> !transfer.integer
    %8 = "transfer.get_all_ones"(%5) : (!transfer.integer) -> !transfer.integer
    %9 = "transfer.get_bit_width"(%5) : (!transfer.integer) -> !transfer.integer
    %10 = "transfer.ashr"(%6, %5) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %11 = "transfer.clear_high_bits"(%7, %4) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %12 = "transfer.umax"(%5, %11) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %13 = "transfer.umax"(%9, %2) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %14 = "transfer.clear_high_bits"(%3, %10) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %15 = "transfer.ashr"(%6, %2) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %16 = "transfer.sub"(%13, %15) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %17 = "transfer.smax"(%12, %14) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %18 = "transfer.set_sign_bit"(%10) : (!transfer.integer) -> !transfer.integer
    %19 = "transfer.and"(%16, %18) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %20 = "transfer.mul"(%8, %8) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %21 = "transfer.umax"(%17, %20) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %22 = "transfer.set_sign_bit"(%21) : (!transfer.integer) -> !transfer.integer
    %23 = "transfer.and"(%22, %21) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %24 = "transfer.shl"(%19, %11) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %25 = "transfer.make"(%24, %23) : (!transfer.integer, !transfer.integer) -> !transfer.abs_value<[!transfer.integer, !transfer.integer]>
    func.return %25 : !transfer.abs_value<[!transfer.integer, !transfer.integer]>
  }
  func.func @c_partial_solution_1_body(%0 : !transfer.abs_value<[!transfer.integer, !transfer.integer]>, %1 : !transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.abs_value<[!transfer.integer, !transfer.integer]> attributes {number = "0_251_8"} {
    %2 = "transfer.get"(%0) {index = 1 : index} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %3 = "transfer.get"(%1) {index = 0 : index} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %4 = "transfer.get"(%1) {index = 1 : index} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %5 = "transfer.constant"(%4) {value = 0 : index} : (!transfer.integer) -> !transfer.integer
    %6 = "transfer.get_all_ones"(%4) : (!transfer.integer) -> !transfer.integer
    %7 = "transfer.get_bit_width"(%4) : (!transfer.integer) -> !transfer.integer
    %8 = "transfer.udiv"(%5, %6) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %9 = "transfer.or"(%2, %4) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %10 = "transfer.lshr"(%2, %7) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %11 = "transfer.set_sign_bit"(%8) : (!transfer.integer) -> !transfer.integer
    %12 = "transfer.clear_sign_bit"(%9) : (!transfer.integer) -> !transfer.integer
    %13 = "transfer.srem"(%12, %10) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %14 = "transfer.and"(%11, %3) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %15 = "transfer.make"(%14, %13) : (!transfer.integer, !transfer.integer) -> !transfer.abs_value<[!transfer.integer, !transfer.integer]>
    func.return %15 : !transfer.abs_value<[!transfer.integer, !transfer.integer]>
  }
  func.func @c_partial_solution_2_body(%0 : !transfer.abs_value<[!transfer.integer, !transfer.integer]>, %1 : !transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.abs_value<[!transfer.integer, !transfer.integer]> attributes {from_weighted_dsl, number = "0_259_37"} {
    %2 = "transfer.get"(%1) {index = 0 : index} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %3 = "transfer.get"(%1) {index = 1 : index} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %4 = "transfer.constant"(%3) {value = 1 : index} : (!transfer.integer) -> !transfer.integer
    %5 = "transfer.get_all_ones"(%3) : (!transfer.integer) -> !transfer.integer
    %6 = "transfer.get_bit_width"(%3) : (!transfer.integer) -> !transfer.integer
    %7 = "transfer.countl_zero"(%2) : (!transfer.integer) -> !transfer.integer
    %8 = "transfer.udiv"(%5, %6) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %9 = "transfer.clear_high_bits"(%3, %4) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %10 = "transfer.smax"(%9, %2) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %11 = "transfer.countr_zero"(%8) : (!transfer.integer) -> !transfer.integer
    %12 = "transfer.add"(%11, %10) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %13 = "transfer.set_sign_bit"(%7) : (!transfer.integer) -> !transfer.integer
    %14 = "transfer.make"(%13, %12) : (!transfer.integer, !transfer.integer) -> !transfer.abs_value<[!transfer.integer, !transfer.integer]>
    func.return %14 : !transfer.abs_value<[!transfer.integer, !transfer.integer]>
  }
  func.func @c_partial_solution_2_cond(%0 : !transfer.abs_value<[!transfer.integer, !transfer.integer]>, %1 : !transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> i1 attributes {number = "1_83_21"} {
    %2 = "transfer.get"(%0) {index = 1 : index} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %3 = "transfer.get"(%1) {index = 0 : index} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %4 = "transfer.get"(%1) {index = 1 : index} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %5 = "transfer.constant"(%4) {value = 1 : index} : (!transfer.integer) -> !transfer.integer
    %6 = "transfer.get_all_ones"(%4) : (!transfer.integer) -> !transfer.integer
    %7 = "transfer.get_bit_width"(%4) : (!transfer.integer) -> !transfer.integer
    %8 = "transfer.or"(%2, %7) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %9 = "transfer.cmp"(%3, %8) {predicate = 7 : index} : (!transfer.integer, !transfer.integer) -> i1
    %10 = "transfer.cmp"(%4, %8) {predicate = 7 : index} : (!transfer.integer, !transfer.integer) -> i1
    %11 = arith.xori %9, %10 : i1
    %12 = "transfer.cmp"(%5, %6) {predicate = 6 : index} : (!transfer.integer, !transfer.integer) -> i1
    %13 = arith.xori %12, %11 : i1
    func.return %13 : i1
  }
  func.func @c_partial_solution_3_body(%0 : !transfer.abs_value<[!transfer.integer, !transfer.integer]>, %1 : !transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.abs_value<[!transfer.integer, !transfer.integer]> attributes {number = "0_283_6"} {
    %2 = "transfer.get"(%0) {index = 1 : index} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %3 = "transfer.get"(%1) {index = 0 : index} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %4 = "transfer.countl_zero"(%3) : (!transfer.integer) -> !transfer.integer
    %5 = "transfer.clear_sign_bit"(%2) : (!transfer.integer) -> !transfer.integer
    %6 = "transfer.set_sign_bit"(%4) : (!transfer.integer) -> !transfer.integer
    %7 = "transfer.make"(%6, %5) : (!transfer.integer, !transfer.integer) -> !transfer.abs_value<[!transfer.integer, !transfer.integer]>
    func.return %7 : !transfer.abs_value<[!transfer.integer, !transfer.integer]>
  }
  func.func @c_partial_solution_3_cond(%0 : !transfer.abs_value<[!transfer.integer, !transfer.integer]>, %1 : !transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> i1 attributes {number = "1_213_18"} {
    %2 = "transfer.get"(%0) {index = 0 : index} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %3 = "transfer.get"(%0) {index = 1 : index} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %4 = "transfer.cmp"(%3, %2) {predicate = 0 : index} : (!transfer.integer, !transfer.integer) -> i1
    %5 = "transfer.cmp"(%2, %3) {predicate = 6 : index} : (!transfer.integer, !transfer.integer) -> i1
    %6 = arith.xori %4, %5 : i1
    func.return %6 : i1
  }
  func.func @c_partial_solution_0(%0 : !transfer.abs_value<[!transfer.integer, !transfer.integer]>, %1 : !transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.abs_value<[!transfer.integer, !transfer.integer]> {
    %2 = func.call @c_partial_solution_0_body(%0, %1) : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>, !transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.abs_value<[!transfer.integer, !transfer.integer]>
    func.return %2 : !transfer.abs_value<[!transfer.integer, !transfer.integer]>
  }
  func.func @c_partial_solution_1(%0 : !transfer.abs_value<[!transfer.integer, !transfer.integer]>, %1 : !transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.abs_value<[!transfer.integer, !transfer.integer]> {
    %2 = func.call @c_partial_solution_1_body(%0, %1) : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>, !transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.abs_value<[!transfer.integer, !transfer.integer]>
    func.return %2 : !transfer.abs_value<[!transfer.integer, !transfer.integer]>
  }
  func.func @c_partial_solution_2(%0 : !transfer.abs_value<[!transfer.integer, !transfer.integer]>, %1 : !transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.abs_value<[!transfer.integer, !transfer.integer]> {
    %2 = func.call @getTop(%0) : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.abs_value<[!transfer.integer, !transfer.integer]>
    %3 = "transfer.get"(%2) {index = 0 : index} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %4 = "transfer.get"(%2) {index = 1 : index} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %5 = func.call @c_partial_solution_2_body(%0, %1) : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>, !transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.abs_value<[!transfer.integer, !transfer.integer]>
    %6 = "transfer.get"(%5) {index = 0 : index} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %7 = "transfer.get"(%5) {index = 1 : index} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %8 = func.call @c_partial_solution_2_cond(%0, %1) : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>, !transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> i1
    %9 = "transfer.select"(%8, %6, %3) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %10 = "transfer.select"(%8, %7, %4) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %11 = "transfer.make"(%9, %10) : (!transfer.integer, !transfer.integer) -> !transfer.abs_value<[!transfer.integer, !transfer.integer]>
    func.return %11 : !transfer.abs_value<[!transfer.integer, !transfer.integer]>
  }
  func.func @c_partial_solution_3(%0 : !transfer.abs_value<[!transfer.integer, !transfer.integer]>, %1 : !transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.abs_value<[!transfer.integer, !transfer.integer]> {
    %2 = func.call @getTop(%0) : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.abs_value<[!transfer.integer, !transfer.integer]>
    %3 = "transfer.get"(%2) {index = 0 : index} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %4 = "transfer.get"(%2) {index = 1 : index} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %5 = func.call @c_partial_solution_3_body(%0, %1) : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>, !transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.abs_value<[!transfer.integer, !transfer.integer]>
    %6 = "transfer.get"(%5) {index = 0 : index} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %7 = "transfer.get"(%5) {index = 1 : index} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %8 = func.call @c_partial_solution_3_cond(%0, %1) : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>, !transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> i1
    %9 = "transfer.select"(%8, %6, %3) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %10 = "transfer.select"(%8, %7, %4) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %11 = "transfer.make"(%9, %10) : (!transfer.integer, !transfer.integer) -> !transfer.abs_value<[!transfer.integer, !transfer.integer]>
    func.return %11 : !transfer.abs_value<[!transfer.integer, !transfer.integer]>
  }
  func.func @c_solution(%0 : !transfer.abs_value<[!transfer.integer, !transfer.integer]>, %1 : !transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.abs_value<[!transfer.integer, !transfer.integer]> {
    %2 = func.call @c_partial_solution_0(%0, %1) : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>, !transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.abs_value<[!transfer.integer, !transfer.integer]>
    %3 = func.call @c_partial_solution_1(%0, %1) : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>, !transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.abs_value<[!transfer.integer, !transfer.integer]>
    %4 = func.call @c_partial_solution_2(%0, %1) : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>, !transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.abs_value<[!transfer.integer, !transfer.integer]>
    %5 = func.call @c_partial_solution_3(%0, %1) : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>, !transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.abs_value<[!transfer.integer, !transfer.integer]>
    %6 = func.call @meet(%2, %3) : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>, !transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.abs_value<[!transfer.integer, !transfer.integer]>
    %7 = func.call @meet(%6, %4) : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>, !transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.abs_value<[!transfer.integer, !transfer.integer]>
    %8 = func.call @meet(%7, %5) : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>, !transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.abs_value<[!transfer.integer, !transfer.integer]>
    func.return %8 : !transfer.abs_value<[!transfer.integer, !transfer.integer]>
  }
  func.func @heur(%lhs : !transfer.abs_value<[!transfer.integer, !transfer.integer]>, %rhs : !transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.abs_value<[!transfer.integer, !transfer.integer]> {
    %lhs_lower = "transfer.get"(%lhs) {index = 0 : index} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %lhs_upper = "transfer.get"(%lhs) {index = 1 : index} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %rhs_lower = "transfer.get"(%rhs) {index = 0 : index} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %rhs_upper = "transfer.get"(%rhs) {index = 1 : index} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer

    %const0 = "transfer.constant"(%lhs_lower) {value = 0 : index} : (!transfer.integer) -> !transfer.integer
    %smin = "transfer.get_signed_min_value"(%lhs_lower) : (!transfer.integer) -> !transfer.integer
    %smax = "transfer.get_signed_max_value"(%lhs_lower) : (!transfer.integer) -> !transfer.integer
    %minus1 = "transfer.get_all_ones"(%lhs_lower) : (!transfer.integer) -> !transfer.integer

    %lhs_is_const = "transfer.cmp"(%lhs_lower, %lhs_upper) {predicate = 0 : index} : (!transfer.integer, !transfer.integer) -> i1
    %rhs_is_const = "transfer.cmp"(%rhs_lower, %rhs_upper) {predicate = 0 : index} : (!transfer.integer, !transfer.integer) -> i1
    %both_const = arith.andi %lhs_is_const, %rhs_is_const : i1

    %lhs_is_zero_val = "transfer.cmp"(%lhs_lower, %const0) {predicate = 0 : index} : (!transfer.integer, !transfer.integer) -> i1
    %rhs_is_zero_val = "transfer.cmp"(%rhs_lower, %const0) {predicate = 0 : index} : (!transfer.integer, !transfer.integer) -> i1
    %lhs_const_zero = arith.andi %lhs_is_const, %lhs_is_zero_val : i1
    %rhs_const_zero = arith.andi %rhs_is_const, %rhs_is_zero_val : i1

    %lhs_is_minus1_val = "transfer.cmp"(%lhs_lower, %minus1) {predicate = 0 : index} : (!transfer.integer, !transfer.integer) -> i1
    %rhs_is_minus1_val = "transfer.cmp"(%rhs_lower, %minus1) {predicate = 0 : index} : (!transfer.integer, !transfer.integer) -> i1
    %lhs_const_minus1 = arith.andi %lhs_is_const, %lhs_is_minus1_val : i1
    %rhs_const_minus1 = arith.andi %rhs_is_const, %rhs_is_minus1_val : i1

    %lhs_nonneg = "transfer.cmp"(%lhs_lower, %const0) {predicate = 5 : index} : (!transfer.integer, !transfer.integer) -> i1
    %rhs_nonneg = "transfer.cmp"(%rhs_lower, %const0) {predicate = 5 : index} : (!transfer.integer, !transfer.integer) -> i1
    %lhs_neg = "transfer.cmp"(%lhs_upper, %const0) {predicate = 2 : index} : (!transfer.integer, !transfer.integer) -> i1
    %rhs_neg = "transfer.cmp"(%rhs_upper, %const0) {predicate = 2 : index} : (!transfer.integer, !transfer.integer) -> i1

    %either_nonneg = arith.ori %lhs_nonneg, %rhs_nonneg : i1
    %both_nonneg = arith.andi %lhs_nonneg, %rhs_nonneg : i1
    %both_neg = arith.andi %lhs_neg, %rhs_neg : i1

    %both_nonneg_upper = "transfer.smin"(%lhs_upper, %rhs_upper) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %single_nonneg_upper = "transfer.select"(%lhs_nonneg, %lhs_upper, %rhs_upper) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %nonneg_upper = "transfer.select"(%both_nonneg, %both_nonneg_upper, %single_nonneg_upper) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %both_neg_upper = "transfer.smin"(%lhs_upper, %rhs_upper) : (!transfer.integer, !transfer.integer) -> !transfer.integer

    %ret_lower_sign = "transfer.select"(%either_nonneg, %const0, %smin) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %ret_upper_sign_0 = "transfer.select"(%both_neg, %both_neg_upper, %smax) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %ret_upper_sign = "transfer.select"(%either_nonneg, %nonneg_upper, %ret_upper_sign_0) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer

    %const_res = "transfer.and"(%lhs_lower, %rhs_lower) : (!transfer.integer, !transfer.integer) -> !transfer.integer

    %ret_lower_lz = "transfer.select"(%lhs_const_zero, %const0, %ret_lower_sign) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %ret_upper_lz = "transfer.select"(%lhs_const_zero, %const0, %ret_upper_sign) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer

    %ret_lower_rz = "transfer.select"(%rhs_const_zero, %const0, %ret_lower_lz) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %ret_upper_rz = "transfer.select"(%rhs_const_zero, %const0, %ret_upper_lz) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer

    %ret_lower_lm1 = "transfer.select"(%lhs_const_minus1, %rhs_lower, %ret_lower_rz) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %ret_upper_lm1 = "transfer.select"(%lhs_const_minus1, %rhs_upper, %ret_upper_rz) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer

    %ret_lower_rm1 = "transfer.select"(%rhs_const_minus1, %lhs_lower, %ret_lower_lm1) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %ret_upper_rm1 = "transfer.select"(%rhs_const_minus1, %lhs_upper, %ret_upper_lm1) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer

    %ret_lower = "transfer.select"(%both_const, %const_res, %ret_lower_rm1) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %ret_upper = "transfer.select"(%both_const, %const_res, %ret_upper_rm1) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer

    %r = "transfer.make"(%ret_lower, %ret_upper) : (!transfer.integer, !transfer.integer) -> !transfer.abs_value<[!transfer.integer, !transfer.integer]>
    func.return %r : !transfer.abs_value<[!transfer.integer, !transfer.integer]>
  }

  func.func @scr_and(%0 : !transfer.abs_value<[!transfer.integer, !transfer.integer]>, %1 : !transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.abs_value<[!transfer.integer, !transfer.integer]> {
    %2 = func.call @solution(%0, %1) : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>, !transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.abs_value<[!transfer.integer, !transfer.integer]>
    %3 = func.call @b_solution(%0, %1) : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>, !transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.abs_value<[!transfer.integer, !transfer.integer]>
    %4 = func.call @meet(%2, %3) : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>, !transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.abs_value<[!transfer.integer, !transfer.integer]>
    %5 = func.call @c_solution(%0, %1) : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>, !transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.abs_value<[!transfer.integer, !transfer.integer]>
    %6 = func.call @meet(%4, %5) : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>, !transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.abs_value<[!transfer.integer, !transfer.integer]>
    %7 = func.call @heur(%0, %1) : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>, !transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.abs_value<[!transfer.integer, !transfer.integer]>
    %8 = func.call @meet(%6, %7) : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>, !transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.abs_value<[!transfer.integer, !transfer.integer]>
    func.return %8 : !transfer.abs_value<[!transfer.integer, !transfer.integer]>
  }
}

"func.func"() ({
  ^0(%lhs : !transfer.abs_value<[!transfer.integer, !transfer.integer]>, %rhs : !transfer.abs_value<[!transfer.integer, !transfer.integer]>):
    %lhs_lower = "transfer.get"(%lhs) {index = 0} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %lhs_upper = "transfer.get"(%lhs) {index = 1} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %rhs_lower = "transfer.get"(%rhs) {index = 0} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %rhs_upper = "transfer.get"(%rhs) {index = 1} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer

    %const0 = "transfer.constant"(%lhs_lower) {value = 0 : index} : (!transfer.integer) -> !transfer.integer
    %smin = "transfer.get_signed_min_value"(%lhs_lower) : (!transfer.integer) -> !transfer.integer
    %smax = "transfer.get_signed_max_value"(%lhs_lower) : (!transfer.integer) -> !transfer.integer
    %bw = "transfer.get_bit_width"(%lhs_lower) : (!transfer.integer) -> !transfer.integer
    %const_true = "arith.constant"() {value = 1 : i1} : () -> i1

    %lhs_is_const = "transfer.cmp"(%lhs_lower, %lhs_upper) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %rhs_is_const = "transfer.cmp"(%rhs_lower, %rhs_upper) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %both_const = "arith.andi"(%lhs_is_const, %rhs_is_const) : (i1, i1) -> i1

    %lhs_is_zero = "transfer.cmp"(%lhs_lower, %const0) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %rhs_is_zero = "transfer.cmp"(%rhs_lower, %const0) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %lhs_const_zero = "arith.andi"(%lhs_is_const, %lhs_is_zero) : (i1, i1) -> i1
    %rhs_const_zero = "arith.andi"(%rhs_is_const, %rhs_is_zero) : (i1, i1) -> i1

    %rhs_upper_ge_0 = "transfer.cmp"(%rhs_upper, %const0) {predicate = 5 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %rhs_lower_le_bw = "transfer.cmp"(%rhs_lower, %bw) {predicate = 3 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %rhs_has_valid = "arith.andi"(%rhs_upper_ge_0, %rhs_lower_le_bw) : (i1, i1) -> i1
    %bw_is_small = "transfer.cmp"(%bw, %const0) {predicate = 2 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %bw_not_small = "arith.xori"(%bw_is_small, %const_true) : (i1, i1) -> i1

    %rhs_lower_ge_0 = "transfer.cmp"(%rhs_lower, %const0) {predicate = 5 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %rhs_upper_le_bw = "transfer.cmp"(%rhs_upper, %bw) {predicate = 3 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %rhs_all_valid = "arith.andi"(%rhs_lower_ge_0, %rhs_upper_le_bw) : (i1, i1) -> i1
    %rhs_has_valid_or_small = "arith.ori"(%rhs_has_valid, %bw_is_small) : (i1, i1) -> i1
    %rhs_has_valid_safe = "arith.andi"(%rhs_has_valid, %bw_not_small) : (i1, i1) -> i1
    %rhs_all_valid_safe = "arith.andi"(%rhs_all_valid, %bw_not_small) : (i1, i1) -> i1
    %rhs_eff_lower = "transfer.select"(%rhs_lower_ge_0, %rhs_lower, %const0) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %rhs_eff_upper = "transfer.select"(%rhs_upper_le_bw, %rhs_upper, %bw) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer

    %cand_valid_lower = "transfer.select"(%rhs_has_valid_or_small, %smin, %smax) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %cand_valid_upper = "transfer.select"(%rhs_has_valid_or_small, %smax, %smin) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer

    %cand_lhs0_ok = "arith.andi"(%lhs_const_zero, %rhs_has_valid_safe) : (i1, i1) -> i1
    %cand_lhs0_lower = "transfer.select"(%cand_lhs0_ok, %const0, %smin) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %cand_lhs0_upper = "transfer.select"(%cand_lhs0_ok, %const0, %smax) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer

    %cand_rhs0_ok = "arith.andi"(%rhs_const_zero, %rhs_all_valid_safe) : (i1, i1) -> i1
    %cand_rhs0_lower = "transfer.select"(%cand_rhs0_ok, %lhs_lower, %smin) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %cand_rhs0_upper = "transfer.select"(%cand_rhs0_ok, %lhs_upper, %smax) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer

    %cand_const_ok = "arith.andi"(%both_const, %rhs_all_valid_safe) : (i1, i1) -> i1
    %const_shl = "transfer.shl"(%lhs_lower, %rhs_lower) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %cand_const_lower = "transfer.select"(%cand_const_ok, %const_shl, %smin) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %cand_const_upper = "transfer.select"(%cand_const_ok, %const_shl, %smax) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer

    %lhs_nonneg = "transfer.cmp"(%lhs_lower, %const0) {predicate = 5 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %clz_upper = "transfer.countl_zero"(%lhs_upper) : (!transfer.integer) -> !transfer.integer
    %rhs_lt_clz = "transfer.cmp"(%rhs_eff_upper, %clz_upper) {predicate = 6 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %cand_nonneg_ok_0 = "arith.andi"(%rhs_has_valid_safe, %lhs_nonneg) : (i1, i1) -> i1
    %cand_nonneg_ok = "arith.andi"(%cand_nonneg_ok_0, %rhs_lt_clz) : (i1, i1) -> i1
    %nonneg_lower = "transfer.shl"(%lhs_lower, %rhs_eff_lower) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %nonneg_upper = "transfer.shl"(%lhs_upper, %rhs_eff_upper) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %cand_nonneg_lower = "transfer.select"(%cand_nonneg_ok, %nonneg_lower, %smin) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %cand_nonneg_upper = "transfer.select"(%cand_nonneg_ok, %nonneg_upper, %smax) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer

    %lhs_neg = "transfer.cmp"(%lhs_upper, %const0) {predicate = 2 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %clo_lower = "transfer.countl_one"(%lhs_lower) : (!transfer.integer) -> !transfer.integer
    %rhs_lt_clo = "transfer.cmp"(%rhs_eff_upper, %clo_lower) {predicate = 6 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %cand_neg_ok_0 = "arith.andi"(%rhs_has_valid_safe, %lhs_neg) : (i1, i1) -> i1
    %cand_neg_ok = "arith.andi"(%cand_neg_ok_0, %rhs_lt_clo) : (i1, i1) -> i1
    %neg_lower = "transfer.shl"(%lhs_lower, %rhs_eff_upper) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %neg_upper = "transfer.shl"(%lhs_upper, %rhs_eff_lower) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %cand_neg_lower = "transfer.select"(%cand_neg_ok, %neg_lower, %smin) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %cand_neg_upper = "transfer.select"(%cand_neg_ok, %neg_upper, %smax) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer

    %lhs_mixed_neg = "transfer.cmp"(%lhs_lower, %const0) {predicate = 2 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %lhs_mixed_nonneg = "transfer.cmp"(%lhs_upper, %const0) {predicate = 5 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %lhs_mixed = "arith.andi"(%lhs_mixed_neg, %lhs_mixed_nonneg) : (i1, i1) -> i1
    %cand_mixed_ok_0 = "arith.andi"(%rhs_has_valid_safe, %lhs_mixed) : (i1, i1) -> i1
    %cand_mixed_ok_1 = "arith.andi"(%cand_mixed_ok_0, %rhs_lt_clz) : (i1, i1) -> i1
    %cand_mixed_ok = "arith.andi"(%cand_mixed_ok_1, %rhs_lt_clo) : (i1, i1) -> i1
    %mixed_lower = "transfer.shl"(%lhs_lower, %rhs_eff_upper) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %mixed_upper = "transfer.shl"(%lhs_upper, %rhs_eff_upper) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %cand_mixed_lower = "transfer.select"(%cand_mixed_ok, %mixed_lower, %smin) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %cand_mixed_upper = "transfer.select"(%cand_mixed_ok, %mixed_upper, %smax) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer

    %ret_lower_1 = "transfer.smax"(%smin, %cand_valid_lower) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %ret_upper_1 = "transfer.smin"(%smax, %cand_valid_upper) : (!transfer.integer, !transfer.integer) -> !transfer.integer

    %ret_lower_2 = "transfer.smax"(%ret_lower_1, %cand_lhs0_lower) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %ret_upper_2 = "transfer.smin"(%ret_upper_1, %cand_lhs0_upper) : (!transfer.integer, !transfer.integer) -> !transfer.integer

    %ret_lower_3 = "transfer.smax"(%ret_lower_2, %cand_rhs0_lower) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %ret_upper_3 = "transfer.smin"(%ret_upper_2, %cand_rhs0_upper) : (!transfer.integer, !transfer.integer) -> !transfer.integer

    %ret_lower_4 = "transfer.smax"(%ret_lower_3, %cand_const_lower) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %ret_upper_4 = "transfer.smin"(%ret_upper_3, %cand_const_upper) : (!transfer.integer, !transfer.integer) -> !transfer.integer

    %ret_lower_5 = "transfer.smax"(%ret_lower_4, %cand_nonneg_lower) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %ret_upper_5 = "transfer.smin"(%ret_upper_4, %cand_nonneg_upper) : (!transfer.integer, !transfer.integer) -> !transfer.integer

    %ret_lower_6 = "transfer.smax"(%ret_lower_5, %cand_neg_lower) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %ret_upper_6 = "transfer.smin"(%ret_upper_5, %cand_neg_upper) : (!transfer.integer, !transfer.integer) -> !transfer.integer

    %ret_lower = "transfer.smax"(%ret_lower_6, %cand_mixed_lower) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %ret_upper = "transfer.smin"(%ret_upper_6, %cand_mixed_upper) : (!transfer.integer, !transfer.integer) -> !transfer.integer

    %r = "transfer.make"(%ret_lower, %ret_upper) : (!transfer.integer, !transfer.integer) -> !transfer.abs_value<[!transfer.integer, !transfer.integer]>
    "func.return"(%r) : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> ()
}) {"sym_name" = "scr_shl", "function_type" = (!transfer.abs_value<[!transfer.integer, !transfer.integer]>, !transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.abs_value<[!transfer.integer, !transfer.integer]>} : () -> ()

"func.func"() ({
  ^0(%lhs : !transfer.abs_value<[!transfer.integer, !transfer.integer]>, %rhs : !transfer.abs_value<[!transfer.integer, !transfer.integer]>):
    %lhs_lower = "transfer.get"(%lhs) {index = 0} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %lhs_upper = "transfer.get"(%lhs) {index = 1} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %rhs_lower = "transfer.get"(%rhs) {index = 0} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %rhs_upper = "transfer.get"(%rhs) {index = 1} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer

    %const0 = "transfer.constant"(%lhs_lower) {value = 0 : index} : (!transfer.integer) -> !transfer.integer
    %const1 = "transfer.constant"(%lhs_lower) {value = 1 : index} : (!transfer.integer) -> !transfer.integer
    %all_ones = "transfer.get_all_ones"(%lhs_lower) : (!transfer.integer) -> !transfer.integer
    %smin = "transfer.get_signed_min_value"(%lhs_lower) : (!transfer.integer) -> !transfer.integer
    %smax = "transfer.get_signed_max_value"(%lhs_lower) : (!transfer.integer) -> !transfer.integer

    %lhs_nonneg = "transfer.cmp"(%lhs_lower, %const0) {predicate = 5 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %rhs_nonneg = "transfer.cmp"(%rhs_lower, %const0) {predicate = 5 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %lhs_neg = "transfer.cmp"(%lhs_upper, %all_ones) {predicate = 3 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %rhs_neg = "transfer.cmp"(%rhs_upper, %all_ones) {predicate = 3 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %both_nonneg = "arith.andi"(%lhs_nonneg, %rhs_nonneg) : (i1, i1) -> i1
    %both_neg = "arith.andi"(%lhs_neg, %rhs_neg) : (i1, i1) -> i1
    %same_sign = "arith.ori"(%both_nonneg, %both_neg) : (i1, i1) -> i1
    %lhs_nonneg_rhs_neg = "arith.andi"(%lhs_nonneg, %rhs_neg) : (i1, i1) -> i1
    %lhs_neg_rhs_nonneg = "arith.andi"(%lhs_neg, %rhs_nonneg) : (i1, i1) -> i1
    %cross_sign = "arith.ori"(%lhs_nonneg_rhs_neg, %lhs_neg_rhs_nonneg) : (i1, i1) -> i1

    %lhs_before_rhs = "transfer.cmp"(%lhs_upper, %rhs_lower) {predicate = 2 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %rhs_before_lhs = "transfer.cmp"(%rhs_upper, %lhs_lower) {predicate = 2 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %disjoint = "arith.ori"(%lhs_before_rhs, %rhs_before_lhs) : (i1, i1) -> i1
    %same_sign_disjoint = "arith.andi"(%same_sign, %disjoint) : (i1, i1) -> i1

    %fallback_lower_0 = "transfer.select"(%same_sign, %const0, %smin) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %fallback_lower = "transfer.select"(%same_sign_disjoint, %const1, %fallback_lower_0) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %fallback_upper = "transfer.select"(%cross_sign, %all_ones, %smax) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer

    %lhs_is_const = "transfer.cmp"(%lhs_lower, %lhs_upper) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %rhs_is_const = "transfer.cmp"(%rhs_lower, %rhs_upper) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %both_const = "arith.andi"(%lhs_is_const, %rhs_is_const) : (i1, i1) -> i1

    %lhs_is_zero_val = "transfer.cmp"(%lhs_lower, %const0) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %rhs_is_zero_val = "transfer.cmp"(%rhs_lower, %const0) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %lhs_const_zero = "arith.andi"(%lhs_is_const, %lhs_is_zero_val) : (i1, i1) -> i1
    %rhs_const_zero = "arith.andi"(%rhs_is_const, %rhs_is_zero_val) : (i1, i1) -> i1

    %lhs_is_all_ones_val = "transfer.cmp"(%lhs_lower, %all_ones) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %rhs_is_all_ones_val = "transfer.cmp"(%rhs_lower, %all_ones) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %lhs_const_all_ones = "arith.andi"(%lhs_is_const, %lhs_is_all_ones_val) : (i1, i1) -> i1
    %rhs_const_all_ones = "arith.andi"(%rhs_is_const, %rhs_is_all_ones_val) : (i1, i1) -> i1

    %rhs_not_lower = "transfer.xor"(%rhs_upper, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %rhs_not_upper = "transfer.xor"(%rhs_lower, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %lhs_not_lower = "transfer.xor"(%lhs_upper, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %lhs_not_upper = "transfer.xor"(%lhs_lower, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer

    %const_res = "transfer.xor"(%lhs_lower, %rhs_lower) : (!transfer.integer, !transfer.integer) -> !transfer.integer

    %ret_lower_lz = "transfer.select"(%lhs_const_zero, %rhs_lower, %fallback_lower) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %ret_upper_lz = "transfer.select"(%lhs_const_zero, %rhs_upper, %fallback_upper) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer

    %ret_lower_rz = "transfer.select"(%rhs_const_zero, %lhs_lower, %ret_lower_lz) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %ret_upper_rz = "transfer.select"(%rhs_const_zero, %lhs_upper, %ret_upper_lz) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer

    %ret_lower_la = "transfer.select"(%lhs_const_all_ones, %rhs_not_lower, %ret_lower_rz) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %ret_upper_la = "transfer.select"(%lhs_const_all_ones, %rhs_not_upper, %ret_upper_rz) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer

    %ret_lower_ra = "transfer.select"(%rhs_const_all_ones, %lhs_not_lower, %ret_lower_la) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %ret_upper_ra = "transfer.select"(%rhs_const_all_ones, %lhs_not_upper, %ret_upper_la) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer

    %ret_lower = "transfer.select"(%both_const, %const_res, %ret_lower_ra) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %ret_upper = "transfer.select"(%both_const, %const_res, %ret_upper_ra) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer

    %r = "transfer.make"(%ret_lower, %ret_upper) : (!transfer.integer, !transfer.integer) -> !transfer.abs_value<[!transfer.integer, !transfer.integer]>
    "func.return"(%r) : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> ()
}) {"sym_name" = "scr_xor", "function_type" = (!transfer.abs_value<[!transfer.integer, !transfer.integer]>, !transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.abs_value<[!transfer.integer, !transfer.integer]>} : () -> ()

builtin.module {
  func.func @func0(%h0 : !transfer.abs_value<[!transfer.integer, !transfer.integer]>, %h1 : !transfer.abs_value<[!transfer.integer, !transfer.integer]>, %arg0 : !transfer.abs_value<[!transfer.integer, !transfer.integer]>, %arg1 : !transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.abs_value<[!transfer.integer, !transfer.integer]> {
    %v2 = func.call @%h1(%arg0, %arg1) : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>, !transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %v4 = func.call @%h0(%arg0, %arg1) : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>, !transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %v3 = "transfer.get"(%v4) {index = 0} : (!transfer.integer) -> !transfer.integer
    %v6 = func.call @getTop(%arg0) : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %v5 = "transfer.get"(%v6) {index = 0} : (!transfer.integer) -> !transfer.integer
    %v1 = "transfer.select"(%v2, %v3, %v5) : (!transfer.integer, !transfer.integer, !transfer.integer) -> !transfer.integer
    %v8 = func.call @%h1(%arg0, %arg1) : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>, !transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %v10 = func.call @%h0(%arg0, %arg1) : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>, !transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %v9 = "transfer.get"(%v10) {index = 1} : (!transfer.integer) -> !transfer.integer
    %v12 = func.call @getTop(%arg0) : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %v11 = "transfer.get"(%v12) {index = 1} : (!transfer.integer) -> !transfer.integer
    %v7 = "transfer.select"(%v8, %v9, %v11) : (!transfer.integer, !transfer.integer, !transfer.integer) -> !transfer.integer
    %v0 = "transfer.make"(%v1, %v7) : (!transfer.integer, !transfer.integer) -> !transfer.abs_value<[!transfer.integer, !transfer.integer]>
    func.return %v0 : !transfer.abs_value<[!transfer.integer, !transfer.integer]>
  }
  func.func @func1(%h0 : !transfer.integer, %arg0 : !transfer.integer) -> !transfer.abs_value<[!transfer.integer, !transfer.integer]> {
    %v0 = "transfer.make"(%h0, %arg0) : (!transfer.integer, !transfer.integer) -> !transfer.abs_value<[!transfer.integer, !transfer.integer]>
    func.return %v0 : !transfer.abs_value<[!transfer.integer, !transfer.integer]>
  }
  func.func @func2(%arg0 : !transfer.abs_value<[!transfer.integer, !transfer.integer]>, %arg1 : !transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.abs_value<[!transfer.integer, !transfer.integer]> {
    %v4 = "transfer.get"(%arg0) {index = 0} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %v5 = "transfer.get"(%arg1) {index = 0} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %v3 = "transfer.cmp"(%v4, %v5) {predicate = 7 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %v7 = "transfer.get"(%arg1) {index = 1} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %v6 = "transfer.constant"(%v7) {value = 0 : index} : (!transfer.integer) -> !transfer.integer
    %v8 = "transfer.get"(%arg1) {index = 1} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %v2 = "transfer.select"(%v3, %v6, %v8) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %v11 = "transfer.get"(%arg1) {index = 0} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %v10 = "transfer.neg"(%v11) : (!transfer.integer) -> !transfer.integer
    %v13 = "transfer.get"(%arg1) {index = 1} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %v12 = "transfer.get_all_ones"(%v13) : (!transfer.integer) -> !transfer.integer
    %v9 = "transfer.add"(%v10, %v12) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %v1 = "transfer.lshr"(%v2, %v9) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %v15 = "transfer.get"(%arg1) {index = 1} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %v22 = "transfer.get"(%arg1) {index = 1} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %v21 = "transfer.get_bit_width"(%v22) : (!transfer.integer) -> !transfer.integer
    %v20 = "transfer.countr_one"(%v21) : (!transfer.integer) -> !transfer.integer
    %v25 = "transfer.get"(%arg1) {index = 0} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %v24 = "transfer.neg"(%v25) : (!transfer.integer) -> !transfer.integer
    %v27 = "transfer.get"(%arg1) {index = 1} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %v26 = "transfer.get_all_ones"(%v27) : (!transfer.integer) -> !transfer.integer
    %v23 = "transfer.mul"(%v24, %v26) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %v19 = "transfer.srem"(%v20, %v23) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %v30 = "transfer.get"(%arg1) {index = 0} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %v29 = "transfer.neg"(%v30) : (!transfer.integer) -> !transfer.integer
    %v32 = "transfer.get"(%arg1) {index = 1} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %v31 = "transfer.get_all_ones"(%v32) : (!transfer.integer) -> !transfer.integer
    %v28 = "transfer.mul"(%v29, %v31) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %v18 = "transfer.clear_high_bits"(%v19, %v28) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %v35 = "transfer.get"(%arg0) {index = 0} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %v36 = "transfer.get"(%arg1) {index = 0} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %v34 = "transfer.cmp"(%v35, %v36) {predicate = 7 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %v38 = "transfer.get"(%arg1) {index = 1} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %v37 = "transfer.constant"(%v38) {value = 0 : index} : (!transfer.integer) -> !transfer.integer
    %v39 = "transfer.get"(%arg1) {index = 1} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %v33 = "transfer.select"(%v34, %v37, %v39) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %v17 = "transfer.umax"(%v18, %v33) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %v41 = "transfer.get"(%arg1) {index = 0} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %v40 = "transfer.neg"(%v41) : (!transfer.integer) -> !transfer.integer
    %v16 = "transfer.urem"(%v17, %v40) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %v14 = "transfer.umax"(%v15, %v16) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %v0 = "transfer.make"(%v1, %v14) : (!transfer.integer, !transfer.integer) -> !transfer.abs_value<[!transfer.integer, !transfer.integer]>
    func.return %v0 : !transfer.abs_value<[!transfer.integer, !transfer.integer]>
  }
}

builtin.module {
  func.func @partial_solution_0_body(%0 : !transfer.abs_value<[!transfer.integer, !transfer.integer]>, %1 : !transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.abs_value<[!transfer.integer, !transfer.integer]> attributes {number = "0_252_16"} {
    %2 = "transfer.get"(%0) {index = 1 : index} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %3 = "transfer.get"(%1) {index = 1 : index} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %4 = "transfer.get_bit_width"(%3) : (!transfer.integer) -> !transfer.integer
    %5 = "transfer.countl_one"(%4) : (!transfer.integer) -> !transfer.integer
    %6 = "transfer.or"(%5, %2) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %7 = "transfer.clear_sign_bit"(%2) : (!transfer.integer) -> !transfer.integer
    %8 = "transfer.umin"(%3, %6) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %9 = "transfer.xor"(%7, %7) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %10 = "transfer.make"(%9, %8) : (!transfer.integer, !transfer.integer) -> !transfer.abs_value<[!transfer.integer, !transfer.integer]>
    func.return %10 : !transfer.abs_value<[!transfer.integer, !transfer.integer]>
  }
  func.func @partial_solution_1_body(%0 : !transfer.abs_value<[!transfer.integer, !transfer.integer]>, %1 : !transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.abs_value<[!transfer.integer, !transfer.integer]> attributes {from_weighted_dsl, number = "0_103_26"} {
    %2 = "transfer.get"(%0) {index = 0 : index} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %3 = "transfer.get"(%0) {index = 1 : index} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %4 = "transfer.get"(%1) {index = 0 : index} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %5 = "transfer.get"(%1) {index = 1 : index} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %6 = "transfer.constant"(%5) {value = 1 : index} : (!transfer.integer) -> !transfer.integer
    %7 = "transfer.get_bit_width"(%5) : (!transfer.integer) -> !transfer.integer
    %8 = "transfer.smin"(%6, %3) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %9 = "transfer.and"(%4, %2) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %10 = "transfer.countl_one"(%7) : (!transfer.integer) -> !transfer.integer
    %11 = "transfer.ashr"(%9, %9) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %12 = "transfer.sdiv"(%10, %8) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %13 = "transfer.clear_low_bits"(%5, %12) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %14 = "transfer.popcount"(%11) : (!transfer.integer) -> !transfer.integer
    %15 = "transfer.make"(%14, %13) : (!transfer.integer, !transfer.integer) -> !transfer.abs_value<[!transfer.integer, !transfer.integer]>
    func.return %15 : !transfer.abs_value<[!transfer.integer, !transfer.integer]>
  }
  func.func @partial_solution_2_body(%0 : !transfer.abs_value<[!transfer.integer, !transfer.integer]>, %1 : !transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.abs_value<[!transfer.integer, !transfer.integer]> attributes {number = "0_268_9"} {
    %2 = "transfer.get"(%0) {index = 1 : index} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %3 = "transfer.get"(%1) {index = 0 : index} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %4 = "transfer.get"(%1) {index = 1 : index} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %5 = "transfer.constant"(%4) {value = 0 : index} : (!transfer.integer) -> !transfer.integer
    %6 = "transfer.constant"(%4) {value = 1 : index} : (!transfer.integer) -> !transfer.integer
    %7 = "transfer.get_all_ones"(%4) : (!transfer.integer) -> !transfer.integer
    %8 = "transfer.get_bit_width"(%4) : (!transfer.integer) -> !transfer.integer
    %9 = "transfer.cmp"(%7, %8) {predicate = 6 : index} : (!transfer.integer, !transfer.integer) -> i1
    %10 = "transfer.sub"(%4, %6) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %11 = "transfer.umin"(%6, %8) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %12 = "transfer.select"(%9, %10, %5) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %13 = "transfer.clear_low_bits"(%7, %11) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %14 = "transfer.or"(%12, %4) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %15 = "transfer.clear_low_bits"(%3, %2) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %16 = "transfer.countr_one"(%13) : (!transfer.integer) -> !transfer.integer
    %17 = "transfer.sdiv"(%2, %3) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %18 = "transfer.lshr"(%15, %16) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %19 = "transfer.smax"(%17, %12) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %20 = "transfer.xor"(%14, %18) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %21 = "transfer.and"(%19, %16) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %22 = "transfer.make"(%21, %20) : (!transfer.integer, !transfer.integer) -> !transfer.abs_value<[!transfer.integer, !transfer.integer]>
    func.return %22 : !transfer.abs_value<[!transfer.integer, !transfer.integer]>
  }
  func.func @partial_solution_3_body(%0 : !transfer.abs_value<[!transfer.integer, !transfer.integer]>, %1 : !transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.abs_value<[!transfer.integer, !transfer.integer]> attributes {from_weighted_dsl, number = "0_204_29"} {
    %2 = "transfer.get"(%0) {index = 1 : index} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %3 = "transfer.get"(%1) {index = 0 : index} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %4 = "transfer.get"(%1) {index = 1 : index} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %5 = "transfer.get_bit_width"(%4) : (!transfer.integer) -> !transfer.integer
    %6 = "transfer.countr_zero"(%5) : (!transfer.integer) -> !transfer.integer
    %7 = "transfer.sdiv"(%3, %6) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %8 = "transfer.xor"(%7, %7) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %9 = "transfer.shl"(%6, %4) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %10 = "transfer.add"(%9, %2) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %11 = "transfer.countr_one"(%8) : (!transfer.integer) -> !transfer.integer
    %12 = "transfer.make"(%11, %10) : (!transfer.integer, !transfer.integer) -> !transfer.abs_value<[!transfer.integer, !transfer.integer]>
    func.return %12 : !transfer.abs_value<[!transfer.integer, !transfer.integer]>
  }
  func.func @partial_solution_3_cond(%0 : !transfer.abs_value<[!transfer.integer, !transfer.integer]>, %1 : !transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> i1 attributes {number = "1_216_22"} {
    %2 = "transfer.get"(%0) {index = 0 : index} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %3 = "transfer.get"(%0) {index = 1 : index} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %4 = "transfer.get"(%1) {index = 0 : index} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %5 = "transfer.get"(%1) {index = 1 : index} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %6 = "transfer.constant"(%5) {value = 0 : index} : (!transfer.integer) -> !transfer.integer
    %7 = "transfer.cmp"(%3, %2) {predicate = 0 : index} : (!transfer.integer, !transfer.integer) -> i1
    %8 = "transfer.cmp"(%4, %6) {predicate = 6 : index} : (!transfer.integer, !transfer.integer) -> i1
    %9 = arith.ori %8, %7 : i1
    %10 = arith.andi %9, %9 : i1
    %11 = arith.andi %10, %10 : i1
    func.return %11 : i1
  }
  func.func @partial_solution_4_body(%0 : !transfer.abs_value<[!transfer.integer, !transfer.integer]>, %1 : !transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.abs_value<[!transfer.integer, !transfer.integer]> attributes {from_weighted_dsl, number = "0_81_33"} {
    %2 = "transfer.get"(%0) {index = 0 : index} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %3 = "transfer.get"(%0) {index = 1 : index} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %4 = "transfer.get"(%1) {index = 0 : index} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %5 = "transfer.get"(%1) {index = 1 : index} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %6 = "transfer.get_all_ones"(%5) : (!transfer.integer) -> !transfer.integer
    %7 = "transfer.countl_zero"(%2) : (!transfer.integer) -> !transfer.integer
    %8 = "transfer.udiv"(%4, %6) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %9 = "transfer.neg"(%3) : (!transfer.integer) -> !transfer.integer
    %10 = "transfer.sub"(%7, %7) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %11 = "transfer.clear_low_bits"(%8, %9) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %12 = "transfer.umax"(%11, %3) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %13 = "transfer.or"(%11, %10) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %14 = "transfer.make"(%13, %12) : (!transfer.integer, !transfer.integer) -> !transfer.abs_value<[!transfer.integer, !transfer.integer]>
    func.return %14 : !transfer.abs_value<[!transfer.integer, !transfer.integer]>
  }
  func.func @partial_solution_4_cond(%0 : !transfer.abs_value<[!transfer.integer, !transfer.integer]>, %1 : !transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> i1 attributes {number = "1_145_24"} {
    %2 = "transfer.get"(%0) {index = 0 : index} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %3 = "transfer.get"(%1) {index = 1 : index} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %4 = "transfer.constant"(%3) {value = 0 : index} : (!transfer.integer) -> !transfer.integer
    %5 = "transfer.constant"(%3) {value = 1 : index} : (!transfer.integer) -> !transfer.integer
    %6 = "transfer.cmp"(%4, %2) {predicate = 7 : index} : (!transfer.integer, !transfer.integer) -> i1
    %7 = "transfer.cmp"(%2, %5) {predicate = 6 : index} : (!transfer.integer, !transfer.integer) -> i1
    %8 = arith.xori %7, %6 : i1
    %9 = arith.andi %8, %6 : i1
    func.return %9 : i1
  }
  func.func @partial_solution_5_body(%0 : !transfer.abs_value<[!transfer.integer, !transfer.integer]>, %1 : !transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.abs_value<[!transfer.integer, !transfer.integer]> attributes {number = "0_25_2"} {
    %2 = "transfer.get"(%0) {index = 1 : index} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %3 = "transfer.get"(%1) {index = 1 : index} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %4 = "transfer.constant"(%3) {value = 0 : index} : (!transfer.integer) -> !transfer.integer
    %5 = "transfer.constant"(%3) {value = 1 : index} : (!transfer.integer) -> !transfer.integer
    %6 = "transfer.srem"(%2, %4) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %7 = "transfer.sdiv"(%5, %4) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %8 = "transfer.neg"(%5) : (!transfer.integer) -> !transfer.integer
    %9 = "transfer.countr_zero"(%8) : (!transfer.integer) -> !transfer.integer
    %10 = "transfer.srem"(%9, %4) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %11 = "transfer.clear_sign_bit"(%6) : (!transfer.integer) -> !transfer.integer
    %12 = "transfer.urem"(%7, %10) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %13 = "transfer.make"(%12, %11) : (!transfer.integer, !transfer.integer) -> !transfer.abs_value<[!transfer.integer, !transfer.integer]>
    func.return %13 : !transfer.abs_value<[!transfer.integer, !transfer.integer]>
  }
  func.func @partial_solution_5_cond(%0 : !transfer.abs_value<[!transfer.integer, !transfer.integer]>, %1 : !transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> i1 attributes {number = "1_70_12"} {
    %2 = "transfer.get"(%0) {index = 0 : index} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %3 = "transfer.get"(%1) {index = 1 : index} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %4 = "transfer.countl_one"(%2) : (!transfer.integer) -> !transfer.integer
    %5 = "transfer.cmp"(%3, %4) {predicate = 0 : index} : (!transfer.integer, !transfer.integer) -> i1
    func.return %5 : i1
  }
  func.func @partial_solution_6_body(%0 : !transfer.abs_value<[!transfer.integer, !transfer.integer]>, %1 : !transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.abs_value<[!transfer.integer, !transfer.integer]> attributes {number = "0_239_13"} {
    %2 = "transfer.get"(%0) {index = 0 : index} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %3 = "transfer.get"(%0) {index = 1 : index} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %4 = "transfer.get"(%1) {index = 1 : index} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %5 = "transfer.constant"(%4) {value = 1 : index} : (!transfer.integer) -> !transfer.integer
    %6 = "transfer.get_bit_width"(%4) : (!transfer.integer) -> !transfer.integer
    %7 = "transfer.lshr"(%6, %3) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %8 = "transfer.or"(%5, %2) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %9 = "transfer.countr_zero"(%8) : (!transfer.integer) -> !transfer.integer
    %10 = "transfer.umin"(%6, %7) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %11 = "transfer.or"(%4, %7) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %12 = "transfer.set_sign_bit"(%11) : (!transfer.integer) -> !transfer.integer
    %13 = "transfer.clear_low_bits"(%11, %10) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %14 = "transfer.and"(%9, %12) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %15 = "transfer.make"(%14, %13) : (!transfer.integer, !transfer.integer) -> !transfer.abs_value<[!transfer.integer, !transfer.integer]>
    func.return %15 : !transfer.abs_value<[!transfer.integer, !transfer.integer]>
  }
  func.func @partial_solution_6_cond(%0 : !transfer.abs_value<[!transfer.integer, !transfer.integer]>, %1 : !transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> i1 attributes {number = "1_0_27"} {
    %2 = "transfer.get"(%0) {index = 0 : index} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %3 = "transfer.get"(%0) {index = 1 : index} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %4 = "transfer.get"(%1) {index = 1 : index} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %5 = "transfer.constant"(%4) {value = 1 : index} : (!transfer.integer) -> !transfer.integer
    %6 = "transfer.clear_high_bits"(%3, %5) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %7 = "transfer.cmp"(%4, %3) {predicate = 6 : index} : (!transfer.integer, !transfer.integer) -> i1
    %8 = "transfer.cmp"(%2, %6) {predicate = 6 : index} : (!transfer.integer, !transfer.integer) -> i1
    %9 = arith.ori %7, %8 : i1
    %10 = arith.xori %9, %8 : i1
    func.return %10 : i1
  }
  func.func @partial_solution_0(%0 : !transfer.abs_value<[!transfer.integer, !transfer.integer]>, %1 : !transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.abs_value<[!transfer.integer, !transfer.integer]> {
    %2 = func.call @partial_solution_0_body(%0, %1) : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>, !transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.abs_value<[!transfer.integer, !transfer.integer]>
    func.return %2 : !transfer.abs_value<[!transfer.integer, !transfer.integer]>
  }
  func.func @partial_solution_1(%0 : !transfer.abs_value<[!transfer.integer, !transfer.integer]>, %1 : !transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.abs_value<[!transfer.integer, !transfer.integer]> {
    %2 = func.call @partial_solution_1_body(%0, %1) : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>, !transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.abs_value<[!transfer.integer, !transfer.integer]>
    func.return %2 : !transfer.abs_value<[!transfer.integer, !transfer.integer]>
  }
  func.func @partial_solution_2(%0 : !transfer.abs_value<[!transfer.integer, !transfer.integer]>, %1 : !transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.abs_value<[!transfer.integer, !transfer.integer]> {
    %2 = func.call @partial_solution_2_body(%0, %1) : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>, !transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.abs_value<[!transfer.integer, !transfer.integer]>
    func.return %2 : !transfer.abs_value<[!transfer.integer, !transfer.integer]>
  }
  func.func @partial_solution_3(%0 : !transfer.abs_value<[!transfer.integer, !transfer.integer]>, %1 : !transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.abs_value<[!transfer.integer, !transfer.integer]> {
    %2 = func.call @getTop(%0) : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.abs_value<[!transfer.integer, !transfer.integer]>
    %3 = "transfer.get"(%2) {index = 0 : index} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %4 = "transfer.get"(%2) {index = 1 : index} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %5 = func.call @partial_solution_3_body(%0, %1) : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>, !transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.abs_value<[!transfer.integer, !transfer.integer]>
    %6 = "transfer.get"(%5) {index = 0 : index} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %7 = "transfer.get"(%5) {index = 1 : index} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %8 = func.call @partial_solution_3_cond(%0, %1) : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>, !transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> i1
    %9 = "transfer.select"(%8, %6, %3) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %10 = "transfer.select"(%8, %7, %4) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %11 = "transfer.make"(%9, %10) : (!transfer.integer, !transfer.integer) -> !transfer.abs_value<[!transfer.integer, !transfer.integer]>
    func.return %11 : !transfer.abs_value<[!transfer.integer, !transfer.integer]>
  }
  func.func @partial_solution_4(%0 : !transfer.abs_value<[!transfer.integer, !transfer.integer]>, %1 : !transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.abs_value<[!transfer.integer, !transfer.integer]> {
    %2 = func.call @getTop(%0) : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.abs_value<[!transfer.integer, !transfer.integer]>
    %3 = "transfer.get"(%2) {index = 0 : index} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %4 = "transfer.get"(%2) {index = 1 : index} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %5 = func.call @partial_solution_4_body(%0, %1) : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>, !transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.abs_value<[!transfer.integer, !transfer.integer]>
    %6 = "transfer.get"(%5) {index = 0 : index} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %7 = "transfer.get"(%5) {index = 1 : index} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %8 = func.call @partial_solution_4_cond(%0, %1) : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>, !transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> i1
    %9 = "transfer.select"(%8, %6, %3) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %10 = "transfer.select"(%8, %7, %4) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %11 = "transfer.make"(%9, %10) : (!transfer.integer, !transfer.integer) -> !transfer.abs_value<[!transfer.integer, !transfer.integer]>
    func.return %11 : !transfer.abs_value<[!transfer.integer, !transfer.integer]>
  }
  func.func @partial_solution_5(%0 : !transfer.abs_value<[!transfer.integer, !transfer.integer]>, %1 : !transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.abs_value<[!transfer.integer, !transfer.integer]> {
    %2 = func.call @getTop(%0) : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.abs_value<[!transfer.integer, !transfer.integer]>
    %3 = "transfer.get"(%2) {index = 0 : index} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %4 = "transfer.get"(%2) {index = 1 : index} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %5 = func.call @partial_solution_5_body(%0, %1) : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>, !transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.abs_value<[!transfer.integer, !transfer.integer]>
    %6 = "transfer.get"(%5) {index = 0 : index} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %7 = "transfer.get"(%5) {index = 1 : index} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %8 = func.call @partial_solution_5_cond(%0, %1) : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>, !transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> i1
    %9 = "transfer.select"(%8, %6, %3) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %10 = "transfer.select"(%8, %7, %4) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %11 = "transfer.make"(%9, %10) : (!transfer.integer, !transfer.integer) -> !transfer.abs_value<[!transfer.integer, !transfer.integer]>
    func.return %11 : !transfer.abs_value<[!transfer.integer, !transfer.integer]>
  }
  func.func @partial_solution_6(%0 : !transfer.abs_value<[!transfer.integer, !transfer.integer]>, %1 : !transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.abs_value<[!transfer.integer, !transfer.integer]> {
    %2 = func.call @getTop(%0) : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.abs_value<[!transfer.integer, !transfer.integer]>
    %3 = "transfer.get"(%2) {index = 0 : index} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %4 = "transfer.get"(%2) {index = 1 : index} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %5 = func.call @partial_solution_6_body(%0, %1) : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>, !transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.abs_value<[!transfer.integer, !transfer.integer]>
    %6 = "transfer.get"(%5) {index = 0 : index} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %7 = "transfer.get"(%5) {index = 1 : index} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %8 = func.call @partial_solution_6_cond(%0, %1) : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>, !transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> i1
    %9 = "transfer.select"(%8, %6, %3) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %10 = "transfer.select"(%8, %7, %4) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %11 = "transfer.make"(%9, %10) : (!transfer.integer, !transfer.integer) -> !transfer.abs_value<[!transfer.integer, !transfer.integer]>
    func.return %11 : !transfer.abs_value<[!transfer.integer, !transfer.integer]>
  }
  func.func @solution(%0 : !transfer.abs_value<[!transfer.integer, !transfer.integer]>, %1 : !transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.abs_value<[!transfer.integer, !transfer.integer]> {
    %2 = func.call @partial_solution_0(%0, %1) : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>, !transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.abs_value<[!transfer.integer, !transfer.integer]>
    %3 = func.call @partial_solution_1(%0, %1) : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>, !transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.abs_value<[!transfer.integer, !transfer.integer]>
    %4 = func.call @partial_solution_2(%0, %1) : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>, !transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.abs_value<[!transfer.integer, !transfer.integer]>
    %5 = func.call @partial_solution_3(%0, %1) : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>, !transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.abs_value<[!transfer.integer, !transfer.integer]>
    %6 = func.call @partial_solution_4(%0, %1) : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>, !transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.abs_value<[!transfer.integer, !transfer.integer]>
    %7 = func.call @partial_solution_5(%0, %1) : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>, !transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.abs_value<[!transfer.integer, !transfer.integer]>
    %8 = func.call @partial_solution_6(%0, %1) : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>, !transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.abs_value<[!transfer.integer, !transfer.integer]>
    %9 = func.call @meet(%2, %3) : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>, !transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.abs_value<[!transfer.integer, !transfer.integer]>
    %10 = func.call @meet(%9, %4) : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>, !transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.abs_value<[!transfer.integer, !transfer.integer]>
    %11 = func.call @meet(%10, %5) : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>, !transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.abs_value<[!transfer.integer, !transfer.integer]>
    %12 = func.call @meet(%11, %6) : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>, !transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.abs_value<[!transfer.integer, !transfer.integer]>
    %13 = func.call @meet(%12, %7) : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>, !transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.abs_value<[!transfer.integer, !transfer.integer]>
    %14 = func.call @meet(%13, %8) : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>, !transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.abs_value<[!transfer.integer, !transfer.integer]>
    func.return %14 : !transfer.abs_value<[!transfer.integer, !transfer.integer]>
  }
  func.func @solution_safe(%0 : !transfer.abs_value<[!transfer.integer, !transfer.integer]>, %1 : !transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.abs_value<[!transfer.integer, !transfer.integer]> {
    %2 = func.call @partial_solution_0(%0, %1) : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>, !transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.abs_value<[!transfer.integer, !transfer.integer]>
    %3 = func.call @partial_solution_1(%0, %1) : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>, !transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.abs_value<[!transfer.integer, !transfer.integer]>
    %4 = func.call @partial_solution_2(%0, %1) : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>, !transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.abs_value<[!transfer.integer, !transfer.integer]>
    %5 = func.call @partial_solution_3(%0, %1) : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>, !transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.abs_value<[!transfer.integer, !transfer.integer]>
    %6 = func.call @partial_solution_4(%0, %1) : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>, !transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.abs_value<[!transfer.integer, !transfer.integer]>
    %7 = func.call @partial_solution_5(%0, %1) : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>, !transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.abs_value<[!transfer.integer, !transfer.integer]>
    %8 = func.call @meet(%2, %3) : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>, !transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.abs_value<[!transfer.integer, !transfer.integer]>
    %9 = func.call @meet(%8, %4) : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>, !transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.abs_value<[!transfer.integer, !transfer.integer]>
    %10 = func.call @meet(%9, %5) : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>, !transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.abs_value<[!transfer.integer, !transfer.integer]>
    %11 = func.call @meet(%10, %6) : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>, !transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.abs_value<[!transfer.integer, !transfer.integer]>
    %12 = func.call @meet(%11, %7) : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>, !transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.abs_value<[!transfer.integer, !transfer.integer]>
    func.return %12 : !transfer.abs_value<[!transfer.integer, !transfer.integer]>
  }
  func.func @b_partial_solution_0_body(%0 : !transfer.abs_value<[!transfer.integer, !transfer.integer]>, %1 : !transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.abs_value<[!transfer.integer, !transfer.integer]> attributes {number = "0_258_5"} {
    %2 = "transfer.get"(%0) {index = 0 : index} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %3 = "transfer.get"(%0) {index = 1 : index} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %4 = "transfer.get"(%1) {index = 1 : index} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %5 = "transfer.constant"(%4) {value = 1 : index} : (!transfer.integer) -> !transfer.integer
    %6 = "transfer.get_bit_width"(%4) : (!transfer.integer) -> !transfer.integer
    %7 = "transfer.neg"(%5) : (!transfer.integer) -> !transfer.integer
    %8 = "transfer.umax"(%2, %3) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %9 = "transfer.ashr"(%5, %7) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %10 = "transfer.clear_low_bits"(%4, %9) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %11 = "transfer.clear_low_bits"(%6, %6) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %12 = "transfer.umin"(%10, %8) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %13 = "transfer.set_low_bits"(%9, %11) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %14 = "transfer.make"(%13, %12) : (!transfer.integer, !transfer.integer) -> !transfer.abs_value<[!transfer.integer, !transfer.integer]>
    func.return %14 : !transfer.abs_value<[!transfer.integer, !transfer.integer]>
  }
  func.func @b_partial_solution_1_body(%0 : !transfer.abs_value<[!transfer.integer, !transfer.integer]>, %1 : !transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.abs_value<[!transfer.integer, !transfer.integer]> attributes {number = "0_276_17"} {
    %2 = "transfer.get"(%1) {index = 0 : index} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %3 = "transfer.get"(%1) {index = 1 : index} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %4 = "transfer.constant"(%3) {value = 1 : index} : (!transfer.integer) -> !transfer.integer
    %5 = "transfer.get_all_ones"(%3) : (!transfer.integer) -> !transfer.integer
    %6 = "transfer.get_bit_width"(%3) : (!transfer.integer) -> !transfer.integer
    %7 = "transfer.sub"(%5, %4) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %8 = "transfer.xor"(%2, %7) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %9 = "transfer.or"(%8, %3) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %10 = "transfer.countl_zero"(%9) : (!transfer.integer) -> !transfer.integer
    %11 = "transfer.lshr"(%3, %8) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %12 = "transfer.mul"(%3, %5) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %13 = "transfer.srem"(%5, %11) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %14 = "transfer.sub"(%10, %12) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %15 = "transfer.lshr"(%6, %13) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %16 = "transfer.make"(%15, %14) : (!transfer.integer, !transfer.integer) -> !transfer.abs_value<[!transfer.integer, !transfer.integer]>
    func.return %16 : !transfer.abs_value<[!transfer.integer, !transfer.integer]>
  }
  func.func @b_partial_solution_1_cond(%0 : !transfer.abs_value<[!transfer.integer, !transfer.integer]>, %1 : !transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> i1 attributes {number = "1_0_16"} {
    %2 = "transfer.get"(%0) {index = 0 : index} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %3 = "transfer.get"(%0) {index = 1 : index} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %4 = "transfer.get"(%1) {index = 1 : index} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %5 = "transfer.get_bit_width"(%4) : (!transfer.integer) -> !transfer.integer
    %6 = "transfer.cmp"(%5, %3) {predicate = 6 : index} : (!transfer.integer, !transfer.integer) -> i1
    %7 = "transfer.cmp"(%2, %3) {predicate = 0 : index} : (!transfer.integer, !transfer.integer) -> i1
    %8 = arith.andi %6, %7 : i1
    func.return %8 : i1
  }
  func.func @b_partial_solution_2_body(%0 : !transfer.abs_value<[!transfer.integer, !transfer.integer]>, %1 : !transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.abs_value<[!transfer.integer, !transfer.integer]> attributes {number = "0_264_9"} {
    %2 = "transfer.get"(%0) {index = 0 : index} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %3 = "transfer.get"(%1) {index = 0 : index} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %4 = "transfer.get"(%1) {index = 1 : index} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %5 = "transfer.constant"(%4) {value = 0 : index} : (!transfer.integer) -> !transfer.integer
    %6 = "transfer.get_all_ones"(%4) : (!transfer.integer) -> !transfer.integer
    %7 = "transfer.get_bit_width"(%4) : (!transfer.integer) -> !transfer.integer
    %8 = "transfer.cmp"(%2, %3) {predicate = 7 : index} : (!transfer.integer, !transfer.integer) -> i1
    %9 = "transfer.select"(%8, %5, %4) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %10 = "transfer.countr_one"(%7) : (!transfer.integer) -> !transfer.integer
    %11 = "transfer.neg"(%3) : (!transfer.integer) -> !transfer.integer
    %12 = "transfer.mul"(%11, %6) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %13 = "transfer.add"(%11, %6) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %14 = "transfer.srem"(%10, %12) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %15 = "transfer.clear_high_bits"(%14, %12) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %16 = "transfer.umax"(%15, %9) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %17 = "transfer.urem"(%16, %11) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %18 = "transfer.umax"(%4, %17) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %19 = "transfer.lshr"(%9, %13) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %20 = "transfer.make"(%19, %18) : (!transfer.integer, !transfer.integer) -> !transfer.abs_value<[!transfer.integer, !transfer.integer]>
    func.return %20 : !transfer.abs_value<[!transfer.integer, !transfer.integer]>
  }
  func.func @b_partial_solution_2_cond(%0 : !transfer.abs_value<[!transfer.integer, !transfer.integer]>, %1 : !transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> i1 attributes {number = "1_244_18"} {
    %2 = "transfer.get"(%0) {index = 0 : index} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %3 = "transfer.get"(%1) {index = 0 : index} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %4 = "transfer.get"(%1) {index = 1 : index} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %5 = "transfer.get_bit_width"(%4) : (!transfer.integer) -> !transfer.integer
    %6 = "transfer.countl_one"(%4) : (!transfer.integer) -> !transfer.integer
    %7 = "transfer.cmp"(%6, %5) {predicate = 6 : index} : (!transfer.integer, !transfer.integer) -> i1
    %8 = "transfer.cmp"(%2, %3) {predicate = 7 : index} : (!transfer.integer, !transfer.integer) -> i1
    %9 = arith.xori %7, %8 : i1
    func.return %9 : i1
  }
  func.func @b_partial_solution_3_body(%0 : !transfer.abs_value<[!transfer.integer, !transfer.integer]>, %1 : !transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.abs_value<[!transfer.integer, !transfer.integer]> attributes {number = "0_198_10"} {
    %2 = "transfer.get"(%1) {index = 0 : index} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %3 = "transfer.get"(%1) {index = 1 : index} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %4 = "transfer.constant"(%3) {value = 1 : index} : (!transfer.integer) -> !transfer.integer
    %5 = "transfer.get_bit_width"(%3) : (!transfer.integer) -> !transfer.integer
    %6 = "transfer.umax"(%4, %2) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %7 = "transfer.lshr"(%2, %6) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %8 = "transfer.set_low_bits"(%7, %5) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %9 = "transfer.xor"(%3, %7) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %10 = "transfer.udiv"(%6, %8) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %11 = "transfer.make"(%10, %9) : (!transfer.integer, !transfer.integer) -> !transfer.abs_value<[!transfer.integer, !transfer.integer]>
    func.return %11 : !transfer.abs_value<[!transfer.integer, !transfer.integer]>
  }
  func.func @b_partial_solution_3_cond(%0 : !transfer.abs_value<[!transfer.integer, !transfer.integer]>, %1 : !transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> i1 attributes {number = "1_180_28"} {
    %2 = "transfer.get"(%0) {index = 0 : index} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %3 = "transfer.get"(%1) {index = 1 : index} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %4 = "transfer.constant"(%3) {value = 1 : index} : (!transfer.integer) -> !transfer.integer
    %5 = "transfer.get_all_ones"(%3) : (!transfer.integer) -> !transfer.integer
    %6 = "transfer.sub"(%2, %4) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %7 = "transfer.cmp"(%6, %5) {predicate = 6 : index} : (!transfer.integer, !transfer.integer) -> i1
    %8 = arith.ori %7, %7 : i1
    func.return %8 : i1
  }
  func.func @b_partial_solution_4_body(%0 : !transfer.abs_value<[!transfer.integer, !transfer.integer]>, %1 : !transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.abs_value<[!transfer.integer, !transfer.integer]> attributes {from_weighted_dsl, number = "0_111_31"} {
    %2 = "transfer.get"(%0) {index = 0 : index} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %3 = "transfer.get"(%1) {index = 0 : index} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %4 = "transfer.get"(%1) {index = 1 : index} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %5 = "transfer.constant"(%4) {value = 1 : index} : (!transfer.integer) -> !transfer.integer
    %6 = "transfer.get_bit_width"(%4) : (!transfer.integer) -> !transfer.integer
    %7 = "transfer.neg"(%2) : (!transfer.integer) -> !transfer.integer
    %8 = "transfer.smax"(%2, %3) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %9 = "transfer.shl"(%4, %4) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %10 = "transfer.sub"(%4, %5) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %11 = "transfer.set_low_bits"(%9, %7) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %12 = "transfer.umin"(%6, %11) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %13 = "transfer.smax"(%4, %10) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %14 = "transfer.clear_low_bits"(%8, %12) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %15 = "transfer.make"(%14, %13) : (!transfer.integer, !transfer.integer) -> !transfer.abs_value<[!transfer.integer, !transfer.integer]>
    func.return %15 : !transfer.abs_value<[!transfer.integer, !transfer.integer]>
  }
  func.func @b_partial_solution_4_cond(%0 : !transfer.abs_value<[!transfer.integer, !transfer.integer]>, %1 : !transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> i1 attributes {number = "1_142_12"} {
    %2 = "transfer.get"(%1) {index = 0 : index} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %3 = "transfer.get"(%1) {index = 1 : index} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %4 = "transfer.get_all_ones"(%3) : (!transfer.integer) -> !transfer.integer
    %5 = "transfer.lshr"(%2, %3) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %6 = "transfer.or"(%5, %2) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %7 = "transfer.cmp"(%4, %6) {predicate = 7 : index} : (!transfer.integer, !transfer.integer) -> i1
    func.return %7 : i1
  }
  func.func @b_partial_solution_5_body(%0 : !transfer.abs_value<[!transfer.integer, !transfer.integer]>, %1 : !transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.abs_value<[!transfer.integer, !transfer.integer]> attributes {from_weighted_dsl, number = "0_89_39"} {
    %2 = "transfer.get"(%0) {index = 1 : index} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %3 = "transfer.get"(%1) {index = 0 : index} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %4 = "transfer.get"(%1) {index = 1 : index} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %5 = "transfer.constant"(%4) {value = 0 : index} : (!transfer.integer) -> !transfer.integer
    %6 = "transfer.get_all_ones"(%4) : (!transfer.integer) -> !transfer.integer
    %7 = "transfer.get_bit_width"(%4) : (!transfer.integer) -> !transfer.integer
    %8 = "transfer.cmp"(%3, %6) {predicate = 0 : index} : (!transfer.integer, !transfer.integer) -> i1
    %9 = "transfer.udiv"(%3, %7) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %10 = "transfer.set_sign_bit"(%2) : (!transfer.integer) -> !transfer.integer
    %11 = "transfer.urem"(%10, %7) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %12 = "transfer.lshr"(%9, %7) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %13 = "transfer.smin"(%11, %9) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %14 = "transfer.smin"(%5, %7) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %15 = "transfer.shl"(%4, %14) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %16 = "transfer.select"(%8, %13, %12) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %17 = "transfer.make"(%16, %15) : (!transfer.integer, !transfer.integer) -> !transfer.abs_value<[!transfer.integer, !transfer.integer]>
    func.return %17 : !transfer.abs_value<[!transfer.integer, !transfer.integer]>
  }
  func.func @b_partial_solution_5_cond(%0 : !transfer.abs_value<[!transfer.integer, !transfer.integer]>, %1 : !transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> i1 attributes {number = "1_199_24"} {
    %2 = "transfer.get"(%0) {index = 0 : index} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %3 = "transfer.get"(%1) {index = 1 : index} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %4 = "transfer.constant"(%3) {value = 1 : index} : (!transfer.integer) -> !transfer.integer
    %5 = "transfer.get_all_ones"(%3) : (!transfer.integer) -> !transfer.integer
    %6 = "transfer.get_bit_width"(%3) : (!transfer.integer) -> !transfer.integer
    %7 = "transfer.cmp"(%6, %2) {predicate = 6 : index} : (!transfer.integer, !transfer.integer) -> i1
    %8 = "transfer.cmp"(%5, %4) {predicate = 7 : index} : (!transfer.integer, !transfer.integer) -> i1
    %9 = arith.andi %7, %7 : i1
    %10 = arith.xori %8, %9 : i1
    func.return %10 : i1
  }
  func.func @b_partial_solution_6_body(%0 : !transfer.abs_value<[!transfer.integer, !transfer.integer]>, %1 : !transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.abs_value<[!transfer.integer, !transfer.integer]> attributes {number = "0_264_9"} {
    %2 = "transfer.get"(%0) {index = 0 : index} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %3 = "transfer.get"(%1) {index = 0 : index} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %4 = "transfer.get"(%1) {index = 1 : index} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %5 = "transfer.constant"(%4) {value = 0 : index} : (!transfer.integer) -> !transfer.integer
    %6 = "transfer.get_all_ones"(%4) : (!transfer.integer) -> !transfer.integer
    %7 = "transfer.get_bit_width"(%4) : (!transfer.integer) -> !transfer.integer
    %8 = "transfer.cmp"(%2, %3) {predicate = 7 : index} : (!transfer.integer, !transfer.integer) -> i1
    %9 = "transfer.select"(%8, %5, %4) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %10 = "transfer.countr_one"(%7) : (!transfer.integer) -> !transfer.integer
    %11 = "transfer.neg"(%3) : (!transfer.integer) -> !transfer.integer
    %12 = "transfer.mul"(%11, %6) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %13 = "transfer.add"(%11, %6) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %14 = "transfer.srem"(%10, %12) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %15 = "transfer.clear_high_bits"(%14, %12) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %16 = "transfer.umax"(%15, %9) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %17 = "transfer.urem"(%16, %11) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %18 = "transfer.umax"(%4, %17) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %19 = "transfer.lshr"(%9, %13) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %20 = "transfer.make"(%19, %18) : (!transfer.integer, !transfer.integer) -> !transfer.abs_value<[!transfer.integer, !transfer.integer]>
    func.return %20 : !transfer.abs_value<[!transfer.integer, !transfer.integer]>
  }
  func.func @b_partial_solution_6_cond(%0 : !transfer.abs_value<[!transfer.integer, !transfer.integer]>, %1 : !transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> i1 attributes {number = "1_250_19"} {
    %2 = "transfer.get"(%0) {index = 0 : index} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %3 = "transfer.get"(%0) {index = 1 : index} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %4 = "transfer.get"(%1) {index = 1 : index} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %5 = "transfer.constant"(%4) {value = 1 : index} : (!transfer.integer) -> !transfer.integer
    %6 = "transfer.sub"(%5, %4) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %7 = "transfer.cmp"(%2, %3) {predicate = 6 : index} : (!transfer.integer, !transfer.integer) -> i1
    %8 = "transfer.cmp"(%3, %6) {predicate = 6 : index} : (!transfer.integer, !transfer.integer) -> i1
    %9 = arith.ori %8, %7 : i1
    func.return %9 : i1
  }
  func.func @b_partial_solution_7_body(%0 : !transfer.abs_value<[!transfer.integer, !transfer.integer]>, %1 : !transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.abs_value<[!transfer.integer, !transfer.integer]> attributes {number = "0_128_15"} {
    %2 = "transfer.get"(%0) {index = 0 : index} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %3 = "transfer.get"(%0) {index = 1 : index} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %4 = "transfer.get"(%1) {index = 1 : index} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %5 = "transfer.constant"(%4) {value = 0 : index} : (!transfer.integer) -> !transfer.integer
    %6 = "transfer.get_all_ones"(%4) : (!transfer.integer) -> !transfer.integer
    %7 = "transfer.ashr"(%6, %5) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %8 = "transfer.and"(%3, %7) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %9 = "transfer.lshr"(%2, %4) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %10 = "transfer.sdiv"(%2, %9) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %11 = "transfer.countr_zero"(%10) : (!transfer.integer) -> !transfer.integer
    %12 = "transfer.add"(%11, %9) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %13 = "transfer.sub"(%3, %12) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %14 = "transfer.lshr"(%11, %8) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %15 = "transfer.make"(%14, %13) : (!transfer.integer, !transfer.integer) -> !transfer.abs_value<[!transfer.integer, !transfer.integer]>
    func.return %15 : !transfer.abs_value<[!transfer.integer, !transfer.integer]>
  }
  func.func @b_partial_solution_0(%0 : !transfer.abs_value<[!transfer.integer, !transfer.integer]>, %1 : !transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.abs_value<[!transfer.integer, !transfer.integer]> {
    %2 = func.call @b_partial_solution_0_body(%0, %1) : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>, !transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.abs_value<[!transfer.integer, !transfer.integer]>
    func.return %2 : !transfer.abs_value<[!transfer.integer, !transfer.integer]>
  }
  func.func @b_partial_solution_1(%0 : !transfer.abs_value<[!transfer.integer, !transfer.integer]>, %1 : !transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.abs_value<[!transfer.integer, !transfer.integer]> {
    %2 = func.call @getTop(%0) : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.abs_value<[!transfer.integer, !transfer.integer]>
    %3 = "transfer.get"(%2) {index = 0 : index} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %4 = "transfer.get"(%2) {index = 1 : index} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %5 = func.call @b_partial_solution_1_body(%0, %1) : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>, !transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.abs_value<[!transfer.integer, !transfer.integer]>
    %6 = "transfer.get"(%5) {index = 0 : index} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %7 = "transfer.get"(%5) {index = 1 : index} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %8 = func.call @b_partial_solution_1_cond(%0, %1) : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>, !transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> i1
    %9 = "transfer.select"(%8, %6, %3) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %10 = "transfer.select"(%8, %7, %4) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %11 = "transfer.make"(%9, %10) : (!transfer.integer, !transfer.integer) -> !transfer.abs_value<[!transfer.integer, !transfer.integer]>
    func.return %11 : !transfer.abs_value<[!transfer.integer, !transfer.integer]>
  }
  func.func @b_partial_solution_2(%0 : !transfer.abs_value<[!transfer.integer, !transfer.integer]>, %1 : !transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.abs_value<[!transfer.integer, !transfer.integer]> {
    %2 = func.call @getTop(%0) : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.abs_value<[!transfer.integer, !transfer.integer]>
    %3 = "transfer.get"(%2) {index = 0 : index} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %4 = "transfer.get"(%2) {index = 1 : index} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %5 = func.call @b_partial_solution_2_body(%0, %1) : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>, !transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.abs_value<[!transfer.integer, !transfer.integer]>
    %6 = "transfer.get"(%5) {index = 0 : index} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %7 = "transfer.get"(%5) {index = 1 : index} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %8 = func.call @b_partial_solution_2_cond(%0, %1) : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>, !transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> i1
    %9 = "transfer.select"(%8, %6, %3) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %10 = "transfer.select"(%8, %7, %4) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %11 = "transfer.make"(%9, %10) : (!transfer.integer, !transfer.integer) -> !transfer.abs_value<[!transfer.integer, !transfer.integer]>
    func.return %11 : !transfer.abs_value<[!transfer.integer, !transfer.integer]>
  }
  func.func @b_partial_solution_3(%0 : !transfer.abs_value<[!transfer.integer, !transfer.integer]>, %1 : !transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.abs_value<[!transfer.integer, !transfer.integer]> {
    %2 = func.call @getTop(%0) : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.abs_value<[!transfer.integer, !transfer.integer]>
    %3 = "transfer.get"(%2) {index = 0 : index} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %4 = "transfer.get"(%2) {index = 1 : index} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %5 = func.call @b_partial_solution_3_body(%0, %1) : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>, !transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.abs_value<[!transfer.integer, !transfer.integer]>
    %6 = "transfer.get"(%5) {index = 0 : index} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %7 = "transfer.get"(%5) {index = 1 : index} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %8 = func.call @b_partial_solution_3_cond(%0, %1) : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>, !transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> i1
    %9 = "transfer.select"(%8, %6, %3) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %10 = "transfer.select"(%8, %7, %4) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %11 = "transfer.make"(%9, %10) : (!transfer.integer, !transfer.integer) -> !transfer.abs_value<[!transfer.integer, !transfer.integer]>
    func.return %11 : !transfer.abs_value<[!transfer.integer, !transfer.integer]>
  }
  func.func @b_partial_solution_4(%0 : !transfer.abs_value<[!transfer.integer, !transfer.integer]>, %1 : !transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.abs_value<[!transfer.integer, !transfer.integer]> {
    %2 = func.call @getTop(%0) : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.abs_value<[!transfer.integer, !transfer.integer]>
    %3 = "transfer.get"(%2) {index = 0 : index} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %4 = "transfer.get"(%2) {index = 1 : index} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %5 = func.call @b_partial_solution_4_body(%0, %1) : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>, !transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.abs_value<[!transfer.integer, !transfer.integer]>
    %6 = "transfer.get"(%5) {index = 0 : index} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %7 = "transfer.get"(%5) {index = 1 : index} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %8 = func.call @b_partial_solution_4_cond(%0, %1) : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>, !transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> i1
    %9 = "transfer.select"(%8, %6, %3) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %10 = "transfer.select"(%8, %7, %4) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %11 = "transfer.make"(%9, %10) : (!transfer.integer, !transfer.integer) -> !transfer.abs_value<[!transfer.integer, !transfer.integer]>
    func.return %11 : !transfer.abs_value<[!transfer.integer, !transfer.integer]>
  }
  func.func @b_partial_solution_5(%0 : !transfer.abs_value<[!transfer.integer, !transfer.integer]>, %1 : !transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.abs_value<[!transfer.integer, !transfer.integer]> {
    %2 = func.call @getTop(%0) : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.abs_value<[!transfer.integer, !transfer.integer]>
    %3 = "transfer.get"(%2) {index = 0 : index} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %4 = "transfer.get"(%2) {index = 1 : index} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %5 = func.call @b_partial_solution_5_body(%0, %1) : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>, !transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.abs_value<[!transfer.integer, !transfer.integer]>
    %6 = "transfer.get"(%5) {index = 0 : index} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %7 = "transfer.get"(%5) {index = 1 : index} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %8 = func.call @b_partial_solution_5_cond(%0, %1) : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>, !transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> i1
    %9 = "transfer.select"(%8, %6, %3) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %10 = "transfer.select"(%8, %7, %4) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %11 = "transfer.make"(%9, %10) : (!transfer.integer, !transfer.integer) -> !transfer.abs_value<[!transfer.integer, !transfer.integer]>
    func.return %11 : !transfer.abs_value<[!transfer.integer, !transfer.integer]>
  }
  func.func @b_partial_solution_6(%0 : !transfer.abs_value<[!transfer.integer, !transfer.integer]>, %1 : !transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.abs_value<[!transfer.integer, !transfer.integer]> {
    %2 = func.call @getTop(%0) : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.abs_value<[!transfer.integer, !transfer.integer]>
    %3 = "transfer.get"(%2) {index = 0 : index} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %4 = "transfer.get"(%2) {index = 1 : index} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %5 = func.call @b_partial_solution_6_body(%0, %1) : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>, !transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.abs_value<[!transfer.integer, !transfer.integer]>
    %6 = "transfer.get"(%5) {index = 0 : index} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %7 = "transfer.get"(%5) {index = 1 : index} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %8 = func.call @b_partial_solution_6_cond(%0, %1) : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>, !transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> i1
    %9 = "transfer.select"(%8, %6, %3) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %10 = "transfer.select"(%8, %7, %4) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %11 = "transfer.make"(%9, %10) : (!transfer.integer, !transfer.integer) -> !transfer.abs_value<[!transfer.integer, !transfer.integer]>
    func.return %11 : !transfer.abs_value<[!transfer.integer, !transfer.integer]>
  }
  func.func @b_partial_solution_7(%0 : !transfer.abs_value<[!transfer.integer, !transfer.integer]>, %1 : !transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.abs_value<[!transfer.integer, !transfer.integer]> {
    %2 = func.call @b_partial_solution_7_body(%0, %1) : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>, !transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.abs_value<[!transfer.integer, !transfer.integer]>
    func.return %2 : !transfer.abs_value<[!transfer.integer, !transfer.integer]>
  }
  func.func @b_solution(%0 : !transfer.abs_value<[!transfer.integer, !transfer.integer]>, %1 : !transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.abs_value<[!transfer.integer, !transfer.integer]> {
    %2 = func.call @b_partial_solution_0(%0, %1) : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>, !transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.abs_value<[!transfer.integer, !transfer.integer]>
    %3 = func.call @b_partial_solution_1(%0, %1) : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>, !transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.abs_value<[!transfer.integer, !transfer.integer]>
    %4 = func.call @b_partial_solution_2(%0, %1) : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>, !transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.abs_value<[!transfer.integer, !transfer.integer]>
    %5 = func.call @b_partial_solution_3(%0, %1) : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>, !transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.abs_value<[!transfer.integer, !transfer.integer]>
    %6 = func.call @b_partial_solution_4(%0, %1) : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>, !transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.abs_value<[!transfer.integer, !transfer.integer]>
    %7 = func.call @b_partial_solution_5(%0, %1) : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>, !transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.abs_value<[!transfer.integer, !transfer.integer]>
    %8 = func.call @b_partial_solution_6(%0, %1) : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>, !transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.abs_value<[!transfer.integer, !transfer.integer]>
    %9 = func.call @b_partial_solution_7(%0, %1) : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>, !transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.abs_value<[!transfer.integer, !transfer.integer]>
    %10 = func.call @meet(%2, %3) : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>, !transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.abs_value<[!transfer.integer, !transfer.integer]>
    %11 = func.call @meet(%10, %4) : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>, !transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.abs_value<[!transfer.integer, !transfer.integer]>
    %12 = func.call @meet(%11, %5) : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>, !transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.abs_value<[!transfer.integer, !transfer.integer]>
    %13 = func.call @meet(%12, %6) : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>, !transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.abs_value<[!transfer.integer, !transfer.integer]>
    %14 = func.call @meet(%13, %7) : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>, !transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.abs_value<[!transfer.integer, !transfer.integer]>
    %15 = func.call @meet(%14, %8) : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>, !transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.abs_value<[!transfer.integer, !transfer.integer]>
    %16 = func.call @meet(%15, %9) : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>, !transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.abs_value<[!transfer.integer, !transfer.integer]>
    func.return %16 : !transfer.abs_value<[!transfer.integer, !transfer.integer]>
  }
  func.func @ucr_and(%0 : !transfer.abs_value<[!transfer.integer, !transfer.integer]>, %1 : !transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.abs_value<[!transfer.integer, !transfer.integer]> {
    %2 = func.call @solution_safe(%0, %1) : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>, !transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.abs_value<[!transfer.integer, !transfer.integer]>
    %3 = func.call @b_solution(%0, %1) : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>, !transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.abs_value<[!transfer.integer, !transfer.integer]>
    %4 = func.call @meet(%2, %3) : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>, !transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.abs_value<[!transfer.integer, !transfer.integer]>
    func.return %4 : !transfer.abs_value<[!transfer.integer, !transfer.integer]>
  }
}

"func.func"() ({
  ^0(%lhs : !transfer.abs_value<[!transfer.integer, !transfer.integer]>, %rhs : !transfer.abs_value<[!transfer.integer, !transfer.integer]>):
    %lhs_lower = "transfer.get"(%lhs) {index = 0} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %lhs_upper = "transfer.get"(%lhs) {index = 1} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %rhs_lower = "transfer.get"(%rhs) {index = 0} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %rhs_upper = "transfer.get"(%rhs) {index = 1} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer

    %const0 = "transfer.constant"(%lhs_lower) {value = 0 : index} : (!transfer.integer) -> !transfer.integer
    %const1 = "transfer.constant"(%lhs_lower) {value = 1 : index} : (!transfer.integer) -> !transfer.integer
    %const_true = "arith.constant"() {value = 1 : i1} : () -> i1
    %all_ones = "transfer.get_all_ones"(%lhs_lower) : (!transfer.integer) -> !transfer.integer
    %bw = "transfer.get_bit_width"(%lhs_lower) : (!transfer.integer) -> !transfer.integer

    %has_valid_rhs = "transfer.cmp"(%rhs_lower, %bw) {predicate = 7 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %rhs_upper_le_bw = "transfer.cmp"(%rhs_upper, %bw) {predicate = 7 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %rhs_eff_upper = "transfer.select"(%rhs_upper_le_bw, %rhs_upper, %bw) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer

    %y0 = "transfer.add"(%rhs_lower, %const0) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %y1 = "transfer.add"(%y0, %const1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %y2 = "transfer.add"(%y1, %const1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %y3 = "transfer.add"(%y2, %const1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %y4 = "transfer.add"(%y3, %const1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %y5 = "transfer.add"(%y4, %const1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %y6 = "transfer.add"(%y5, %const1) : (!transfer.integer, !transfer.integer) -> !transfer.integer

    %bw_minus_y0 = "transfer.sub"(%bw, %y0) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %lhs_lower_q0 = "transfer.lshr"(%lhs_lower, %bw_minus_y0) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %lhs_upper_q0 = "transfer.lshr"(%lhs_upper, %bw_minus_y0) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %cross0 = "transfer.cmp"(%lhs_lower_q0, %lhs_upper_q0) {predicate = 1 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %nowrap_low0 = "transfer.shl"(%lhs_lower, %y0) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %nowrap_hi0 = "transfer.shl"(%lhs_upper, %y0) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %wrap_hi0 = "transfer.clear_low_bits"(%all_ones, %y0) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %low_nonbw0 = "transfer.select"(%cross0, %const0, %nowrap_low0) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %hi_nonbw0 = "transfer.select"(%cross0, %wrap_hi0, %nowrap_hi0) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %y0_is_bw = "transfer.cmp"(%y0, %bw) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %low0 = "transfer.select"(%y0_is_bw, %const0, %low_nonbw0) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %hi0 = "transfer.select"(%y0_is_bw, %const0, %hi_nonbw0) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer

    %bw_minus_y1 = "transfer.sub"(%bw, %y1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %lhs_lower_q1 = "transfer.lshr"(%lhs_lower, %bw_minus_y1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %lhs_upper_q1 = "transfer.lshr"(%lhs_upper, %bw_minus_y1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %cross1 = "transfer.cmp"(%lhs_lower_q1, %lhs_upper_q1) {predicate = 1 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %nowrap_low1 = "transfer.shl"(%lhs_lower, %y1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %nowrap_hi1 = "transfer.shl"(%lhs_upper, %y1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %wrap_hi1 = "transfer.clear_low_bits"(%all_ones, %y1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %low_nonbw1 = "transfer.select"(%cross1, %const0, %nowrap_low1) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %hi_nonbw1 = "transfer.select"(%cross1, %wrap_hi1, %nowrap_hi1) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %y1_is_bw = "transfer.cmp"(%y1, %bw) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %low1 = "transfer.select"(%y1_is_bw, %const0, %low_nonbw1) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %hi1 = "transfer.select"(%y1_is_bw, %const0, %hi_nonbw1) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer

    %bw_minus_y2 = "transfer.sub"(%bw, %y2) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %lhs_lower_q2 = "transfer.lshr"(%lhs_lower, %bw_minus_y2) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %lhs_upper_q2 = "transfer.lshr"(%lhs_upper, %bw_minus_y2) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %cross2 = "transfer.cmp"(%lhs_lower_q2, %lhs_upper_q2) {predicate = 1 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %nowrap_low2 = "transfer.shl"(%lhs_lower, %y2) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %nowrap_hi2 = "transfer.shl"(%lhs_upper, %y2) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %wrap_hi2 = "transfer.clear_low_bits"(%all_ones, %y2) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %low_nonbw2 = "transfer.select"(%cross2, %const0, %nowrap_low2) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %hi_nonbw2 = "transfer.select"(%cross2, %wrap_hi2, %nowrap_hi2) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %y2_is_bw = "transfer.cmp"(%y2, %bw) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %low2 = "transfer.select"(%y2_is_bw, %const0, %low_nonbw2) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %hi2 = "transfer.select"(%y2_is_bw, %const0, %hi_nonbw2) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer

    %bw_minus_y3 = "transfer.sub"(%bw, %y3) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %lhs_lower_q3 = "transfer.lshr"(%lhs_lower, %bw_minus_y3) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %lhs_upper_q3 = "transfer.lshr"(%lhs_upper, %bw_minus_y3) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %cross3 = "transfer.cmp"(%lhs_lower_q3, %lhs_upper_q3) {predicate = 1 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %nowrap_low3 = "transfer.shl"(%lhs_lower, %y3) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %nowrap_hi3 = "transfer.shl"(%lhs_upper, %y3) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %wrap_hi3 = "transfer.clear_low_bits"(%all_ones, %y3) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %low_nonbw3 = "transfer.select"(%cross3, %const0, %nowrap_low3) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %hi_nonbw3 = "transfer.select"(%cross3, %wrap_hi3, %nowrap_hi3) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %y3_is_bw = "transfer.cmp"(%y3, %bw) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %low3 = "transfer.select"(%y3_is_bw, %const0, %low_nonbw3) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %hi3 = "transfer.select"(%y3_is_bw, %const0, %hi_nonbw3) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer

    %bw_minus_y4 = "transfer.sub"(%bw, %y4) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %lhs_lower_q4 = "transfer.lshr"(%lhs_lower, %bw_minus_y4) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %lhs_upper_q4 = "transfer.lshr"(%lhs_upper, %bw_minus_y4) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %cross4 = "transfer.cmp"(%lhs_lower_q4, %lhs_upper_q4) {predicate = 1 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %nowrap_low4 = "transfer.shl"(%lhs_lower, %y4) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %nowrap_hi4 = "transfer.shl"(%lhs_upper, %y4) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %wrap_hi4 = "transfer.clear_low_bits"(%all_ones, %y4) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %low_nonbw4 = "transfer.select"(%cross4, %const0, %nowrap_low4) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %hi_nonbw4 = "transfer.select"(%cross4, %wrap_hi4, %nowrap_hi4) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %y4_is_bw = "transfer.cmp"(%y4, %bw) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %low4 = "transfer.select"(%y4_is_bw, %const0, %low_nonbw4) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %hi4 = "transfer.select"(%y4_is_bw, %const0, %hi_nonbw4) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer

    %bw_minus_y5 = "transfer.sub"(%bw, %y5) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %lhs_lower_q5 = "transfer.lshr"(%lhs_lower, %bw_minus_y5) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %lhs_upper_q5 = "transfer.lshr"(%lhs_upper, %bw_minus_y5) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %cross5 = "transfer.cmp"(%lhs_lower_q5, %lhs_upper_q5) {predicate = 1 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %nowrap_low5 = "transfer.shl"(%lhs_lower, %y5) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %nowrap_hi5 = "transfer.shl"(%lhs_upper, %y5) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %wrap_hi5 = "transfer.clear_low_bits"(%all_ones, %y5) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %low_nonbw5 = "transfer.select"(%cross5, %const0, %nowrap_low5) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %hi_nonbw5 = "transfer.select"(%cross5, %wrap_hi5, %nowrap_hi5) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %y5_is_bw = "transfer.cmp"(%y5, %bw) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %low5 = "transfer.select"(%y5_is_bw, %const0, %low_nonbw5) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %hi5 = "transfer.select"(%y5_is_bw, %const0, %hi_nonbw5) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer

    %lower_acc0 = "transfer.add"(%low0, %const0) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %upper_acc0 = "transfer.add"(%hi0, %const0) : (!transfer.integer, !transfer.integer) -> !transfer.integer

    %present1 = "transfer.cmp"(%y0, %rhs_eff_upper) {predicate = 6 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %lower_join1 = "transfer.umin"(%lower_acc0, %low1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %upper_join1 = "transfer.umax"(%upper_acc0, %hi1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %lower_acc1 = "transfer.select"(%present1, %lower_join1, %lower_acc0) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %upper_acc1 = "transfer.select"(%present1, %upper_join1, %upper_acc0) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer

    %present2 = "transfer.cmp"(%y1, %rhs_eff_upper) {predicate = 6 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %lower_join2 = "transfer.umin"(%lower_acc1, %low2) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %upper_join2 = "transfer.umax"(%upper_acc1, %hi2) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %lower_acc2 = "transfer.select"(%present2, %lower_join2, %lower_acc1) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %upper_acc2 = "transfer.select"(%present2, %upper_join2, %upper_acc1) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer

    %present3 = "transfer.cmp"(%y2, %rhs_eff_upper) {predicate = 6 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %lower_join3 = "transfer.umin"(%lower_acc2, %low3) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %upper_join3 = "transfer.umax"(%upper_acc2, %hi3) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %lower_acc3 = "transfer.select"(%present3, %lower_join3, %lower_acc2) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %upper_acc3 = "transfer.select"(%present3, %upper_join3, %upper_acc2) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer

    %present4 = "transfer.cmp"(%y3, %rhs_eff_upper) {predicate = 6 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %lower_join4 = "transfer.umin"(%lower_acc3, %low4) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %upper_join4 = "transfer.umax"(%upper_acc3, %hi4) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %lower_acc4 = "transfer.select"(%present4, %lower_join4, %lower_acc3) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %upper_acc4 = "transfer.select"(%present4, %upper_join4, %upper_acc3) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer

    %present5 = "transfer.cmp"(%y4, %rhs_eff_upper) {predicate = 6 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %lower_join5 = "transfer.umin"(%lower_acc4, %low5) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %upper_join5 = "transfer.umax"(%upper_acc4, %hi5) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %lower_acc5 = "transfer.select"(%present5, %lower_join5, %lower_acc4) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %upper_acc5 = "transfer.select"(%present5, %upper_join5, %upper_acc4) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer

    %present6 = "transfer.cmp"(%y5, %rhs_eff_upper) {predicate = 6 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %no_more = "arith.xori"(%present6, %const_true) : (i1, i1) -> i1
    %safe_known = "arith.ori"(%no_more, %cross5) : (i1, i1) -> i1

    %tail_mask = "transfer.clear_low_bits"(%all_ones, %y6) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %upper_tail_bound = "transfer.umax"(%upper_acc5, %tail_mask) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %lower_known = "transfer.select"(%safe_known, %lower_acc5, %const0) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %upper_known = "transfer.select"(%safe_known, %upper_acc5, %upper_tail_bound) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer

    %ret_lower = "transfer.select"(%has_valid_rhs, %lower_known, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %ret_upper = "transfer.select"(%has_valid_rhs, %upper_known, %const0) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer

    %r = "transfer.make"(%ret_lower, %ret_upper) : (!transfer.integer, !transfer.integer) -> !transfer.abs_value<[!transfer.integer, !transfer.integer]>
    "func.return"(%r) : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> ()
}) {"sym_name" = "ucr_shl", "function_type" = (!transfer.abs_value<[!transfer.integer, !transfer.integer]>, !transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.abs_value<[!transfer.integer, !transfer.integer]>} : () -> ()

"func.func"() ({
  ^0(%lhs : !transfer.abs_value<[!transfer.integer, !transfer.integer]>, %rhs : !transfer.abs_value<[!transfer.integer, !transfer.integer]>):
    %lhs_lower = "transfer.get"(%lhs) {index = 0} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %lhs_upper = "transfer.get"(%lhs) {index = 1} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %rhs_lower = "transfer.get"(%rhs) {index = 0} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %rhs_upper = "transfer.get"(%rhs) {index = 1} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer

    %const0 = "transfer.constant"(%lhs_lower) {value = 0 : index} : (!transfer.integer) -> !transfer.integer
    %const1 = "transfer.constant"(%lhs_lower) {value = 1 : index} : (!transfer.integer) -> !transfer.integer
    %all_ones = "transfer.get_all_ones"(%lhs_lower) : (!transfer.integer) -> !transfer.integer

    // For unsigned intervals, x ^ y <= x + y in naturals. If max+max does not overflow,
    // we can use that as a tighter generic upper bound than all-ones.
    %sum_upper = "transfer.add"(%lhs_upper, %rhs_upper) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %sum_overflow = "transfer.uadd_overflow"(%lhs_upper, %rhs_upper) : (!transfer.integer, !transfer.integer) -> i1
    %fallback_upper = "transfer.select"(%sum_overflow, %all_ones, %sum_upper) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer

    // If intervals are disjoint, x != y for all pairs, so x ^ y is never zero.
    %lhs_before_rhs = "transfer.cmp"(%lhs_upper, %rhs_lower) {predicate = 6 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %rhs_before_lhs = "transfer.cmp"(%rhs_upper, %lhs_lower) {predicate = 6 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %disjoint = "arith.ori"(%lhs_before_rhs, %rhs_before_lhs) : (i1, i1) -> i1
    %fallback_lower = "transfer.select"(%disjoint, %const1, %const0) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer

    %lhs_is_const = "transfer.cmp"(%lhs_lower, %lhs_upper) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %rhs_is_const = "transfer.cmp"(%rhs_lower, %rhs_upper) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %both_const = "arith.andi"(%lhs_is_const, %rhs_is_const) : (i1, i1) -> i1

    %lhs_is_zero_val = "transfer.cmp"(%lhs_lower, %const0) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %rhs_is_zero_val = "transfer.cmp"(%rhs_lower, %const0) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %lhs_const_zero = "arith.andi"(%lhs_is_const, %lhs_is_zero_val) : (i1, i1) -> i1
    %rhs_const_zero = "arith.andi"(%rhs_is_const, %rhs_is_zero_val) : (i1, i1) -> i1

    %lhs_is_all_ones_val = "transfer.cmp"(%lhs_lower, %all_ones) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %rhs_is_all_ones_val = "transfer.cmp"(%rhs_lower, %all_ones) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %lhs_const_all_ones = "arith.andi"(%lhs_is_const, %lhs_is_all_ones_val) : (i1, i1) -> i1
    %rhs_const_all_ones = "arith.andi"(%rhs_is_const, %rhs_is_all_ones_val) : (i1, i1) -> i1

    %rhs_not_lower = "transfer.xor"(%rhs_lower, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %rhs_not_upper = "transfer.xor"(%rhs_upper, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %lhs_not_lower = "transfer.xor"(%lhs_lower, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %lhs_not_upper = "transfer.xor"(%lhs_upper, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer

    %const_res = "transfer.xor"(%lhs_lower, %rhs_lower) : (!transfer.integer, !transfer.integer) -> !transfer.integer

    %ret_lower_lz = "transfer.select"(%lhs_const_zero, %rhs_lower, %fallback_lower) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %ret_upper_lz = "transfer.select"(%lhs_const_zero, %rhs_upper, %fallback_upper) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer

    %ret_lower_rz = "transfer.select"(%rhs_const_zero, %lhs_lower, %ret_lower_lz) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %ret_upper_rz = "transfer.select"(%rhs_const_zero, %lhs_upper, %ret_upper_lz) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer

    %ret_lower_la = "transfer.select"(%lhs_const_all_ones, %rhs_not_upper, %ret_lower_rz) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %ret_upper_la = "transfer.select"(%lhs_const_all_ones, %rhs_not_lower, %ret_upper_rz) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer

    %ret_lower_ra = "transfer.select"(%rhs_const_all_ones, %lhs_not_upper, %ret_lower_la) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %ret_upper_ra = "transfer.select"(%rhs_const_all_ones, %lhs_not_lower, %ret_upper_la) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer

    %ret_lower = "transfer.select"(%both_const, %const_res, %ret_lower_ra) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %ret_upper = "transfer.select"(%both_const, %const_res, %ret_upper_ra) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer

    %r = "transfer.make"(%ret_lower, %ret_upper) : (!transfer.integer, !transfer.integer) -> !transfer.abs_value<[!transfer.integer, !transfer.integer]>
    "func.return"(%r) : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> ()
}) {"sym_name" = "ucr_xor", "function_type" = (!transfer.abs_value<[!transfer.integer, !transfer.integer]>, !transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.abs_value<[!transfer.integer, !transfer.integer]>} : () -> ()


## Existing library (do not duplicate)

The library already contains the following helpers. Do not re-emit functions that are already present or are trivially equivalent to them:

```mlir
builtin.module {}
```

## Available primitives

Library functions must use only these building blocks:

### Constructor and Deconstructor

- transfer.get : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
- transfer.make : (!transfer.integer, !transfer.integer) -> !transfer.abs_value<[!transfer.integer, !transfer.integer]>

### Boolean Operations (i1)

- transfer.cmp: (!transfer.integer, !transfer.integer) -> i1
- arith.andi: (i1, i1) -> i1
- arith.ori: (i1, i1) -> i1
- arith.xori: (i1, i1) -> i1

### Integer Operations

- transfer.neg: (!transfer.integer) -> !transfer.integer
- transfer.and: (!transfer.integer, !transfer.integer) -> !transfer.integer
- transfer.or: (!transfer.integer, !transfer.integer) -> !transfer.integer
- transfer.xor: (!transfer.integer, !transfer.integer) -> !transfer.integer
- transfer.add: (!transfer.integer, !transfer.integer) -> !transfer.integer
- transfer.sub: (!transfer.integer, !transfer.integer) -> !transfer.integer
- transfer.select: (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
- transfer.mul: (!transfer.integer, !transfer.integer) -> !transfer.integer
- transfer.lshr: (!transfer.integer, !transfer.integer) -> !transfer.integer
- transfer.shl: (!transfer.integer, !transfer.integer) -> !transfer.integer
- transfer.umin: (!transfer.integer, !transfer.integer) -> !transfer.integer
- transfer.umax: (!transfer.integer, !transfer.integer) -> !transfer.integer
- transfer.smin: (!transfer.integer, !transfer.integer) -> !transfer.integer
- transfer.smax: (!transfer.integer, !transfer.integer) -> !transfer.integer
- transfer.udiv: (!transfer.integer, !transfer.integer) -> !transfer.integer
- transfer.sdiv: (!transfer.integer, !transfer.integer) -> !transfer.integer
- transfer.urem: (!transfer.integer, !transfer.integer) -> !transfer.integer
- transfer.srem: (!transfer.integer, !transfer.integer) -> !transfer.integer
- transfer.set_high_bits: (!transfer.integer, !transfer.integer) -> !transfer.integer
- transfer.set_low_bits: (!transfer.integer, !transfer.integer) -> !transfer.integer
- transfer.clear_high_bits: (!transfer.integer, !transfer.integer) -> !transfer.integer
- transfer.clear_low_bits: (!transfer.integer, !transfer.integer) -> !transfer.integer
- transfer.set_signed_bits: (!transfer.integer, !transfer.integer) -> !transfer.integer
- transfer.clear_signed_bits: (!transfer.integer, !transfer.integer) -> !transfer.integer
- transfer.countl_one: (!transfer.integer) -> !transfer.integer
- transfer.countl_zero: (!transfer.integer) -> !transfer.integer
- transfer.countr_one: (!transfer.integer) -> !transfer.integer
- transfer.countr_zero: (!transfer.integer) -> !transfer.integer

## Utility Operations

- transfer.constant: (!transfer.integer) -> !transfer.integer
    - example: `%const0 = "transfer.constant"(%arg){value=42:index} : (!transfer.integer) -> !transfer.integer` provides constant 42.
    - the argument `%arg` is to decide bitwidth
- transfer.get_all_ones: (!transfer.integer) -> !transfer.integer
    - the argument is to decide bitwidth
- transfer.get_bit_width: (!transfer.integer) -> !transfer.integer


## What to extract

A good library function:
1. **Encodes a meaningful semantic concept** — e.g., "extract the maybe-zero mask", "compute the carry-propagate bits", "get the minimum possible concrete value of a KnownBits". Prefer names that describe what the function *means*, not how it is computed.
2. **Appears across multiple transfer functions**, or is a large, self-contained sub-computation that would reduce duplication if future transfer functions were refactored to use it.
3. **Is non-trivial** — it should be at least 3 operations long. Do not extract single-op wrappers.
4. **Is general** — parameters should be abstract values or integers; do not hard-code bitwidth-specific constants unless the concept is inherently about a specific constant.

Do **not** extract the transfer functions themselves (e.g. `@kb_add`). Only extract helper functions that could be called from within transfer functions.

## Output format

Output a single `builtin.module` containing only the new library functions you are adding. Do not include the transfer functions from the input. Use `func.func` with:
- SSA form only
- One allowed operation per line
- Descriptive `snake_case` function names
- A brief `//` comment on the first line of each function body explaining its purpose
- Arguments typed as `!transfer.integer` or `!transfer.abs_value<[!transfer.integer, !transfer.integer]>` as appropriate

Example output shape (illustrative, do not copy verbatim):

```mlir
builtin.module {
  func.func @maybe_zero(%kb : !transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer {
    // Returns the mask of bits that might be 0: complement of known-one.
    %known1 = "transfer.get"(%kb) {index = 1} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %all_ones = "transfer.get_all_ones"(%known1) : (!transfer.integer) -> !transfer.integer
    %res = "transfer.xor"(%known1, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    func.return %res : !transfer.integer
  }
}
```

## Required workflow

1. Read each synthesized transfer function carefully. For each one, annotate (mentally) which sub-sequences of operations compute a semantically coherent intermediate result.
2. Look for sub-computations that appear in more than one function, or that are large enough to deserve a name on their own.
3. For each candidate, decide on a precise semantic description and a clear name.
4. Write the MLIR for each helper function. Verify it uses only allowed primitives and is in valid SSA form.
5. Output **only** the `builtin.module` containing the new helper functions — no explanation, no transfer functions, no markdown fences around the final answer.