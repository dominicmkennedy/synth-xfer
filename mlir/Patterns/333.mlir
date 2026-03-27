module {
  func.func @concrete_op(%arg0: !transfer.integer, %arg1: !transfer.integer, %arg2: !transfer.integer) -> !transfer.integer {
    %0 = "transfer.mul"(%arg1, %arg2) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %1 = "transfer.lshr"(%0, %arg0) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %2 = "transfer.xor"(%0, %1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    return %2 : !transfer.integer
  }
  func.func @op_constraint(%arg0: !transfer.integer, %arg1: !transfer.integer, %arg2: !transfer.integer) -> i1 {
    %ssa_0_con_0_z = func.call @mul_nuw(%arg1, %arg2) : (!transfer.integer, !transfer.integer) -> i1
    %0 = "transfer.mul"(%arg1, %arg2) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %ssa_1_con_0_z = func.call @shift_lt_bw(%0, %arg0) : (!transfer.integer, !transfer.integer) -> i1
    %and_0 = arith.andi %ssa_0_con_0_z, %ssa_1_con_0_z : i1
    return %and_0 : i1
  }
  func.func @mul_nuw(%arg0: !transfer.integer, %arg1: !transfer.integer) -> i1 {
    %0 = "transfer.umul_overflow"(%arg0, %arg1) : (!transfer.integer, !transfer.integer) -> i1
    %true = arith.constant true
    %1 = arith.xori %0, %true : i1
    return %1 : i1
  }
  func.func @shift_lt_bw(%arg0: !transfer.integer, %arg1: !transfer.integer) -> i1 {
    %bitwidth = "transfer.get_bit_width"(%arg0) : (!transfer.integer) -> !transfer.integer
    %shift_amt_lt_bw = "transfer.cmp"(%arg1, %bitwidth) {predicate = 6 : i64} : (!transfer.integer, !transfer.integer) -> i1
    return %shift_amt_lt_bw : i1
  }
}
