module {
  func.func @concrete_op(%arg0: !transfer.integer, %arg1: !transfer.integer, %arg2: !transfer.integer, %arg3: !transfer.integer, %arg4: !transfer.integer) -> !transfer.integer {
    %0 = "transfer.shl"(%arg4, %arg3) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %1 = "transfer.and"(%arg2, %0) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %2 = "transfer.or"(%arg1, %1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %3 = "transfer.or"(%arg0, %2) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    return %3 : !transfer.integer
  }
  func.func @op_constraint(%arg0: !transfer.integer, %arg1: !transfer.integer, %arg2: !transfer.integer, %arg3: !transfer.integer, %arg4: !transfer.integer) -> i1 {
    %true = arith.constant true
    %0 = "transfer.shl"(%arg4, %arg3) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %1 = call @shifting_amount_less_bitwidth(%arg4, %arg3) : (!transfer.integer, !transfer.integer) -> i1
    %2 = "transfer.and"(%arg2, %0) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %3 = "transfer.or"(%arg1, %2) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %4 = call @or_disjoint(%arg1, %2) : (!transfer.integer, !transfer.integer) -> i1
    %5 = "transfer.or"(%arg0, %3) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %6 = call @or_disjoint(%arg0, %3) : (!transfer.integer, !transfer.integer) -> i1
    %7 = arith.andi %true, %1 : i1
    %8 = arith.andi %7, %4 : i1
    %9 = arith.andi %8, %6 : i1
    return %9 : i1
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