"func.func"() ({
  ^0(%lhs : !transfer.abs_value<[!transfer.integer, !transfer.integer]>, %rhs : !transfer.abs_value<[!transfer.integer, !transfer.integer]>):
    %lhs_lower = "transfer.get"(%lhs) {index = 0} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %lhs_upper = "transfer.get"(%lhs) {index = 1} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %rhs_lower = "transfer.get"(%rhs) {index = 0} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %rhs_upper = "transfer.get"(%rhs) {index = 1} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer

    %const0 = "transfer.constant"(%lhs_lower) {value = 0 : index} : (!transfer.integer) -> !transfer.integer
    %const1 = "transfer.constant"(%lhs_lower) {value = 1 : index} : (!transfer.integer) -> !transfer.integer
    %all_ones = "transfer.get_all_ones"(%lhs_lower) : (!transfer.integer) -> !transfer.integer
    %sign_minus_1 = "transfer.lshr"(%all_ones, %const1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %sign_bit = "transfer.add"(%sign_minus_1, %const1) : (!transfer.integer, !transfer.integer) -> !transfer.integer

    // Partition each unsigned input interval into signed nonnegative and signed negative pieces.
    %lhs_nonneg_exists = "transfer.cmp"(%lhs_lower, %sign_minus_1) {predicate = 7 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %rhs_nonneg_exists = "transfer.cmp"(%rhs_lower, %sign_minus_1) {predicate = 7 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %lhs_nonneg_upper = "transfer.umin"(%lhs_upper, %sign_minus_1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %rhs_nonneg_upper = "transfer.umin"(%rhs_upper, %sign_minus_1) : (!transfer.integer, !transfer.integer) -> !transfer.integer

    %lhs_neg_exists = "transfer.cmp"(%sign_bit, %lhs_upper) {predicate = 7 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %rhs_neg_exists = "transfer.cmp"(%sign_bit, %rhs_upper) {predicate = 7 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %lhs_neg_lower = "transfer.umax"(%lhs_lower, %sign_bit) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %rhs_neg_lower = "transfer.umax"(%rhs_lower, %sign_bit) : (!transfer.integer, !transfer.integer) -> !transfer.integer

    // Case A: lhs >= 0, rhs >= 0 (signed).
    %a_exists = "arith.andi"(%lhs_nonneg_exists, %rhs_nonneg_exists) : (i1, i1) -> i1
    %a_min_or = "transfer.or"(%lhs_lower, %rhs_lower) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %a_min_xor = "transfer.xor"(%lhs_lower, %rhs_lower) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %a_min_ashr = "transfer.ashr"(%a_min_xor, %const1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %a_min = "transfer.sub"(%a_min_or, %a_min_ashr) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %a_max_or = "transfer.or"(%lhs_nonneg_upper, %rhs_nonneg_upper) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %a_max_xor = "transfer.xor"(%lhs_nonneg_upper, %rhs_nonneg_upper) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %a_max_ashr = "transfer.ashr"(%a_max_xor, %const1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %a_max = "transfer.sub"(%a_max_or, %a_max_ashr) : (!transfer.integer, !transfer.integer) -> !transfer.integer

    // Case B: lhs < 0, rhs < 0 (signed).
    %b_exists = "arith.andi"(%lhs_neg_exists, %rhs_neg_exists) : (i1, i1) -> i1
    %b_min_or = "transfer.or"(%lhs_neg_lower, %rhs_neg_lower) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %b_min_xor = "transfer.xor"(%lhs_neg_lower, %rhs_neg_lower) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %b_min_ashr = "transfer.ashr"(%b_min_xor, %const1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %b_min = "transfer.sub"(%b_min_or, %b_min_ashr) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %b_max_or = "transfer.or"(%lhs_upper, %rhs_upper) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %b_max_xor = "transfer.xor"(%lhs_upper, %rhs_upper) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %b_max_ashr = "transfer.ashr"(%b_max_xor, %const1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %b_max = "transfer.sub"(%b_max_or, %b_max_ashr) : (!transfer.integer, !transfer.integer) -> !transfer.integer

    // Case C: lhs >= 0, rhs < 0 (signed).
    %c_exists = "arith.andi"(%lhs_nonneg_exists, %rhs_neg_exists) : (i1, i1) -> i1
    %c_min_signed_or = "transfer.or"(%lhs_lower, %rhs_neg_lower) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %c_min_signed_xor = "transfer.xor"(%lhs_lower, %rhs_neg_lower) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %c_min_signed_ashr = "transfer.ashr"(%c_min_signed_xor, %const1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %c_min_signed = "transfer.sub"(%c_min_signed_or, %c_min_signed_ashr) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %c_max_signed_or = "transfer.or"(%lhs_nonneg_upper, %rhs_upper) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %c_max_signed_xor = "transfer.xor"(%lhs_nonneg_upper, %rhs_upper) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %c_max_signed_ashr = "transfer.ashr"(%c_max_signed_xor, %const1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %c_max_signed = "transfer.sub"(%c_max_signed_or, %c_max_signed_ashr) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %c_min_is_neg = "transfer.cmp"(%sign_bit, %c_min_signed) {predicate = 7 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %c_max_is_nonneg = "transfer.cmp"(%c_max_signed, %sign_minus_1) {predicate = 7 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %c_crosses_sign = "arith.andi"(%c_min_is_neg, %c_max_is_nonneg) : (i1, i1) -> i1
    %c_min = "transfer.select"(%c_crosses_sign, %const0, %c_min_signed) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %c_max = "transfer.select"(%c_crosses_sign, %all_ones, %c_max_signed) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer

    // Case D: lhs < 0, rhs >= 0 (signed).
    %d_exists = "arith.andi"(%lhs_neg_exists, %rhs_nonneg_exists) : (i1, i1) -> i1
    %d_min_signed_or = "transfer.or"(%lhs_neg_lower, %rhs_lower) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %d_min_signed_xor = "transfer.xor"(%lhs_neg_lower, %rhs_lower) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %d_min_signed_ashr = "transfer.ashr"(%d_min_signed_xor, %const1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %d_min_signed = "transfer.sub"(%d_min_signed_or, %d_min_signed_ashr) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %d_max_signed_or = "transfer.or"(%lhs_upper, %rhs_nonneg_upper) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %d_max_signed_xor = "transfer.xor"(%lhs_upper, %rhs_nonneg_upper) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %d_max_signed_ashr = "transfer.ashr"(%d_max_signed_xor, %const1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %d_max_signed = "transfer.sub"(%d_max_signed_or, %d_max_signed_ashr) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %d_min_is_neg = "transfer.cmp"(%sign_bit, %d_min_signed) {predicate = 7 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %d_max_is_nonneg = "transfer.cmp"(%d_max_signed, %sign_minus_1) {predicate = 7 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %d_crosses_sign = "arith.andi"(%d_min_is_neg, %d_max_is_nonneg) : (i1, i1) -> i1
    %d_min = "transfer.select"(%d_crosses_sign, %const0, %d_min_signed) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %d_max = "transfer.select"(%d_crosses_sign, %all_ones, %d_max_signed) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer

    // Join all present case ranges in unsigned order (start from bottom [max, 0]).
    %ret_lower_0 = "transfer.add"(%all_ones, %const0) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %ret_upper_0 = "transfer.add"(%const0, %const0) : (!transfer.integer, !transfer.integer) -> !transfer.integer

    %ret_lower_a = "transfer.umin"(%ret_lower_0, %a_min) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %ret_upper_a = "transfer.umax"(%ret_upper_0, %a_max) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %ret_lower_1 = "transfer.select"(%a_exists, %ret_lower_a, %ret_lower_0) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %ret_upper_1 = "transfer.select"(%a_exists, %ret_upper_a, %ret_upper_0) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer

    %ret_lower_b = "transfer.umin"(%ret_lower_1, %b_min) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %ret_upper_b = "transfer.umax"(%ret_upper_1, %b_max) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %ret_lower_2 = "transfer.select"(%b_exists, %ret_lower_b, %ret_lower_1) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %ret_upper_2 = "transfer.select"(%b_exists, %ret_upper_b, %ret_upper_1) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer

    %ret_lower_c = "transfer.umin"(%ret_lower_2, %c_min) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %ret_upper_c = "transfer.umax"(%ret_upper_2, %c_max) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %ret_lower_3 = "transfer.select"(%c_exists, %ret_lower_c, %ret_lower_2) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %ret_upper_3 = "transfer.select"(%c_exists, %ret_upper_c, %ret_upper_2) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer

    %ret_lower_d = "transfer.umin"(%ret_lower_3, %d_min) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %ret_upper_d = "transfer.umax"(%ret_upper_3, %d_max) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %ret_lower = "transfer.select"(%d_exists, %ret_lower_d, %ret_lower_3) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %ret_upper = "transfer.select"(%d_exists, %ret_upper_d, %ret_upper_3) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer

    %r = "transfer.make"(%ret_lower, %ret_upper) : (!transfer.integer, !transfer.integer) -> !transfer.abs_value<[!transfer.integer, !transfer.integer]>
    "func.return"(%r) : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> ()
}) {"sym_name" = "ucr_avgceils", "function_type" = (!transfer.abs_value<[!transfer.integer, !transfer.integer]>, !transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.abs_value<[!transfer.integer, !transfer.integer]>} : () -> ()
