module {
  func.func @concrete_op(%arg0: !transfer.integer, %arg1: !transfer.integer, %arg2: !transfer.integer, %arg3: !transfer.integer) -> !transfer.integer {
    %0 = "transfer.shl"(%arg3, %arg2) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %1 = "transfer.and"(%arg1, %0) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %2 = "transfer.or"(%arg0, %1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    return %2 : !transfer.integer
  }
  func.func @op_constraint(%arg0: !transfer.integer, %arg1: !transfer.integer, %arg2: !transfer.integer, %arg3: !transfer.integer) -> i1 {
    %0 = "transfer.shl"(%arg3, %arg2) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %ssa_0_con_0_z = func.call @shl_nuw(%arg3, %arg2) : (!transfer.integer, !transfer.integer) -> i1
    %ssa_0_con_1_z = func.call @shl_nsw(%arg3, %arg2) : (!transfer.integer, !transfer.integer) -> i1
    %ssa_0_con_2_z = func.call @shift_lt_bw(%arg3, %arg2) : (!transfer.integer, !transfer.integer) -> i1
    %1 = "transfer.and"(%arg1, %0) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %ssa_2_con_0_z = func.call @or_disjoint(%arg0, %1) : (!transfer.integer, !transfer.integer) -> i1
    %and_0 = arith.andi %ssa_0_con_0_z, %ssa_0_con_1_z : i1
    %and_1 = arith.andi %and_0, %ssa_0_con_2_z : i1
    %and_2 = arith.andi %and_1, %ssa_2_con_0_z : i1
    return %and_2 : i1
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
  func.func @or_disjoint(%arg0: !transfer.integer, %arg1: !transfer.integer) -> i1 {
    %0 = "transfer.constant"(%arg1) {value = 0 : index} : (!transfer.integer) -> !transfer.integer
    %1 = "transfer.and"(%arg0, %arg1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %2 = "transfer.cmp"(%1, %0) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    return %2 : i1
  }
}
