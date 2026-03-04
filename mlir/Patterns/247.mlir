module {
  func.func @concrete_op(%arg0: !transfer.integer, %arg1: !transfer.integer, %arg2: !transfer.integer, %arg3: !transfer.integer, %arg4: !transfer.integer) -> !transfer.integer {
    %0 = "transfer.shl"(%arg4, %arg3) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %1 = "transfer.or"(%arg2, %0) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %2 = "transfer.shl"(%arg1, %arg0) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %3 = "transfer.or"(%1, %2) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    return %3 : !transfer.integer
  }
  func.func @op_constraint(%arg0: !transfer.integer, %arg1: !transfer.integer, %arg2: !transfer.integer, %arg3: !transfer.integer, %arg4: !transfer.integer) -> i1 {
    %true = arith.constant true
    %0 = "transfer.shl"(%arg4, %arg3) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %1 = call @shl_nuw(%arg4, %arg3) : (!transfer.integer, !transfer.integer) -> i1
    %2 = call @shl_nsw(%arg4, %arg3) : (!transfer.integer, !transfer.integer) -> i1
    %3 = call @shifting_amount_less_bitwidth(%arg4, %arg3) : (!transfer.integer, !transfer.integer) -> i1
    %4 = "transfer.or"(%arg2, %0) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %5 = call @or_disjoint(%arg2, %0) : (!transfer.integer, !transfer.integer) -> i1
    %6 = "transfer.shl"(%arg1, %arg0) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %7 = call @shl_nuw(%arg1, %arg0) : (!transfer.integer, !transfer.integer) -> i1
    %8 = call @shl_nsw(%arg1, %arg0) : (!transfer.integer, !transfer.integer) -> i1
    %9 = call @shifting_amount_less_bitwidth(%arg1, %arg0) : (!transfer.integer, !transfer.integer) -> i1
    %10 = "transfer.or"(%4, %6) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %11 = call @or_disjoint(%4, %6) : (!transfer.integer, !transfer.integer) -> i1
    %12 = arith.andi %true, %1 : i1
    %13 = arith.andi %12, %2 : i1
    %14 = arith.andi %13, %3 : i1
    %15 = arith.andi %14, %5 : i1
    %16 = arith.andi %15, %7 : i1
    %17 = arith.andi %16, %8 : i1
    %18 = arith.andi %17, %9 : i1
    %19 = arith.andi %18, %11 : i1
    return %19 : i1
  }
  func.func @shl_nuw(%arg0: !transfer.integer, %arg1: !transfer.integer) -> i1 {
    %0 = "transfer.constant"(%arg1) {value = 0 : index} : (!transfer.integer) -> !transfer.integer
    %1 = "transfer.get_bit_width"(%arg0) : (!transfer.integer) -> !transfer.integer
    %2 = "transfer.cmp"(%arg1, %0) {predicate = 9 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %3 = "transfer.cmp"(%arg1, %1) {predicate = 7 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %4 = arith.andi %2, %3 : i1
    %5 = "transfer.countl_zero"(%arg0) : (!transfer.integer) -> !transfer.integer
    %6 = "transfer.cmp"(%5, %arg1) {predicate = 9 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %7 = arith.andi %4, %6 : i1
    return %7 : i1
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
  func.func @or_disjoint(%arg0: !transfer.integer, %arg1: !transfer.integer) -> i1 {
    %0 = "transfer.constant"(%arg1) {value = 0 : index} : (!transfer.integer) -> !transfer.integer
    %1 = "transfer.and"(%arg0, %arg1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %2 = "transfer.cmp"(%1, %0) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    return %2 : i1
  }
}