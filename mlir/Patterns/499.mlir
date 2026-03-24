module {
  func.func @concrete_op(%arg0: !transfer.integer, %arg1: !transfer.integer, %arg2: !transfer.integer) -> !transfer.integer {
    %0 = "transfer.add"(%arg1, %arg2) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %1 = "transfer.ashr"(%0, %arg0) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    return %1 : !transfer.integer
  }
  func.func @op_constraint(%arg0: !transfer.integer, %arg1: !transfer.integer, %arg2: !transfer.integer) -> i1 {
    %0 = "transfer.add"(%arg1, %arg2) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %constraint_0_0 = func.call @add_nsw(%arg1, %arg2) : (!transfer.integer, !transfer.integer) -> i1
    %constraint_1_0 = func.call @ashr_exact(%0, %arg0) : (!transfer.integer, !transfer.integer) -> i1
    %constraint_1_1 = func.call @shift_lt_bw(%0, %arg0) : (!transfer.integer, !transfer.integer) -> i1
    %and_0 = arith.andi %constraint_0_0, %constraint_1_0 : i1
    %and_1 = arith.andi %and_0, %constraint_1_1 : i1
    return %and_1 : i1
  }
  func.func @add_nsw(%arg0: !transfer.integer, %arg1: !transfer.integer) -> i1 {
    %sadd_ov = "transfer.sadd_overflow"(%arg0, %arg1) : (!transfer.integer, !transfer.integer) -> i1
    %true = arith.constant true
    %no_ov = arith.xori %sadd_ov, %true : i1
    return %no_ov : i1
  }
  func.func @ashr_exact(%arg0: !transfer.integer, %arg1: !transfer.integer) -> i1 {
    %ashr = "transfer.ashr"(%arg0, %arg1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %shl = "transfer.shl"(%ashr, %arg1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %exact = "transfer.cmp"(%shl, %arg0) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    return %exact : i1
  }
  func.func @shift_lt_bw(%arg0: !transfer.integer, %arg1: !transfer.integer) -> i1 {
    %bitwidth = "transfer.get_bit_width"(%arg0) : (!transfer.integer) -> !transfer.integer
    %shift_amt_lt_bw = "transfer.cmp"(%arg1, %bitwidth) {predicate = 6 : i64} : (!transfer.integer, !transfer.integer) -> i1
    return %shift_amt_lt_bw : i1
  }
}
