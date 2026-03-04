## Task: Extract a reusable library from KnownBits transfer functions

You are given a set of synthesized KnownBits transfer functions in MLIR. Your goal is to identify reusable sub-computations across them and factor these out as named helper functions in a library module.

## Background: KnownBits representation

Each abstract value is a 2-element container `!transfer.abs_value<[!transfer.integer, !transfer.integer]>`:
- element **0**: known-zero mask — a bit set here means that bit is definitely 0
- element **1**: known-one mask — a bit set here means that bit is definitely 1

The complement of known-zero gives the "maybe-one" mask; the complement of known-one gives the "maybe-zero" mask.

## Synthesized transfer functions (inputs)


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

    %rhs_is_zero_val = "transfer.cmp"(%rhs_lower, %const0) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %rhs_const_zero = "arith.andi"(%rhs_is_const, %rhs_is_zero_val) : (i1, i1) -> i1

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
    %const_invalid = "arith.xori"(%const_valid, %const_true) : (i1, i1) -> i1
    %both_const_invalid = "arith.andi"(%both_const, %const_invalid) : (i1, i1) -> i1
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

    %lhs_gt0 = "transfer.cmp"(%lhs_lower, %const0) {predicate = 4 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %lhs_lt0 = "transfer.cmp"(%lhs_upper, %const0) {predicate = 2 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %q_pos_0 = "arith.andi"(%lhs_gt0, %rhs_pos) : (i1, i1) -> i1
    %q_pos_1 = "arith.andi"(%lhs_lt0, %rhs_neg) : (i1, i1) -> i1
    %q_pos_known = "arith.ori"(%q_pos_0, %q_pos_1) : (i1, i1) -> i1
    %q_neg_0 = "arith.andi"(%lhs_lt0, %rhs_pos) : (i1, i1) -> i1
    %q_neg_1 = "arith.andi"(%lhs_gt0, %rhs_neg) : (i1, i1) -> i1
    %q_neg_known = "arith.ori"(%q_neg_0, %q_neg_1) : (i1, i1) -> i1
    %nz_fallback_lower0 = "transfer.select"(%q_pos_known, %const1, %safe_fallback_lower) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %nz_fallback_upper0 = "transfer.select"(%q_neg_known, %minus1, %safe_fallback_upper) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %nz_fb_bad = "transfer.cmp"(%nz_fallback_lower0, %nz_fallback_upper0) {predicate = 4 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %nz_fallback_lower = "transfer.select"(%nz_fb_bad, %safe_fallback_lower, %nz_fallback_lower0) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %nz_fallback_upper = "transfer.select"(%nz_fb_bad, %safe_fallback_upper, %nz_fallback_upper0) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer

    %rhs_const_pos = "arith.andi"(%rhs_is_const, %rhs_pos) : (i1, i1) -> i1
    %lhs_l_div = "transfer.sdiv"(%lhs_lower, %safe_rhs) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %lhs_u_div = "transfer.sdiv"(%lhs_upper, %safe_rhs) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %lhs_l_rem = "transfer.srem"(%lhs_lower, %safe_rhs) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %lhs_u_rem = "transfer.srem"(%lhs_upper, %safe_rhs) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %lhs_l_pos = "transfer.cmp"(%lhs_lower, %const0) {predicate = 4 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %lhs_u_neg = "transfer.cmp"(%lhs_upper, %const0) {predicate = 2 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %lhs_l_rem_nz = "transfer.cmp"(%lhs_l_rem, %const0) {predicate = 1 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %lhs_u_rem_nz = "transfer.cmp"(%lhs_u_rem, %const0) {predicate = 1 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %l_inc_cond = "arith.andi"(%lhs_l_pos, %lhs_l_rem_nz) : (i1, i1) -> i1
    %u_dec_cond = "arith.andi"(%lhs_u_neg, %lhs_u_rem_nz) : (i1, i1) -> i1
    %lhs_l_div_inc = "transfer.add"(%lhs_l_div, %const1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %lhs_u_div_dec = "transfer.sub"(%lhs_u_div, %const1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %const_pos_low = "transfer.select"(%l_inc_cond, %lhs_l_div_inc, %lhs_l_div) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %const_pos_high = "transfer.select"(%u_dec_cond, %lhs_u_div_dec, %lhs_u_div) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %const_pos_empty = "transfer.cmp"(%const_pos_low, %const_pos_high) {predicate = 4 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %const_pos_not_empty = "arith.xori"(%const_pos_empty, %const_true) : (i1, i1) -> i1
    %const_pos_valid = "arith.andi"(%rhs_const_pos, %const_pos_not_empty) : (i1, i1) -> i1
    %rhs_const_pos_empty = "arith.andi"(%rhs_const_pos, %const_pos_empty) : (i1, i1) -> i1

    %ret_lower_r1 = "transfer.select"(%rhs_const_one, %lhs_lower, %nz_fallback_lower) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %ret_upper_r1 = "transfer.select"(%rhs_const_one, %lhs_upper, %nz_fallback_upper) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer

    %ret_lower_m1 = "transfer.select"(%rhs_minus1_case, %neg_lower, %ret_lower_r1) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %ret_upper_m1 = "transfer.select"(%rhs_minus1_case, %neg_upper, %ret_upper_r1) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer

    %ret_lower_lz = "transfer.select"(%lhs_const_zero, %const0, %ret_lower_m1) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %ret_upper_lz = "transfer.select"(%lhs_const_zero, %const0, %ret_upper_m1) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer

    %ret_lower_rcp = "transfer.select"(%const_pos_valid, %const_pos_low, %ret_lower_lz) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %ret_upper_rcp = "transfer.select"(%const_pos_valid, %const_pos_high, %ret_upper_lz) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer

    %ret_lower_cv = "transfer.select"(%const_valid, %const_res, %ret_lower_rcp) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %ret_upper_cv = "transfer.select"(%const_valid, %const_res, %ret_upper_rcp) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer

    %neg_lhs_lower = "transfer.sub"(%const0, %lhs_lower) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %neg_rhs_upper = "transfer.sub"(%const0, %rhs_upper) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %neg_lhs_ov = "transfer.ssub_overflow"(%const0, %lhs_lower) : (!transfer.integer, !transfer.integer) -> i1
    %neg_rhs_ov = "transfer.ssub_overflow"(%const0, %rhs_upper) : (!transfer.integer, !transfer.integer) -> i1
    %neg_lhs_ok = "arith.xori"(%neg_lhs_ov, %const_true) : (i1, i1) -> i1
    %neg_rhs_ok = "arith.xori"(%neg_rhs_ov, %const_true) : (i1, i1) -> i1

    %small_mag_pos = "transfer.cmp"(%lhs_upper, %rhs_lower) {predicate = 2 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %small_mag_pos_case = "arith.andi"(%case_nn, %small_mag_pos) : (i1, i1) -> i1

    %small_mag_neg_pre = "transfer.cmp"(%neg_lhs_lower, %neg_rhs_upper) {predicate = 2 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %small_mag_neg_0 = "arith.andi"(%case_nnneg, %small_mag_neg_pre) : (i1, i1) -> i1
    %small_mag_neg_1 = "arith.andi"(%small_mag_neg_0, %neg_lhs_ok) : (i1, i1) -> i1
    %small_mag_neg_case = "arith.andi"(%small_mag_neg_1, %neg_rhs_ok) : (i1, i1) -> i1

    %lhs_le_zero = "transfer.cmp"(%lhs_lower, %const0) {predicate = 3 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %zero_le_lhs_upper = "transfer.cmp"(%const0, %lhs_upper) {predicate = 3 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %lhs_may_be_zero = "arith.andi"(%lhs_le_zero, %zero_le_lhs_upper) : (i1, i1) -> i1

    %cross_pos_abs1 = "transfer.cmp"(%lhs_upper, %rhs_lower) {predicate = 2 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %cross_pos_abs2_pre = "transfer.cmp"(%neg_lhs_lower, %rhs_lower) {predicate = 2 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %cross_pos_abs2 = "arith.andi"(%cross_pos_abs2_pre, %neg_lhs_ok) : (i1, i1) -> i1
    %cross_pos_abs = "arith.andi"(%cross_pos_abs1, %cross_pos_abs2) : (i1, i1) -> i1
    %small_mag_cross_pos0 = "arith.andi"(%rhs_pos, %cross_pos_abs) : (i1, i1) -> i1
    %small_mag_cross_pos = "arith.andi"(%small_mag_cross_pos0, %lhs_may_be_zero) : (i1, i1) -> i1

    %cross_neg_abs1 = "transfer.cmp"(%lhs_upper, %neg_rhs_upper) {predicate = 2 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %cross_neg_abs2_pre = "transfer.cmp"(%neg_lhs_lower, %neg_rhs_upper) {predicate = 2 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %cross_neg_abs2_0 = "arith.andi"(%cross_neg_abs2_pre, %neg_lhs_ok) : (i1, i1) -> i1
    %cross_neg_abs2 = "arith.andi"(%cross_neg_abs2_0, %neg_rhs_ok) : (i1, i1) -> i1
    %cross_neg_abs = "arith.andi"(%cross_neg_abs1, %cross_neg_abs2) : (i1, i1) -> i1
    %small_mag_cross_neg0 = "arith.andi"(%rhs_neg, %cross_neg_abs) : (i1, i1) -> i1
    %small_mag_cross_neg = "arith.andi"(%small_mag_cross_neg0, %lhs_may_be_zero) : (i1, i1) -> i1

    %small_mag_case_0 = "arith.ori"(%small_mag_pos_case, %small_mag_neg_case) : (i1, i1) -> i1
    %small_mag_case_1 = "arith.ori"(%small_mag_case_0, %small_mag_cross_pos) : (i1, i1) -> i1
    %small_mag_case = "arith.ori"(%small_mag_case_1, %small_mag_cross_neg) : (i1, i1) -> i1

    %small_mag_zero_only = "arith.andi"(%small_mag_case, %lhs_may_be_zero) : (i1, i1) -> i1
    %lhs_no_zero = "arith.xori"(%lhs_may_be_zero, %const_true) : (i1, i1) -> i1
    %small_mag_bottom = "arith.andi"(%small_mag_case, %lhs_no_zero) : (i1, i1) -> i1

    %ret_lower_sm = "transfer.select"(%small_mag_zero_only, %const0, %ret_lower_cv) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %ret_upper_sm = "transfer.select"(%small_mag_zero_only, %const0, %ret_upper_cv) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer

    %invalid_any = "arith.ori"(%rhs_const_zero, %both_const_invalid) : (i1, i1) -> i1
    %invalid_any2 = "arith.ori"(%invalid_any, %rhs_const_pos_empty) : (i1, i1) -> i1
    %invalid_any3 = "arith.ori"(%invalid_any2, %small_mag_bottom) : (i1, i1) -> i1
    %ret_lower = "transfer.select"(%invalid_any3, %smax, %ret_lower_sm) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %ret_upper = "transfer.select"(%invalid_any3, %smin, %ret_upper_sm) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer

    %r = "transfer.make"(%ret_lower, %ret_upper) : (!transfer.integer, !transfer.integer) -> !transfer.abs_value<[!transfer.integer, !transfer.integer]>
    "func.return"(%r) : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> ()
}) {"sym_name" = "scr_sdivexact", "function_type" = (!transfer.abs_value<[!transfer.integer, !transfer.integer]>, !transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.abs_value<[!transfer.integer, !transfer.integer]>} : () -> ()

builtin.module {
  func.func @func0(%h0 : i1, %h1 : !transfer.abs_value<[!transfer.integer, !transfer.integer]>, %arg0 : i1) -> !transfer.integer {
    %v1 = "arith.andi"(%h0, %arg0) : (i1, i1) -> i1
    %v0 = func.call @%h1(%v1) : (i1) -> !transfer.integer
    func.return %v0 : !transfer.integer
  }
  func.func @func1(%h0 : i1, %h1 : !transfer.abs_value<[!transfer.integer, !transfer.integer]>, %arg0 : i1) -> !transfer.integer {
    %v1 = "arith.andi"(%arg0, %h0) : (i1, i1) -> i1
    %v0 = func.call @%h1(%v1) : (i1) -> !transfer.integer
    func.return %v0 : !transfer.integer
  }
  func.func @func2(%h0 : !transfer.abs_value<[!transfer.integer, !transfer.integer]>, %h1 : !transfer.abs_value<[!transfer.integer, !transfer.integer]>, %h2 : !transfer.abs_value<[!transfer.integer, !transfer.integer]>, %arg0 : !transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer {
    %v1 = func.call @%h1(%arg0, %h0) : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>, !transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %v0 = func.call @%h2(%v1) : (!transfer.integer) -> !transfer.integer
    func.return %v0 : !transfer.integer
  }
}

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


## Existing library (do not duplicate)

The library already contains the following helpers. Do not re-emit functions that are already present or are trivially equivalent to them:

```mlir
builtin.module {}
```

## Available primitives

Library functions must use only these building blocks:

### Constructor and Deconstructor

- transfer.get : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
- transfer.make : (!transfer.integer, !transfer.integer) -> !transfer.abs_value<[!transfer.integer, !transfer.integer]>

### Boolean Operations (i1)

- transfer.cmp: (!transfer.integer, !transfer.integer) -> i1
- arith.andi: (i1, i1) -> i1
- arith.ori: (i1, i1) -> i1
- arith.xori: (i1, i1) -> i1

### Integer Operations

- transfer.neg: (!transfer.integer) -> !transfer.integer
- transfer.and: (!transfer.integer, !transfer.integer) -> !transfer.integer
- transfer.or: (!transfer.integer, !transfer.integer) -> !transfer.integer
- transfer.xor: (!transfer.integer, !transfer.integer) -> !transfer.integer
- transfer.add: (!transfer.integer, !transfer.integer) -> !transfer.integer
- transfer.sub: (!transfer.integer, !transfer.integer) -> !transfer.integer
- transfer.select: (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
- transfer.mul: (!transfer.integer, !transfer.integer) -> !transfer.integer
- transfer.lshr: (!transfer.integer, !transfer.integer) -> !transfer.integer
- transfer.shl: (!transfer.integer, !transfer.integer) -> !transfer.integer
- transfer.umin: (!transfer.integer, !transfer.integer) -> !transfer.integer
- transfer.umax: (!transfer.integer, !transfer.integer) -> !transfer.integer
- transfer.smin: (!transfer.integer, !transfer.integer) -> !transfer.integer
- transfer.smax: (!transfer.integer, !transfer.integer) -> !transfer.integer
- transfer.udiv: (!transfer.integer, !transfer.integer) -> !transfer.integer
- transfer.sdiv: (!transfer.integer, !transfer.integer) -> !transfer.integer
- transfer.urem: (!transfer.integer, !transfer.integer) -> !transfer.integer
- transfer.srem: (!transfer.integer, !transfer.integer) -> !transfer.integer
- transfer.set_high_bits: (!transfer.integer, !transfer.integer) -> !transfer.integer
- transfer.set_low_bits: (!transfer.integer, !transfer.integer) -> !transfer.integer
- transfer.clear_high_bits: (!transfer.integer, !transfer.integer) -> !transfer.integer
- transfer.clear_low_bits: (!transfer.integer, !transfer.integer) -> !transfer.integer
- transfer.set_signed_bits: (!transfer.integer, !transfer.integer) -> !transfer.integer
- transfer.clear_signed_bits: (!transfer.integer, !transfer.integer) -> !transfer.integer
- transfer.countl_one: (!transfer.integer) -> !transfer.integer
- transfer.countl_zero: (!transfer.integer) -> !transfer.integer
- transfer.countr_one: (!transfer.integer) -> !transfer.integer
- transfer.countr_zero: (!transfer.integer) -> !transfer.integer

## Utility Operations

- transfer.constant: (!transfer.integer) -> !transfer.integer
    - example: `%const0 = "transfer.constant"(%arg){value=42:index} : (!transfer.integer) -> !transfer.integer` provides constant 42.
    - the argument `%arg` is to decide bitwidth
- transfer.get_all_ones: (!transfer.integer) -> !transfer.integer
    - the argument is to decide bitwidth
- transfer.get_bit_width: (!transfer.integer) -> !transfer.integer


## What to extract

A good library function:
1. **Encodes a meaningful semantic concept** — e.g., "extract the maybe-zero mask", "compute the carry-propagate bits", "get the minimum possible concrete value of a KnownBits". Prefer names that describe what the function *means*, not how it is computed.
2. **Appears across multiple transfer functions**, or is a large, self-contained sub-computation that would reduce duplication if future transfer functions were refactored to use it.
3. **Is non-trivial** — it should be at least 3 operations long. Do not extract single-op wrappers.
4. **Is general** — parameters should be abstract values or integers; do not hard-code bitwidth-specific constants unless the concept is inherently about a specific constant.

Do **not** extract the transfer functions themselves (e.g. `@kb_add`). Only extract helper functions that could be called from within transfer functions.

## Output format

Output a single `builtin.module` containing only the new library functions you are adding. Do not include the transfer functions from the input. Use `func.func` with:
- SSA form only
- One allowed operation per line
- Descriptive `snake_case` function names
- A brief `//` comment on the first line of each function body explaining its purpose
- Arguments typed as `!transfer.integer` or `!transfer.abs_value<[!transfer.integer, !transfer.integer]>` as appropriate

Example output shape (illustrative, do not copy verbatim):

```mlir
builtin.module {
  func.func @maybe_zero(%kb : !transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer {
    // Returns the mask of bits that might be 0: complement of known-one.
    %known1 = "transfer.get"(%kb) {index = 1} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %all_ones = "transfer.get_all_ones"(%known1) : (!transfer.integer) -> !transfer.integer
    %res = "transfer.xor"(%known1, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    func.return %res : !transfer.integer
  }
}
```

## Required workflow

1. Read each synthesized transfer function carefully. For each one, annotate (mentally) which sub-sequences of operations compute a semantically coherent intermediate result.
2. Look for sub-computations that appear in more than one function, or that are large enough to deserve a name on their own.
3. For each candidate, decide on a precise semantic description and a clear name.
4. Write the MLIR for each helper function. Verify it uses only allowed primitives and is in valid SSA form.
5. Output **only** the `builtin.module` containing the new helper functions — no explanation, no transfer functions, no markdown fences around the final answer.