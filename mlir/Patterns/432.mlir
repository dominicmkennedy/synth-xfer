module {
  func.func @concrete_op(%arg0: !transfer.integer, %arg1: !transfer.integer, %arg2: !transfer.integer, %arg3: !transfer.integer, %arg4: !transfer.integer, %arg5: !transfer.integer) -> !transfer.integer {
    %0 = "transfer.add"(%arg4, %arg5) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %1 = "transfer.mul"(%arg3, %0) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %2 = "transfer.add"(%arg1, %arg2) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %3 = "transfer.add"(%1, %2) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %4 = "transfer.and"(%arg0, %3) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    return %4 : !transfer.integer
  }
  func.func @op_constraint(%arg0: !transfer.integer, %arg1: !transfer.integer, %arg2: !transfer.integer, %arg3: !transfer.integer, %arg4: !transfer.integer, %arg5: !transfer.integer) -> i1 {
    %0 = "transfer.add"(%arg4, %arg5) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %1 = "transfer.mul"(%arg3, %0) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %constraint_1_0 = func.call @mul_nuw(%arg3, %0) : (!transfer.integer, !transfer.integer) -> i1
    %2 = "transfer.add"(%arg1, %arg2) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %constraint_3_0 = func.call @add_nuw(%1, %2) : (!transfer.integer, !transfer.integer) -> i1
    %and_0 = arith.andi %constraint_1_0, %constraint_3_0 : i1
    return %and_0 : i1
  }
  func.func @mul_nuw(%arg0: !transfer.integer, %arg1: !transfer.integer) -> i1 {
    %0 = "transfer.umul_overflow"(%arg0, %arg1) : (!transfer.integer, !transfer.integer) -> i1
    %true = arith.constant true
    %1 = arith.xori %0, %true : i1
    return %1 : i1
  }
  func.func @add_nuw(%arg0: !transfer.integer, %arg1: !transfer.integer) -> i1 {
    %0 = "transfer.add"(%arg0, %arg1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %1 = "transfer.cmp"(%0, %arg0) {predicate = 9 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %2 = "transfer.cmp"(%0, %arg1) {predicate = 9 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %3 = arith.andi %1, %2 : i1
    return %3 : i1
  }
}
