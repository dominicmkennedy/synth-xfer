module {
  func.func @concrete_op(%arg0: !transfer.integer, %arg1: !transfer.integer, %arg2: !transfer.integer) -> !transfer.integer {
    %0 = "transfer.add"(%arg1, %arg2) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %1 = "transfer.sub"(%0, %arg0) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    return %1 : !transfer.integer
  }
  func.func @op_constraint(%arg0: !transfer.integer, %arg1: !transfer.integer, %arg2: !transfer.integer) -> i1 {
    %true = arith.constant true
    %0 = "transfer.add"(%arg1, %arg2) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %1 = "transfer.sub"(%0, %arg0) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %2 = call @sub_nuw(%0, %arg0) : (!transfer.integer, !transfer.integer) -> i1
    %3 = arith.andi %true, %2 : i1
    return %3 : i1
  }
  func.func @sub_nuw(%arg0: !transfer.integer, %arg1: !transfer.integer) -> i1 {
    %0 = "transfer.cmp"(%arg0, %arg1) {predicate = 9 : i64} : (!transfer.integer, !transfer.integer) -> i1
    return %0 : i1
  }
}