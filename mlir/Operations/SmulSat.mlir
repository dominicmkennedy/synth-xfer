module {
  func.func @concrete_op(%arg0: !transfer.integer, %arg1: !transfer.integer) -> !transfer.integer {
    %mul = "transfer.mul"(%arg0, %arg1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %smul_ov = "transfer.smul_overflow"(%arg0, %arg1) : (!transfer.integer, !transfer.integer) -> i1
    %const_0 = "transfer.constant"(%arg1) {value = 0 : index} : (!transfer.integer) -> !transfer.integer
    %int_min = "transfer.get_signed_min_value"(%arg0) : (!transfer.integer) -> !transfer.integer
    %int_max = "transfer.get_signed_max_value"(%arg0) : (!transfer.integer) -> !transfer.integer
    %arg0_is_neg = "transfer.cmp"(%arg0, %const_0) {predicate = 2 : index} : (!transfer.integer, !transfer.integer) -> i1
    %arg1_is_neg = "transfer.cmp"(%arg1, %const_0) {predicate = 2 : index} : (!transfer.integer, !transfer.integer) -> i1
    %mixed_sign = arith.xori %arg0_is_neg, %arg1_is_neg : i1
    %sat_val = "transfer.select"(%mixed_sign, %int_min, %int_max) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %result = "transfer.select"(%smul_ov, %sat_val, %mul) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    return %result : !transfer.integer
  }
}
