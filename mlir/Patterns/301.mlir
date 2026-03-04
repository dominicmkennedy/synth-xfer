module {
  func.func @concrete_op(%arg0: !transfer.integer, %arg1: !transfer.integer, %arg2: !transfer.integer, %arg3: !transfer.integer, %arg4: !transfer.integer, %arg5: !transfer.integer) -> !transfer.integer {
    %0 = "transfer.mul"(%arg4, %arg5) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %1 = "transfer.add"(%arg3, %0) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %2 = "transfer.and"(%arg2, %1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %3 = "transfer.add"(%arg0, %arg1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %4 = "transfer.add"(%2, %3) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    return %4 : !transfer.integer
  }
  func.func @op_constraint(%arg0: !transfer.integer, %arg1: !transfer.integer, %arg2: !transfer.integer, %arg3: !transfer.integer, %arg4: !transfer.integer, %arg5: !transfer.integer) -> i1 {
    %true = arith.constant true
    %0 = "transfer.mul"(%arg4, %arg5) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %1 = call @mul_nuw(%arg4, %arg5) : (!transfer.integer, !transfer.integer) -> i1
    %2 = "transfer.add"(%arg3, %0) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %3 = call @add_nuw(%arg3, %0) : (!transfer.integer, !transfer.integer) -> i1
    %4 = "transfer.and"(%arg2, %2) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %5 = "transfer.add"(%arg0, %arg1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %6 = "transfer.add"(%4, %5) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %7 = call @add_nuw(%4, %5) : (!transfer.integer, !transfer.integer) -> i1
    %8 = arith.andi %true, %1 : i1
    %9 = arith.andi %8, %3 : i1
    %10 = arith.andi %9, %7 : i1
    return %10 : i1
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