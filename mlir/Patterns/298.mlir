module {
  func.func @concrete_op(%arg0: !transfer.integer, %arg1: !transfer.integer, %arg2: !transfer.integer, %arg3: !transfer.integer) -> !transfer.integer {
    %0 = "transfer.or"(%arg2, %arg3) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %1 = "transfer.or"(%arg2, %arg3) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %2 = "transfer.lshr"(%1, %arg1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %3 = "transfer.or"(%0, %2) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %4 = "transfer.lshr"(%3, %arg0) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    return %4 : !transfer.integer
  }
  func.func @op_constraint(%arg0: !transfer.integer, %arg1: !transfer.integer, %arg2: !transfer.integer, %arg3: !transfer.integer) -> i1 {
    %0 = "transfer.or"(%arg2, %arg3) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %1 = "transfer.or"(%arg2, %arg3) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %2 = "transfer.lshr"(%1, %arg1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %constraint_2_0 = func.call @shift_lt_bw(%1, %arg1) : (!transfer.integer, !transfer.integer) -> i1
    %3 = "transfer.or"(%0, %2) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %constraint_4_0 = func.call @shift_lt_bw(%3, %arg0) : (!transfer.integer, !transfer.integer) -> i1
    %and_0 = arith.andi %constraint_2_0, %constraint_4_0 : i1
    return %and_0 : i1
  }
  func.func @shift_lt_bw(%arg0: !transfer.integer, %arg1: !transfer.integer) -> i1 {
    %bitwidth = "transfer.get_bit_width"(%arg0) : (!transfer.integer) -> !transfer.integer
    %shift_amt_lt_bw = "transfer.cmp"(%arg1, %bitwidth) {predicate = 6 : i64} : (!transfer.integer, !transfer.integer) -> i1
    return %shift_amt_lt_bw : i1
  }
}
