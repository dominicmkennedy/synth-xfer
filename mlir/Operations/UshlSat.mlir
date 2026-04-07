module {
  func.func @concrete_op(%arg0: !transfer.integer, %arg1: !transfer.integer) -> !transfer.integer {
    %shl = "transfer.shl"(%arg0, %arg1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %ushl_ov = "transfer.ushl_overflow"(%arg0, %arg1) {predicate = 9 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %uint_max = "transfer.get_all_ones"(%arg0) : (!transfer.integer) -> !transfer.integer
    %result = "transfer.select"(%ushl_ov, %uint_max, %shl) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    return %result : !transfer.integer
  }
}
