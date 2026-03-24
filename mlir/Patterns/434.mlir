module {
  func.func @concrete_op(%arg0: !transfer.integer, %arg1: !transfer.integer, %arg2: !transfer.integer) -> !transfer.integer {
    %0 = "transfer.mul"(%arg1, %arg2) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %1 = "transfer.sdiv"(%0, %arg0) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    return %1 : !transfer.integer
  }
  func.func @op_constraint(%arg0: !transfer.integer, %arg1: !transfer.integer, %arg2: !transfer.integer) -> i1 {
    %0 = "transfer.mul"(%arg1, %arg2) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %constraint_0_0 = func.call @mul_nsw(%arg1, %arg2) : (!transfer.integer, !transfer.integer) -> i1
    %constraint_1_0 = func.call @rhs_neq_zero(%0, %arg0) : (!transfer.integer, !transfer.integer) -> i1
    %constraint_1_1 = func.call @no_sdiv_ov(%0, %arg0) : (!transfer.integer, !transfer.integer) -> i1
    %and_0 = arith.andi %constraint_0_0, %constraint_1_0 : i1
    %and_1 = arith.andi %and_0, %constraint_1_1 : i1
    return %and_1 : i1
  }
  func.func @mul_nsw(%arg0: !transfer.integer, %arg1: !transfer.integer) -> i1 {
    %0 = "transfer.smul_overflow"(%arg0, %arg1) : (!transfer.integer, !transfer.integer) -> i1
    %true = arith.constant true
    %1 = arith.xori %0, %true : i1
    return %1 : i1
  }
  func.func @rhs_neq_zero(%arg0: !transfer.integer, %arg1: !transfer.integer) -> i1 {
    %0 = "transfer.constant"(%arg1) {value = 0 : index} : (!transfer.integer) -> !transfer.integer
    %1 = "transfer.cmp"(%0, %arg1) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %true = arith.constant true
    %2 = arith.xori %1, %true : i1
    return %2 : i1
  }
  func.func @no_sdiv_ov(%arg0: !transfer.integer, %arg1: !transfer.integer) -> i1 {
    %true = arith.constant true
    return %true : i1
  }
}
