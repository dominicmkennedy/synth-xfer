module {
  func.func @concrete_op(%arg0: !transfer.integer, %arg1: !transfer.integer) -> !transfer.integer {
    %0 = "transfer.sdiv"(%arg0, %arg1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    return %0 : !transfer.integer
  }
  func.func @op_constraint(%arg0: !transfer.integer, %arg1: !transfer.integer) -> i1 {
    %const_0 = "transfer.constant"(%arg1) {value = 0 : i64} : (!transfer.integer) -> !transfer.integer
    %rhs_not_0 = "transfer.cmp"(%const_0, %arg1) {predicate = 1 : i64} : (!transfer.integer, !transfer.integer) -> i1

    %int_min = "transfer.get_signed_min_value"(%arg0) : (!transfer.integer) -> !transfer.integer
    %lhs_not_int_min = "transfer.cmp"(%int_min, %arg0) {predicate = 1 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %neg_1 = "transfer.get_all_ones"(%arg0) : (!transfer.integer) -> !transfer.integer
    %rhs_not_neg_1 = "transfer.cmp"(%neg_1, %arg1) {predicate = 1 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %no_overflow = "arith.ori"(%lhs_not_int_min, %rhs_not_neg_1) : (i1, i1) -> i1
    %res = "arith.andi"(%rhs_not_0, %no_overflow) : (i1, i1) -> i1
    return %res : i1
  }
}
