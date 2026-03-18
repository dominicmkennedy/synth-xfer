module {
  func.func @concrete_op(%arg0: !transfer.integer, %arg1: !transfer.integer) -> !transfer.integer {
    %0 = "transfer.lshr"(%arg0, %arg1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    return %0 : !transfer.integer
  }
  func.func @op_constraint(%arg0: !transfer.integer, %arg1: !transfer.integer) -> i1 {
    %ct_0 = "transfer.countr_zero"(%arg0) : (!transfer.integer) -> !transfer.integer
    %exact = "transfer.cmp"(%ct_0, %arg1) {predicate = 9 : i64} : (!transfer.integer, !transfer.integer) -> i1

    %bitwidth = "transfer.get_bit_width"(%arg0) : (!transfer.integer) -> !transfer.integer
    %shift_lt_bw = "transfer.cmp"(%arg1, %bitwidth) {predicate = 6 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %res = arith.andi %shift_lt_bw, %exact : i1
    return %res : i1
  }
}
