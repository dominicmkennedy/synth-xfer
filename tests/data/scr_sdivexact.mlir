"func.func"() ({
  ^0(%lhs : !transfer.abs_value<[!transfer.integer, !transfer.integer]>, %rhs : !transfer.abs_value<[!transfer.integer, !transfer.integer]>):
    %lhs_lower = "transfer.get"(%lhs) {index = 0} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %lhs_upper = "transfer.get"(%lhs) {index = 1} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %rhs_lower = "transfer.get"(%rhs) {index = 0} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %rhs_upper = "transfer.get"(%rhs) {index = 1} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer

    %const0 = "transfer.constant"(%lhs_lower) {value = 0 : index} : (!transfer.integer) -> !transfer.integer
    %const1 = "transfer.constant"(%lhs_lower) {value = 1 : index} : (!transfer.integer) -> !transfer.integer
    %const_true = "arith.constant"() {value=1:i1} : () -> i1
    %minus1 = "transfer.get_all_ones"(%lhs_lower) : (!transfer.integer) -> !transfer.integer
    %smin = "transfer.get_signed_min_value"(%lhs_lower) : (!transfer.integer) -> !transfer.integer
    %smax = "transfer.get_signed_max_value"(%lhs_lower) : (!transfer.integer) -> !transfer.integer

    %lhs_is_const = "transfer.cmp"(%lhs_lower, %lhs_upper) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %rhs_is_const = "transfer.cmp"(%rhs_lower, %rhs_upper) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %both_const = "arith.andi"(%lhs_is_const, %rhs_is_const) : (i1, i1) -> i1

    %lhs_is_zero_val = "transfer.cmp"(%lhs_lower, %const0) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %lhs_const_zero = "arith.andi"(%lhs_is_const, %lhs_is_zero_val) : (i1, i1) -> i1

    %rhs_is_one_val = "transfer.cmp"(%rhs_lower, %const1) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %rhs_const_one = "arith.andi"(%rhs_is_const, %rhs_is_one_val) : (i1, i1) -> i1

    %rhs_is_minus1_val = "transfer.cmp"(%rhs_lower, %minus1) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %rhs_const_minus1 = "arith.andi"(%rhs_is_const, %rhs_is_minus1_val) : (i1, i1) -> i1

    %lhs_lower_is_smin = "transfer.cmp"(%lhs_lower, %smin) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %lhs_excludes_smin = "arith.xori"(%lhs_lower_is_smin, %const_true) : (i1, i1) -> i1
    %rhs_minus1_safe = "arith.andi"(%rhs_const_minus1, %lhs_excludes_smin) : (i1, i1) -> i1

    %neg_lower = "transfer.sub"(%const0, %lhs_upper) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %neg_upper = "transfer.sub"(%const0, %lhs_lower) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %neg_ov_l = "transfer.ssub_overflow"(%const0, %lhs_upper) : (!transfer.integer, !transfer.integer) -> i1
    %neg_ov_u = "transfer.ssub_overflow"(%const0, %lhs_lower) : (!transfer.integer, !transfer.integer) -> i1
    %neg_mixed_ov = "arith.xori"(%neg_ov_l, %neg_ov_u) : (i1, i1) -> i1
    %neg_bad_order = "transfer.cmp"(%neg_lower, %neg_upper) {predicate = 4 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %neg_bad = "arith.ori"(%neg_mixed_ov, %neg_bad_order) : (i1, i1) -> i1
    %neg_ok = "arith.xori"(%neg_bad, %const_true) : (i1, i1) -> i1
    %rhs_minus1_case = "arith.andi"(%rhs_minus1_safe, %neg_ok) : (i1, i1) -> i1

    %rhs_nonzero = "transfer.cmp"(%rhs_lower, %const0) {predicate = 1 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %rhs_upper_nonzero = "transfer.cmp"(%rhs_upper, %const0) {predicate = 1 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %safe_rhs = "transfer.select"(%rhs_nonzero, %rhs_lower, %const1) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %safe_rhs_upper = "transfer.select"(%rhs_upper_nonzero, %rhs_upper, %const1) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %rem = "transfer.srem"(%lhs_lower, %safe_rhs) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %rem_zero = "transfer.cmp"(%rem, %const0) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1

    %lhs_plus_lhs = "transfer.add"(%lhs_lower, %lhs_lower) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %lhs_plus_lhs_neq0 = "transfer.cmp"(%lhs_plus_lhs, %const0) {predicate = 1 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %lhs_neq_smin = "arith.ori"(%lhs_is_zero_val, %lhs_plus_lhs_neq0) : (i1, i1) -> i1
    %rhs_neq_minus1 = "transfer.cmp"(%minus1, %rhs_lower) {predicate = 1 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %no_ub2 = "arith.ori"(%lhs_neq_smin, %rhs_neq_minus1) : (i1, i1) -> i1
    %no_ub = "arith.andi"(%rhs_nonzero, %no_ub2) : (i1, i1) -> i1

    %const_valid_0 = "arith.andi"(%both_const, %rem_zero) : (i1, i1) -> i1
    %const_valid = "arith.andi"(%const_valid_0, %no_ub) : (i1, i1) -> i1
    %const_res = "transfer.sdiv"(%lhs_lower, %safe_rhs) : (!transfer.integer, !transfer.integer) -> !transfer.integer

    %lhs_nonneg = "transfer.cmp"(%lhs_lower, %const0) {predicate = 5 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %lhs_nonpos = "transfer.cmp"(%lhs_upper, %const0) {predicate = 3 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %rhs_pos = "transfer.cmp"(%rhs_lower, %const0) {predicate = 4 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %rhs_neg = "transfer.cmp"(%rhs_upper, %const0) {predicate = 2 : i64} : (!transfer.integer, !transfer.integer) -> i1

    %case_nn = "arith.andi"(%lhs_nonneg, %rhs_pos) : (i1, i1) -> i1
    %case_np = "arith.andi"(%lhs_nonpos, %rhs_pos) : (i1, i1) -> i1
    %case_pn = "arith.andi"(%lhs_nonneg, %rhs_neg) : (i1, i1) -> i1
    %case_nnneg = "arith.andi"(%lhs_nonpos, %rhs_neg) : (i1, i1) -> i1

    %nn_lower = "transfer.sdiv"(%lhs_lower, %safe_rhs_upper) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %nn_upper = "transfer.sdiv"(%lhs_upper, %safe_rhs) : (!transfer.integer, !transfer.integer) -> !transfer.integer

    %np_lower = "transfer.sdiv"(%lhs_lower, %safe_rhs) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %np_upper = "transfer.sdiv"(%lhs_upper, %safe_rhs_upper) : (!transfer.integer, !transfer.integer) -> !transfer.integer

    %pn_lower = "transfer.sdiv"(%lhs_upper, %safe_rhs_upper) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pn_upper = "transfer.sdiv"(%lhs_lower, %safe_rhs) : (!transfer.integer, !transfer.integer) -> !transfer.integer

    %nnneg_lower = "transfer.sdiv"(%lhs_upper, %safe_rhs) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %nnneg_upper = "transfer.sdiv"(%lhs_lower, %safe_rhs_upper) : (!transfer.integer, !transfer.integer) -> !transfer.integer

    %fb_lower_0 = "transfer.select"(%case_nn, %nn_lower, %smin) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %fb_upper_0 = "transfer.select"(%case_nn, %nn_upper, %smax) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer

    %fb_lower_1 = "transfer.select"(%case_np, %np_lower, %fb_lower_0) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %fb_upper_1 = "transfer.select"(%case_np, %np_upper, %fb_upper_0) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer

    %fb_lower_2 = "transfer.select"(%case_pn, %pn_lower, %fb_lower_1) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %fb_upper_2 = "transfer.select"(%case_pn, %pn_upper, %fb_upper_1) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer

    %fallback_lower = "transfer.select"(%case_nnneg, %nnneg_lower, %fb_lower_2) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %fallback_upper = "transfer.select"(%case_nnneg, %nnneg_upper, %fb_upper_2) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer

    %fb_bad = "transfer.cmp"(%fallback_lower, %fallback_upper) {predicate = 4 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %safe_fallback_lower = "transfer.select"(%fb_bad, %smin, %fallback_lower) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %safe_fallback_upper = "transfer.select"(%fb_bad, %smax, %fallback_upper) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer

    %ret_lower_r1 = "transfer.select"(%rhs_const_one, %lhs_lower, %safe_fallback_lower) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %ret_upper_r1 = "transfer.select"(%rhs_const_one, %lhs_upper, %safe_fallback_upper) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer

    %ret_lower_m1 = "transfer.select"(%rhs_minus1_case, %neg_lower, %ret_lower_r1) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %ret_upper_m1 = "transfer.select"(%rhs_minus1_case, %neg_upper, %ret_upper_r1) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer

    %ret_lower_lz = "transfer.select"(%lhs_const_zero, %const0, %ret_lower_m1) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %ret_upper_lz = "transfer.select"(%lhs_const_zero, %const0, %ret_upper_m1) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer

    %ret_lower = "transfer.select"(%const_valid, %const_res, %ret_lower_lz) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %ret_upper = "transfer.select"(%const_valid, %const_res, %ret_upper_lz) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer

    %r = "transfer.make"(%ret_lower, %ret_upper) : (!transfer.integer, !transfer.integer) -> !transfer.abs_value<[!transfer.integer, !transfer.integer]>
    "func.return"(%r) : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> ()
}) {"sym_name" = "scr_sdivexact", "function_type" = (!transfer.abs_value<[!transfer.integer, !transfer.integer]>, !transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.abs_value<[!transfer.integer, !transfer.integer]>} : () -> ()
