module {
  func.func @concrete_op(%arg0: !transfer.integer, %arg1: !transfer.integer, %arg2: !transfer.integer) -> !transfer.integer {
    %0 = "transfer.shl"(%arg2, %arg1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %1 = "transfer.xor"(%arg0, %0) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    return %1 : !transfer.integer
  }
  func.func @op_constraint(%arg0: !transfer.integer, %arg1: !transfer.integer, %arg2: !transfer.integer) -> i1 {
    %ssa_0_con_0_z = func.call @shl_nuw(%arg2, %arg1) : (!transfer.integer, !transfer.integer) -> i1
    %ssa_0_con_1_z = func.call @shl_nsw(%arg2, %arg1) : (!transfer.integer, !transfer.integer) -> i1
    %ssa_0_con_2_z = func.call @shift_lt_bw(%arg2, %arg1) : (!transfer.integer, !transfer.integer) -> i1
    %and_0 = arith.andi %ssa_0_con_0_z, %ssa_0_con_1_z : i1
    %and_1 = arith.andi %and_0, %ssa_0_con_2_z : i1
    return %and_1 : i1
  }
  func.func @shl_nuw(%arg0: !transfer.integer, %arg1: !transfer.integer) -> i1 {
    %shl = "transfer.shl"(%arg0, %arg1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %lshr = "transfer.lshr"(%shl, %arg1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %nuw = "transfer.cmp"(%lshr, %arg0) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    return %nuw : i1
  }
  func.func @shl_nsw(%arg0: !transfer.integer, %arg1: !transfer.integer) -> i1 {
    %shl = "transfer.shl"(%arg0, %arg1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %ashr = "transfer.ashr"(%shl, %arg1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %nsw = "transfer.cmp"(%ashr, %arg0) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    return %nsw : i1
  }
  func.func @shift_lt_bw(%arg0: !transfer.integer, %arg1: !transfer.integer) -> i1 {
    %bitwidth = "transfer.get_bit_width"(%arg0) : (!transfer.integer) -> !transfer.integer
    %shift_amt_lt_bw = "transfer.cmp"(%arg1, %bitwidth) {predicate = 6 : i64} : (!transfer.integer, !transfer.integer) -> i1
    return %shift_amt_lt_bw : i1
  }
}
