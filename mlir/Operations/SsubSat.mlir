module {
  func.func @concrete_op(%arg0: !transfer.integer, %arg1: !transfer.integer) -> !transfer.integer {
    %sub = "transfer.sub"(%arg0, %arg1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %ssub_ov = "transfer.ssub_overflow"(%arg0, %arg1) : (!transfer.integer, !transfer.integer) -> i1
    %const_0 = "transfer.constant"(%arg0) {value = 0 : index} : (!transfer.integer) -> !transfer.integer
    %int_min = "transfer.get_signed_min_value"(%arg0) : (!transfer.integer) -> !transfer.integer
    %int_max = "transfer.get_signed_max_value"(%arg0) : (!transfer.integer) -> !transfer.integer
    %arg0_is_neg = "transfer.cmp"(%arg0, %const_0) {predicate = 2 : index} : (!transfer.integer, !transfer.integer) -> i1
    %sat_val = "transfer.select"(%arg0_is_neg, %int_min, %int_max) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %result = "transfer.select"(%ssub_ov, %sat_val, %sub) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    return %result : !transfer.integer
  }
}
