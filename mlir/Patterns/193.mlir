module {
  func.func @concrete_op(%arg0: !transfer.integer, %arg1: !transfer.integer, %arg2: !transfer.integer) -> !transfer.integer {
    %0 = "transfer.lshr"(%arg2, %arg1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %1 = "transfer.add"(%arg0, %0) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %2 = "transfer.shl"(%1, %arg1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %3 = "transfer.or"(%arg1, %2) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    return %3 : !transfer.integer
  }
  func.func @op_constraint(%arg0: !transfer.integer, %arg1: !transfer.integer, %arg2: !transfer.integer) -> i1 {
    %0 = "transfer.lshr"(%arg2, %arg1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %constraint_0_0 = func.call @shift_lt_bw(%arg2, %arg1) : (!transfer.integer, !transfer.integer) -> i1
    %1 = "transfer.add"(%arg0, %0) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %constraint_1_0 = func.call @add_nuw(%arg0, %0) : (!transfer.integer, !transfer.integer) -> i1
    %2 = "transfer.shl"(%1, %arg1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %constraint_2_0 = func.call @shl_nuw(%1, %arg1) : (!transfer.integer, !transfer.integer) -> i1
    %constraint_2_1 = func.call @shift_lt_bw(%1, %arg1) : (!transfer.integer, !transfer.integer) -> i1
    %constraint_3_0 = func.call @or_disjoint(%arg1, %2) : (!transfer.integer, !transfer.integer) -> i1
    %and_0 = arith.andi %constraint_0_0, %constraint_1_0 : i1
    %and_1 = arith.andi %and_0, %constraint_2_0 : i1
    %and_2 = arith.andi %and_1, %constraint_2_1 : i1
    %and_3 = arith.andi %and_2, %constraint_3_0 : i1
    return %and_3 : i1
  }
  func.func @shift_lt_bw(%arg0: !transfer.integer, %arg1: !transfer.integer) -> i1 {
    %bitwidth = "transfer.get_bit_width"(%arg0) : (!transfer.integer) -> !transfer.integer
    %shift_amt_lt_bw = "transfer.cmp"(%arg1, %bitwidth) {predicate = 6 : i64} : (!transfer.integer, !transfer.integer) -> i1
    return %shift_amt_lt_bw : i1
  }
  func.func @add_nuw(%arg0: !transfer.integer, %arg1: !transfer.integer) -> i1 {
    %uadd_ov = "transfer.uadd_overflow"(%arg0, %arg1) : (!transfer.integer, !transfer.integer) -> i1
    %true = arith.constant true
    %no_ov = arith.xori %uadd_ov, %true : i1
    return %no_ov : i1
  }
  func.func @shl_nuw(%arg0: !transfer.integer, %arg1: !transfer.integer) -> i1 {
    %0 = "transfer.constant"(%arg1) {value = 0 : index} : (!transfer.integer) -> !transfer.integer
    %1 = "transfer.get_bit_width"(%arg0) : (!transfer.integer) -> !transfer.integer
    %2 = "transfer.cmp"(%arg1, %0) {predicate = 9 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %3 = "transfer.cmp"(%arg1, %1) {predicate = 7 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %4 = arith.andi %2, %3 : i1
    %5 = "transfer.countl_zero"(%arg0) : (!transfer.integer) -> !transfer.integer
    %6 = "transfer.cmp"(%5, %arg1) {predicate = 9 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %7 = arith.andi %4, %6 : i1
    return %7 : i1
  }
  func.func @or_disjoint(%arg0: !transfer.integer, %arg1: !transfer.integer) -> i1 {
    %0 = "transfer.constant"(%arg1) {value = 0 : index} : (!transfer.integer) -> !transfer.integer
    %1 = "transfer.and"(%arg0, %arg1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %2 = "transfer.cmp"(%1, %0) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    return %2 : i1
  }
}
