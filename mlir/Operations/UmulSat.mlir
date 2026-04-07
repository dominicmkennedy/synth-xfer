module {
  func.func @concrete_op(%arg0: !transfer.integer, %arg1: !transfer.integer) -> !transfer.integer {
    %mul = "transfer.mul"(%arg0, %arg1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %umul_ov = "transfer.umul_overflow"(%arg0, %arg1) : (!transfer.integer, !transfer.integer) -> i1
    %uint_max = "transfer.get_all_ones"(%arg0) : (!transfer.integer) -> !transfer.integer
    %result = "transfer.select"(%umul_ov, %uint_max, %mul) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    return %result : !transfer.integer
  }
}
