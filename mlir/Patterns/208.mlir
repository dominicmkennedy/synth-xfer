module {
  func.func @concrete_op(%arg0: !transfer.integer, %arg1: !transfer.integer, %arg2: !transfer.integer) -> !transfer.integer {
    %0 = "transfer.sdiv"(%arg2, %arg1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %1 = "transfer.add"(%arg0, %0) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    return %1 : !transfer.integer
  }
  func.func @op_constraint(%arg0: !transfer.integer, %arg1: !transfer.integer, %arg2: !transfer.integer) -> i1 {
    %0 = "transfer.sdiv"(%arg2, %arg1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %ssa_0_con_0_z = func.call @sdiv_exact(%arg2, %arg1) : (!transfer.integer, !transfer.integer) -> i1
    %ssa_0_con_1_z = func.call @rhs_neq_zero(%arg2, %arg1) : (!transfer.integer, !transfer.integer) -> i1
    %ssa_0_con_2_z = func.call @no_sdiv_ov(%arg2, %arg1) : (!transfer.integer, !transfer.integer) -> i1
    %ssa_1_con_0_z = func.call @add_nsw(%arg0, %0) : (!transfer.integer, !transfer.integer) -> i1
    %and_0 = arith.andi %ssa_0_con_0_z, %ssa_0_con_1_z : i1
    %and_1 = arith.andi %and_0, %ssa_1_con_0_z : i1
    %and_2 = arith.andi %and_1, %ssa_0_con_2_z : i1
    return %and_2 : i1
  }
  func.func @sdiv_exact(%arg0: !transfer.integer, %arg1: !transfer.integer) -> i1 {
    %const = "transfer.constant"(%arg1) {value = 0 : i64} : (!transfer.integer) -> !transfer.integer
    %srem = "transfer.srem"(%arg0, %arg1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %exact = "transfer.cmp"(%srem, %const) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    return %exact : i1
  }
  func.func @rhs_neq_zero(%arg0: !transfer.integer, %arg1: !transfer.integer) -> i1 {
    %const = "transfer.constant"(%arg1) {value = 0 : index} : (!transfer.integer) -> !transfer.integer
    %rhs_not = "transfer.cmp"(%const, %arg1) {predicate = 1 : i64} : (!transfer.integer, !transfer.integer) -> i1
    return %rhs_not : i1
  }
  func.func @add_nsw(%arg0: !transfer.integer, %arg1: !transfer.integer) -> i1 {
    %sadd_ov = "transfer.sadd_overflow"(%arg0, %arg1) : (!transfer.integer, !transfer.integer) -> i1
    %true = arith.constant true
    %no_ov = arith.xori %sadd_ov, %true : i1
    return %no_ov : i1
  }
  func.func @no_sdiv_ov(%arg0: !transfer.integer, %arg1: !transfer.integer) -> i1 {
    %int_min = "transfer.get_signed_min_value"(%arg0) : (!transfer.integer) -> !transfer.integer
    %lhs_not_int_min = "transfer.cmp"(%int_min, %arg0) {predicate = 1 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %neg = "transfer.get_all_ones"(%arg0) : (!transfer.integer) -> !transfer.integer
    %rhs_not_neg = "transfer.cmp"(%neg, %arg1) {predicate = 1 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %no_overflow = arith.ori %lhs_not_int_min, %rhs_not_neg : i1
    return %no_overflow : i1
  }
}
