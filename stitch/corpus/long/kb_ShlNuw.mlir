"func.func"() ({
  ^0(%lhs : !transfer.abs_value<[!transfer.integer, !transfer.integer]>, %rhs : !transfer.abs_value<[!transfer.integer, !transfer.integer]>):
    %lhs0 = "transfer.get"(%lhs) {index = 0} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %lhs1 = "transfer.get"(%lhs) {index = 1} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %rhs0 = "transfer.get"(%rhs) {index = 0} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %rhs1 = "transfer.get"(%rhs) {index = 1} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer

    %all_ones = "transfer.get_all_ones"(%lhs0) : (!transfer.integer) -> !transfer.integer
    %const0 = "transfer.constant"(%lhs0) {value = 0 : index} : (!transfer.integer) -> !transfer.integer
    %const1 = "transfer.constant"(%lhs0) {value = 1 : index} : (!transfer.integer) -> !transfer.integer
    %const_true = "arith.constant"() {value = 1 : i1} : () -> i1
    %const_false = "arith.constant"() {value = 0 : i1} : () -> i1
    %bitwidth = "transfer.get_bit_width"(%lhs0) : (!transfer.integer) -> !transfer.integer

    %lhs_conflict = "transfer.and"(%lhs0, %lhs1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %rhs_conflict = "transfer.and"(%rhs0, %rhs1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %lhs_consistent = "transfer.cmp"(%lhs_conflict, %const0) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %rhs_consistent = "transfer.cmp"(%rhs_conflict, %const0) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %rhs_min_le_bw = "transfer.cmp"(%rhs1, %bitwidth) {predicate = 7 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %lhs_lz_ub = "transfer.countl_zero"(%lhs1) : (!transfer.integer) -> !transfer.integer
    %lhs_lo_ub = "transfer.countl_zero"(%lhs0) : (!transfer.integer) -> !transfer.integer
    %lhs_nonneg_possible = "arith.andi"(%const_true, %const_true) : (i1, i1) -> i1
    %lhs_neg_possible = "arith.andi"(%const_false, %const_true) : (i1, i1) -> i1
    %rhs_lt_lz_ub = "transfer.cmp"(%rhs1, %lhs_lz_ub) {predicate = 7 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %rhs_lt_lo_ub = "transfer.cmp"(%rhs1, %lhs_lo_ub) {predicate = 6 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %nsw_feasible_nonneg = "arith.andi"(%lhs_nonneg_possible, %rhs_lt_lz_ub) : (i1, i1) -> i1
    %nsw_feasible_neg = "arith.andi"(%lhs_neg_possible, %rhs_lt_lo_ub) : (i1, i1) -> i1
    %nsw_feasible = "arith.ori"(%nsw_feasible_nonneg, %nsw_feasible_neg) : (i1, i1) -> i1
    %rhs_max = "transfer.xor"(%rhs0, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %rhs1_lt_bw = "transfer.cmp"(%rhs1, %bitwidth) {predicate = 6 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %rhs_max_lt_bw = "transfer.cmp"(%rhs_max, %bitwidth) {predicate = 6 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %inputs_consistent = "arith.andi"(%lhs_consistent, %rhs_consistent) : (i1, i1) -> i1
    %has_feasible_pair_base = "arith.andi"(%inputs_consistent, %rhs_min_le_bw) : (i1, i1) -> i1
    %has_feasible_pair = "arith.andi"(%has_feasible_pair_base, %nsw_feasible) : (i1, i1) -> i1

    %const_shift_res0 = "transfer.shl"(%lhs0, %rhs1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %const_res1 = "transfer.shl"(%lhs1, %rhs1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %const_intro_mask = "transfer.shl"(%all_ones, %rhs1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %const_intro_zero = "transfer.xor"(%const_intro_mask, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %const_intro = "transfer.select"(%rhs1_lt_bw, %const_intro_zero, %const0) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %const_res0 = "transfer.or"(%const_shift_res0, %const_intro) : (!transfer.integer, !transfer.integer) -> !transfer.integer

    %rhs1_not = "transfer.xor"(%rhs1, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %rhs_is_const = "transfer.cmp"(%rhs0, %rhs1_not) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %lhs1_not = "transfer.xor"(%lhs1, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %lhs_is_const = "transfer.cmp"(%lhs0, %lhs1_not) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %both_const = "arith.andi"(%lhs_is_const, %rhs_is_const) : (i1, i1) -> i1

    %lhs_known_union = "transfer.or"(%lhs0, %lhs1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %lhs_unknown_mask = "transfer.xor"(%lhs_known_union, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %lhs_unknown_nonzero = "transfer.cmp"(%lhs_unknown_mask, %const0) {predicate = 1 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %lhs_unknown_minus_1 = "transfer.sub"(%lhs_unknown_mask, %const1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %lhs_unknown_and_minus_1 = "transfer.and"(%lhs_unknown_mask, %lhs_unknown_minus_1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %lhs_unknown_pow2ish = "transfer.cmp"(%lhs_unknown_and_minus_1, %const0) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %lhs_one_unknown = "arith.andi"(%lhs_unknown_nonzero, %lhs_unknown_pow2ish) : (i1, i1) -> i1
    %lhs_unknown_neg = "transfer.neg"(%lhs_unknown_mask) : (!transfer.integer) -> !transfer.integer
    %lhs_unknown_lowbit = "transfer.and"(%lhs_unknown_mask, %lhs_unknown_neg) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %lhs_unknown_rest = "transfer.xor"(%lhs_unknown_mask, %lhs_unknown_lowbit) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %lhs_rest_nonzero = "transfer.cmp"(%lhs_unknown_rest, %const0) {predicate = 1 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %lhs_rest_minus_1 = "transfer.sub"(%lhs_unknown_rest, %const1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %lhs_rest_and_minus_1 = "transfer.and"(%lhs_unknown_rest, %lhs_rest_minus_1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %lhs_rest_pow2ish = "transfer.cmp"(%lhs_rest_and_minus_1, %const0) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %lhs_two_unknown = "arith.andi"(%lhs_rest_nonzero, %lhs_rest_pow2ish) : (i1, i1) -> i1
    %rhs_const_lhs_one_unknown = "arith.andi"(%rhs_is_const, %lhs_one_unknown) : (i1, i1) -> i1
    %rhs_const_lhs_two_unknown = "arith.andi"(%rhs_is_const, %lhs_two_unknown) : (i1, i1) -> i1

    %const_val0_not = "transfer.xor"(%const_res1, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %lhs_one_alt = "transfer.add"(%lhs1, %lhs_unknown_mask) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %lhs_one_alt_val = "transfer.shl"(%lhs_one_alt, %rhs1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %lhs_one_alt_not = "transfer.xor"(%lhs_one_alt_val, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %lhs_one_res0_raw = "transfer.and"(%const_val0_not, %lhs_one_alt_not) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %lhs_one_res1_raw = "transfer.and"(%const_res1, %lhs_one_alt_val) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %lhs_one_res0 = "transfer.select"(%rhs_const_lhs_one_unknown, %lhs_one_res0_raw, %const0) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %lhs_one_res1 = "transfer.select"(%rhs_const_lhs_one_unknown, %lhs_one_res1_raw, %const0) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer

    %lhs_two_alt1 = "transfer.add"(%lhs1, %lhs_unknown_lowbit) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %lhs_two_alt2 = "transfer.add"(%lhs1, %lhs_unknown_rest) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %lhs_two_alt3 = "transfer.add"(%lhs1, %lhs_unknown_mask) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %lhs_two_val1 = "transfer.shl"(%lhs_two_alt1, %rhs1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %lhs_two_val2 = "transfer.shl"(%lhs_two_alt2, %rhs1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %lhs_two_val3 = "transfer.shl"(%lhs_two_alt3, %rhs1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %lhs_two_not1 = "transfer.xor"(%lhs_two_val1, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %lhs_two_not2 = "transfer.xor"(%lhs_two_val2, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %lhs_two_not3 = "transfer.xor"(%lhs_two_val3, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %lhs_two_res0_01 = "transfer.and"(%const_val0_not, %lhs_two_not1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %lhs_two_res0_23 = "transfer.and"(%lhs_two_not2, %lhs_two_not3) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %lhs_two_res0_raw = "transfer.and"(%lhs_two_res0_01, %lhs_two_res0_23) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %lhs_two_res1_01 = "transfer.and"(%const_res1, %lhs_two_val1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %lhs_two_res1_23 = "transfer.and"(%lhs_two_val2, %lhs_two_val3) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %lhs_two_res1_raw = "transfer.and"(%lhs_two_res1_01, %lhs_two_res1_23) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %lhs_two_res0 = "transfer.select"(%rhs_const_lhs_two_unknown, %lhs_two_res0_raw, %const0) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %lhs_two_res1 = "transfer.select"(%rhs_const_lhs_two_unknown, %lhs_two_res1_raw, %const0) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer

    %const_res0_lhs1 = "transfer.select"(%rhs_const_lhs_one_unknown, %lhs_one_res0, %const_res0) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %const_res1_lhs1 = "transfer.select"(%rhs_const_lhs_one_unknown, %lhs_one_res1, %const_res1) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %const_res0_lhs = "transfer.select"(%rhs_const_lhs_two_unknown, %lhs_two_res0, %const_res0_lhs1) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %const_res1_lhs = "transfer.select"(%rhs_const_lhs_two_unknown, %lhs_two_res1, %const_res1_lhs1) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer

    %rhs_known_union = "transfer.or"(%rhs0, %rhs1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %rhs_unknown_mask = "transfer.xor"(%rhs_known_union, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %rhs_unknown_nonzero = "transfer.cmp"(%rhs_unknown_mask, %const0) {predicate = 1 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %rhs_unknown_minus_1 = "transfer.sub"(%rhs_unknown_mask, %const1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %rhs_unknown_and_minus_1 = "transfer.and"(%rhs_unknown_mask, %rhs_unknown_minus_1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %rhs_unknown_pow2ish = "transfer.cmp"(%rhs_unknown_and_minus_1, %const0) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %rhs_one_unknown = "arith.andi"(%rhs_unknown_nonzero, %rhs_unknown_pow2ish) : (i1, i1) -> i1
    %rhs_unknown_not_pow2 = "arith.xori"(%rhs_one_unknown, %const_true) : (i1, i1) -> i1

    %rhs_u2_rem = "transfer.and"(%rhs_unknown_mask, %rhs_unknown_minus_1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %rhs_u2_rem_nonzero = "transfer.cmp"(%rhs_u2_rem, %const0) {predicate = 1 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %rhs_u2_rem_minus_1 = "transfer.sub"(%rhs_u2_rem, %const1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %rhs_u2_rem_and_minus_1 = "transfer.and"(%rhs_u2_rem, %rhs_u2_rem_minus_1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %rhs_u2_rem_pow2ish = "transfer.cmp"(%rhs_u2_rem_and_minus_1, %const0) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %rhs_u2_rem_pow2 = "arith.andi"(%rhs_u2_rem_nonzero, %rhs_u2_rem_pow2ish) : (i1, i1) -> i1
    %rhs_two_unknown_0 = "arith.andi"(%rhs_unknown_nonzero, %rhs_unknown_not_pow2) : (i1, i1) -> i1
    %rhs_two_unknown = "arith.andi"(%rhs_two_unknown_0, %rhs_u2_rem_pow2) : (i1, i1) -> i1

    %rhs_u3_rem1_not_pow2 = "arith.xori"(%rhs_u2_rem_pow2, %const_true) : (i1, i1) -> i1
    %rhs_u3_rem2 = "transfer.and"(%rhs_u2_rem, %rhs_u2_rem_minus_1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %rhs_u3_rem2_nonzero = "transfer.cmp"(%rhs_u3_rem2, %const0) {predicate = 1 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %rhs_u3_rem2_minus_1 = "transfer.sub"(%rhs_u3_rem2, %const1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %rhs_u3_rem2_and_minus_1 = "transfer.and"(%rhs_u3_rem2, %rhs_u3_rem2_minus_1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %rhs_u3_rem2_pow2ish = "transfer.cmp"(%rhs_u3_rem2_and_minus_1, %const0) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %rhs_u3_rem2_pow2 = "arith.andi"(%rhs_u3_rem2_nonzero, %rhs_u3_rem2_pow2ish) : (i1, i1) -> i1
    %rhs_three_unknown_0 = "arith.andi"(%rhs_unknown_nonzero, %rhs_unknown_not_pow2) : (i1, i1) -> i1
    %rhs_three_unknown_1 = "arith.andi"(%rhs_three_unknown_0, %rhs_u3_rem1_not_pow2) : (i1, i1) -> i1
    %rhs_three_unknown = "arith.andi"(%rhs_three_unknown_1, %rhs_u3_rem2_pow2) : (i1, i1) -> i1

    %rhs_alt = "transfer.add"(%rhs1, %rhs_unknown_mask) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %rhs_alt_lt_bw = "transfer.cmp"(%rhs_alt, %bitwidth) {predicate = 6 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %rhs_alt_le_bw = "transfer.cmp"(%rhs_alt, %bitwidth) {predicate = 7 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %rhs_alt_lt_lz_ub = "transfer.cmp"(%rhs_alt, %lhs_lz_ub) {predicate = 7 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %rhs_alt_lt_lo_ub = "transfer.cmp"(%rhs_alt, %lhs_lo_ub) {predicate = 6 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %rhs_alt_nsw_nonneg = "arith.andi"(%lhs_nonneg_possible, %rhs_alt_lt_lz_ub) : (i1, i1) -> i1
    %rhs_alt_nsw_neg = "arith.andi"(%lhs_neg_possible, %rhs_alt_lt_lo_ub) : (i1, i1) -> i1
    %rhs_alt_nsw_feasible = "arith.ori"(%rhs_alt_nsw_nonneg, %rhs_alt_nsw_neg) : (i1, i1) -> i1
    %rhs_val0_le_bw = "transfer.cmp"(%rhs1, %bitwidth) {predicate = 7 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %rhs_feas0 = "arith.andi"(%rhs_one_unknown, %rhs_val0_le_bw) : (i1, i1) -> i1
    %rhs_feas1 = "arith.andi"(%rhs_one_unknown, %rhs_alt_le_bw) : (i1, i1) -> i1
    %rhs_feas0_nsw = "arith.andi"(%rhs_feas0, %nsw_feasible) : (i1, i1) -> i1
    %rhs_feas1_nsw = "arith.andi"(%rhs_feas1, %rhs_alt_nsw_feasible) : (i1, i1) -> i1
    %rhs_any_feas_nsw = "arith.ori"(%rhs_feas0_nsw, %rhs_feas1_nsw) : (i1, i1) -> i1

    %alt_shift_res0 = "transfer.shl"(%lhs0, %rhs_alt) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %alt_res1 = "transfer.shl"(%lhs1, %rhs_alt) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %alt_res1_not = "transfer.xor"(%alt_res1, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %alt_intro_mask = "transfer.shl"(%all_ones, %rhs_alt) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %alt_intro_zero = "transfer.xor"(%alt_intro_mask, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %alt_intro = "transfer.select"(%rhs_alt_lt_bw, %alt_intro_zero, %const0) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %alt_res0 = "transfer.or"(%alt_shift_res0, %alt_intro) : (!transfer.integer, !transfer.integer) -> !transfer.integer

    %two_sel0_0 = "transfer.select"(%rhs_feas0_nsw, %const_res0, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %two_sel0_1 = "transfer.select"(%rhs_feas1_nsw, %alt_res0, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %two_acc0 = "transfer.and"(%two_sel0_0, %two_sel0_1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %two_case_res0 = "transfer.select"(%rhs_any_feas_nsw, %two_acc0, %const0) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer

    %two_sel1_0 = "transfer.select"(%rhs_feas0_nsw, %const_res1, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %two_sel1_1 = "transfer.select"(%rhs_feas1_nsw, %alt_res1, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %two_acc1 = "transfer.and"(%two_sel1_0, %two_sel1_1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %two_case_res1 = "transfer.select"(%rhs_any_feas_nsw, %two_acc1, %const0) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer

    %rhs_u2_rem_not = "transfer.xor"(%rhs_u2_rem, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %rhs_u2_lowbit = "transfer.and"(%rhs_unknown_mask, %rhs_u2_rem_not) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %rhs_u2_highbit = "transfer.xor"(%rhs_unknown_mask, %rhs_u2_lowbit) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %rhs_u2_val1 = "transfer.add"(%rhs1, %rhs_u2_lowbit) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %rhs_u2_val2 = "transfer.add"(%rhs1, %rhs_u2_highbit) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %rhs_u2_val3 = "transfer.add"(%rhs1, %rhs_unknown_mask) : (!transfer.integer, !transfer.integer) -> !transfer.integer

    %rhs_u2_v0_le_bw = "transfer.cmp"(%rhs1, %bitwidth) {predicate = 7 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %rhs_u2_v1_le_bw = "transfer.cmp"(%rhs_u2_val1, %bitwidth) {predicate = 7 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %rhs_u2_v2_le_bw = "transfer.cmp"(%rhs_u2_val2, %bitwidth) {predicate = 7 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %rhs_u2_v3_le_bw = "transfer.cmp"(%rhs_u2_val3, %bitwidth) {predicate = 7 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %rhs_u2_v1_lt_lz_ub = "transfer.cmp"(%rhs_u2_val1, %lhs_lz_ub) {predicate = 7 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %rhs_u2_v2_lt_lz_ub = "transfer.cmp"(%rhs_u2_val2, %lhs_lz_ub) {predicate = 7 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %rhs_u2_v3_lt_lz_ub = "transfer.cmp"(%rhs_u2_val3, %lhs_lz_ub) {predicate = 7 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %rhs_u2_v1_lt_lo_ub = "transfer.cmp"(%rhs_u2_val1, %lhs_lo_ub) {predicate = 6 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %rhs_u2_v2_lt_lo_ub = "transfer.cmp"(%rhs_u2_val2, %lhs_lo_ub) {predicate = 6 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %rhs_u2_v3_lt_lo_ub = "transfer.cmp"(%rhs_u2_val3, %lhs_lo_ub) {predicate = 6 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %rhs_u2_v0_nsw_nonneg = "arith.andi"(%lhs_nonneg_possible, %rhs_lt_lz_ub) : (i1, i1) -> i1
    %rhs_u2_v1_nsw_nonneg = "arith.andi"(%lhs_nonneg_possible, %rhs_u2_v1_lt_lz_ub) : (i1, i1) -> i1
    %rhs_u2_v2_nsw_nonneg = "arith.andi"(%lhs_nonneg_possible, %rhs_u2_v2_lt_lz_ub) : (i1, i1) -> i1
    %rhs_u2_v3_nsw_nonneg = "arith.andi"(%lhs_nonneg_possible, %rhs_u2_v3_lt_lz_ub) : (i1, i1) -> i1
    %rhs_u2_v0_nsw_neg = "arith.andi"(%lhs_neg_possible, %rhs_lt_lo_ub) : (i1, i1) -> i1
    %rhs_u2_v1_nsw_neg = "arith.andi"(%lhs_neg_possible, %rhs_u2_v1_lt_lo_ub) : (i1, i1) -> i1
    %rhs_u2_v2_nsw_neg = "arith.andi"(%lhs_neg_possible, %rhs_u2_v2_lt_lo_ub) : (i1, i1) -> i1
    %rhs_u2_v3_nsw_neg = "arith.andi"(%lhs_neg_possible, %rhs_u2_v3_lt_lo_ub) : (i1, i1) -> i1
    %rhs_u2_v0_nsw = "arith.ori"(%rhs_u2_v0_nsw_nonneg, %rhs_u2_v0_nsw_neg) : (i1, i1) -> i1
    %rhs_u2_v1_nsw = "arith.ori"(%rhs_u2_v1_nsw_nonneg, %rhs_u2_v1_nsw_neg) : (i1, i1) -> i1
    %rhs_u2_v2_nsw = "arith.ori"(%rhs_u2_v2_nsw_nonneg, %rhs_u2_v2_nsw_neg) : (i1, i1) -> i1
    %rhs_u2_v3_nsw = "arith.ori"(%rhs_u2_v3_nsw_nonneg, %rhs_u2_v3_nsw_neg) : (i1, i1) -> i1
    %rhs_u2_feas0 = "arith.andi"(%rhs_two_unknown, %rhs_u2_v0_le_bw) : (i1, i1) -> i1
    %rhs_u2_feas1 = "arith.andi"(%rhs_two_unknown, %rhs_u2_v1_le_bw) : (i1, i1) -> i1
    %rhs_u2_feas2 = "arith.andi"(%rhs_two_unknown, %rhs_u2_v2_le_bw) : (i1, i1) -> i1
    %rhs_u2_feas3 = "arith.andi"(%rhs_two_unknown, %rhs_u2_v3_le_bw) : (i1, i1) -> i1
    %rhs_u2_feas0_nsw = "arith.andi"(%rhs_u2_feas0, %rhs_u2_v0_nsw) : (i1, i1) -> i1
    %rhs_u2_feas1_nsw = "arith.andi"(%rhs_u2_feas1, %rhs_u2_v1_nsw) : (i1, i1) -> i1
    %rhs_u2_feas2_nsw = "arith.andi"(%rhs_u2_feas2, %rhs_u2_v2_nsw) : (i1, i1) -> i1
    %rhs_u2_feas3_nsw = "arith.andi"(%rhs_u2_feas3, %rhs_u2_v3_nsw) : (i1, i1) -> i1
    %rhs_u2_any01 = "arith.ori"(%rhs_u2_feas0_nsw, %rhs_u2_feas1_nsw) : (i1, i1) -> i1
    %rhs_u2_any23 = "arith.ori"(%rhs_u2_feas2_nsw, %rhs_u2_feas3_nsw) : (i1, i1) -> i1
    %rhs_u2_any_nsw = "arith.ori"(%rhs_u2_any01, %rhs_u2_any23) : (i1, i1) -> i1

    %rhs_u2_shift0_1 = "transfer.shl"(%lhs0, %rhs_u2_val1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %rhs_u2_shift0_2 = "transfer.shl"(%lhs0, %rhs_u2_val2) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %rhs_u2_shift0_3 = "transfer.shl"(%lhs0, %rhs_u2_val3) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %rhs_u2_v1_lt_bw = "transfer.cmp"(%rhs_u2_val1, %bitwidth) {predicate = 6 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %rhs_u2_v2_lt_bw = "transfer.cmp"(%rhs_u2_val2, %bitwidth) {predicate = 6 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %rhs_u2_v3_lt_bw = "transfer.cmp"(%rhs_u2_val3, %bitwidth) {predicate = 6 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %rhs_u2_intro_mask_1 = "transfer.shl"(%all_ones, %rhs_u2_val1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %rhs_u2_intro_mask_2 = "transfer.shl"(%all_ones, %rhs_u2_val2) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %rhs_u2_intro_mask_3 = "transfer.shl"(%all_ones, %rhs_u2_val3) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %rhs_u2_intro_zero_1 = "transfer.xor"(%rhs_u2_intro_mask_1, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %rhs_u2_intro_zero_2 = "transfer.xor"(%rhs_u2_intro_mask_2, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %rhs_u2_intro_zero_3 = "transfer.xor"(%rhs_u2_intro_mask_3, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %rhs_u2_intro_1 = "transfer.select"(%rhs_u2_v1_lt_bw, %rhs_u2_intro_zero_1, %const0) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %rhs_u2_intro_2 = "transfer.select"(%rhs_u2_v2_lt_bw, %rhs_u2_intro_zero_2, %const0) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %rhs_u2_intro_3 = "transfer.select"(%rhs_u2_v3_lt_bw, %rhs_u2_intro_zero_3, %const0) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %rhs_u2_res0_1 = "transfer.or"(%rhs_u2_shift0_1, %rhs_u2_intro_1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %rhs_u2_res0_2 = "transfer.or"(%rhs_u2_shift0_2, %rhs_u2_intro_2) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %rhs_u2_res0_3 = "transfer.or"(%rhs_u2_shift0_3, %rhs_u2_intro_3) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %rhs_u2_sel0_0 = "transfer.select"(%rhs_u2_feas0_nsw, %const_res0, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %rhs_u2_sel0_1 = "transfer.select"(%rhs_u2_feas1_nsw, %rhs_u2_res0_1, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %rhs_u2_sel0_2 = "transfer.select"(%rhs_u2_feas2_nsw, %rhs_u2_res0_2, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %rhs_u2_sel0_3 = "transfer.select"(%rhs_u2_feas3_nsw, %rhs_u2_res0_3, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %rhs_u2_acc0_01 = "transfer.and"(%rhs_u2_sel0_0, %rhs_u2_sel0_1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %rhs_u2_acc0_23 = "transfer.and"(%rhs_u2_sel0_2, %rhs_u2_sel0_3) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %rhs_u2_acc0 = "transfer.and"(%rhs_u2_acc0_01, %rhs_u2_acc0_23) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %rhs_u2_case_res0 = "transfer.select"(%rhs_u2_any_nsw, %rhs_u2_acc0, %const0) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer

    %rhs_u2_res1_1 = "transfer.shl"(%lhs1, %rhs_u2_val1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %rhs_u2_res1_2 = "transfer.shl"(%lhs1, %rhs_u2_val2) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %rhs_u2_res1_3 = "transfer.shl"(%lhs1, %rhs_u2_val3) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %rhs_u2_sel1_0 = "transfer.select"(%rhs_u2_feas0_nsw, %const_res1, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %rhs_u2_sel1_1 = "transfer.select"(%rhs_u2_feas1_nsw, %rhs_u2_res1_1, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %rhs_u2_sel1_2 = "transfer.select"(%rhs_u2_feas2_nsw, %rhs_u2_res1_2, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %rhs_u2_sel1_3 = "transfer.select"(%rhs_u2_feas3_nsw, %rhs_u2_res1_3, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %rhs_u2_acc1_01 = "transfer.and"(%rhs_u2_sel1_0, %rhs_u2_sel1_1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %rhs_u2_acc1_23 = "transfer.and"(%rhs_u2_sel1_2, %rhs_u2_sel1_3) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %rhs_u2_acc1 = "transfer.and"(%rhs_u2_acc1_01, %rhs_u2_acc1_23) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %rhs_u2_case_res1 = "transfer.select"(%rhs_u2_any_nsw, %rhs_u2_acc1, %const0) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer

    %rhs_u3_rem1_not = "transfer.xor"(%rhs_u2_rem, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %rhs_u3_bit1 = "transfer.and"(%rhs_unknown_mask, %rhs_u3_rem1_not) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %rhs_u3_rest = "transfer.xor"(%rhs_unknown_mask, %rhs_u3_bit1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %rhs_u3_rem2_not = "transfer.xor"(%rhs_u3_rem2, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %rhs_u3_bit2 = "transfer.and"(%rhs_u3_rest, %rhs_u3_rem2_not) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %rhs_u3_bit3 = "transfer.xor"(%rhs_u3_rest, %rhs_u3_bit2) : (!transfer.integer, !transfer.integer) -> !transfer.integer

    %rhs_u3_val1 = "transfer.add"(%rhs1, %rhs_u3_bit1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %rhs_u3_val2 = "transfer.add"(%rhs1, %rhs_u3_bit2) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %rhs_u3_val3 = "transfer.add"(%rhs1, %rhs_u3_bit3) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %rhs_u3_bit12 = "transfer.add"(%rhs_u3_bit1, %rhs_u3_bit2) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %rhs_u3_bit13 = "transfer.add"(%rhs_u3_bit1, %rhs_u3_bit3) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %rhs_u3_bit23 = "transfer.add"(%rhs_u3_bit2, %rhs_u3_bit3) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %rhs_u3_val4 = "transfer.add"(%rhs1, %rhs_u3_bit12) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %rhs_u3_val5 = "transfer.add"(%rhs1, %rhs_u3_bit13) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %rhs_u3_val6 = "transfer.add"(%rhs1, %rhs_u3_bit23) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %rhs_u3_val7 = "transfer.add"(%rhs1, %rhs_unknown_mask) : (!transfer.integer, !transfer.integer) -> !transfer.integer

    %rhs_u3_v0_le_bw = "transfer.cmp"(%rhs1, %bitwidth) {predicate = 7 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %rhs_u3_v1_le_bw = "transfer.cmp"(%rhs_u3_val1, %bitwidth) {predicate = 7 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %rhs_u3_v2_le_bw = "transfer.cmp"(%rhs_u3_val2, %bitwidth) {predicate = 7 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %rhs_u3_v3_le_bw = "transfer.cmp"(%rhs_u3_val3, %bitwidth) {predicate = 7 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %rhs_u3_v4_le_bw = "transfer.cmp"(%rhs_u3_val4, %bitwidth) {predicate = 7 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %rhs_u3_v5_le_bw = "transfer.cmp"(%rhs_u3_val5, %bitwidth) {predicate = 7 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %rhs_u3_v6_le_bw = "transfer.cmp"(%rhs_u3_val6, %bitwidth) {predicate = 7 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %rhs_u3_v7_le_bw = "transfer.cmp"(%rhs_u3_val7, %bitwidth) {predicate = 7 : i64} : (!transfer.integer, !transfer.integer) -> i1

    %rhs_u3_v1_lt_lz_ub = "transfer.cmp"(%rhs_u3_val1, %lhs_lz_ub) {predicate = 7 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %rhs_u3_v2_lt_lz_ub = "transfer.cmp"(%rhs_u3_val2, %lhs_lz_ub) {predicate = 7 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %rhs_u3_v3_lt_lz_ub = "transfer.cmp"(%rhs_u3_val3, %lhs_lz_ub) {predicate = 7 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %rhs_u3_v4_lt_lz_ub = "transfer.cmp"(%rhs_u3_val4, %lhs_lz_ub) {predicate = 7 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %rhs_u3_v5_lt_lz_ub = "transfer.cmp"(%rhs_u3_val5, %lhs_lz_ub) {predicate = 7 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %rhs_u3_v6_lt_lz_ub = "transfer.cmp"(%rhs_u3_val6, %lhs_lz_ub) {predicate = 7 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %rhs_u3_v7_lt_lz_ub = "transfer.cmp"(%rhs_u3_val7, %lhs_lz_ub) {predicate = 7 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %rhs_u3_v1_lt_lo_ub = "transfer.cmp"(%rhs_u3_val1, %lhs_lo_ub) {predicate = 6 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %rhs_u3_v2_lt_lo_ub = "transfer.cmp"(%rhs_u3_val2, %lhs_lo_ub) {predicate = 6 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %rhs_u3_v3_lt_lo_ub = "transfer.cmp"(%rhs_u3_val3, %lhs_lo_ub) {predicate = 6 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %rhs_u3_v4_lt_lo_ub = "transfer.cmp"(%rhs_u3_val4, %lhs_lo_ub) {predicate = 6 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %rhs_u3_v5_lt_lo_ub = "transfer.cmp"(%rhs_u3_val5, %lhs_lo_ub) {predicate = 6 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %rhs_u3_v6_lt_lo_ub = "transfer.cmp"(%rhs_u3_val6, %lhs_lo_ub) {predicate = 6 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %rhs_u3_v7_lt_lo_ub = "transfer.cmp"(%rhs_u3_val7, %lhs_lo_ub) {predicate = 6 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %rhs_u3_v0_nsw_nonneg = "arith.andi"(%lhs_nonneg_possible, %rhs_lt_lz_ub) : (i1, i1) -> i1
    %rhs_u3_v1_nsw_nonneg = "arith.andi"(%lhs_nonneg_possible, %rhs_u3_v1_lt_lz_ub) : (i1, i1) -> i1
    %rhs_u3_v2_nsw_nonneg = "arith.andi"(%lhs_nonneg_possible, %rhs_u3_v2_lt_lz_ub) : (i1, i1) -> i1
    %rhs_u3_v3_nsw_nonneg = "arith.andi"(%lhs_nonneg_possible, %rhs_u3_v3_lt_lz_ub) : (i1, i1) -> i1
    %rhs_u3_v4_nsw_nonneg = "arith.andi"(%lhs_nonneg_possible, %rhs_u3_v4_lt_lz_ub) : (i1, i1) -> i1
    %rhs_u3_v5_nsw_nonneg = "arith.andi"(%lhs_nonneg_possible, %rhs_u3_v5_lt_lz_ub) : (i1, i1) -> i1
    %rhs_u3_v6_nsw_nonneg = "arith.andi"(%lhs_nonneg_possible, %rhs_u3_v6_lt_lz_ub) : (i1, i1) -> i1
    %rhs_u3_v7_nsw_nonneg = "arith.andi"(%lhs_nonneg_possible, %rhs_u3_v7_lt_lz_ub) : (i1, i1) -> i1
    %rhs_u3_v0_nsw_neg = "arith.andi"(%lhs_neg_possible, %rhs_lt_lo_ub) : (i1, i1) -> i1
    %rhs_u3_v1_nsw_neg = "arith.andi"(%lhs_neg_possible, %rhs_u3_v1_lt_lo_ub) : (i1, i1) -> i1
    %rhs_u3_v2_nsw_neg = "arith.andi"(%lhs_neg_possible, %rhs_u3_v2_lt_lo_ub) : (i1, i1) -> i1
    %rhs_u3_v3_nsw_neg = "arith.andi"(%lhs_neg_possible, %rhs_u3_v3_lt_lo_ub) : (i1, i1) -> i1
    %rhs_u3_v4_nsw_neg = "arith.andi"(%lhs_neg_possible, %rhs_u3_v4_lt_lo_ub) : (i1, i1) -> i1
    %rhs_u3_v5_nsw_neg = "arith.andi"(%lhs_neg_possible, %rhs_u3_v5_lt_lo_ub) : (i1, i1) -> i1
    %rhs_u3_v6_nsw_neg = "arith.andi"(%lhs_neg_possible, %rhs_u3_v6_lt_lo_ub) : (i1, i1) -> i1
    %rhs_u3_v7_nsw_neg = "arith.andi"(%lhs_neg_possible, %rhs_u3_v7_lt_lo_ub) : (i1, i1) -> i1
    %rhs_u3_v0_nsw = "arith.ori"(%rhs_u3_v0_nsw_nonneg, %rhs_u3_v0_nsw_neg) : (i1, i1) -> i1
    %rhs_u3_v1_nsw = "arith.ori"(%rhs_u3_v1_nsw_nonneg, %rhs_u3_v1_nsw_neg) : (i1, i1) -> i1
    %rhs_u3_v2_nsw = "arith.ori"(%rhs_u3_v2_nsw_nonneg, %rhs_u3_v2_nsw_neg) : (i1, i1) -> i1
    %rhs_u3_v3_nsw = "arith.ori"(%rhs_u3_v3_nsw_nonneg, %rhs_u3_v3_nsw_neg) : (i1, i1) -> i1
    %rhs_u3_v4_nsw = "arith.ori"(%rhs_u3_v4_nsw_nonneg, %rhs_u3_v4_nsw_neg) : (i1, i1) -> i1
    %rhs_u3_v5_nsw = "arith.ori"(%rhs_u3_v5_nsw_nonneg, %rhs_u3_v5_nsw_neg) : (i1, i1) -> i1
    %rhs_u3_v6_nsw = "arith.ori"(%rhs_u3_v6_nsw_nonneg, %rhs_u3_v6_nsw_neg) : (i1, i1) -> i1
    %rhs_u3_v7_nsw = "arith.ori"(%rhs_u3_v7_nsw_nonneg, %rhs_u3_v7_nsw_neg) : (i1, i1) -> i1
    %rhs_u3_feas0 = "arith.andi"(%rhs_three_unknown, %rhs_u3_v0_le_bw) : (i1, i1) -> i1
    %rhs_u3_feas1 = "arith.andi"(%rhs_three_unknown, %rhs_u3_v1_le_bw) : (i1, i1) -> i1
    %rhs_u3_feas2 = "arith.andi"(%rhs_three_unknown, %rhs_u3_v2_le_bw) : (i1, i1) -> i1
    %rhs_u3_feas3 = "arith.andi"(%rhs_three_unknown, %rhs_u3_v3_le_bw) : (i1, i1) -> i1
    %rhs_u3_feas4 = "arith.andi"(%rhs_three_unknown, %rhs_u3_v4_le_bw) : (i1, i1) -> i1
    %rhs_u3_feas5 = "arith.andi"(%rhs_three_unknown, %rhs_u3_v5_le_bw) : (i1, i1) -> i1
    %rhs_u3_feas6 = "arith.andi"(%rhs_three_unknown, %rhs_u3_v6_le_bw) : (i1, i1) -> i1
    %rhs_u3_feas7 = "arith.andi"(%rhs_three_unknown, %rhs_u3_v7_le_bw) : (i1, i1) -> i1
    %rhs_u3_feas0_nsw = "arith.andi"(%rhs_u3_feas0, %rhs_u3_v0_nsw) : (i1, i1) -> i1
    %rhs_u3_feas1_nsw = "arith.andi"(%rhs_u3_feas1, %rhs_u3_v1_nsw) : (i1, i1) -> i1
    %rhs_u3_feas2_nsw = "arith.andi"(%rhs_u3_feas2, %rhs_u3_v2_nsw) : (i1, i1) -> i1
    %rhs_u3_feas3_nsw = "arith.andi"(%rhs_u3_feas3, %rhs_u3_v3_nsw) : (i1, i1) -> i1
    %rhs_u3_feas4_nsw = "arith.andi"(%rhs_u3_feas4, %rhs_u3_v4_nsw) : (i1, i1) -> i1
    %rhs_u3_feas5_nsw = "arith.andi"(%rhs_u3_feas5, %rhs_u3_v5_nsw) : (i1, i1) -> i1
    %rhs_u3_feas6_nsw = "arith.andi"(%rhs_u3_feas6, %rhs_u3_v6_nsw) : (i1, i1) -> i1
    %rhs_u3_feas7_nsw = "arith.andi"(%rhs_u3_feas7, %rhs_u3_v7_nsw) : (i1, i1) -> i1

    %rhs_u3_any01 = "arith.ori"(%rhs_u3_feas0_nsw, %rhs_u3_feas1_nsw) : (i1, i1) -> i1
    %rhs_u3_any23 = "arith.ori"(%rhs_u3_feas2_nsw, %rhs_u3_feas3_nsw) : (i1, i1) -> i1
    %rhs_u3_any45 = "arith.ori"(%rhs_u3_feas4_nsw, %rhs_u3_feas5_nsw) : (i1, i1) -> i1
    %rhs_u3_any67 = "arith.ori"(%rhs_u3_feas6_nsw, %rhs_u3_feas7_nsw) : (i1, i1) -> i1
    %rhs_u3_any0123 = "arith.ori"(%rhs_u3_any01, %rhs_u3_any23) : (i1, i1) -> i1
    %rhs_u3_any4567 = "arith.ori"(%rhs_u3_any45, %rhs_u3_any67) : (i1, i1) -> i1
    %rhs_u3_any = "arith.ori"(%rhs_u3_any0123, %rhs_u3_any4567) : (i1, i1) -> i1

    %rhs_u3_shift0_1 = "transfer.shl"(%lhs0, %rhs_u3_val1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %rhs_u3_shift0_2 = "transfer.shl"(%lhs0, %rhs_u3_val2) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %rhs_u3_shift0_3 = "transfer.shl"(%lhs0, %rhs_u3_val3) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %rhs_u3_shift0_4 = "transfer.shl"(%lhs0, %rhs_u3_val4) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %rhs_u3_shift0_5 = "transfer.shl"(%lhs0, %rhs_u3_val5) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %rhs_u3_shift0_6 = "transfer.shl"(%lhs0, %rhs_u3_val6) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %rhs_u3_shift0_7 = "transfer.shl"(%lhs0, %rhs_u3_val7) : (!transfer.integer, !transfer.integer) -> !transfer.integer

    %rhs_u3_v1_lt_bw = "transfer.cmp"(%rhs_u3_val1, %bitwidth) {predicate = 6 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %rhs_u3_v2_lt_bw = "transfer.cmp"(%rhs_u3_val2, %bitwidth) {predicate = 6 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %rhs_u3_v3_lt_bw = "transfer.cmp"(%rhs_u3_val3, %bitwidth) {predicate = 6 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %rhs_u3_v4_lt_bw = "transfer.cmp"(%rhs_u3_val4, %bitwidth) {predicate = 6 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %rhs_u3_v5_lt_bw = "transfer.cmp"(%rhs_u3_val5, %bitwidth) {predicate = 6 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %rhs_u3_v6_lt_bw = "transfer.cmp"(%rhs_u3_val6, %bitwidth) {predicate = 6 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %rhs_u3_v7_lt_bw = "transfer.cmp"(%rhs_u3_val7, %bitwidth) {predicate = 6 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %rhs_u3_intro_mask_1 = "transfer.shl"(%all_ones, %rhs_u3_val1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %rhs_u3_intro_mask_2 = "transfer.shl"(%all_ones, %rhs_u3_val2) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %rhs_u3_intro_mask_3 = "transfer.shl"(%all_ones, %rhs_u3_val3) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %rhs_u3_intro_mask_4 = "transfer.shl"(%all_ones, %rhs_u3_val4) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %rhs_u3_intro_mask_5 = "transfer.shl"(%all_ones, %rhs_u3_val5) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %rhs_u3_intro_mask_6 = "transfer.shl"(%all_ones, %rhs_u3_val6) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %rhs_u3_intro_mask_7 = "transfer.shl"(%all_ones, %rhs_u3_val7) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %rhs_u3_intro_zero_1 = "transfer.xor"(%rhs_u3_intro_mask_1, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %rhs_u3_intro_zero_2 = "transfer.xor"(%rhs_u3_intro_mask_2, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %rhs_u3_intro_zero_3 = "transfer.xor"(%rhs_u3_intro_mask_3, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %rhs_u3_intro_zero_4 = "transfer.xor"(%rhs_u3_intro_mask_4, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %rhs_u3_intro_zero_5 = "transfer.xor"(%rhs_u3_intro_mask_5, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %rhs_u3_intro_zero_6 = "transfer.xor"(%rhs_u3_intro_mask_6, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %rhs_u3_intro_zero_7 = "transfer.xor"(%rhs_u3_intro_mask_7, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %rhs_u3_intro_1 = "transfer.select"(%rhs_u3_v1_lt_bw, %rhs_u3_intro_zero_1, %const0) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %rhs_u3_intro_2 = "transfer.select"(%rhs_u3_v2_lt_bw, %rhs_u3_intro_zero_2, %const0) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %rhs_u3_intro_3 = "transfer.select"(%rhs_u3_v3_lt_bw, %rhs_u3_intro_zero_3, %const0) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %rhs_u3_intro_4 = "transfer.select"(%rhs_u3_v4_lt_bw, %rhs_u3_intro_zero_4, %const0) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %rhs_u3_intro_5 = "transfer.select"(%rhs_u3_v5_lt_bw, %rhs_u3_intro_zero_5, %const0) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %rhs_u3_intro_6 = "transfer.select"(%rhs_u3_v6_lt_bw, %rhs_u3_intro_zero_6, %const0) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %rhs_u3_intro_7 = "transfer.select"(%rhs_u3_v7_lt_bw, %rhs_u3_intro_zero_7, %const0) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %rhs_u3_res0_1 = "transfer.or"(%rhs_u3_shift0_1, %rhs_u3_intro_1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %rhs_u3_res0_2 = "transfer.or"(%rhs_u3_shift0_2, %rhs_u3_intro_2) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %rhs_u3_res0_3 = "transfer.or"(%rhs_u3_shift0_3, %rhs_u3_intro_3) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %rhs_u3_res0_4 = "transfer.or"(%rhs_u3_shift0_4, %rhs_u3_intro_4) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %rhs_u3_res0_5 = "transfer.or"(%rhs_u3_shift0_5, %rhs_u3_intro_5) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %rhs_u3_res0_6 = "transfer.or"(%rhs_u3_shift0_6, %rhs_u3_intro_6) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %rhs_u3_res0_7 = "transfer.or"(%rhs_u3_shift0_7, %rhs_u3_intro_7) : (!transfer.integer, !transfer.integer) -> !transfer.integer

    %rhs_u3_sel0_0 = "transfer.select"(%rhs_u3_feas0_nsw, %const_res0, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %rhs_u3_sel0_1 = "transfer.select"(%rhs_u3_feas1_nsw, %rhs_u3_res0_1, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %rhs_u3_sel0_2 = "transfer.select"(%rhs_u3_feas2_nsw, %rhs_u3_res0_2, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %rhs_u3_sel0_3 = "transfer.select"(%rhs_u3_feas3_nsw, %rhs_u3_res0_3, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %rhs_u3_sel0_4 = "transfer.select"(%rhs_u3_feas4_nsw, %rhs_u3_res0_4, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %rhs_u3_sel0_5 = "transfer.select"(%rhs_u3_feas5_nsw, %rhs_u3_res0_5, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %rhs_u3_sel0_6 = "transfer.select"(%rhs_u3_feas6_nsw, %rhs_u3_res0_6, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %rhs_u3_sel0_7 = "transfer.select"(%rhs_u3_feas7_nsw, %rhs_u3_res0_7, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer

    %rhs_u3_acc0_01 = "transfer.and"(%rhs_u3_sel0_0, %rhs_u3_sel0_1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %rhs_u3_acc0_23 = "transfer.and"(%rhs_u3_sel0_2, %rhs_u3_sel0_3) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %rhs_u3_acc0_45 = "transfer.and"(%rhs_u3_sel0_4, %rhs_u3_sel0_5) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %rhs_u3_acc0_67 = "transfer.and"(%rhs_u3_sel0_6, %rhs_u3_sel0_7) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %rhs_u3_acc0_0123 = "transfer.and"(%rhs_u3_acc0_01, %rhs_u3_acc0_23) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %rhs_u3_acc0_4567 = "transfer.and"(%rhs_u3_acc0_45, %rhs_u3_acc0_67) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %rhs_u3_acc0 = "transfer.and"(%rhs_u3_acc0_0123, %rhs_u3_acc0_4567) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %rhs_u3_case_res0 = "transfer.select"(%rhs_u3_any, %rhs_u3_acc0, %const0) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer

    %rhs_u3_res1_1 = "transfer.shl"(%lhs1, %rhs_u3_val1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %rhs_u3_res1_2 = "transfer.shl"(%lhs1, %rhs_u3_val2) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %rhs_u3_res1_3 = "transfer.shl"(%lhs1, %rhs_u3_val3) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %rhs_u3_res1_4 = "transfer.shl"(%lhs1, %rhs_u3_val4) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %rhs_u3_res1_5 = "transfer.shl"(%lhs1, %rhs_u3_val5) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %rhs_u3_res1_6 = "transfer.shl"(%lhs1, %rhs_u3_val6) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %rhs_u3_res1_7 = "transfer.shl"(%lhs1, %rhs_u3_val7) : (!transfer.integer, !transfer.integer) -> !transfer.integer

    %rhs_u3_sel1_0 = "transfer.select"(%rhs_u3_feas0_nsw, %const_res1, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %rhs_u3_sel1_1 = "transfer.select"(%rhs_u3_feas1_nsw, %rhs_u3_res1_1, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %rhs_u3_sel1_2 = "transfer.select"(%rhs_u3_feas2_nsw, %rhs_u3_res1_2, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %rhs_u3_sel1_3 = "transfer.select"(%rhs_u3_feas3_nsw, %rhs_u3_res1_3, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %rhs_u3_sel1_4 = "transfer.select"(%rhs_u3_feas4_nsw, %rhs_u3_res1_4, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %rhs_u3_sel1_5 = "transfer.select"(%rhs_u3_feas5_nsw, %rhs_u3_res1_5, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %rhs_u3_sel1_6 = "transfer.select"(%rhs_u3_feas6_nsw, %rhs_u3_res1_6, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %rhs_u3_sel1_7 = "transfer.select"(%rhs_u3_feas7_nsw, %rhs_u3_res1_7, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer

    %rhs_u3_acc1_01 = "transfer.and"(%rhs_u3_sel1_0, %rhs_u3_sel1_1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %rhs_u3_acc1_23 = "transfer.and"(%rhs_u3_sel1_2, %rhs_u3_sel1_3) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %rhs_u3_acc1_45 = "transfer.and"(%rhs_u3_sel1_4, %rhs_u3_sel1_5) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %rhs_u3_acc1_67 = "transfer.and"(%rhs_u3_sel1_6, %rhs_u3_sel1_7) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %rhs_u3_acc1_0123 = "transfer.and"(%rhs_u3_acc1_01, %rhs_u3_acc1_23) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %rhs_u3_acc1_4567 = "transfer.and"(%rhs_u3_acc1_45, %rhs_u3_acc1_67) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %rhs_u3_acc1 = "transfer.and"(%rhs_u3_acc1_0123, %rhs_u3_acc1_4567) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %rhs_u3_case_res1 = "transfer.select"(%rhs_u3_any, %rhs_u3_acc1, %const0) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer

    %lhs_rhs_one_one = "arith.andi"(%lhs_one_unknown, %rhs_one_unknown) : (i1, i1) -> i1
    %lhs_rhs_11_val = "transfer.shl"(%lhs_one_alt, %rhs_alt) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %lhs_rhs_11_not = "transfer.xor"(%lhs_rhs_11_val, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %lhs_rhs_11_res0_01 = "transfer.and"(%const_val0_not, %alt_res1_not) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %lhs_rhs_11_res0_23 = "transfer.and"(%lhs_one_alt_not, %lhs_rhs_11_not) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %lhs_rhs_11_res0_raw = "transfer.and"(%lhs_rhs_11_res0_01, %lhs_rhs_11_res0_23) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %lhs_rhs_11_res1_01 = "transfer.and"(%const_res1, %alt_res1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %lhs_rhs_11_res1_23 = "transfer.and"(%lhs_one_alt_val, %lhs_rhs_11_val) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %lhs_rhs_11_res1_raw = "transfer.and"(%lhs_rhs_11_res1_01, %lhs_rhs_11_res1_23) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %lhs_rhs_11_res0 = "transfer.select"(%lhs_rhs_one_one, %lhs_rhs_11_res0_raw, %const0) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %lhs_rhs_11_res1 = "transfer.select"(%lhs_rhs_one_one, %lhs_rhs_11_res1_raw, %const0) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer

    %lhs_rhs_one_two = "arith.andi"(%lhs_one_unknown, %rhs_two_unknown) : (i1, i1) -> i1
    %lhs_rhs_12_active = "arith.andi"(%lhs_rhs_one_two, %rhs_u2_any_nsw) : (i1, i1) -> i1
    %lhs_one_u2_val1 = "transfer.shl"(%lhs_one_alt, %rhs_u2_val1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %lhs_one_u2_val2 = "transfer.shl"(%lhs_one_alt, %rhs_u2_val2) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %lhs_one_u2_val3 = "transfer.shl"(%lhs_one_alt, %rhs_u2_val3) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %lhs_one_u2_not1 = "transfer.xor"(%lhs_one_u2_val1, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %lhs_one_u2_not2 = "transfer.xor"(%lhs_one_u2_val2, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %lhs_one_u2_not3 = "transfer.xor"(%lhs_one_u2_val3, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %lhs_12_sel0_0 = "transfer.select"(%rhs_u2_feas0_nsw, %lhs_one_alt_not, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %lhs_12_sel0_1 = "transfer.select"(%rhs_u2_feas1_nsw, %lhs_one_u2_not1, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %lhs_12_sel0_2 = "transfer.select"(%rhs_u2_feas2_nsw, %lhs_one_u2_not2, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %lhs_12_sel0_3 = "transfer.select"(%rhs_u2_feas3_nsw, %lhs_one_u2_not3, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %lhs_12_acc0_01 = "transfer.and"(%lhs_12_sel0_0, %lhs_12_sel0_1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %lhs_12_acc0_23 = "transfer.and"(%lhs_12_sel0_2, %lhs_12_sel0_3) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %lhs_12_acc0 = "transfer.and"(%lhs_12_acc0_01, %lhs_12_acc0_23) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %lhs_12_res0_raw = "transfer.and"(%const_val0_not, %lhs_12_acc0) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %lhs_12_sel1_0 = "transfer.select"(%rhs_u2_feas0_nsw, %lhs_one_alt_val, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %lhs_12_sel1_1 = "transfer.select"(%rhs_u2_feas1_nsw, %lhs_one_u2_val1, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %lhs_12_sel1_2 = "transfer.select"(%rhs_u2_feas2_nsw, %lhs_one_u2_val2, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %lhs_12_sel1_3 = "transfer.select"(%rhs_u2_feas3_nsw, %lhs_one_u2_val3, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %lhs_12_acc1_01 = "transfer.and"(%lhs_12_sel1_0, %lhs_12_sel1_1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %lhs_12_acc1_23 = "transfer.and"(%lhs_12_sel1_2, %lhs_12_sel1_3) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %lhs_12_acc1 = "transfer.and"(%lhs_12_acc1_01, %lhs_12_acc1_23) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %lhs_12_res1_raw = "transfer.and"(%const_res1, %lhs_12_acc1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %lhs_rhs_12_res0 = "transfer.select"(%lhs_rhs_12_active, %lhs_12_res0_raw, %const0) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %lhs_rhs_12_res1 = "transfer.select"(%lhs_rhs_12_active, %lhs_12_res1_raw, %const0) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer

    %lhs_rhs_two_one = "arith.andi"(%lhs_two_unknown, %rhs_one_unknown) : (i1, i1) -> i1
    %lhs_rhs_21_active = "arith.andi"(%lhs_rhs_two_one, %rhs_any_feas_nsw) : (i1, i1) -> i1
    %lhs_two_alt_val1 = "transfer.shl"(%lhs_two_alt1, %rhs_alt) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %lhs_two_alt_val2 = "transfer.shl"(%lhs_two_alt2, %rhs_alt) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %lhs_two_alt_val3 = "transfer.shl"(%lhs_two_alt3, %rhs_alt) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %lhs_two_alt_not1 = "transfer.xor"(%lhs_two_alt_val1, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %lhs_two_alt_not2 = "transfer.xor"(%lhs_two_alt_val2, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %lhs_two_alt_not3 = "transfer.xor"(%lhs_two_alt_val3, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %lhs_21_sel0_a0 = "transfer.select"(%rhs_feas0_nsw, %const_val0_not, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %lhs_21_sel0_a1 = "transfer.select"(%rhs_feas1_nsw, %alt_res1_not, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %lhs_21_sel0_b0 = "transfer.select"(%rhs_feas0_nsw, %lhs_two_not1, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %lhs_21_sel0_b1 = "transfer.select"(%rhs_feas1_nsw, %lhs_two_alt_not1, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %lhs_21_sel0_c0 = "transfer.select"(%rhs_feas0_nsw, %lhs_two_not2, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %lhs_21_sel0_c1 = "transfer.select"(%rhs_feas1_nsw, %lhs_two_alt_not2, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %lhs_21_sel0_d0 = "transfer.select"(%rhs_feas0_nsw, %lhs_two_not3, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %lhs_21_sel0_d1 = "transfer.select"(%rhs_feas1_nsw, %lhs_two_alt_not3, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %lhs_21_acc0_a = "transfer.and"(%lhs_21_sel0_a0, %lhs_21_sel0_a1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %lhs_21_acc0_b = "transfer.and"(%lhs_21_sel0_b0, %lhs_21_sel0_b1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %lhs_21_acc0_c = "transfer.and"(%lhs_21_sel0_c0, %lhs_21_sel0_c1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %lhs_21_acc0_d = "transfer.and"(%lhs_21_sel0_d0, %lhs_21_sel0_d1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %lhs_21_acc0_ab = "transfer.and"(%lhs_21_acc0_a, %lhs_21_acc0_b) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %lhs_21_acc0_cd = "transfer.and"(%lhs_21_acc0_c, %lhs_21_acc0_d) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %lhs_21_res0_raw = "transfer.and"(%lhs_21_acc0_ab, %lhs_21_acc0_cd) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %lhs_21_sel1_a0 = "transfer.select"(%rhs_feas0_nsw, %const_res1, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %lhs_21_sel1_a1 = "transfer.select"(%rhs_feas1_nsw, %alt_res1, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %lhs_21_sel1_b0 = "transfer.select"(%rhs_feas0_nsw, %lhs_two_val1, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %lhs_21_sel1_b1 = "transfer.select"(%rhs_feas1_nsw, %lhs_two_alt_val1, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %lhs_21_sel1_c0 = "transfer.select"(%rhs_feas0_nsw, %lhs_two_val2, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %lhs_21_sel1_c1 = "transfer.select"(%rhs_feas1_nsw, %lhs_two_alt_val2, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %lhs_21_sel1_d0 = "transfer.select"(%rhs_feas0_nsw, %lhs_two_val3, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %lhs_21_sel1_d1 = "transfer.select"(%rhs_feas1_nsw, %lhs_two_alt_val3, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %lhs_21_acc1_a = "transfer.and"(%lhs_21_sel1_a0, %lhs_21_sel1_a1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %lhs_21_acc1_b = "transfer.and"(%lhs_21_sel1_b0, %lhs_21_sel1_b1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %lhs_21_acc1_c = "transfer.and"(%lhs_21_sel1_c0, %lhs_21_sel1_c1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %lhs_21_acc1_d = "transfer.and"(%lhs_21_sel1_d0, %lhs_21_sel1_d1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %lhs_21_acc1_ab = "transfer.and"(%lhs_21_acc1_a, %lhs_21_acc1_b) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %lhs_21_acc1_cd = "transfer.and"(%lhs_21_acc1_c, %lhs_21_acc1_d) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %lhs_21_res1_raw = "transfer.and"(%lhs_21_acc1_ab, %lhs_21_acc1_cd) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %lhs_rhs_21_res0 = "transfer.select"(%lhs_rhs_21_active, %lhs_21_res0_raw, %const0) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %lhs_rhs_21_res1 = "transfer.select"(%lhs_rhs_21_active, %lhs_21_res1_raw, %const0) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer

    %var_base_intro = "transfer.select"(%rhs_max_lt_bw, %const_intro_zero, %const0) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %var_res0 = "transfer.add"(%var_base_intro, %const0) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %var_res1 = "transfer.add"(%const0, %const0) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %var_res0_dyn1 = "transfer.select"(%rhs_one_unknown, %two_case_res0, %var_res0) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %var_res1_dyn1 = "transfer.select"(%rhs_one_unknown, %two_case_res1, %var_res1) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %var_res0_dyn2 = "transfer.select"(%rhs_two_unknown, %rhs_u2_case_res0, %var_res0_dyn1) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %var_res1_dyn2 = "transfer.select"(%rhs_two_unknown, %rhs_u2_case_res1, %var_res1_dyn1) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %var_res0_dyn = "transfer.select"(%rhs_three_unknown, %rhs_u3_case_res0, %var_res0_dyn2) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %var_res1_dyn = "transfer.select"(%rhs_three_unknown, %rhs_u3_case_res1, %var_res1_dyn2) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %var_res0_dyn_cross1 = "transfer.select"(%lhs_rhs_one_one, %lhs_rhs_11_res0, %var_res0_dyn) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %var_res1_dyn_cross1 = "transfer.select"(%lhs_rhs_one_one, %lhs_rhs_11_res1, %var_res1_dyn) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %var_res0_dyn_cross2 = "transfer.select"(%lhs_rhs_one_two, %lhs_rhs_12_res0, %var_res0_dyn_cross1) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %var_res1_dyn_cross2 = "transfer.select"(%lhs_rhs_one_two, %lhs_rhs_12_res1, %var_res1_dyn_cross1) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %var_res0_dyn_cross = "transfer.select"(%lhs_rhs_two_one, %lhs_rhs_21_res0, %var_res0_dyn_cross2) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %var_res1_dyn_cross = "transfer.select"(%lhs_rhs_two_one, %lhs_rhs_21_res1, %var_res1_dyn_cross2) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer

    %res0_const_sel = "transfer.select"(%rhs_is_const, %const_res0_lhs, %var_res0_dyn_cross) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %res1_const_sel = "transfer.select"(%rhs_is_const, %const_res1_lhs, %var_res1_dyn_cross) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer

    %lhs0_all_ones = "transfer.cmp"(%lhs0, %all_ones) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %lhs1_is_zero = "transfer.cmp"(%lhs1, %const0) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %lhs_is_zero = "arith.andi"(%lhs0_all_ones, %lhs1_is_zero) : (i1, i1) -> i1
    %res0 = "transfer.select"(%lhs_is_zero, %all_ones, %res0_const_sel) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %res1 = "transfer.select"(%lhs_is_zero, %const0, %res1_const_sel) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer

    %res0_exact = "transfer.select"(%both_const, %const_val0_not, %res0) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %res1_exact = "transfer.select"(%both_const, %const_res1, %res1) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer

    // Exact refinement for small unknown sets (not bitwidth-specialized).
    %ex4_false = "arith.constant"() {value = 0 : i1} : () -> i1
    %ex4_lhs_rem0_m1 = "transfer.sub"(%lhs_unknown_mask, %const1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %ex4_lhs_rem1 = "transfer.and"(%lhs_unknown_mask, %ex4_lhs_rem0_m1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %ex4_lhs_b1 = "transfer.xor"(%lhs_unknown_mask, %ex4_lhs_rem1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %ex4_lhs_rem1_m1 = "transfer.sub"(%ex4_lhs_rem1, %const1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %ex4_lhs_rem2 = "transfer.and"(%ex4_lhs_rem1, %ex4_lhs_rem1_m1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %ex4_lhs_b2 = "transfer.xor"(%ex4_lhs_rem1, %ex4_lhs_rem2) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %ex4_lhs_rem2_m1 = "transfer.sub"(%ex4_lhs_rem2, %const1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %ex4_lhs_rem3 = "transfer.and"(%ex4_lhs_rem2, %ex4_lhs_rem2_m1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %ex4_lhs_b3 = "transfer.xor"(%ex4_lhs_rem2, %ex4_lhs_rem3) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %ex4_lhs_le3 = "transfer.cmp"(%ex4_lhs_rem3, %const0) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %ex4_lhs_v0 = "transfer.add"(%lhs1, %const0) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %ex4_lhs_v1 = "transfer.add"(%ex4_lhs_v0, %ex4_lhs_b1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %ex4_lhs_v2 = "transfer.add"(%ex4_lhs_v0, %ex4_lhs_b2) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %ex4_lhs_v3 = "transfer.add"(%ex4_lhs_v1, %ex4_lhs_b2) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %ex4_lhs_v4 = "transfer.add"(%ex4_lhs_v0, %ex4_lhs_b3) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %ex4_lhs_v5 = "transfer.add"(%ex4_lhs_v1, %ex4_lhs_b3) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %ex4_lhs_v6 = "transfer.add"(%ex4_lhs_v2, %ex4_lhs_b3) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %ex4_lhs_v7 = "transfer.add"(%ex4_lhs_v3, %ex4_lhs_b3) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %ex4_rhs_rem0_m1 = "transfer.sub"(%rhs_unknown_mask, %const1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %ex4_rhs_rem1 = "transfer.and"(%rhs_unknown_mask, %ex4_rhs_rem0_m1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %ex4_rhs_b1 = "transfer.xor"(%rhs_unknown_mask, %ex4_rhs_rem1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %ex4_rhs_rem1_m1 = "transfer.sub"(%ex4_rhs_rem1, %const1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %ex4_rhs_rem2 = "transfer.and"(%ex4_rhs_rem1, %ex4_rhs_rem1_m1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %ex4_rhs_b2 = "transfer.xor"(%ex4_rhs_rem1, %ex4_rhs_rem2) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %ex4_rhs_rem2_m1 = "transfer.sub"(%ex4_rhs_rem2, %const1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %ex4_rhs_rem3 = "transfer.and"(%ex4_rhs_rem2, %ex4_rhs_rem2_m1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %ex4_rhs_b3 = "transfer.xor"(%ex4_rhs_rem2, %ex4_rhs_rem3) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %ex4_rhs_le3 = "transfer.cmp"(%ex4_rhs_rem3, %const0) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %ex4_rhs_v0 = "transfer.add"(%rhs1, %const0) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %ex4_rhs_v1 = "transfer.add"(%ex4_rhs_v0, %ex4_rhs_b1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %ex4_rhs_v2 = "transfer.add"(%ex4_rhs_v0, %ex4_rhs_b2) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %ex4_rhs_v3 = "transfer.add"(%ex4_rhs_v1, %ex4_rhs_b2) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %ex4_rhs_v4 = "transfer.add"(%ex4_rhs_v0, %ex4_rhs_b3) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %ex4_rhs_v5 = "transfer.add"(%ex4_rhs_v1, %ex4_rhs_b3) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %ex4_rhs_v6 = "transfer.add"(%ex4_rhs_v2, %ex4_rhs_b3) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %ex4_rhs_v7 = "transfer.add"(%ex4_rhs_v3, %ex4_rhs_b3) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %ex4_small_lhs_rhs = "arith.andi"(%ex4_lhs_le3, %ex4_rhs_le3) : (i1, i1) -> i1
    %ex4_exact_on = "arith.andi"(%ex4_small_lhs_rhs, %inputs_consistent) : (i1, i1) -> i1
    %ex4_acc0_0 = "transfer.add"(%all_ones, %const0) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %ex4_acc1_0 = "transfer.add"(%all_ones, %const0) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %ex4_any_0 = "arith.andi"(%ex4_false, %ex4_false) : (i1, i1) -> i1
    %ex4_chk_0 = "transfer.cmp"(%ex4_rhs_v0, %bitwidth) {predicate = 9 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %ex4_clz_0 = "transfer.countl_zero"(%ex4_lhs_v0) : (!transfer.integer) -> !transfer.integer
    %ex4_nuw_0 = "transfer.cmp"(%ex4_clz_0, %ex4_rhs_v0) {predicate = 9 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %ex4_ok_0 = "arith.andi"(%ex4_chk_0, %ex4_nuw_0) : (i1, i1) -> i1
    %ex4_cond_0 = "arith.andi"(%ex4_exact_on, %ex4_ok_0) : (i1, i1) -> i1
    %ex4_out_0 = "transfer.shl"(%ex4_lhs_v0, %ex4_rhs_v0) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %ex4_outn_0 = "transfer.xor"(%ex4_out_0, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %ex4_sel0_0 = "transfer.select"(%ex4_cond_0, %ex4_outn_0, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %ex4_sel1_0 = "transfer.select"(%ex4_cond_0, %ex4_out_0, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %ex4_acc0_1 = "transfer.and"(%ex4_acc0_0, %ex4_sel0_0) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %ex4_acc1_1 = "transfer.and"(%ex4_acc1_0, %ex4_sel1_0) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %ex4_any_1 = "arith.ori"(%ex4_any_0, %ex4_cond_0) : (i1, i1) -> i1
    %ex4_chk_1 = "transfer.cmp"(%ex4_rhs_v1, %bitwidth) {predicate = 9 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %ex4_clz_1 = "transfer.countl_zero"(%ex4_lhs_v0) : (!transfer.integer) -> !transfer.integer
    %ex4_nuw_1 = "transfer.cmp"(%ex4_clz_1, %ex4_rhs_v1) {predicate = 9 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %ex4_ok_1 = "arith.andi"(%ex4_chk_1, %ex4_nuw_1) : (i1, i1) -> i1
    %ex4_cond_1 = "arith.andi"(%ex4_exact_on, %ex4_ok_1) : (i1, i1) -> i1
    %ex4_out_1 = "transfer.shl"(%ex4_lhs_v0, %ex4_rhs_v1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %ex4_outn_1 = "transfer.xor"(%ex4_out_1, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %ex4_sel0_1 = "transfer.select"(%ex4_cond_1, %ex4_outn_1, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %ex4_sel1_1 = "transfer.select"(%ex4_cond_1, %ex4_out_1, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %ex4_acc0_2 = "transfer.and"(%ex4_acc0_1, %ex4_sel0_1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %ex4_acc1_2 = "transfer.and"(%ex4_acc1_1, %ex4_sel1_1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %ex4_any_2 = "arith.ori"(%ex4_any_1, %ex4_cond_1) : (i1, i1) -> i1
    %ex4_chk_2 = "transfer.cmp"(%ex4_rhs_v2, %bitwidth) {predicate = 9 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %ex4_clz_2 = "transfer.countl_zero"(%ex4_lhs_v0) : (!transfer.integer) -> !transfer.integer
    %ex4_nuw_2 = "transfer.cmp"(%ex4_clz_2, %ex4_rhs_v2) {predicate = 9 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %ex4_ok_2 = "arith.andi"(%ex4_chk_2, %ex4_nuw_2) : (i1, i1) -> i1
    %ex4_cond_2 = "arith.andi"(%ex4_exact_on, %ex4_ok_2) : (i1, i1) -> i1
    %ex4_out_2 = "transfer.shl"(%ex4_lhs_v0, %ex4_rhs_v2) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %ex4_outn_2 = "transfer.xor"(%ex4_out_2, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %ex4_sel0_2 = "transfer.select"(%ex4_cond_2, %ex4_outn_2, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %ex4_sel1_2 = "transfer.select"(%ex4_cond_2, %ex4_out_2, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %ex4_acc0_3 = "transfer.and"(%ex4_acc0_2, %ex4_sel0_2) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %ex4_acc1_3 = "transfer.and"(%ex4_acc1_2, %ex4_sel1_2) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %ex4_any_3 = "arith.ori"(%ex4_any_2, %ex4_cond_2) : (i1, i1) -> i1
    %ex4_chk_3 = "transfer.cmp"(%ex4_rhs_v3, %bitwidth) {predicate = 9 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %ex4_clz_3 = "transfer.countl_zero"(%ex4_lhs_v0) : (!transfer.integer) -> !transfer.integer
    %ex4_nuw_3 = "transfer.cmp"(%ex4_clz_3, %ex4_rhs_v3) {predicate = 9 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %ex4_ok_3 = "arith.andi"(%ex4_chk_3, %ex4_nuw_3) : (i1, i1) -> i1
    %ex4_cond_3 = "arith.andi"(%ex4_exact_on, %ex4_ok_3) : (i1, i1) -> i1
    %ex4_out_3 = "transfer.shl"(%ex4_lhs_v0, %ex4_rhs_v3) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %ex4_outn_3 = "transfer.xor"(%ex4_out_3, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %ex4_sel0_3 = "transfer.select"(%ex4_cond_3, %ex4_outn_3, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %ex4_sel1_3 = "transfer.select"(%ex4_cond_3, %ex4_out_3, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %ex4_acc0_4 = "transfer.and"(%ex4_acc0_3, %ex4_sel0_3) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %ex4_acc1_4 = "transfer.and"(%ex4_acc1_3, %ex4_sel1_3) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %ex4_any_4 = "arith.ori"(%ex4_any_3, %ex4_cond_3) : (i1, i1) -> i1
    %ex4_chk_4 = "transfer.cmp"(%ex4_rhs_v4, %bitwidth) {predicate = 9 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %ex4_clz_4 = "transfer.countl_zero"(%ex4_lhs_v0) : (!transfer.integer) -> !transfer.integer
    %ex4_nuw_4 = "transfer.cmp"(%ex4_clz_4, %ex4_rhs_v4) {predicate = 9 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %ex4_ok_4 = "arith.andi"(%ex4_chk_4, %ex4_nuw_4) : (i1, i1) -> i1
    %ex4_cond_4 = "arith.andi"(%ex4_exact_on, %ex4_ok_4) : (i1, i1) -> i1
    %ex4_out_4 = "transfer.shl"(%ex4_lhs_v0, %ex4_rhs_v4) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %ex4_outn_4 = "transfer.xor"(%ex4_out_4, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %ex4_sel0_4 = "transfer.select"(%ex4_cond_4, %ex4_outn_4, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %ex4_sel1_4 = "transfer.select"(%ex4_cond_4, %ex4_out_4, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %ex4_acc0_5 = "transfer.and"(%ex4_acc0_4, %ex4_sel0_4) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %ex4_acc1_5 = "transfer.and"(%ex4_acc1_4, %ex4_sel1_4) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %ex4_any_5 = "arith.ori"(%ex4_any_4, %ex4_cond_4) : (i1, i1) -> i1
    %ex4_chk_5 = "transfer.cmp"(%ex4_rhs_v5, %bitwidth) {predicate = 9 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %ex4_clz_5 = "transfer.countl_zero"(%ex4_lhs_v0) : (!transfer.integer) -> !transfer.integer
    %ex4_nuw_5 = "transfer.cmp"(%ex4_clz_5, %ex4_rhs_v5) {predicate = 9 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %ex4_ok_5 = "arith.andi"(%ex4_chk_5, %ex4_nuw_5) : (i1, i1) -> i1
    %ex4_cond_5 = "arith.andi"(%ex4_exact_on, %ex4_ok_5) : (i1, i1) -> i1
    %ex4_out_5 = "transfer.shl"(%ex4_lhs_v0, %ex4_rhs_v5) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %ex4_outn_5 = "transfer.xor"(%ex4_out_5, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %ex4_sel0_5 = "transfer.select"(%ex4_cond_5, %ex4_outn_5, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %ex4_sel1_5 = "transfer.select"(%ex4_cond_5, %ex4_out_5, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %ex4_acc0_6 = "transfer.and"(%ex4_acc0_5, %ex4_sel0_5) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %ex4_acc1_6 = "transfer.and"(%ex4_acc1_5, %ex4_sel1_5) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %ex4_any_6 = "arith.ori"(%ex4_any_5, %ex4_cond_5) : (i1, i1) -> i1
    %ex4_chk_6 = "transfer.cmp"(%ex4_rhs_v6, %bitwidth) {predicate = 9 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %ex4_clz_6 = "transfer.countl_zero"(%ex4_lhs_v0) : (!transfer.integer) -> !transfer.integer
    %ex4_nuw_6 = "transfer.cmp"(%ex4_clz_6, %ex4_rhs_v6) {predicate = 9 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %ex4_ok_6 = "arith.andi"(%ex4_chk_6, %ex4_nuw_6) : (i1, i1) -> i1
    %ex4_cond_6 = "arith.andi"(%ex4_exact_on, %ex4_ok_6) : (i1, i1) -> i1
    %ex4_out_6 = "transfer.shl"(%ex4_lhs_v0, %ex4_rhs_v6) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %ex4_outn_6 = "transfer.xor"(%ex4_out_6, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %ex4_sel0_6 = "transfer.select"(%ex4_cond_6, %ex4_outn_6, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %ex4_sel1_6 = "transfer.select"(%ex4_cond_6, %ex4_out_6, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %ex4_acc0_7 = "transfer.and"(%ex4_acc0_6, %ex4_sel0_6) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %ex4_acc1_7 = "transfer.and"(%ex4_acc1_6, %ex4_sel1_6) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %ex4_any_7 = "arith.ori"(%ex4_any_6, %ex4_cond_6) : (i1, i1) -> i1
    %ex4_chk_7 = "transfer.cmp"(%ex4_rhs_v7, %bitwidth) {predicate = 9 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %ex4_clz_7 = "transfer.countl_zero"(%ex4_lhs_v0) : (!transfer.integer) -> !transfer.integer
    %ex4_nuw_7 = "transfer.cmp"(%ex4_clz_7, %ex4_rhs_v7) {predicate = 9 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %ex4_ok_7 = "arith.andi"(%ex4_chk_7, %ex4_nuw_7) : (i1, i1) -> i1
    %ex4_cond_7 = "arith.andi"(%ex4_exact_on, %ex4_ok_7) : (i1, i1) -> i1
    %ex4_out_7 = "transfer.shl"(%ex4_lhs_v0, %ex4_rhs_v7) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %ex4_outn_7 = "transfer.xor"(%ex4_out_7, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %ex4_sel0_7 = "transfer.select"(%ex4_cond_7, %ex4_outn_7, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %ex4_sel1_7 = "transfer.select"(%ex4_cond_7, %ex4_out_7, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %ex4_acc0_8 = "transfer.and"(%ex4_acc0_7, %ex4_sel0_7) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %ex4_acc1_8 = "transfer.and"(%ex4_acc1_7, %ex4_sel1_7) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %ex4_any_8 = "arith.ori"(%ex4_any_7, %ex4_cond_7) : (i1, i1) -> i1
    %ex4_chk_8 = "transfer.cmp"(%ex4_rhs_v0, %bitwidth) {predicate = 9 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %ex4_clz_8 = "transfer.countl_zero"(%ex4_lhs_v1) : (!transfer.integer) -> !transfer.integer
    %ex4_nuw_8 = "transfer.cmp"(%ex4_clz_8, %ex4_rhs_v0) {predicate = 9 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %ex4_ok_8 = "arith.andi"(%ex4_chk_8, %ex4_nuw_8) : (i1, i1) -> i1
    %ex4_cond_8 = "arith.andi"(%ex4_exact_on, %ex4_ok_8) : (i1, i1) -> i1
    %ex4_out_8 = "transfer.shl"(%ex4_lhs_v1, %ex4_rhs_v0) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %ex4_outn_8 = "transfer.xor"(%ex4_out_8, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %ex4_sel0_8 = "transfer.select"(%ex4_cond_8, %ex4_outn_8, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %ex4_sel1_8 = "transfer.select"(%ex4_cond_8, %ex4_out_8, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %ex4_acc0_9 = "transfer.and"(%ex4_acc0_8, %ex4_sel0_8) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %ex4_acc1_9 = "transfer.and"(%ex4_acc1_8, %ex4_sel1_8) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %ex4_any_9 = "arith.ori"(%ex4_any_8, %ex4_cond_8) : (i1, i1) -> i1
    %ex4_chk_9 = "transfer.cmp"(%ex4_rhs_v1, %bitwidth) {predicate = 9 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %ex4_clz_9 = "transfer.countl_zero"(%ex4_lhs_v1) : (!transfer.integer) -> !transfer.integer
    %ex4_nuw_9 = "transfer.cmp"(%ex4_clz_9, %ex4_rhs_v1) {predicate = 9 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %ex4_ok_9 = "arith.andi"(%ex4_chk_9, %ex4_nuw_9) : (i1, i1) -> i1
    %ex4_cond_9 = "arith.andi"(%ex4_exact_on, %ex4_ok_9) : (i1, i1) -> i1
    %ex4_out_9 = "transfer.shl"(%ex4_lhs_v1, %ex4_rhs_v1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %ex4_outn_9 = "transfer.xor"(%ex4_out_9, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %ex4_sel0_9 = "transfer.select"(%ex4_cond_9, %ex4_outn_9, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %ex4_sel1_9 = "transfer.select"(%ex4_cond_9, %ex4_out_9, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %ex4_acc0_10 = "transfer.and"(%ex4_acc0_9, %ex4_sel0_9) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %ex4_acc1_10 = "transfer.and"(%ex4_acc1_9, %ex4_sel1_9) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %ex4_any_10 = "arith.ori"(%ex4_any_9, %ex4_cond_9) : (i1, i1) -> i1
    %ex4_chk_10 = "transfer.cmp"(%ex4_rhs_v2, %bitwidth) {predicate = 9 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %ex4_clz_10 = "transfer.countl_zero"(%ex4_lhs_v1) : (!transfer.integer) -> !transfer.integer
    %ex4_nuw_10 = "transfer.cmp"(%ex4_clz_10, %ex4_rhs_v2) {predicate = 9 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %ex4_ok_10 = "arith.andi"(%ex4_chk_10, %ex4_nuw_10) : (i1, i1) -> i1
    %ex4_cond_10 = "arith.andi"(%ex4_exact_on, %ex4_ok_10) : (i1, i1) -> i1
    %ex4_out_10 = "transfer.shl"(%ex4_lhs_v1, %ex4_rhs_v2) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %ex4_outn_10 = "transfer.xor"(%ex4_out_10, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %ex4_sel0_10 = "transfer.select"(%ex4_cond_10, %ex4_outn_10, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %ex4_sel1_10 = "transfer.select"(%ex4_cond_10, %ex4_out_10, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %ex4_acc0_11 = "transfer.and"(%ex4_acc0_10, %ex4_sel0_10) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %ex4_acc1_11 = "transfer.and"(%ex4_acc1_10, %ex4_sel1_10) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %ex4_any_11 = "arith.ori"(%ex4_any_10, %ex4_cond_10) : (i1, i1) -> i1
    %ex4_chk_11 = "transfer.cmp"(%ex4_rhs_v3, %bitwidth) {predicate = 9 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %ex4_clz_11 = "transfer.countl_zero"(%ex4_lhs_v1) : (!transfer.integer) -> !transfer.integer
    %ex4_nuw_11 = "transfer.cmp"(%ex4_clz_11, %ex4_rhs_v3) {predicate = 9 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %ex4_ok_11 = "arith.andi"(%ex4_chk_11, %ex4_nuw_11) : (i1, i1) -> i1
    %ex4_cond_11 = "arith.andi"(%ex4_exact_on, %ex4_ok_11) : (i1, i1) -> i1
    %ex4_out_11 = "transfer.shl"(%ex4_lhs_v1, %ex4_rhs_v3) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %ex4_outn_11 = "transfer.xor"(%ex4_out_11, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %ex4_sel0_11 = "transfer.select"(%ex4_cond_11, %ex4_outn_11, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %ex4_sel1_11 = "transfer.select"(%ex4_cond_11, %ex4_out_11, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %ex4_acc0_12 = "transfer.and"(%ex4_acc0_11, %ex4_sel0_11) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %ex4_acc1_12 = "transfer.and"(%ex4_acc1_11, %ex4_sel1_11) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %ex4_any_12 = "arith.ori"(%ex4_any_11, %ex4_cond_11) : (i1, i1) -> i1
    %ex4_chk_12 = "transfer.cmp"(%ex4_rhs_v4, %bitwidth) {predicate = 9 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %ex4_clz_12 = "transfer.countl_zero"(%ex4_lhs_v1) : (!transfer.integer) -> !transfer.integer
    %ex4_nuw_12 = "transfer.cmp"(%ex4_clz_12, %ex4_rhs_v4) {predicate = 9 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %ex4_ok_12 = "arith.andi"(%ex4_chk_12, %ex4_nuw_12) : (i1, i1) -> i1
    %ex4_cond_12 = "arith.andi"(%ex4_exact_on, %ex4_ok_12) : (i1, i1) -> i1
    %ex4_out_12 = "transfer.shl"(%ex4_lhs_v1, %ex4_rhs_v4) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %ex4_outn_12 = "transfer.xor"(%ex4_out_12, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %ex4_sel0_12 = "transfer.select"(%ex4_cond_12, %ex4_outn_12, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %ex4_sel1_12 = "transfer.select"(%ex4_cond_12, %ex4_out_12, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %ex4_acc0_13 = "transfer.and"(%ex4_acc0_12, %ex4_sel0_12) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %ex4_acc1_13 = "transfer.and"(%ex4_acc1_12, %ex4_sel1_12) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %ex4_any_13 = "arith.ori"(%ex4_any_12, %ex4_cond_12) : (i1, i1) -> i1
    %ex4_chk_13 = "transfer.cmp"(%ex4_rhs_v5, %bitwidth) {predicate = 9 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %ex4_clz_13 = "transfer.countl_zero"(%ex4_lhs_v1) : (!transfer.integer) -> !transfer.integer
    %ex4_nuw_13 = "transfer.cmp"(%ex4_clz_13, %ex4_rhs_v5) {predicate = 9 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %ex4_ok_13 = "arith.andi"(%ex4_chk_13, %ex4_nuw_13) : (i1, i1) -> i1
    %ex4_cond_13 = "arith.andi"(%ex4_exact_on, %ex4_ok_13) : (i1, i1) -> i1
    %ex4_out_13 = "transfer.shl"(%ex4_lhs_v1, %ex4_rhs_v5) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %ex4_outn_13 = "transfer.xor"(%ex4_out_13, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %ex4_sel0_13 = "transfer.select"(%ex4_cond_13, %ex4_outn_13, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %ex4_sel1_13 = "transfer.select"(%ex4_cond_13, %ex4_out_13, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %ex4_acc0_14 = "transfer.and"(%ex4_acc0_13, %ex4_sel0_13) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %ex4_acc1_14 = "transfer.and"(%ex4_acc1_13, %ex4_sel1_13) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %ex4_any_14 = "arith.ori"(%ex4_any_13, %ex4_cond_13) : (i1, i1) -> i1
    %ex4_chk_14 = "transfer.cmp"(%ex4_rhs_v6, %bitwidth) {predicate = 9 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %ex4_clz_14 = "transfer.countl_zero"(%ex4_lhs_v1) : (!transfer.integer) -> !transfer.integer
    %ex4_nuw_14 = "transfer.cmp"(%ex4_clz_14, %ex4_rhs_v6) {predicate = 9 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %ex4_ok_14 = "arith.andi"(%ex4_chk_14, %ex4_nuw_14) : (i1, i1) -> i1
    %ex4_cond_14 = "arith.andi"(%ex4_exact_on, %ex4_ok_14) : (i1, i1) -> i1
    %ex4_out_14 = "transfer.shl"(%ex4_lhs_v1, %ex4_rhs_v6) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %ex4_outn_14 = "transfer.xor"(%ex4_out_14, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %ex4_sel0_14 = "transfer.select"(%ex4_cond_14, %ex4_outn_14, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %ex4_sel1_14 = "transfer.select"(%ex4_cond_14, %ex4_out_14, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %ex4_acc0_15 = "transfer.and"(%ex4_acc0_14, %ex4_sel0_14) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %ex4_acc1_15 = "transfer.and"(%ex4_acc1_14, %ex4_sel1_14) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %ex4_any_15 = "arith.ori"(%ex4_any_14, %ex4_cond_14) : (i1, i1) -> i1
    %ex4_chk_15 = "transfer.cmp"(%ex4_rhs_v7, %bitwidth) {predicate = 9 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %ex4_clz_15 = "transfer.countl_zero"(%ex4_lhs_v1) : (!transfer.integer) -> !transfer.integer
    %ex4_nuw_15 = "transfer.cmp"(%ex4_clz_15, %ex4_rhs_v7) {predicate = 9 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %ex4_ok_15 = "arith.andi"(%ex4_chk_15, %ex4_nuw_15) : (i1, i1) -> i1
    %ex4_cond_15 = "arith.andi"(%ex4_exact_on, %ex4_ok_15) : (i1, i1) -> i1
    %ex4_out_15 = "transfer.shl"(%ex4_lhs_v1, %ex4_rhs_v7) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %ex4_outn_15 = "transfer.xor"(%ex4_out_15, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %ex4_sel0_15 = "transfer.select"(%ex4_cond_15, %ex4_outn_15, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %ex4_sel1_15 = "transfer.select"(%ex4_cond_15, %ex4_out_15, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %ex4_acc0_16 = "transfer.and"(%ex4_acc0_15, %ex4_sel0_15) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %ex4_acc1_16 = "transfer.and"(%ex4_acc1_15, %ex4_sel1_15) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %ex4_any_16 = "arith.ori"(%ex4_any_15, %ex4_cond_15) : (i1, i1) -> i1
    %ex4_chk_16 = "transfer.cmp"(%ex4_rhs_v0, %bitwidth) {predicate = 9 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %ex4_clz_16 = "transfer.countl_zero"(%ex4_lhs_v2) : (!transfer.integer) -> !transfer.integer
    %ex4_nuw_16 = "transfer.cmp"(%ex4_clz_16, %ex4_rhs_v0) {predicate = 9 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %ex4_ok_16 = "arith.andi"(%ex4_chk_16, %ex4_nuw_16) : (i1, i1) -> i1
    %ex4_cond_16 = "arith.andi"(%ex4_exact_on, %ex4_ok_16) : (i1, i1) -> i1
    %ex4_out_16 = "transfer.shl"(%ex4_lhs_v2, %ex4_rhs_v0) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %ex4_outn_16 = "transfer.xor"(%ex4_out_16, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %ex4_sel0_16 = "transfer.select"(%ex4_cond_16, %ex4_outn_16, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %ex4_sel1_16 = "transfer.select"(%ex4_cond_16, %ex4_out_16, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %ex4_acc0_17 = "transfer.and"(%ex4_acc0_16, %ex4_sel0_16) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %ex4_acc1_17 = "transfer.and"(%ex4_acc1_16, %ex4_sel1_16) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %ex4_any_17 = "arith.ori"(%ex4_any_16, %ex4_cond_16) : (i1, i1) -> i1
    %ex4_chk_17 = "transfer.cmp"(%ex4_rhs_v1, %bitwidth) {predicate = 9 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %ex4_clz_17 = "transfer.countl_zero"(%ex4_lhs_v2) : (!transfer.integer) -> !transfer.integer
    %ex4_nuw_17 = "transfer.cmp"(%ex4_clz_17, %ex4_rhs_v1) {predicate = 9 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %ex4_ok_17 = "arith.andi"(%ex4_chk_17, %ex4_nuw_17) : (i1, i1) -> i1
    %ex4_cond_17 = "arith.andi"(%ex4_exact_on, %ex4_ok_17) : (i1, i1) -> i1
    %ex4_out_17 = "transfer.shl"(%ex4_lhs_v2, %ex4_rhs_v1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %ex4_outn_17 = "transfer.xor"(%ex4_out_17, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %ex4_sel0_17 = "transfer.select"(%ex4_cond_17, %ex4_outn_17, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %ex4_sel1_17 = "transfer.select"(%ex4_cond_17, %ex4_out_17, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %ex4_acc0_18 = "transfer.and"(%ex4_acc0_17, %ex4_sel0_17) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %ex4_acc1_18 = "transfer.and"(%ex4_acc1_17, %ex4_sel1_17) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %ex4_any_18 = "arith.ori"(%ex4_any_17, %ex4_cond_17) : (i1, i1) -> i1
    %ex4_chk_18 = "transfer.cmp"(%ex4_rhs_v2, %bitwidth) {predicate = 9 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %ex4_clz_18 = "transfer.countl_zero"(%ex4_lhs_v2) : (!transfer.integer) -> !transfer.integer
    %ex4_nuw_18 = "transfer.cmp"(%ex4_clz_18, %ex4_rhs_v2) {predicate = 9 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %ex4_ok_18 = "arith.andi"(%ex4_chk_18, %ex4_nuw_18) : (i1, i1) -> i1
    %ex4_cond_18 = "arith.andi"(%ex4_exact_on, %ex4_ok_18) : (i1, i1) -> i1
    %ex4_out_18 = "transfer.shl"(%ex4_lhs_v2, %ex4_rhs_v2) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %ex4_outn_18 = "transfer.xor"(%ex4_out_18, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %ex4_sel0_18 = "transfer.select"(%ex4_cond_18, %ex4_outn_18, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %ex4_sel1_18 = "transfer.select"(%ex4_cond_18, %ex4_out_18, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %ex4_acc0_19 = "transfer.and"(%ex4_acc0_18, %ex4_sel0_18) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %ex4_acc1_19 = "transfer.and"(%ex4_acc1_18, %ex4_sel1_18) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %ex4_any_19 = "arith.ori"(%ex4_any_18, %ex4_cond_18) : (i1, i1) -> i1
    %ex4_chk_19 = "transfer.cmp"(%ex4_rhs_v3, %bitwidth) {predicate = 9 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %ex4_clz_19 = "transfer.countl_zero"(%ex4_lhs_v2) : (!transfer.integer) -> !transfer.integer
    %ex4_nuw_19 = "transfer.cmp"(%ex4_clz_19, %ex4_rhs_v3) {predicate = 9 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %ex4_ok_19 = "arith.andi"(%ex4_chk_19, %ex4_nuw_19) : (i1, i1) -> i1
    %ex4_cond_19 = "arith.andi"(%ex4_exact_on, %ex4_ok_19) : (i1, i1) -> i1
    %ex4_out_19 = "transfer.shl"(%ex4_lhs_v2, %ex4_rhs_v3) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %ex4_outn_19 = "transfer.xor"(%ex4_out_19, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %ex4_sel0_19 = "transfer.select"(%ex4_cond_19, %ex4_outn_19, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %ex4_sel1_19 = "transfer.select"(%ex4_cond_19, %ex4_out_19, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %ex4_acc0_20 = "transfer.and"(%ex4_acc0_19, %ex4_sel0_19) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %ex4_acc1_20 = "transfer.and"(%ex4_acc1_19, %ex4_sel1_19) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %ex4_any_20 = "arith.ori"(%ex4_any_19, %ex4_cond_19) : (i1, i1) -> i1
    %ex4_chk_20 = "transfer.cmp"(%ex4_rhs_v4, %bitwidth) {predicate = 9 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %ex4_clz_20 = "transfer.countl_zero"(%ex4_lhs_v2) : (!transfer.integer) -> !transfer.integer
    %ex4_nuw_20 = "transfer.cmp"(%ex4_clz_20, %ex4_rhs_v4) {predicate = 9 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %ex4_ok_20 = "arith.andi"(%ex4_chk_20, %ex4_nuw_20) : (i1, i1) -> i1
    %ex4_cond_20 = "arith.andi"(%ex4_exact_on, %ex4_ok_20) : (i1, i1) -> i1
    %ex4_out_20 = "transfer.shl"(%ex4_lhs_v2, %ex4_rhs_v4) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %ex4_outn_20 = "transfer.xor"(%ex4_out_20, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %ex4_sel0_20 = "transfer.select"(%ex4_cond_20, %ex4_outn_20, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %ex4_sel1_20 = "transfer.select"(%ex4_cond_20, %ex4_out_20, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %ex4_acc0_21 = "transfer.and"(%ex4_acc0_20, %ex4_sel0_20) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %ex4_acc1_21 = "transfer.and"(%ex4_acc1_20, %ex4_sel1_20) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %ex4_any_21 = "arith.ori"(%ex4_any_20, %ex4_cond_20) : (i1, i1) -> i1
    %ex4_chk_21 = "transfer.cmp"(%ex4_rhs_v5, %bitwidth) {predicate = 9 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %ex4_clz_21 = "transfer.countl_zero"(%ex4_lhs_v2) : (!transfer.integer) -> !transfer.integer
    %ex4_nuw_21 = "transfer.cmp"(%ex4_clz_21, %ex4_rhs_v5) {predicate = 9 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %ex4_ok_21 = "arith.andi"(%ex4_chk_21, %ex4_nuw_21) : (i1, i1) -> i1
    %ex4_cond_21 = "arith.andi"(%ex4_exact_on, %ex4_ok_21) : (i1, i1) -> i1
    %ex4_out_21 = "transfer.shl"(%ex4_lhs_v2, %ex4_rhs_v5) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %ex4_outn_21 = "transfer.xor"(%ex4_out_21, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %ex4_sel0_21 = "transfer.select"(%ex4_cond_21, %ex4_outn_21, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %ex4_sel1_21 = "transfer.select"(%ex4_cond_21, %ex4_out_21, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %ex4_acc0_22 = "transfer.and"(%ex4_acc0_21, %ex4_sel0_21) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %ex4_acc1_22 = "transfer.and"(%ex4_acc1_21, %ex4_sel1_21) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %ex4_any_22 = "arith.ori"(%ex4_any_21, %ex4_cond_21) : (i1, i1) -> i1
    %ex4_chk_22 = "transfer.cmp"(%ex4_rhs_v6, %bitwidth) {predicate = 9 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %ex4_clz_22 = "transfer.countl_zero"(%ex4_lhs_v2) : (!transfer.integer) -> !transfer.integer
    %ex4_nuw_22 = "transfer.cmp"(%ex4_clz_22, %ex4_rhs_v6) {predicate = 9 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %ex4_ok_22 = "arith.andi"(%ex4_chk_22, %ex4_nuw_22) : (i1, i1) -> i1
    %ex4_cond_22 = "arith.andi"(%ex4_exact_on, %ex4_ok_22) : (i1, i1) -> i1
    %ex4_out_22 = "transfer.shl"(%ex4_lhs_v2, %ex4_rhs_v6) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %ex4_outn_22 = "transfer.xor"(%ex4_out_22, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %ex4_sel0_22 = "transfer.select"(%ex4_cond_22, %ex4_outn_22, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %ex4_sel1_22 = "transfer.select"(%ex4_cond_22, %ex4_out_22, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %ex4_acc0_23 = "transfer.and"(%ex4_acc0_22, %ex4_sel0_22) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %ex4_acc1_23 = "transfer.and"(%ex4_acc1_22, %ex4_sel1_22) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %ex4_any_23 = "arith.ori"(%ex4_any_22, %ex4_cond_22) : (i1, i1) -> i1
    %ex4_chk_23 = "transfer.cmp"(%ex4_rhs_v7, %bitwidth) {predicate = 9 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %ex4_clz_23 = "transfer.countl_zero"(%ex4_lhs_v2) : (!transfer.integer) -> !transfer.integer
    %ex4_nuw_23 = "transfer.cmp"(%ex4_clz_23, %ex4_rhs_v7) {predicate = 9 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %ex4_ok_23 = "arith.andi"(%ex4_chk_23, %ex4_nuw_23) : (i1, i1) -> i1
    %ex4_cond_23 = "arith.andi"(%ex4_exact_on, %ex4_ok_23) : (i1, i1) -> i1
    %ex4_out_23 = "transfer.shl"(%ex4_lhs_v2, %ex4_rhs_v7) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %ex4_outn_23 = "transfer.xor"(%ex4_out_23, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %ex4_sel0_23 = "transfer.select"(%ex4_cond_23, %ex4_outn_23, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %ex4_sel1_23 = "transfer.select"(%ex4_cond_23, %ex4_out_23, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %ex4_acc0_24 = "transfer.and"(%ex4_acc0_23, %ex4_sel0_23) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %ex4_acc1_24 = "transfer.and"(%ex4_acc1_23, %ex4_sel1_23) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %ex4_any_24 = "arith.ori"(%ex4_any_23, %ex4_cond_23) : (i1, i1) -> i1
    %ex4_chk_24 = "transfer.cmp"(%ex4_rhs_v0, %bitwidth) {predicate = 9 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %ex4_clz_24 = "transfer.countl_zero"(%ex4_lhs_v3) : (!transfer.integer) -> !transfer.integer
    %ex4_nuw_24 = "transfer.cmp"(%ex4_clz_24, %ex4_rhs_v0) {predicate = 9 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %ex4_ok_24 = "arith.andi"(%ex4_chk_24, %ex4_nuw_24) : (i1, i1) -> i1
    %ex4_cond_24 = "arith.andi"(%ex4_exact_on, %ex4_ok_24) : (i1, i1) -> i1
    %ex4_out_24 = "transfer.shl"(%ex4_lhs_v3, %ex4_rhs_v0) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %ex4_outn_24 = "transfer.xor"(%ex4_out_24, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %ex4_sel0_24 = "transfer.select"(%ex4_cond_24, %ex4_outn_24, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %ex4_sel1_24 = "transfer.select"(%ex4_cond_24, %ex4_out_24, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %ex4_acc0_25 = "transfer.and"(%ex4_acc0_24, %ex4_sel0_24) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %ex4_acc1_25 = "transfer.and"(%ex4_acc1_24, %ex4_sel1_24) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %ex4_any_25 = "arith.ori"(%ex4_any_24, %ex4_cond_24) : (i1, i1) -> i1
    %ex4_chk_25 = "transfer.cmp"(%ex4_rhs_v1, %bitwidth) {predicate = 9 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %ex4_clz_25 = "transfer.countl_zero"(%ex4_lhs_v3) : (!transfer.integer) -> !transfer.integer
    %ex4_nuw_25 = "transfer.cmp"(%ex4_clz_25, %ex4_rhs_v1) {predicate = 9 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %ex4_ok_25 = "arith.andi"(%ex4_chk_25, %ex4_nuw_25) : (i1, i1) -> i1
    %ex4_cond_25 = "arith.andi"(%ex4_exact_on, %ex4_ok_25) : (i1, i1) -> i1
    %ex4_out_25 = "transfer.shl"(%ex4_lhs_v3, %ex4_rhs_v1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %ex4_outn_25 = "transfer.xor"(%ex4_out_25, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %ex4_sel0_25 = "transfer.select"(%ex4_cond_25, %ex4_outn_25, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %ex4_sel1_25 = "transfer.select"(%ex4_cond_25, %ex4_out_25, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %ex4_acc0_26 = "transfer.and"(%ex4_acc0_25, %ex4_sel0_25) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %ex4_acc1_26 = "transfer.and"(%ex4_acc1_25, %ex4_sel1_25) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %ex4_any_26 = "arith.ori"(%ex4_any_25, %ex4_cond_25) : (i1, i1) -> i1
    %ex4_chk_26 = "transfer.cmp"(%ex4_rhs_v2, %bitwidth) {predicate = 9 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %ex4_clz_26 = "transfer.countl_zero"(%ex4_lhs_v3) : (!transfer.integer) -> !transfer.integer
    %ex4_nuw_26 = "transfer.cmp"(%ex4_clz_26, %ex4_rhs_v2) {predicate = 9 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %ex4_ok_26 = "arith.andi"(%ex4_chk_26, %ex4_nuw_26) : (i1, i1) -> i1
    %ex4_cond_26 = "arith.andi"(%ex4_exact_on, %ex4_ok_26) : (i1, i1) -> i1
    %ex4_out_26 = "transfer.shl"(%ex4_lhs_v3, %ex4_rhs_v2) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %ex4_outn_26 = "transfer.xor"(%ex4_out_26, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %ex4_sel0_26 = "transfer.select"(%ex4_cond_26, %ex4_outn_26, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %ex4_sel1_26 = "transfer.select"(%ex4_cond_26, %ex4_out_26, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %ex4_acc0_27 = "transfer.and"(%ex4_acc0_26, %ex4_sel0_26) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %ex4_acc1_27 = "transfer.and"(%ex4_acc1_26, %ex4_sel1_26) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %ex4_any_27 = "arith.ori"(%ex4_any_26, %ex4_cond_26) : (i1, i1) -> i1
    %ex4_chk_27 = "transfer.cmp"(%ex4_rhs_v3, %bitwidth) {predicate = 9 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %ex4_clz_27 = "transfer.countl_zero"(%ex4_lhs_v3) : (!transfer.integer) -> !transfer.integer
    %ex4_nuw_27 = "transfer.cmp"(%ex4_clz_27, %ex4_rhs_v3) {predicate = 9 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %ex4_ok_27 = "arith.andi"(%ex4_chk_27, %ex4_nuw_27) : (i1, i1) -> i1
    %ex4_cond_27 = "arith.andi"(%ex4_exact_on, %ex4_ok_27) : (i1, i1) -> i1
    %ex4_out_27 = "transfer.shl"(%ex4_lhs_v3, %ex4_rhs_v3) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %ex4_outn_27 = "transfer.xor"(%ex4_out_27, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %ex4_sel0_27 = "transfer.select"(%ex4_cond_27, %ex4_outn_27, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %ex4_sel1_27 = "transfer.select"(%ex4_cond_27, %ex4_out_27, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %ex4_acc0_28 = "transfer.and"(%ex4_acc0_27, %ex4_sel0_27) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %ex4_acc1_28 = "transfer.and"(%ex4_acc1_27, %ex4_sel1_27) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %ex4_any_28 = "arith.ori"(%ex4_any_27, %ex4_cond_27) : (i1, i1) -> i1
    %ex4_chk_28 = "transfer.cmp"(%ex4_rhs_v4, %bitwidth) {predicate = 9 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %ex4_clz_28 = "transfer.countl_zero"(%ex4_lhs_v3) : (!transfer.integer) -> !transfer.integer
    %ex4_nuw_28 = "transfer.cmp"(%ex4_clz_28, %ex4_rhs_v4) {predicate = 9 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %ex4_ok_28 = "arith.andi"(%ex4_chk_28, %ex4_nuw_28) : (i1, i1) -> i1
    %ex4_cond_28 = "arith.andi"(%ex4_exact_on, %ex4_ok_28) : (i1, i1) -> i1
    %ex4_out_28 = "transfer.shl"(%ex4_lhs_v3, %ex4_rhs_v4) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %ex4_outn_28 = "transfer.xor"(%ex4_out_28, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %ex4_sel0_28 = "transfer.select"(%ex4_cond_28, %ex4_outn_28, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %ex4_sel1_28 = "transfer.select"(%ex4_cond_28, %ex4_out_28, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %ex4_acc0_29 = "transfer.and"(%ex4_acc0_28, %ex4_sel0_28) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %ex4_acc1_29 = "transfer.and"(%ex4_acc1_28, %ex4_sel1_28) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %ex4_any_29 = "arith.ori"(%ex4_any_28, %ex4_cond_28) : (i1, i1) -> i1
    %ex4_chk_29 = "transfer.cmp"(%ex4_rhs_v5, %bitwidth) {predicate = 9 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %ex4_clz_29 = "transfer.countl_zero"(%ex4_lhs_v3) : (!transfer.integer) -> !transfer.integer
    %ex4_nuw_29 = "transfer.cmp"(%ex4_clz_29, %ex4_rhs_v5) {predicate = 9 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %ex4_ok_29 = "arith.andi"(%ex4_chk_29, %ex4_nuw_29) : (i1, i1) -> i1
    %ex4_cond_29 = "arith.andi"(%ex4_exact_on, %ex4_ok_29) : (i1, i1) -> i1
    %ex4_out_29 = "transfer.shl"(%ex4_lhs_v3, %ex4_rhs_v5) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %ex4_outn_29 = "transfer.xor"(%ex4_out_29, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %ex4_sel0_29 = "transfer.select"(%ex4_cond_29, %ex4_outn_29, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %ex4_sel1_29 = "transfer.select"(%ex4_cond_29, %ex4_out_29, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %ex4_acc0_30 = "transfer.and"(%ex4_acc0_29, %ex4_sel0_29) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %ex4_acc1_30 = "transfer.and"(%ex4_acc1_29, %ex4_sel1_29) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %ex4_any_30 = "arith.ori"(%ex4_any_29, %ex4_cond_29) : (i1, i1) -> i1
    %ex4_chk_30 = "transfer.cmp"(%ex4_rhs_v6, %bitwidth) {predicate = 9 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %ex4_clz_30 = "transfer.countl_zero"(%ex4_lhs_v3) : (!transfer.integer) -> !transfer.integer
    %ex4_nuw_30 = "transfer.cmp"(%ex4_clz_30, %ex4_rhs_v6) {predicate = 9 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %ex4_ok_30 = "arith.andi"(%ex4_chk_30, %ex4_nuw_30) : (i1, i1) -> i1
    %ex4_cond_30 = "arith.andi"(%ex4_exact_on, %ex4_ok_30) : (i1, i1) -> i1
    %ex4_out_30 = "transfer.shl"(%ex4_lhs_v3, %ex4_rhs_v6) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %ex4_outn_30 = "transfer.xor"(%ex4_out_30, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %ex4_sel0_30 = "transfer.select"(%ex4_cond_30, %ex4_outn_30, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %ex4_sel1_30 = "transfer.select"(%ex4_cond_30, %ex4_out_30, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %ex4_acc0_31 = "transfer.and"(%ex4_acc0_30, %ex4_sel0_30) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %ex4_acc1_31 = "transfer.and"(%ex4_acc1_30, %ex4_sel1_30) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %ex4_any_31 = "arith.ori"(%ex4_any_30, %ex4_cond_30) : (i1, i1) -> i1
    %ex4_chk_31 = "transfer.cmp"(%ex4_rhs_v7, %bitwidth) {predicate = 9 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %ex4_clz_31 = "transfer.countl_zero"(%ex4_lhs_v3) : (!transfer.integer) -> !transfer.integer
    %ex4_nuw_31 = "transfer.cmp"(%ex4_clz_31, %ex4_rhs_v7) {predicate = 9 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %ex4_ok_31 = "arith.andi"(%ex4_chk_31, %ex4_nuw_31) : (i1, i1) -> i1
    %ex4_cond_31 = "arith.andi"(%ex4_exact_on, %ex4_ok_31) : (i1, i1) -> i1
    %ex4_out_31 = "transfer.shl"(%ex4_lhs_v3, %ex4_rhs_v7) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %ex4_outn_31 = "transfer.xor"(%ex4_out_31, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %ex4_sel0_31 = "transfer.select"(%ex4_cond_31, %ex4_outn_31, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %ex4_sel1_31 = "transfer.select"(%ex4_cond_31, %ex4_out_31, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %ex4_acc0_32 = "transfer.and"(%ex4_acc0_31, %ex4_sel0_31) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %ex4_acc1_32 = "transfer.and"(%ex4_acc1_31, %ex4_sel1_31) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %ex4_any_32 = "arith.ori"(%ex4_any_31, %ex4_cond_31) : (i1, i1) -> i1
    %ex4_chk_32 = "transfer.cmp"(%ex4_rhs_v0, %bitwidth) {predicate = 9 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %ex4_clz_32 = "transfer.countl_zero"(%ex4_lhs_v4) : (!transfer.integer) -> !transfer.integer
    %ex4_nuw_32 = "transfer.cmp"(%ex4_clz_32, %ex4_rhs_v0) {predicate = 9 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %ex4_ok_32 = "arith.andi"(%ex4_chk_32, %ex4_nuw_32) : (i1, i1) -> i1
    %ex4_cond_32 = "arith.andi"(%ex4_exact_on, %ex4_ok_32) : (i1, i1) -> i1
    %ex4_out_32 = "transfer.shl"(%ex4_lhs_v4, %ex4_rhs_v0) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %ex4_outn_32 = "transfer.xor"(%ex4_out_32, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %ex4_sel0_32 = "transfer.select"(%ex4_cond_32, %ex4_outn_32, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %ex4_sel1_32 = "transfer.select"(%ex4_cond_32, %ex4_out_32, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %ex4_acc0_33 = "transfer.and"(%ex4_acc0_32, %ex4_sel0_32) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %ex4_acc1_33 = "transfer.and"(%ex4_acc1_32, %ex4_sel1_32) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %ex4_any_33 = "arith.ori"(%ex4_any_32, %ex4_cond_32) : (i1, i1) -> i1
    %ex4_chk_33 = "transfer.cmp"(%ex4_rhs_v1, %bitwidth) {predicate = 9 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %ex4_clz_33 = "transfer.countl_zero"(%ex4_lhs_v4) : (!transfer.integer) -> !transfer.integer
    %ex4_nuw_33 = "transfer.cmp"(%ex4_clz_33, %ex4_rhs_v1) {predicate = 9 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %ex4_ok_33 = "arith.andi"(%ex4_chk_33, %ex4_nuw_33) : (i1, i1) -> i1
    %ex4_cond_33 = "arith.andi"(%ex4_exact_on, %ex4_ok_33) : (i1, i1) -> i1
    %ex4_out_33 = "transfer.shl"(%ex4_lhs_v4, %ex4_rhs_v1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %ex4_outn_33 = "transfer.xor"(%ex4_out_33, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %ex4_sel0_33 = "transfer.select"(%ex4_cond_33, %ex4_outn_33, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %ex4_sel1_33 = "transfer.select"(%ex4_cond_33, %ex4_out_33, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %ex4_acc0_34 = "transfer.and"(%ex4_acc0_33, %ex4_sel0_33) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %ex4_acc1_34 = "transfer.and"(%ex4_acc1_33, %ex4_sel1_33) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %ex4_any_34 = "arith.ori"(%ex4_any_33, %ex4_cond_33) : (i1, i1) -> i1
    %ex4_chk_34 = "transfer.cmp"(%ex4_rhs_v2, %bitwidth) {predicate = 9 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %ex4_clz_34 = "transfer.countl_zero"(%ex4_lhs_v4) : (!transfer.integer) -> !transfer.integer
    %ex4_nuw_34 = "transfer.cmp"(%ex4_clz_34, %ex4_rhs_v2) {predicate = 9 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %ex4_ok_34 = "arith.andi"(%ex4_chk_34, %ex4_nuw_34) : (i1, i1) -> i1
    %ex4_cond_34 = "arith.andi"(%ex4_exact_on, %ex4_ok_34) : (i1, i1) -> i1
    %ex4_out_34 = "transfer.shl"(%ex4_lhs_v4, %ex4_rhs_v2) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %ex4_outn_34 = "transfer.xor"(%ex4_out_34, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %ex4_sel0_34 = "transfer.select"(%ex4_cond_34, %ex4_outn_34, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %ex4_sel1_34 = "transfer.select"(%ex4_cond_34, %ex4_out_34, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %ex4_acc0_35 = "transfer.and"(%ex4_acc0_34, %ex4_sel0_34) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %ex4_acc1_35 = "transfer.and"(%ex4_acc1_34, %ex4_sel1_34) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %ex4_any_35 = "arith.ori"(%ex4_any_34, %ex4_cond_34) : (i1, i1) -> i1
    %ex4_chk_35 = "transfer.cmp"(%ex4_rhs_v3, %bitwidth) {predicate = 9 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %ex4_clz_35 = "transfer.countl_zero"(%ex4_lhs_v4) : (!transfer.integer) -> !transfer.integer
    %ex4_nuw_35 = "transfer.cmp"(%ex4_clz_35, %ex4_rhs_v3) {predicate = 9 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %ex4_ok_35 = "arith.andi"(%ex4_chk_35, %ex4_nuw_35) : (i1, i1) -> i1
    %ex4_cond_35 = "arith.andi"(%ex4_exact_on, %ex4_ok_35) : (i1, i1) -> i1
    %ex4_out_35 = "transfer.shl"(%ex4_lhs_v4, %ex4_rhs_v3) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %ex4_outn_35 = "transfer.xor"(%ex4_out_35, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %ex4_sel0_35 = "transfer.select"(%ex4_cond_35, %ex4_outn_35, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %ex4_sel1_35 = "transfer.select"(%ex4_cond_35, %ex4_out_35, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %ex4_acc0_36 = "transfer.and"(%ex4_acc0_35, %ex4_sel0_35) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %ex4_acc1_36 = "transfer.and"(%ex4_acc1_35, %ex4_sel1_35) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %ex4_any_36 = "arith.ori"(%ex4_any_35, %ex4_cond_35) : (i1, i1) -> i1
    %ex4_chk_36 = "transfer.cmp"(%ex4_rhs_v4, %bitwidth) {predicate = 9 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %ex4_clz_36 = "transfer.countl_zero"(%ex4_lhs_v4) : (!transfer.integer) -> !transfer.integer
    %ex4_nuw_36 = "transfer.cmp"(%ex4_clz_36, %ex4_rhs_v4) {predicate = 9 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %ex4_ok_36 = "arith.andi"(%ex4_chk_36, %ex4_nuw_36) : (i1, i1) -> i1
    %ex4_cond_36 = "arith.andi"(%ex4_exact_on, %ex4_ok_36) : (i1, i1) -> i1
    %ex4_out_36 = "transfer.shl"(%ex4_lhs_v4, %ex4_rhs_v4) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %ex4_outn_36 = "transfer.xor"(%ex4_out_36, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %ex4_sel0_36 = "transfer.select"(%ex4_cond_36, %ex4_outn_36, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %ex4_sel1_36 = "transfer.select"(%ex4_cond_36, %ex4_out_36, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %ex4_acc0_37 = "transfer.and"(%ex4_acc0_36, %ex4_sel0_36) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %ex4_acc1_37 = "transfer.and"(%ex4_acc1_36, %ex4_sel1_36) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %ex4_any_37 = "arith.ori"(%ex4_any_36, %ex4_cond_36) : (i1, i1) -> i1
    %ex4_chk_37 = "transfer.cmp"(%ex4_rhs_v5, %bitwidth) {predicate = 9 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %ex4_clz_37 = "transfer.countl_zero"(%ex4_lhs_v4) : (!transfer.integer) -> !transfer.integer
    %ex4_nuw_37 = "transfer.cmp"(%ex4_clz_37, %ex4_rhs_v5) {predicate = 9 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %ex4_ok_37 = "arith.andi"(%ex4_chk_37, %ex4_nuw_37) : (i1, i1) -> i1
    %ex4_cond_37 = "arith.andi"(%ex4_exact_on, %ex4_ok_37) : (i1, i1) -> i1
    %ex4_out_37 = "transfer.shl"(%ex4_lhs_v4, %ex4_rhs_v5) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %ex4_outn_37 = "transfer.xor"(%ex4_out_37, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %ex4_sel0_37 = "transfer.select"(%ex4_cond_37, %ex4_outn_37, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %ex4_sel1_37 = "transfer.select"(%ex4_cond_37, %ex4_out_37, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %ex4_acc0_38 = "transfer.and"(%ex4_acc0_37, %ex4_sel0_37) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %ex4_acc1_38 = "transfer.and"(%ex4_acc1_37, %ex4_sel1_37) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %ex4_any_38 = "arith.ori"(%ex4_any_37, %ex4_cond_37) : (i1, i1) -> i1
    %ex4_chk_38 = "transfer.cmp"(%ex4_rhs_v6, %bitwidth) {predicate = 9 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %ex4_clz_38 = "transfer.countl_zero"(%ex4_lhs_v4) : (!transfer.integer) -> !transfer.integer
    %ex4_nuw_38 = "transfer.cmp"(%ex4_clz_38, %ex4_rhs_v6) {predicate = 9 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %ex4_ok_38 = "arith.andi"(%ex4_chk_38, %ex4_nuw_38) : (i1, i1) -> i1
    %ex4_cond_38 = "arith.andi"(%ex4_exact_on, %ex4_ok_38) : (i1, i1) -> i1
    %ex4_out_38 = "transfer.shl"(%ex4_lhs_v4, %ex4_rhs_v6) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %ex4_outn_38 = "transfer.xor"(%ex4_out_38, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %ex4_sel0_38 = "transfer.select"(%ex4_cond_38, %ex4_outn_38, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %ex4_sel1_38 = "transfer.select"(%ex4_cond_38, %ex4_out_38, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %ex4_acc0_39 = "transfer.and"(%ex4_acc0_38, %ex4_sel0_38) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %ex4_acc1_39 = "transfer.and"(%ex4_acc1_38, %ex4_sel1_38) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %ex4_any_39 = "arith.ori"(%ex4_any_38, %ex4_cond_38) : (i1, i1) -> i1
    %ex4_chk_39 = "transfer.cmp"(%ex4_rhs_v7, %bitwidth) {predicate = 9 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %ex4_clz_39 = "transfer.countl_zero"(%ex4_lhs_v4) : (!transfer.integer) -> !transfer.integer
    %ex4_nuw_39 = "transfer.cmp"(%ex4_clz_39, %ex4_rhs_v7) {predicate = 9 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %ex4_ok_39 = "arith.andi"(%ex4_chk_39, %ex4_nuw_39) : (i1, i1) -> i1
    %ex4_cond_39 = "arith.andi"(%ex4_exact_on, %ex4_ok_39) : (i1, i1) -> i1
    %ex4_out_39 = "transfer.shl"(%ex4_lhs_v4, %ex4_rhs_v7) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %ex4_outn_39 = "transfer.xor"(%ex4_out_39, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %ex4_sel0_39 = "transfer.select"(%ex4_cond_39, %ex4_outn_39, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %ex4_sel1_39 = "transfer.select"(%ex4_cond_39, %ex4_out_39, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %ex4_acc0_40 = "transfer.and"(%ex4_acc0_39, %ex4_sel0_39) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %ex4_acc1_40 = "transfer.and"(%ex4_acc1_39, %ex4_sel1_39) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %ex4_any_40 = "arith.ori"(%ex4_any_39, %ex4_cond_39) : (i1, i1) -> i1
    %ex4_chk_40 = "transfer.cmp"(%ex4_rhs_v0, %bitwidth) {predicate = 9 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %ex4_clz_40 = "transfer.countl_zero"(%ex4_lhs_v5) : (!transfer.integer) -> !transfer.integer
    %ex4_nuw_40 = "transfer.cmp"(%ex4_clz_40, %ex4_rhs_v0) {predicate = 9 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %ex4_ok_40 = "arith.andi"(%ex4_chk_40, %ex4_nuw_40) : (i1, i1) -> i1
    %ex4_cond_40 = "arith.andi"(%ex4_exact_on, %ex4_ok_40) : (i1, i1) -> i1
    %ex4_out_40 = "transfer.shl"(%ex4_lhs_v5, %ex4_rhs_v0) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %ex4_outn_40 = "transfer.xor"(%ex4_out_40, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %ex4_sel0_40 = "transfer.select"(%ex4_cond_40, %ex4_outn_40, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %ex4_sel1_40 = "transfer.select"(%ex4_cond_40, %ex4_out_40, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %ex4_acc0_41 = "transfer.and"(%ex4_acc0_40, %ex4_sel0_40) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %ex4_acc1_41 = "transfer.and"(%ex4_acc1_40, %ex4_sel1_40) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %ex4_any_41 = "arith.ori"(%ex4_any_40, %ex4_cond_40) : (i1, i1) -> i1
    %ex4_chk_41 = "transfer.cmp"(%ex4_rhs_v1, %bitwidth) {predicate = 9 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %ex4_clz_41 = "transfer.countl_zero"(%ex4_lhs_v5) : (!transfer.integer) -> !transfer.integer
    %ex4_nuw_41 = "transfer.cmp"(%ex4_clz_41, %ex4_rhs_v1) {predicate = 9 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %ex4_ok_41 = "arith.andi"(%ex4_chk_41, %ex4_nuw_41) : (i1, i1) -> i1
    %ex4_cond_41 = "arith.andi"(%ex4_exact_on, %ex4_ok_41) : (i1, i1) -> i1
    %ex4_out_41 = "transfer.shl"(%ex4_lhs_v5, %ex4_rhs_v1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %ex4_outn_41 = "transfer.xor"(%ex4_out_41, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %ex4_sel0_41 = "transfer.select"(%ex4_cond_41, %ex4_outn_41, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %ex4_sel1_41 = "transfer.select"(%ex4_cond_41, %ex4_out_41, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %ex4_acc0_42 = "transfer.and"(%ex4_acc0_41, %ex4_sel0_41) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %ex4_acc1_42 = "transfer.and"(%ex4_acc1_41, %ex4_sel1_41) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %ex4_any_42 = "arith.ori"(%ex4_any_41, %ex4_cond_41) : (i1, i1) -> i1
    %ex4_chk_42 = "transfer.cmp"(%ex4_rhs_v2, %bitwidth) {predicate = 9 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %ex4_clz_42 = "transfer.countl_zero"(%ex4_lhs_v5) : (!transfer.integer) -> !transfer.integer
    %ex4_nuw_42 = "transfer.cmp"(%ex4_clz_42, %ex4_rhs_v2) {predicate = 9 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %ex4_ok_42 = "arith.andi"(%ex4_chk_42, %ex4_nuw_42) : (i1, i1) -> i1
    %ex4_cond_42 = "arith.andi"(%ex4_exact_on, %ex4_ok_42) : (i1, i1) -> i1
    %ex4_out_42 = "transfer.shl"(%ex4_lhs_v5, %ex4_rhs_v2) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %ex4_outn_42 = "transfer.xor"(%ex4_out_42, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %ex4_sel0_42 = "transfer.select"(%ex4_cond_42, %ex4_outn_42, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %ex4_sel1_42 = "transfer.select"(%ex4_cond_42, %ex4_out_42, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %ex4_acc0_43 = "transfer.and"(%ex4_acc0_42, %ex4_sel0_42) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %ex4_acc1_43 = "transfer.and"(%ex4_acc1_42, %ex4_sel1_42) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %ex4_any_43 = "arith.ori"(%ex4_any_42, %ex4_cond_42) : (i1, i1) -> i1
    %ex4_chk_43 = "transfer.cmp"(%ex4_rhs_v3, %bitwidth) {predicate = 9 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %ex4_clz_43 = "transfer.countl_zero"(%ex4_lhs_v5) : (!transfer.integer) -> !transfer.integer
    %ex4_nuw_43 = "transfer.cmp"(%ex4_clz_43, %ex4_rhs_v3) {predicate = 9 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %ex4_ok_43 = "arith.andi"(%ex4_chk_43, %ex4_nuw_43) : (i1, i1) -> i1
    %ex4_cond_43 = "arith.andi"(%ex4_exact_on, %ex4_ok_43) : (i1, i1) -> i1
    %ex4_out_43 = "transfer.shl"(%ex4_lhs_v5, %ex4_rhs_v3) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %ex4_outn_43 = "transfer.xor"(%ex4_out_43, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %ex4_sel0_43 = "transfer.select"(%ex4_cond_43, %ex4_outn_43, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %ex4_sel1_43 = "transfer.select"(%ex4_cond_43, %ex4_out_43, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %ex4_acc0_44 = "transfer.and"(%ex4_acc0_43, %ex4_sel0_43) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %ex4_acc1_44 = "transfer.and"(%ex4_acc1_43, %ex4_sel1_43) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %ex4_any_44 = "arith.ori"(%ex4_any_43, %ex4_cond_43) : (i1, i1) -> i1
    %ex4_chk_44 = "transfer.cmp"(%ex4_rhs_v4, %bitwidth) {predicate = 9 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %ex4_clz_44 = "transfer.countl_zero"(%ex4_lhs_v5) : (!transfer.integer) -> !transfer.integer
    %ex4_nuw_44 = "transfer.cmp"(%ex4_clz_44, %ex4_rhs_v4) {predicate = 9 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %ex4_ok_44 = "arith.andi"(%ex4_chk_44, %ex4_nuw_44) : (i1, i1) -> i1
    %ex4_cond_44 = "arith.andi"(%ex4_exact_on, %ex4_ok_44) : (i1, i1) -> i1
    %ex4_out_44 = "transfer.shl"(%ex4_lhs_v5, %ex4_rhs_v4) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %ex4_outn_44 = "transfer.xor"(%ex4_out_44, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %ex4_sel0_44 = "transfer.select"(%ex4_cond_44, %ex4_outn_44, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %ex4_sel1_44 = "transfer.select"(%ex4_cond_44, %ex4_out_44, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %ex4_acc0_45 = "transfer.and"(%ex4_acc0_44, %ex4_sel0_44) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %ex4_acc1_45 = "transfer.and"(%ex4_acc1_44, %ex4_sel1_44) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %ex4_any_45 = "arith.ori"(%ex4_any_44, %ex4_cond_44) : (i1, i1) -> i1
    %ex4_chk_45 = "transfer.cmp"(%ex4_rhs_v5, %bitwidth) {predicate = 9 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %ex4_clz_45 = "transfer.countl_zero"(%ex4_lhs_v5) : (!transfer.integer) -> !transfer.integer
    %ex4_nuw_45 = "transfer.cmp"(%ex4_clz_45, %ex4_rhs_v5) {predicate = 9 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %ex4_ok_45 = "arith.andi"(%ex4_chk_45, %ex4_nuw_45) : (i1, i1) -> i1
    %ex4_cond_45 = "arith.andi"(%ex4_exact_on, %ex4_ok_45) : (i1, i1) -> i1
    %ex4_out_45 = "transfer.shl"(%ex4_lhs_v5, %ex4_rhs_v5) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %ex4_outn_45 = "transfer.xor"(%ex4_out_45, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %ex4_sel0_45 = "transfer.select"(%ex4_cond_45, %ex4_outn_45, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %ex4_sel1_45 = "transfer.select"(%ex4_cond_45, %ex4_out_45, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %ex4_acc0_46 = "transfer.and"(%ex4_acc0_45, %ex4_sel0_45) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %ex4_acc1_46 = "transfer.and"(%ex4_acc1_45, %ex4_sel1_45) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %ex4_any_46 = "arith.ori"(%ex4_any_45, %ex4_cond_45) : (i1, i1) -> i1
    %ex4_chk_46 = "transfer.cmp"(%ex4_rhs_v6, %bitwidth) {predicate = 9 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %ex4_clz_46 = "transfer.countl_zero"(%ex4_lhs_v5) : (!transfer.integer) -> !transfer.integer
    %ex4_nuw_46 = "transfer.cmp"(%ex4_clz_46, %ex4_rhs_v6) {predicate = 9 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %ex4_ok_46 = "arith.andi"(%ex4_chk_46, %ex4_nuw_46) : (i1, i1) -> i1
    %ex4_cond_46 = "arith.andi"(%ex4_exact_on, %ex4_ok_46) : (i1, i1) -> i1
    %ex4_out_46 = "transfer.shl"(%ex4_lhs_v5, %ex4_rhs_v6) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %ex4_outn_46 = "transfer.xor"(%ex4_out_46, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %ex4_sel0_46 = "transfer.select"(%ex4_cond_46, %ex4_outn_46, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %ex4_sel1_46 = "transfer.select"(%ex4_cond_46, %ex4_out_46, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %ex4_acc0_47 = "transfer.and"(%ex4_acc0_46, %ex4_sel0_46) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %ex4_acc1_47 = "transfer.and"(%ex4_acc1_46, %ex4_sel1_46) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %ex4_any_47 = "arith.ori"(%ex4_any_46, %ex4_cond_46) : (i1, i1) -> i1
    %ex4_chk_47 = "transfer.cmp"(%ex4_rhs_v7, %bitwidth) {predicate = 9 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %ex4_clz_47 = "transfer.countl_zero"(%ex4_lhs_v5) : (!transfer.integer) -> !transfer.integer
    %ex4_nuw_47 = "transfer.cmp"(%ex4_clz_47, %ex4_rhs_v7) {predicate = 9 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %ex4_ok_47 = "arith.andi"(%ex4_chk_47, %ex4_nuw_47) : (i1, i1) -> i1
    %ex4_cond_47 = "arith.andi"(%ex4_exact_on, %ex4_ok_47) : (i1, i1) -> i1
    %ex4_out_47 = "transfer.shl"(%ex4_lhs_v5, %ex4_rhs_v7) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %ex4_outn_47 = "transfer.xor"(%ex4_out_47, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %ex4_sel0_47 = "transfer.select"(%ex4_cond_47, %ex4_outn_47, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %ex4_sel1_47 = "transfer.select"(%ex4_cond_47, %ex4_out_47, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %ex4_acc0_48 = "transfer.and"(%ex4_acc0_47, %ex4_sel0_47) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %ex4_acc1_48 = "transfer.and"(%ex4_acc1_47, %ex4_sel1_47) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %ex4_any_48 = "arith.ori"(%ex4_any_47, %ex4_cond_47) : (i1, i1) -> i1
    %ex4_chk_48 = "transfer.cmp"(%ex4_rhs_v0, %bitwidth) {predicate = 9 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %ex4_clz_48 = "transfer.countl_zero"(%ex4_lhs_v6) : (!transfer.integer) -> !transfer.integer
    %ex4_nuw_48 = "transfer.cmp"(%ex4_clz_48, %ex4_rhs_v0) {predicate = 9 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %ex4_ok_48 = "arith.andi"(%ex4_chk_48, %ex4_nuw_48) : (i1, i1) -> i1
    %ex4_cond_48 = "arith.andi"(%ex4_exact_on, %ex4_ok_48) : (i1, i1) -> i1
    %ex4_out_48 = "transfer.shl"(%ex4_lhs_v6, %ex4_rhs_v0) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %ex4_outn_48 = "transfer.xor"(%ex4_out_48, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %ex4_sel0_48 = "transfer.select"(%ex4_cond_48, %ex4_outn_48, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %ex4_sel1_48 = "transfer.select"(%ex4_cond_48, %ex4_out_48, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %ex4_acc0_49 = "transfer.and"(%ex4_acc0_48, %ex4_sel0_48) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %ex4_acc1_49 = "transfer.and"(%ex4_acc1_48, %ex4_sel1_48) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %ex4_any_49 = "arith.ori"(%ex4_any_48, %ex4_cond_48) : (i1, i1) -> i1
    %ex4_chk_49 = "transfer.cmp"(%ex4_rhs_v1, %bitwidth) {predicate = 9 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %ex4_clz_49 = "transfer.countl_zero"(%ex4_lhs_v6) : (!transfer.integer) -> !transfer.integer
    %ex4_nuw_49 = "transfer.cmp"(%ex4_clz_49, %ex4_rhs_v1) {predicate = 9 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %ex4_ok_49 = "arith.andi"(%ex4_chk_49, %ex4_nuw_49) : (i1, i1) -> i1
    %ex4_cond_49 = "arith.andi"(%ex4_exact_on, %ex4_ok_49) : (i1, i1) -> i1
    %ex4_out_49 = "transfer.shl"(%ex4_lhs_v6, %ex4_rhs_v1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %ex4_outn_49 = "transfer.xor"(%ex4_out_49, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %ex4_sel0_49 = "transfer.select"(%ex4_cond_49, %ex4_outn_49, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %ex4_sel1_49 = "transfer.select"(%ex4_cond_49, %ex4_out_49, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %ex4_acc0_50 = "transfer.and"(%ex4_acc0_49, %ex4_sel0_49) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %ex4_acc1_50 = "transfer.and"(%ex4_acc1_49, %ex4_sel1_49) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %ex4_any_50 = "arith.ori"(%ex4_any_49, %ex4_cond_49) : (i1, i1) -> i1
    %ex4_chk_50 = "transfer.cmp"(%ex4_rhs_v2, %bitwidth) {predicate = 9 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %ex4_clz_50 = "transfer.countl_zero"(%ex4_lhs_v6) : (!transfer.integer) -> !transfer.integer
    %ex4_nuw_50 = "transfer.cmp"(%ex4_clz_50, %ex4_rhs_v2) {predicate = 9 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %ex4_ok_50 = "arith.andi"(%ex4_chk_50, %ex4_nuw_50) : (i1, i1) -> i1
    %ex4_cond_50 = "arith.andi"(%ex4_exact_on, %ex4_ok_50) : (i1, i1) -> i1
    %ex4_out_50 = "transfer.shl"(%ex4_lhs_v6, %ex4_rhs_v2) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %ex4_outn_50 = "transfer.xor"(%ex4_out_50, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %ex4_sel0_50 = "transfer.select"(%ex4_cond_50, %ex4_outn_50, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %ex4_sel1_50 = "transfer.select"(%ex4_cond_50, %ex4_out_50, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %ex4_acc0_51 = "transfer.and"(%ex4_acc0_50, %ex4_sel0_50) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %ex4_acc1_51 = "transfer.and"(%ex4_acc1_50, %ex4_sel1_50) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %ex4_any_51 = "arith.ori"(%ex4_any_50, %ex4_cond_50) : (i1, i1) -> i1
    %ex4_chk_51 = "transfer.cmp"(%ex4_rhs_v3, %bitwidth) {predicate = 9 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %ex4_clz_51 = "transfer.countl_zero"(%ex4_lhs_v6) : (!transfer.integer) -> !transfer.integer
    %ex4_nuw_51 = "transfer.cmp"(%ex4_clz_51, %ex4_rhs_v3) {predicate = 9 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %ex4_ok_51 = "arith.andi"(%ex4_chk_51, %ex4_nuw_51) : (i1, i1) -> i1
    %ex4_cond_51 = "arith.andi"(%ex4_exact_on, %ex4_ok_51) : (i1, i1) -> i1
    %ex4_out_51 = "transfer.shl"(%ex4_lhs_v6, %ex4_rhs_v3) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %ex4_outn_51 = "transfer.xor"(%ex4_out_51, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %ex4_sel0_51 = "transfer.select"(%ex4_cond_51, %ex4_outn_51, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %ex4_sel1_51 = "transfer.select"(%ex4_cond_51, %ex4_out_51, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %ex4_acc0_52 = "transfer.and"(%ex4_acc0_51, %ex4_sel0_51) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %ex4_acc1_52 = "transfer.and"(%ex4_acc1_51, %ex4_sel1_51) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %ex4_any_52 = "arith.ori"(%ex4_any_51, %ex4_cond_51) : (i1, i1) -> i1
    %ex4_chk_52 = "transfer.cmp"(%ex4_rhs_v4, %bitwidth) {predicate = 9 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %ex4_clz_52 = "transfer.countl_zero"(%ex4_lhs_v6) : (!transfer.integer) -> !transfer.integer
    %ex4_nuw_52 = "transfer.cmp"(%ex4_clz_52, %ex4_rhs_v4) {predicate = 9 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %ex4_ok_52 = "arith.andi"(%ex4_chk_52, %ex4_nuw_52) : (i1, i1) -> i1
    %ex4_cond_52 = "arith.andi"(%ex4_exact_on, %ex4_ok_52) : (i1, i1) -> i1
    %ex4_out_52 = "transfer.shl"(%ex4_lhs_v6, %ex4_rhs_v4) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %ex4_outn_52 = "transfer.xor"(%ex4_out_52, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %ex4_sel0_52 = "transfer.select"(%ex4_cond_52, %ex4_outn_52, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %ex4_sel1_52 = "transfer.select"(%ex4_cond_52, %ex4_out_52, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %ex4_acc0_53 = "transfer.and"(%ex4_acc0_52, %ex4_sel0_52) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %ex4_acc1_53 = "transfer.and"(%ex4_acc1_52, %ex4_sel1_52) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %ex4_any_53 = "arith.ori"(%ex4_any_52, %ex4_cond_52) : (i1, i1) -> i1
    %ex4_chk_53 = "transfer.cmp"(%ex4_rhs_v5, %bitwidth) {predicate = 9 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %ex4_clz_53 = "transfer.countl_zero"(%ex4_lhs_v6) : (!transfer.integer) -> !transfer.integer
    %ex4_nuw_53 = "transfer.cmp"(%ex4_clz_53, %ex4_rhs_v5) {predicate = 9 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %ex4_ok_53 = "arith.andi"(%ex4_chk_53, %ex4_nuw_53) : (i1, i1) -> i1
    %ex4_cond_53 = "arith.andi"(%ex4_exact_on, %ex4_ok_53) : (i1, i1) -> i1
    %ex4_out_53 = "transfer.shl"(%ex4_lhs_v6, %ex4_rhs_v5) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %ex4_outn_53 = "transfer.xor"(%ex4_out_53, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %ex4_sel0_53 = "transfer.select"(%ex4_cond_53, %ex4_outn_53, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %ex4_sel1_53 = "transfer.select"(%ex4_cond_53, %ex4_out_53, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %ex4_acc0_54 = "transfer.and"(%ex4_acc0_53, %ex4_sel0_53) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %ex4_acc1_54 = "transfer.and"(%ex4_acc1_53, %ex4_sel1_53) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %ex4_any_54 = "arith.ori"(%ex4_any_53, %ex4_cond_53) : (i1, i1) -> i1
    %ex4_chk_54 = "transfer.cmp"(%ex4_rhs_v6, %bitwidth) {predicate = 9 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %ex4_clz_54 = "transfer.countl_zero"(%ex4_lhs_v6) : (!transfer.integer) -> !transfer.integer
    %ex4_nuw_54 = "transfer.cmp"(%ex4_clz_54, %ex4_rhs_v6) {predicate = 9 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %ex4_ok_54 = "arith.andi"(%ex4_chk_54, %ex4_nuw_54) : (i1, i1) -> i1
    %ex4_cond_54 = "arith.andi"(%ex4_exact_on, %ex4_ok_54) : (i1, i1) -> i1
    %ex4_out_54 = "transfer.shl"(%ex4_lhs_v6, %ex4_rhs_v6) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %ex4_outn_54 = "transfer.xor"(%ex4_out_54, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %ex4_sel0_54 = "transfer.select"(%ex4_cond_54, %ex4_outn_54, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %ex4_sel1_54 = "transfer.select"(%ex4_cond_54, %ex4_out_54, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %ex4_acc0_55 = "transfer.and"(%ex4_acc0_54, %ex4_sel0_54) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %ex4_acc1_55 = "transfer.and"(%ex4_acc1_54, %ex4_sel1_54) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %ex4_any_55 = "arith.ori"(%ex4_any_54, %ex4_cond_54) : (i1, i1) -> i1
    %ex4_chk_55 = "transfer.cmp"(%ex4_rhs_v7, %bitwidth) {predicate = 9 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %ex4_clz_55 = "transfer.countl_zero"(%ex4_lhs_v6) : (!transfer.integer) -> !transfer.integer
    %ex4_nuw_55 = "transfer.cmp"(%ex4_clz_55, %ex4_rhs_v7) {predicate = 9 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %ex4_ok_55 = "arith.andi"(%ex4_chk_55, %ex4_nuw_55) : (i1, i1) -> i1
    %ex4_cond_55 = "arith.andi"(%ex4_exact_on, %ex4_ok_55) : (i1, i1) -> i1
    %ex4_out_55 = "transfer.shl"(%ex4_lhs_v6, %ex4_rhs_v7) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %ex4_outn_55 = "transfer.xor"(%ex4_out_55, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %ex4_sel0_55 = "transfer.select"(%ex4_cond_55, %ex4_outn_55, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %ex4_sel1_55 = "transfer.select"(%ex4_cond_55, %ex4_out_55, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %ex4_acc0_56 = "transfer.and"(%ex4_acc0_55, %ex4_sel0_55) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %ex4_acc1_56 = "transfer.and"(%ex4_acc1_55, %ex4_sel1_55) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %ex4_any_56 = "arith.ori"(%ex4_any_55, %ex4_cond_55) : (i1, i1) -> i1
    %ex4_chk_56 = "transfer.cmp"(%ex4_rhs_v0, %bitwidth) {predicate = 9 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %ex4_clz_56 = "transfer.countl_zero"(%ex4_lhs_v7) : (!transfer.integer) -> !transfer.integer
    %ex4_nuw_56 = "transfer.cmp"(%ex4_clz_56, %ex4_rhs_v0) {predicate = 9 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %ex4_ok_56 = "arith.andi"(%ex4_chk_56, %ex4_nuw_56) : (i1, i1) -> i1
    %ex4_cond_56 = "arith.andi"(%ex4_exact_on, %ex4_ok_56) : (i1, i1) -> i1
    %ex4_out_56 = "transfer.shl"(%ex4_lhs_v7, %ex4_rhs_v0) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %ex4_outn_56 = "transfer.xor"(%ex4_out_56, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %ex4_sel0_56 = "transfer.select"(%ex4_cond_56, %ex4_outn_56, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %ex4_sel1_56 = "transfer.select"(%ex4_cond_56, %ex4_out_56, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %ex4_acc0_57 = "transfer.and"(%ex4_acc0_56, %ex4_sel0_56) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %ex4_acc1_57 = "transfer.and"(%ex4_acc1_56, %ex4_sel1_56) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %ex4_any_57 = "arith.ori"(%ex4_any_56, %ex4_cond_56) : (i1, i1) -> i1
    %ex4_chk_57 = "transfer.cmp"(%ex4_rhs_v1, %bitwidth) {predicate = 9 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %ex4_clz_57 = "transfer.countl_zero"(%ex4_lhs_v7) : (!transfer.integer) -> !transfer.integer
    %ex4_nuw_57 = "transfer.cmp"(%ex4_clz_57, %ex4_rhs_v1) {predicate = 9 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %ex4_ok_57 = "arith.andi"(%ex4_chk_57, %ex4_nuw_57) : (i1, i1) -> i1
    %ex4_cond_57 = "arith.andi"(%ex4_exact_on, %ex4_ok_57) : (i1, i1) -> i1
    %ex4_out_57 = "transfer.shl"(%ex4_lhs_v7, %ex4_rhs_v1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %ex4_outn_57 = "transfer.xor"(%ex4_out_57, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %ex4_sel0_57 = "transfer.select"(%ex4_cond_57, %ex4_outn_57, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %ex4_sel1_57 = "transfer.select"(%ex4_cond_57, %ex4_out_57, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %ex4_acc0_58 = "transfer.and"(%ex4_acc0_57, %ex4_sel0_57) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %ex4_acc1_58 = "transfer.and"(%ex4_acc1_57, %ex4_sel1_57) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %ex4_any_58 = "arith.ori"(%ex4_any_57, %ex4_cond_57) : (i1, i1) -> i1
    %ex4_chk_58 = "transfer.cmp"(%ex4_rhs_v2, %bitwidth) {predicate = 9 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %ex4_clz_58 = "transfer.countl_zero"(%ex4_lhs_v7) : (!transfer.integer) -> !transfer.integer
    %ex4_nuw_58 = "transfer.cmp"(%ex4_clz_58, %ex4_rhs_v2) {predicate = 9 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %ex4_ok_58 = "arith.andi"(%ex4_chk_58, %ex4_nuw_58) : (i1, i1) -> i1
    %ex4_cond_58 = "arith.andi"(%ex4_exact_on, %ex4_ok_58) : (i1, i1) -> i1
    %ex4_out_58 = "transfer.shl"(%ex4_lhs_v7, %ex4_rhs_v2) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %ex4_outn_58 = "transfer.xor"(%ex4_out_58, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %ex4_sel0_58 = "transfer.select"(%ex4_cond_58, %ex4_outn_58, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %ex4_sel1_58 = "transfer.select"(%ex4_cond_58, %ex4_out_58, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %ex4_acc0_59 = "transfer.and"(%ex4_acc0_58, %ex4_sel0_58) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %ex4_acc1_59 = "transfer.and"(%ex4_acc1_58, %ex4_sel1_58) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %ex4_any_59 = "arith.ori"(%ex4_any_58, %ex4_cond_58) : (i1, i1) -> i1
    %ex4_chk_59 = "transfer.cmp"(%ex4_rhs_v3, %bitwidth) {predicate = 9 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %ex4_clz_59 = "transfer.countl_zero"(%ex4_lhs_v7) : (!transfer.integer) -> !transfer.integer
    %ex4_nuw_59 = "transfer.cmp"(%ex4_clz_59, %ex4_rhs_v3) {predicate = 9 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %ex4_ok_59 = "arith.andi"(%ex4_chk_59, %ex4_nuw_59) : (i1, i1) -> i1
    %ex4_cond_59 = "arith.andi"(%ex4_exact_on, %ex4_ok_59) : (i1, i1) -> i1
    %ex4_out_59 = "transfer.shl"(%ex4_lhs_v7, %ex4_rhs_v3) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %ex4_outn_59 = "transfer.xor"(%ex4_out_59, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %ex4_sel0_59 = "transfer.select"(%ex4_cond_59, %ex4_outn_59, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %ex4_sel1_59 = "transfer.select"(%ex4_cond_59, %ex4_out_59, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %ex4_acc0_60 = "transfer.and"(%ex4_acc0_59, %ex4_sel0_59) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %ex4_acc1_60 = "transfer.and"(%ex4_acc1_59, %ex4_sel1_59) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %ex4_any_60 = "arith.ori"(%ex4_any_59, %ex4_cond_59) : (i1, i1) -> i1
    %ex4_chk_60 = "transfer.cmp"(%ex4_rhs_v4, %bitwidth) {predicate = 9 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %ex4_clz_60 = "transfer.countl_zero"(%ex4_lhs_v7) : (!transfer.integer) -> !transfer.integer
    %ex4_nuw_60 = "transfer.cmp"(%ex4_clz_60, %ex4_rhs_v4) {predicate = 9 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %ex4_ok_60 = "arith.andi"(%ex4_chk_60, %ex4_nuw_60) : (i1, i1) -> i1
    %ex4_cond_60 = "arith.andi"(%ex4_exact_on, %ex4_ok_60) : (i1, i1) -> i1
    %ex4_out_60 = "transfer.shl"(%ex4_lhs_v7, %ex4_rhs_v4) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %ex4_outn_60 = "transfer.xor"(%ex4_out_60, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %ex4_sel0_60 = "transfer.select"(%ex4_cond_60, %ex4_outn_60, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %ex4_sel1_60 = "transfer.select"(%ex4_cond_60, %ex4_out_60, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %ex4_acc0_61 = "transfer.and"(%ex4_acc0_60, %ex4_sel0_60) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %ex4_acc1_61 = "transfer.and"(%ex4_acc1_60, %ex4_sel1_60) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %ex4_any_61 = "arith.ori"(%ex4_any_60, %ex4_cond_60) : (i1, i1) -> i1
    %ex4_chk_61 = "transfer.cmp"(%ex4_rhs_v5, %bitwidth) {predicate = 9 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %ex4_clz_61 = "transfer.countl_zero"(%ex4_lhs_v7) : (!transfer.integer) -> !transfer.integer
    %ex4_nuw_61 = "transfer.cmp"(%ex4_clz_61, %ex4_rhs_v5) {predicate = 9 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %ex4_ok_61 = "arith.andi"(%ex4_chk_61, %ex4_nuw_61) : (i1, i1) -> i1
    %ex4_cond_61 = "arith.andi"(%ex4_exact_on, %ex4_ok_61) : (i1, i1) -> i1
    %ex4_out_61 = "transfer.shl"(%ex4_lhs_v7, %ex4_rhs_v5) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %ex4_outn_61 = "transfer.xor"(%ex4_out_61, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %ex4_sel0_61 = "transfer.select"(%ex4_cond_61, %ex4_outn_61, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %ex4_sel1_61 = "transfer.select"(%ex4_cond_61, %ex4_out_61, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %ex4_acc0_62 = "transfer.and"(%ex4_acc0_61, %ex4_sel0_61) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %ex4_acc1_62 = "transfer.and"(%ex4_acc1_61, %ex4_sel1_61) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %ex4_any_62 = "arith.ori"(%ex4_any_61, %ex4_cond_61) : (i1, i1) -> i1
    %ex4_chk_62 = "transfer.cmp"(%ex4_rhs_v6, %bitwidth) {predicate = 9 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %ex4_clz_62 = "transfer.countl_zero"(%ex4_lhs_v7) : (!transfer.integer) -> !transfer.integer
    %ex4_nuw_62 = "transfer.cmp"(%ex4_clz_62, %ex4_rhs_v6) {predicate = 9 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %ex4_ok_62 = "arith.andi"(%ex4_chk_62, %ex4_nuw_62) : (i1, i1) -> i1
    %ex4_cond_62 = "arith.andi"(%ex4_exact_on, %ex4_ok_62) : (i1, i1) -> i1
    %ex4_out_62 = "transfer.shl"(%ex4_lhs_v7, %ex4_rhs_v6) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %ex4_outn_62 = "transfer.xor"(%ex4_out_62, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %ex4_sel0_62 = "transfer.select"(%ex4_cond_62, %ex4_outn_62, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %ex4_sel1_62 = "transfer.select"(%ex4_cond_62, %ex4_out_62, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %ex4_acc0_63 = "transfer.and"(%ex4_acc0_62, %ex4_sel0_62) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %ex4_acc1_63 = "transfer.and"(%ex4_acc1_62, %ex4_sel1_62) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %ex4_any_63 = "arith.ori"(%ex4_any_62, %ex4_cond_62) : (i1, i1) -> i1
    %ex4_chk_63 = "transfer.cmp"(%ex4_rhs_v7, %bitwidth) {predicate = 9 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %ex4_clz_63 = "transfer.countl_zero"(%ex4_lhs_v7) : (!transfer.integer) -> !transfer.integer
    %ex4_nuw_63 = "transfer.cmp"(%ex4_clz_63, %ex4_rhs_v7) {predicate = 9 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %ex4_ok_63 = "arith.andi"(%ex4_chk_63, %ex4_nuw_63) : (i1, i1) -> i1
    %ex4_cond_63 = "arith.andi"(%ex4_exact_on, %ex4_ok_63) : (i1, i1) -> i1
    %ex4_out_63 = "transfer.shl"(%ex4_lhs_v7, %ex4_rhs_v7) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %ex4_outn_63 = "transfer.xor"(%ex4_out_63, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %ex4_sel0_63 = "transfer.select"(%ex4_cond_63, %ex4_outn_63, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %ex4_sel1_63 = "transfer.select"(%ex4_cond_63, %ex4_out_63, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %ex4_acc0_64 = "transfer.and"(%ex4_acc0_63, %ex4_sel0_63) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %ex4_acc1_64 = "transfer.and"(%ex4_acc1_63, %ex4_sel1_63) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %ex4_any_64 = "arith.ori"(%ex4_any_63, %ex4_cond_63) : (i1, i1) -> i1
    %ex4_res0 = "transfer.select"(%ex4_any_64, %ex4_acc0_64, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %ex4_res1 = "transfer.select"(%ex4_any_64, %ex4_acc1_64, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %res0_exact_final = "transfer.select"(%ex4_exact_on, %ex4_res0, %res0_exact) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %res1_exact_final = "transfer.select"(%ex4_exact_on, %ex4_res1, %res1_exact) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %has_feasible_pair_final = "transfer.select"(%ex4_exact_on, %ex4_any_64, %has_feasible_pair) : (i1, i1, i1) -> i1

    %res0_final = "transfer.select"(%has_feasible_pair_final, %res0_exact_final, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %res1_final = "transfer.select"(%has_feasible_pair_final, %res1_exact_final, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer

    %r = "transfer.make"(%res0_final, %res1_final) : (!transfer.integer, !transfer.integer) -> !transfer.abs_value<[!transfer.integer, !transfer.integer]>
    "func.return"(%r) : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> ()
}) {"sym_name" = "kb_shlnuw", "function_type" = (!transfer.abs_value<[!transfer.integer, !transfer.integer]>, !transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.abs_value<[!transfer.integer, !transfer.integer]>} : () -> ()
