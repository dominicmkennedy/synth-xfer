module {
  func.func @concrete_op(%arg0: !transfer.integer, %arg1: !transfer.integer) -> !transfer.integer {
    %add = "transfer.add"(%arg0, %arg1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %uadd_ov = "transfer.uadd_overflow"(%arg0, %arg1) : (!transfer.integer, !transfer.integer) -> i1
    %uint_max = "transfer.get_all_ones"(%arg0) : (!transfer.integer) -> !transfer.integer
    %result = "transfer.select"(%uadd_ov, %uint_max, %add) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    return %result : !transfer.integer
  }
}
