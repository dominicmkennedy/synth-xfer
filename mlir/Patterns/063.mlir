module {
  func.func @concrete_op(%arg0: !transfer.integer, %arg1: !transfer.integer, %arg2: !transfer.integer, %arg3: !transfer.integer) -> !transfer.integer {
    %0 = "transfer.and"(%arg2, %arg3) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %1 = "transfer.or"(%arg1, %0) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %2 = "transfer.or"(%arg0, %1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    return %2 : !transfer.integer
  }
  func.func @op_constraint(%arg0: !transfer.integer, %arg1: !transfer.integer, %arg2: !transfer.integer, %arg3: !transfer.integer) -> i1 {
    %true = arith.constant true
    %0 = "transfer.and"(%arg2, %arg3) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %1 = "transfer.or"(%arg1, %0) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %2 = call @or_disjoint(%arg1, %0) : (!transfer.integer, !transfer.integer) -> i1
    %3 = "transfer.or"(%arg0, %1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %4 = call @or_disjoint(%arg0, %1) : (!transfer.integer, !transfer.integer) -> i1
    %5 = arith.andi %true, %2 : i1
    %6 = arith.andi %5, %4 : i1
    return %6 : i1
  }
  func.func @or_disjoint(%arg0: !transfer.integer, %arg1: !transfer.integer) -> i1 {
    %0 = "transfer.constant"(%arg1) {value = 0 : index} : (!transfer.integer) -> !transfer.integer
    %1 = "transfer.and"(%arg0, %arg1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %2 = "transfer.cmp"(%1, %0) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    return %2 : i1
  }
}