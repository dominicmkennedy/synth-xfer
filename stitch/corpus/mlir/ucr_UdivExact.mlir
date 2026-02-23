"func.func"() ({
  ^0(%lhs : !transfer.abs_value<[!transfer.integer, !transfer.integer]>, %rhs : !transfer.abs_value<[!transfer.integer, !transfer.integer]>):
    %lhs_lower = "transfer.get"(%lhs) {index = 0} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %lhs_upper = "transfer.get"(%lhs) {index = 1} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %rhs_lower = "transfer.get"(%rhs) {index = 0} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %rhs_upper = "transfer.get"(%rhs) {index = 1} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer

    %const0 = "transfer.constant"(%lhs_lower) {value = 0 : index} : (!transfer.integer) -> !transfer.integer
    %const1 = "transfer.constant"(%lhs_lower) {value = 1 : index} : (!transfer.integer) -> !transfer.integer

    %lhs_is_const = "transfer.cmp"(%lhs_lower, %lhs_upper) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %rhs_is_const = "transfer.cmp"(%rhs_lower, %rhs_upper) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %both_const = "arith.andi"(%lhs_is_const, %rhs_is_const) : (i1, i1) -> i1

    %rhs_nonzero = "transfer.cmp"(%rhs_lower, %const0) {predicate = 1 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %lhs_nonzero = "transfer.cmp"(%lhs_lower, %const0) {predicate = 1 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %safe_rhs_lower = "transfer.select"(%rhs_nonzero, %rhs_lower, %const1) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer

    %rhs_is_one_val = "transfer.cmp"(%rhs_lower, %const1) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %rhs_const_one = "arith.andi"(%rhs_is_const, %rhs_is_one_val) : (i1, i1) -> i1

    %lhs_is_zero_val = "transfer.cmp"(%lhs_lower, %const0) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %lhs_const_zero = "arith.andi"(%lhs_is_const, %lhs_is_zero_val) : (i1, i1) -> i1

    %both_const_safe = "arith.andi"(%both_const, %rhs_nonzero) : (i1, i1) -> i1
    %const_res = "transfer.udiv"(%lhs_lower, %safe_rhs_lower) : (!transfer.integer, !transfer.integer) -> !transfer.integer

    %upper_div = "transfer.udiv"(%lhs_upper, %safe_rhs_lower) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %fallback_upper = "transfer.select"(%rhs_nonzero, %upper_div, %lhs_upper) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %fallback_lower = "transfer.select"(%lhs_nonzero, %const1, %const0) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer

    %lhs_upper_div_safe = "transfer.udiv"(%lhs_upper, %safe_rhs_lower) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %lhs_upper_lt_rhs_lower = "transfer.cmp"(%lhs_upper_div_safe, %const0) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %zero_only_0 = "arith.andi"(%rhs_nonzero, %lhs_upper_lt_rhs_lower) : (i1, i1) -> i1
    %zero_only = "arith.andi"(%zero_only_0, %lhs_is_zero_val) : (i1, i1) -> i1

    %ret_lower_r1 = "transfer.select"(%rhs_const_one, %lhs_lower, %fallback_lower) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %ret_upper_r1 = "transfer.select"(%rhs_const_one, %lhs_upper, %fallback_upper) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer

    %ret_lower_lz = "transfer.select"(%lhs_const_zero, %const0, %ret_lower_r1) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %ret_upper_lz = "transfer.select"(%lhs_const_zero, %const0, %ret_upper_r1) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer

    %ret_lower_zo = "transfer.select"(%zero_only, %const0, %ret_lower_lz) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %ret_upper_zo = "transfer.select"(%zero_only, %const0, %ret_upper_lz) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer

    %ret_lower = "transfer.select"(%both_const_safe, %const_res, %ret_lower_zo) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %ret_upper = "transfer.select"(%both_const_safe, %const_res, %ret_upper_zo) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer

    %r = "transfer.make"(%ret_lower, %ret_upper) : (!transfer.integer, !transfer.integer) -> !transfer.abs_value<[!transfer.integer, !transfer.integer]>
    "func.return"(%r) : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> ()
}) {"sym_name" = "ucr_udivexact", "function_type" = (!transfer.abs_value<[!transfer.integer, !transfer.integer]>, !transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.abs_value<[!transfer.integer, !transfer.integer]>} : () -> ()
