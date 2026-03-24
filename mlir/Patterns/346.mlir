module {
  func.func @concrete_op(%arg0: !transfer.integer, %arg1: !transfer.integer, %arg2: !transfer.integer) -> !transfer.integer {
    %0 = "transfer.and"(%arg1, %arg2) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %1 = "transfer.sub"(%arg0, %0) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    return %1 : !transfer.integer
  }
  func.func @op_constraint(%arg0: !transfer.integer, %arg1: !transfer.integer, %arg2: !transfer.integer) -> i1 {
    %0 = "transfer.and"(%arg1, %arg2) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %constraint_1_0 = func.call @sub_nuw(%arg0, %0) : (!transfer.integer, !transfer.integer) -> i1
    %constraint_1_1 = func.call @sub_nsw(%arg0, %0) : (!transfer.integer, !transfer.integer) -> i1
    %and_0 = arith.andi %constraint_1_0, %constraint_1_1 : i1
    return %and_0 : i1
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
