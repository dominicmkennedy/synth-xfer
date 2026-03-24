module {
  func.func @concrete_op(%arg0: !transfer.integer, %arg1: !transfer.integer, %arg2: !transfer.integer) -> !transfer.integer {
    %0 = "transfer.add"(%arg1, %arg2) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %1 = "transfer.sub"(%0, %arg0) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    return %1 : !transfer.integer
  }
  func.func @op_constraint(%arg0: !transfer.integer, %arg1: !transfer.integer, %arg2: !transfer.integer) -> i1 {
    %0 = "transfer.add"(%arg1, %arg2) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %ssa_1_con_0_z = func.call @sub_nuw(%0, %arg0) : (!transfer.integer, !transfer.integer) -> i1
    return %ssa_1_con_0_z : i1
  }
  func.func @sub_nuw(%arg0: !transfer.integer, %arg1: !transfer.integer) -> i1 {
    %usub_ov = "transfer.usub_overflow"(%arg0, %arg1) : (!transfer.integer, !transfer.integer) -> i1
    %true = arith.constant true
    %no_ov = arith.xori %usub_ov, %true : i1
    return %no_ov : i1
  }
}
