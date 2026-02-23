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
