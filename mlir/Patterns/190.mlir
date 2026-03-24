module {
  func.func @concrete_op(%arg0: !transfer.integer, %arg1: !transfer.integer, %arg2: !transfer.integer) -> !transfer.integer {
    %0 = "transfer.sdiv"(%arg2, %arg1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %1 = "transfer.shl"(%0, %arg0) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    return %1 : !transfer.integer
  }
  func.func @op_constraint(%arg0: !transfer.integer, %arg1: !transfer.integer, %arg2: !transfer.integer) -> i1 {
    %0 = "transfer.sdiv"(%arg2, %arg1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %ssa_0_con_0_z = func.call @rhs_neq_zero(%arg2, %arg1) : (!transfer.integer, !transfer.integer) -> i1
    %ssa_0_con_1_z = func.call @no_sdiv_ov(%arg2, %arg1) : (!transfer.integer, !transfer.integer) -> i1
    %ssa_1_con_0_z = func.call @shl_nsw(%0, %arg0) : (!transfer.integer, !transfer.integer) -> i1
    %ssa_1_con_1_z = func.call @shift_lt_bw(%0, %arg0) : (!transfer.integer, !transfer.integer) -> i1
    %and_0 = arith.andi %ssa_0_con_0_z, %ssa_1_con_0_z : i1
    %and_1 = arith.andi %and_0, %ssa_1_con_1_z : i1
    %and_2 = arith.andi %and_1, %ssa_0_con_1_z : i1
    return %and_2 : i1
  }
  func.func @rhs_neq_zero(%arg0: !transfer.integer, %arg1: !transfer.integer) -> i1 {
    %const_0 = "transfer.constant"(%arg1) {value = 0 : index} : (!transfer.integer) -> !transfer.integer
    %rhs_not = "transfer.cmp"(%const_0, %arg1) {predicate = 1 : i64} : (!transfer.integer, !transfer.integer) -> i1
    return %rhs_not : i1
  }
  func.func @shl_nsw(%arg0: !transfer.integer, %arg1: !transfer.integer) -> i1 {
    %0 = "transfer.constant"(%arg1) {value = 0 : index} : (!transfer.integer) -> !transfer.integer
    %1 = "transfer.get_bit_width"(%arg0) : (!transfer.integer) -> !transfer.integer
    %2 = "transfer.cmp"(%arg1, %0) {predicate = 9 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %3 = "transfer.cmp"(%arg1, %1) {predicate = 7 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %4 = arith.andi %2, %3 : i1
    %5 = "transfer.countl_zero"(%arg0) : (!transfer.integer) -> !transfer.integer
    %6 = "transfer.countl_one"(%arg0) : (!transfer.integer) -> !transfer.integer
    %7 = "transfer.cmp"(%arg0, %0) {predicate = 5 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %8 = "transfer.cmp"(%arg1, %5) {predicate = 6 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %9 = "transfer.cmp"(%arg1, %6) {predicate = 6 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %10 = "transfer.select"(%7, %8, %9) : (i1, i1, i1) -> i1
    %11 = arith.andi %4, %10 : i1
    return %11 : i1
  }
  func.func @shift_lt_bw(%arg0: !transfer.integer, %arg1: !transfer.integer) -> i1 {
    %bitwidth = "transfer.get_bit_width"(%arg0) : (!transfer.integer) -> !transfer.integer
    %shift_amt_lt_bw = "transfer.cmp"(%arg1, %bitwidth) {predicate = 6 : i64} : (!transfer.integer, !transfer.integer) -> i1
    return %shift_amt_lt_bw : i1
  }
  func.func @no_sdiv_ov(%arg0: !transfer.integer, %arg1: !transfer.integer) -> i1 {
    %int_min = "transfer.get_signed_min_value"(%arg0) : (!transfer.integer) -> !transfer.integer
    %lhs_not_int_min = "transfer.cmp"(%int_min, %arg0) {predicate = 1 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %neg = "transfer.get_all_ones"(%arg0) : (!transfer.integer) -> !transfer.integer
    %rhs_not_neg = "transfer.cmp"(%neg, %arg1) {predicate = 1 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %no_overflow = arith.ori %lhs_not_int_min, %rhs_not_neg : i1
    %res = arith.andi %0, %no_overflow : i1
    return %res : i1
  }
}
