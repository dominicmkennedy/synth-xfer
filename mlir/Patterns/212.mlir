module {
  func.func @concrete_op(%arg0: !transfer.integer, %arg1: !transfer.integer, %arg2: !transfer.integer) -> !transfer.integer {
    %0 = "transfer.shl"(%arg2, %arg1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %1 = "transfer.xor"(%arg2, %0) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %2 = "transfer.and"(%arg0, %1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    return %2 : !transfer.integer
  }
  func.func @op_constraint(%arg0: !transfer.integer, %arg1: !transfer.integer, %arg2: !transfer.integer) -> i1 {
    %true = arith.constant true
    %0 = "transfer.shl"(%arg2, %arg1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %1 = call @shl_nsw(%arg2, %arg1) : (!transfer.integer, !transfer.integer) -> i1
    %2 = call @shifting_amount_less_bitwidth(%arg2, %arg1) : (!transfer.integer, !transfer.integer) -> i1
    %3 = "transfer.xor"(%arg2, %0) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %4 = "transfer.and"(%arg0, %3) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %5 = arith.andi %true, %1 : i1
    %6 = arith.andi %5, %2 : i1
    return %6 : i1
  }
  func.func @shl_nsw(%arg0: !transfer.integer, %arg1: !transfer.integer) -> i1 {
    %0 = "transfer.constant"(%arg1) {value = 0 : index} : (!transfer.integer) -> !transfer.integer
    %1 = "transfer.get_bit_width"(%arg0) : (!transfer.integer) -> !transfer.integer
    %2 = "transfer.cmp"(%arg1, %0) {predicate = 9 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %3 = "transfer.cmp"(%arg1, %1) {predicate = 7 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %4 = arith.andi %2, %3 : i1
    %5 = "transfer.countl_zero"(%arg0) : (!transfer.integer) -> !transfer.integer
    %6 = "transfer.countl_one"(%arg0) : (!transfer.integer) -> !transfer.integer
    %7 = "transfer.cmp"(%arg0, %0) {predicate = 5 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %8 = "transfer.cmp"(%arg1, %5) {predicate = 6 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %9 = "transfer.cmp"(%arg1, %6) {predicate = 6 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %10 = "transfer.select"(%7, %8, %9) : (i1, i1, i1) -> i1
    %11 = arith.andi %4, %10 : i1
    return %11 : i1
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