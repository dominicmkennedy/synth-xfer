module {
  func.func @concrete_op(%arg0: !transfer.integer, %arg1: !transfer.integer, %arg2: !transfer.integer, %arg3: !transfer.integer, %arg4: !transfer.integer) -> !transfer.integer {
    %0 = "transfer.add"(%arg3, %arg4) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %1 = "transfer.sub"(%arg2, %arg1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %2 = "transfer.and"(%0, %1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %3 = "transfer.add"(%arg0, %2) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    return %3 : !transfer.integer
  }
  func.func @op_constraint(%arg0: !transfer.integer, %arg1: !transfer.integer, %arg2: !transfer.integer, %arg3: !transfer.integer, %arg4: !transfer.integer) -> i1 {
    %true = arith.constant true
    %0 = "transfer.add"(%arg3, %arg4) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %1 = call @add_nuw(%arg3, %arg4) : (!transfer.integer, !transfer.integer) -> i1
    %2 = "transfer.sub"(%arg2, %arg1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %3 = "transfer.and"(%0, %2) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %4 = "transfer.add"(%arg0, %3) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %5 = call @add_nuw(%arg0, %3) : (!transfer.integer, !transfer.integer) -> i1
    %6 = arith.andi %true, %1 : i1
    %7 = arith.andi %6, %5 : i1
    return %7 : i1
  }
  func.func @add_nuw(%arg0: !transfer.integer, %arg1: !transfer.integer) -> i1 {
    %0 = "transfer.add"(%arg0, %arg1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %1 = "transfer.cmp"(%0, %arg0) {predicate = 9 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %2 = "transfer.cmp"(%0, %arg1) {predicate = 9 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %3 = arith.andi %1, %2 : i1
    return %3 : i1
  }
}