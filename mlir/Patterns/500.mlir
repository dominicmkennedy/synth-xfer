module {
  func.func @concrete_op(%arg0: !transfer.integer, %arg1: !transfer.integer, %arg2: !transfer.integer, %arg3: !transfer.integer) -> !transfer.integer {
    %0 = "transfer.add"(%arg2, %arg3) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %1 = "transfer.lshr"(%0, %arg3) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %2 = "transfer.shl"(%1, %arg1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %3 = "transfer.add"(%arg0, %2) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    return %3 : !transfer.integer
  }
  func.func @op_constraint(%arg0: !transfer.integer, %arg1: !transfer.integer, %arg2: !transfer.integer, %arg3: !transfer.integer) -> i1 {
    %true = arith.constant true
    %0 = "transfer.add"(%arg2, %arg3) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %1 = "transfer.lshr"(%0, %arg3) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %2 = call @shifting_amount_less_bitwidth(%0, %arg3) : (!transfer.integer, !transfer.integer) -> i1
    %3 = "transfer.shl"(%1, %arg1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %4 = call @shifting_amount_less_bitwidth(%1, %arg1) : (!transfer.integer, !transfer.integer) -> i1
    %5 = "transfer.add"(%arg0, %3) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %6 = arith.andi %true, %2 : i1
    %7 = arith.andi %6, %4 : i1
    return %7 : i1
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