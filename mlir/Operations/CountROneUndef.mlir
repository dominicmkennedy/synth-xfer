module {
  func.func @concrete_op(%arg0: !transfer.integer) -> !transfer.integer {
    %0 = "transfer.countr_one"(%arg0) : (!transfer.integer) -> !transfer.integer
    return %0 : !transfer.integer
  }
  func.func @op_constraint(%arg0: !transfer.integer) -> i1 {
    %all_ones = "transfer.get_all_ones"(%arg0) : (!transfer.integer) -> !transfer.integer
    %not_all_ones = "transfer.cmp"(%arg0, %all_ones) {predicate = 1 : i64} : (!transfer.integer, !transfer.integer) -> i1
    return %not_all_ones : i1
  }
}
