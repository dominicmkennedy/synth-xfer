module {
  func.func @concrete_op(%arg0: !transfer.integer, %arg1: !transfer.integer, %arg2: !transfer.integer) -> !transfer.integer {
    %0 = "transfer.mul"(%arg1, %arg2) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %1 = "transfer.sdiv"(%0, %arg0) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    return %1 : !transfer.integer
  }
  func.func @op_constraint(%arg0: !transfer.integer, %arg1: !transfer.integer, %arg2: !transfer.integer) -> i1 {
    %true = arith.constant true
    %0 = "transfer.mul"(%arg1, %arg2) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %1 = call @mul_nsw(%arg1, %arg2) : (!transfer.integer, !transfer.integer) -> i1
    %2 = "transfer.sdiv"(%0, %arg0) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %3 = call @rhs_neq_zero(%0, %arg0) : (!transfer.integer, !transfer.integer) -> i1
    %4 = arith.andi %true, %1 : i1
    %5 = arith.andi %4, %3 : i1
    return %5 : i1
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
}