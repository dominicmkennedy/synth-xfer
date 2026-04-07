module {
  func.func @concrete_op(%arg0: !transfer.integer, %arg1: !transfer.integer) -> !transfer.integer {
    %0 = "transfer.lshr"(%arg0, %arg1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    return %0 : !transfer.integer
  }
  func.func @op_constraint(%arg0: !transfer.integer, %arg1: !transfer.integer) -> i1 {
    %bitwidth = "transfer.get_bit_width"(%arg0) : (!transfer.integer) -> !transfer.integer
    %shift_lt_bw = "transfer.cmp"(%arg1, %bitwidth) {predicate = 6 : i64} : (!transfer.integer, !transfer.integer) -> i1

    %lshr = "transfer.lshr"(%arg0, %arg1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %shl = "transfer.shl"(%lshr, %arg1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %exact = "transfer.cmp"(%shl, %arg0) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %res = arith.andi %shift_lt_bw, %exact : i1
    return %res : i1
  }
}
