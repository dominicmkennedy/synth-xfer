module {
  func.func @concrete_op(%arg0: !transfer.integer, %arg1: !transfer.integer, %arg2: !transfer.integer, %arg3: !transfer.integer, %arg4: !transfer.integer) -> !transfer.integer {
    %0 = "transfer.lshr"(%arg4, %arg3) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %1 = "transfer.and"(%arg2, %0) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %2 = "transfer.and"(%arg0, %arg1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %3 = "transfer.or"(%1, %2) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    return %3 : !transfer.integer
  }
  func.func @op_constraint(%arg0: !transfer.integer, %arg1: !transfer.integer, %arg2: !transfer.integer, %arg3: !transfer.integer, %arg4: !transfer.integer) -> i1 {
    %0 = "transfer.lshr"(%arg4, %arg3) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %ssa_0_con_0_z = func.call @shift_lt_bw(%arg4, %arg3) : (!transfer.integer, !transfer.integer) -> i1
    %1 = "transfer.and"(%arg2, %0) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %2 = "transfer.and"(%arg0, %arg1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %ssa_3_con_0_z = func.call @or_disjoint(%1, %2) : (!transfer.integer, !transfer.integer) -> i1
    %and_0 = arith.andi %ssa_0_con_0_z, %ssa_3_con_0_z : i1
    return %and_0 : i1
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
