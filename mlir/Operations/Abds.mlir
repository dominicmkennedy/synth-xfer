module {
  func.func @concrete_op(%arg0: !transfer.integer, %arg1: !transfer.integer) -> !transfer.integer {
    %arg0_sub_arg1 = "transfer.sub"(%arg0, %arg1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %arg1_sub_arg0 = "transfer.sub"(%arg1, %arg0) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %arg0_sge_arg1 = "transfer.cmp"(%arg0, %arg1) {predicate = 5 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %result = "transfer.select"(%arg0_sge_arg1, %arg0_sub_arg1, %arg1_sub_arg0) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    return %result : !transfer.integer
  }
}
