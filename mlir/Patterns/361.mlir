module {
  func.func @concrete_op(%arg0: !transfer.integer, %arg1: !transfer.integer, %arg2: !transfer.integer, %arg3: !transfer.integer) -> !transfer.integer {
    %0 = "transfer.and"(%arg2, %arg3) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %1 = "transfer.shl"(%arg1, %0) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %2 = "transfer.lshr"(%1, %arg0) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    return %2 : !transfer.integer
  }
  func.func @op_constraint(%arg0: !transfer.integer, %arg1: !transfer.integer, %arg2: !transfer.integer, %arg3: !transfer.integer) -> i1 {
    %0 = "transfer.and"(%arg2, %arg3) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %1 = "transfer.shl"(%arg1, %0) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %constraint_1_0 = func.call @shift_lt_bw(%arg1, %0) : (!transfer.integer, !transfer.integer) -> i1
    %constraint_2_0 = func.call @shift_lt_bw(%1, %arg0) : (!transfer.integer, !transfer.integer) -> i1
    %and_0 = arith.andi %constraint_1_0, %constraint_2_0 : i1
    return %and_0 : i1
  }
  func.func @shift_lt_bw(%arg0: !transfer.integer, %arg1: !transfer.integer) -> i1 {
    %bitwidth = "transfer.get_bit_width"(%arg0) : (!transfer.integer) -> !transfer.integer
    %shift_amt_lt_bw = "transfer.cmp"(%arg1, %bitwidth) {predicate = 6 : i64} : (!transfer.integer, !transfer.integer) -> i1
    return %shift_amt_lt_bw : i1
  }
}
