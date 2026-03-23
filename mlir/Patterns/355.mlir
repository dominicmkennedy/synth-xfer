module {
  func.func @concrete_op(%arg0: !transfer.integer, %arg1: !transfer.integer, %arg2: !transfer.integer, %arg3: !transfer.integer, %arg4: !transfer.integer) -> !transfer.integer {
    %0 = "transfer.xor"(%arg3, %arg4) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %1 = "transfer.xor"(%arg2, %0) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %2 = "transfer.xor"(%arg1, %1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %3 = "transfer.lshr"(%2, %arg0) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    return %3 : !transfer.integer
  }
  func.func @op_constraint(%arg0: !transfer.integer, %arg1: !transfer.integer, %arg2: !transfer.integer, %arg3: !transfer.integer, %arg4: !transfer.integer) -> i1 {
    %true = arith.constant true
    %0 = "transfer.xor"(%arg3, %arg4) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %1 = "transfer.xor"(%arg2, %0) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %2 = "transfer.xor"(%arg1, %1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %3 = "transfer.lshr"(%2, %arg0) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %4 = call @shifting_amount_less_bitwidth(%2, %arg0) : (!transfer.integer, !transfer.integer) -> i1
    %5 = arith.andi %true, %4 : i1
    return %5 : i1
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