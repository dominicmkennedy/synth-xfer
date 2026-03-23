module {
  func.func @concrete_op(%arg0: !transfer.integer, %arg1: !transfer.integer, %arg2: !transfer.integer) -> !transfer.integer {
    %0 = "transfer.and"(%arg1, %arg2) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %1 = "transfer.lshr"(%0, %arg0) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    return %1 : !transfer.integer
  }
  func.func @op_constraint(%arg0: !transfer.integer, %arg1: !transfer.integer, %arg2: !transfer.integer) -> i1 {
    %true = arith.constant true
    %0 = "transfer.and"(%arg1, %arg2) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %1 = "transfer.lshr"(%0, %arg0) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %2 = call @lshr_exact(%0, %arg0) : (!transfer.integer, !transfer.integer) -> i1
    %3 = call @shifting_amount_less_bitwidth(%0, %arg0) : (!transfer.integer, !transfer.integer) -> i1
    %4 = arith.andi %true, %2 : i1
    %5 = arith.andi %4, %3 : i1
    return %5 : i1
  }
  func.func @lshr_exact(%arg0: !transfer.integer, %arg1: !transfer.integer) -> i1 {
    %0 = "transfer.constant"(%arg1) {value = 0 : index} : (!transfer.integer) -> !transfer.integer
    %1 = "transfer.get_bit_width"(%arg0) : (!transfer.integer) -> !transfer.integer
    %2 = "transfer.cmp"(%arg1, %0) {predicate = 9 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %3 = "transfer.cmp"(%arg1, %1) {predicate = 7 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %4 = arith.andi %2, %3 : i1
    %5 = "transfer.lshr"(%arg0, %arg1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %6 = "transfer.shl"(%5, %arg1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %7 = "transfer.cmp"(%6, %arg0) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %8 = arith.andi %4, %7 : i1
    return %8 : i1
  }
  func.func @shifting_amount_less_bitwidth(%arg0: !transfer.integer, %arg1: !transfer.integer) -> i1 {
    %0 = "transfer.constant"(%arg1) {value = 0 : index} : (!transfer.integer) -> !transfer.integer
    %1 = "transfer.get_bit_width"(%arg0) : (!transfer.integer) -> !transfer.integer
    %2 = "transfer.cmp"(%arg1, %0) {predicate = 9 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %3 = "transfer.cmp"(%arg1, %1) {predicate = 7 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %4 = arith.andi %2, %3 : i1
    return %4 : i1
  }
}