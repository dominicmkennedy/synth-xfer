module {
  func.func @concrete_op(%arg0: !transfer.integer, %arg1: !transfer.integer, %arg2: !transfer.integer) -> !transfer.integer {
    %0 = "transfer.sub"(%arg2, %arg1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %1 = "transfer.udiv"(%0, %arg0) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    return %1 : !transfer.integer
  }
  func.func @op_constraint(%arg0: !transfer.integer, %arg1: !transfer.integer, %arg2: !transfer.integer) -> i1 {
    %true = arith.constant true
    %0 = "transfer.sub"(%arg2, %arg1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %1 = "transfer.udiv"(%0, %arg0) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %2 = call @udiv_exact(%0, %arg0) : (!transfer.integer, !transfer.integer) -> i1
    %3 = call @rhs_neq_zero(%0, %arg0) : (!transfer.integer, !transfer.integer) -> i1
    %4 = arith.andi %true, %2 : i1
    %5 = arith.andi %4, %3 : i1
    return %5 : i1
  }
  func.func @udiv_exact(%arg0: !transfer.integer, %arg1: !transfer.integer) -> i1 {
    %0 = "transfer.constant"(%arg1) {value = 0 : index} : (!transfer.integer) -> !transfer.integer
    %1 = "transfer.constant"(%arg1) {value = 1 : index} : (!transfer.integer) -> !transfer.integer
    %2 = "transfer.cmp"(%0, %arg1) {predicate = 1 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %3 = "transfer.select"(%2, %arg1, %1) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %4 = "transfer.urem"(%arg0, %3) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %5 = "transfer.cmp"(%4, %0) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %6 = arith.andi %5, %2 : i1
    return %6 : i1
  }
  func.func @rhs_neq_zero(%arg0: !transfer.integer, %arg1: !transfer.integer) -> i1 {
    %0 = "transfer.constant"(%arg1) {value = 0 : index} : (!transfer.integer) -> !transfer.integer
    %1 = "transfer.cmp"(%0, %arg1) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %true = arith.constant true
    %2 = arith.xori %1, %true : i1
    return %2 : i1
  }
}