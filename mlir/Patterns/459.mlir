module {
  func.func @concrete_op(%arg0: !transfer.integer, %arg1: !transfer.integer, %arg2: !transfer.integer, %arg3: !transfer.integer, %arg4: !transfer.integer, %arg5: !transfer.integer) -> !transfer.integer {
    %0 = "transfer.lshr"(%arg5, %arg4) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %1 = "transfer.and"(%arg3, %0) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %2 = "transfer.or"(%arg2, %1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %3 = "transfer.lshr"(%arg1, %arg0) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %4 = "transfer.or"(%2, %3) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    return %4 : !transfer.integer
  }
  func.func @op_constraint(%arg0: !transfer.integer, %arg1: !transfer.integer, %arg2: !transfer.integer, %arg3: !transfer.integer, %arg4: !transfer.integer, %arg5: !transfer.integer) -> i1 {
    %true = arith.constant true
    %0 = "transfer.lshr"(%arg5, %arg4) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %1 = call @shifting_amount_less_bitwidth(%arg5, %arg4) : (!transfer.integer, !transfer.integer) -> i1
    %2 = "transfer.and"(%arg3, %0) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %3 = "transfer.or"(%arg2, %2) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %4 = call @or_disjoint(%arg2, %2) : (!transfer.integer, !transfer.integer) -> i1
    %5 = "transfer.lshr"(%arg1, %arg0) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %6 = call @shifting_amount_less_bitwidth(%arg1, %arg0) : (!transfer.integer, !transfer.integer) -> i1
    %7 = "transfer.or"(%3, %5) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %8 = call @or_disjoint(%3, %5) : (!transfer.integer, !transfer.integer) -> i1
    %9 = arith.andi %true, %1 : i1
    %10 = arith.andi %9, %4 : i1
    %11 = arith.andi %10, %6 : i1
    %12 = arith.andi %11, %8 : i1
    return %12 : i1
  }
  func.func @shifting_amount_less_bitwidth(%arg0: !transfer.integer, %arg1: !transfer.integer) -> i1 {
    %0 = "transfer.constant"(%arg1) {value = 0 : index} : (!transfer.integer) -> !transfer.integer
    %1 = "transfer.get_bit_width"(%arg0) : (!transfer.integer) -> !transfer.integer
    %2 = "transfer.cmp"(%arg1, %0) {predicate = 9 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %3 = "transfer.cmp"(%arg1, %1) {predicate = 7 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %4 = arith.andi %2, %3 : i1
    return %4 : i1
  }
  func.func @or_disjoint(%arg0: !transfer.integer, %arg1: !transfer.integer) -> i1 {
    %0 = "transfer.constant"(%arg1) {value = 0 : index} : (!transfer.integer) -> !transfer.integer
    %1 = "transfer.and"(%arg0, %arg1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %2 = "transfer.cmp"(%1, %0) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    return %2 : i1
  }
}