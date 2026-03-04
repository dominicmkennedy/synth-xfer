module {
  func.func @concrete_op(%arg0: !transfer.integer, %arg1: !transfer.integer, %arg2: !transfer.integer) -> !transfer.integer {
    %0 = "transfer.sdiv"(%arg2, %arg0) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %1 = "transfer.add"(%arg1, %0) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    return %1 : !transfer.integer
  }
  func.func @op_constraint(%arg0: !transfer.integer, %arg1: !transfer.integer, %arg2: !transfer.integer) -> i1 {
    %true = arith.constant true
    %0 = "transfer.sdiv"(%arg2, %arg0) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %1 = call @sidv_exact(%arg2, %arg0) : (!transfer.integer, !transfer.integer) -> i1
    %2 = call @rhs_neq_zero(%arg2, %arg0) : (!transfer.integer, !transfer.integer) -> i1
    %3 = "transfer.add"(%arg1, %0) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %4 = call @add_nsw(%arg1, %0) : (!transfer.integer, !transfer.integer) -> i1
    %5 = arith.andi %true, %1 : i1
    %6 = arith.andi %5, %2 : i1
    %7 = arith.andi %6, %4 : i1
    return %7 : i1
  }
  func.func @sidv_exact(%arg0: !transfer.integer, %arg1: !transfer.integer) -> i1 {
    %0 = "transfer.constant"(%arg1) {value = 0 : index} : (!transfer.integer) -> !transfer.integer
    %1 = "transfer.cmp"(%0, %arg1) {predicate = 1 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %2 = "transfer.cmp"(%0, %arg0) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %3 = "transfer.add"(%arg0, %arg0) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %4 = "transfer.cmp"(%3, %0) {predicate = 1 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %5 = arith.ori %2, %4 : i1
    %6 = "transfer.get_all_ones"(%arg0) : (!transfer.integer) -> !transfer.integer
    %7 = "transfer.cmp"(%6, %arg1) {predicate = 1 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %8 = arith.ori %5, %7 : i1
    %9 = arith.andi %1, %8 : i1
    %10 = "transfer.constant"(%arg1) {value = 1 : index} : (!transfer.integer) -> !transfer.integer
    %11 = "transfer.select"(%1, %arg1, %10) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %12 = "transfer.srem"(%arg0, %11) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %13 = "transfer.cmp"(%12, %0) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %14 = arith.andi %13, %9 : i1
    return %14 : i1
  }
  func.func @rhs_neq_zero(%arg0: !transfer.integer, %arg1: !transfer.integer) -> i1 {
    %0 = "transfer.constant"(%arg1) {value = 0 : index} : (!transfer.integer) -> !transfer.integer
    %1 = "transfer.cmp"(%0, %arg1) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %true = arith.constant true
    %2 = arith.xori %1, %true : i1
    return %2 : i1
  }
  func.func @add_nsw(%arg0: !transfer.integer, %arg1: !transfer.integer) -> i1 {
    %0 = "transfer.add"(%arg0, %arg1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %1 = "transfer.xor"(%arg0, %0) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %2 = "transfer.xor"(%arg1, %0) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %3 = "transfer.and"(%1, %2) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %4 = "transfer.constant"(%arg0) {value = 0 : index} : (!transfer.integer) -> !transfer.integer
    %5 = "transfer.cmp"(%3, %4) {predicate = 5 : i64} : (!transfer.integer, !transfer.integer) -> i1
    return %5 : i1
  }
}