module {
  func.func @concrete_op(%arg0: !transfer.integer, %arg1: !transfer.integer, %arg2: !transfer.integer) -> !transfer.integer {
    %0 = "transfer.ashr"(%arg2, %arg1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %1 = "transfer.sub"(%arg0, %0) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    return %1 : !transfer.integer
  }
  func.func @op_constraint(%arg0: !transfer.integer, %arg1: !transfer.integer, %arg2: !transfer.integer) -> i1 {
    %0 = "transfer.ashr"(%arg2, %arg1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %ssa_0_con_0_z = func.call @ashr_exact(%arg2, %arg1) : (!transfer.integer, !transfer.integer) -> i1
    %ssa_0_con_1_z = func.call @shift_lt_bw(%arg2, %arg1) : (!transfer.integer, !transfer.integer) -> i1
    %ssa_1_con_0_z = func.call @sub_nuw(%arg0, %0) : (!transfer.integer, !transfer.integer) -> i1
    %ssa_1_con_1_z = func.call @sub_nsw(%arg0, %0) : (!transfer.integer, !transfer.integer) -> i1
    %and_0 = arith.andi %ssa_0_con_0_z, %ssa_0_con_1_z : i1
    %and_1 = arith.andi %and_0, %ssa_1_con_0_z : i1
    %and_2 = arith.andi %and_1, %ssa_1_con_1_z : i1
    return %and_2 : i1
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
  func.func @sub_nuw(%arg0: !transfer.integer, %arg1: !transfer.integer) -> i1 {
    %usub_ov = "transfer.usub_overflow"(%arg0, %arg1) : (!transfer.integer, !transfer.integer) -> i1
    %true = arith.constant true
    %no_ov = arith.xori %usub_ov, %true : i1
    return %no_ov : i1
  }
  func.func @sub_nsw(%arg0: !transfer.integer, %arg1: !transfer.integer) -> i1 {
    %ssub_ov = "transfer.ssub_overflow"(%arg0, %arg1) : (!transfer.integer, !transfer.integer) -> i1
    %true = arith.constant true
    %no_ov = arith.xori %ssub_ov, %true : i1
    return %no_ov : i1
  }
}
