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
    %bitwidth = "transfer.get_bit_width"(%lhs0) : (!transfer.integer) -> !transfer.integer

    %lhs_conflict = "transfer.and"(%lhs0, %lhs1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %rhs_conflict = "transfer.and"(%rhs0, %rhs1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %lhs_consistent = "transfer.cmp"(%lhs_conflict, %const0) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %rhs_consistent = "transfer.cmp"(%rhs_conflict, %const0) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %rhs_min_le_bw = "transfer.cmp"(%rhs1, %bitwidth) {predicate = 7 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %rhs_max = "transfer.xor"(%rhs0, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %rhs1_lt_bw = "transfer.cmp"(%rhs1, %bitwidth) {predicate = 6 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %rhs_max_lt_bw = "transfer.cmp"(%rhs_max, %bitwidth) {predicate = 6 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %inputs_consistent = "arith.andi"(%lhs_consistent, %rhs_consistent) : (i1, i1) -> i1
    %has_feasible_pair = "arith.andi"(%inputs_consistent, %rhs_min_le_bw) : (i1, i1) -> i1

    %const_shift_res0 = "transfer.shl"(%lhs0, %rhs1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %const_res1 = "transfer.shl"(%lhs1, %rhs1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %const_intro_mask = "transfer.shl"(%all_ones, %rhs1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %const_intro_zero = "transfer.xor"(%const_intro_mask, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %const_intro = "transfer.select"(%rhs1_lt_bw, %const_intro_zero, %const0) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %const_res0 = "transfer.or"(%const_shift_res0, %const_intro) : (!transfer.integer, !transfer.integer) -> !transfer.integer

    %rhs1_not = "transfer.xor"(%rhs1, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %rhs_is_const = "transfer.cmp"(%rhs0, %rhs1_not) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1

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
    %rhs_val0_le_bw = "transfer.cmp"(%rhs1, %bitwidth) {predicate = 7 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %rhs_feas0 = "arith.andi"(%rhs_one_unknown, %rhs_val0_le_bw) : (i1, i1) -> i1
    %rhs_feas1 = "arith.andi"(%rhs_one_unknown, %rhs_alt_le_bw) : (i1, i1) -> i1
    %rhs_any_feas = "arith.ori"(%rhs_feas0, %rhs_feas1) : (i1, i1) -> i1

    %alt_shift_res0 = "transfer.shl"(%lhs0, %rhs_alt) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %alt_res1 = "transfer.shl"(%lhs1, %rhs_alt) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %alt_intro_mask = "transfer.shl"(%all_ones, %rhs_alt) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %alt_intro_zero = "transfer.xor"(%alt_intro_mask, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %alt_intro = "transfer.select"(%rhs_alt_lt_bw, %alt_intro_zero, %const0) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %alt_res0 = "transfer.or"(%alt_shift_res0, %alt_intro) : (!transfer.integer, !transfer.integer) -> !transfer.integer

    %two_sel0_0 = "transfer.select"(%rhs_feas0, %const_res0, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %two_sel0_1 = "transfer.select"(%rhs_feas1, %alt_res0, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %two_acc0 = "transfer.and"(%two_sel0_0, %two_sel0_1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %two_case_res0 = "transfer.select"(%rhs_any_feas, %two_acc0, %const0) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer

    %two_sel1_0 = "transfer.select"(%rhs_feas0, %const_res1, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %two_sel1_1 = "transfer.select"(%rhs_feas1, %alt_res1, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %two_acc1 = "transfer.and"(%two_sel1_0, %two_sel1_1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %two_case_res1 = "transfer.select"(%rhs_any_feas, %two_acc1, %const0) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer

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
    %rhs_u2_feas0 = "arith.andi"(%rhs_two_unknown, %rhs_u2_v0_le_bw) : (i1, i1) -> i1
    %rhs_u2_feas1 = "arith.andi"(%rhs_two_unknown, %rhs_u2_v1_le_bw) : (i1, i1) -> i1
    %rhs_u2_feas2 = "arith.andi"(%rhs_two_unknown, %rhs_u2_v2_le_bw) : (i1, i1) -> i1
    %rhs_u2_feas3 = "arith.andi"(%rhs_two_unknown, %rhs_u2_v3_le_bw) : (i1, i1) -> i1
    %rhs_u2_any01 = "arith.ori"(%rhs_u2_feas0, %rhs_u2_feas1) : (i1, i1) -> i1
    %rhs_u2_any23 = "arith.ori"(%rhs_u2_feas2, %rhs_u2_feas3) : (i1, i1) -> i1
    %rhs_u2_any = "arith.ori"(%rhs_u2_any01, %rhs_u2_any23) : (i1, i1) -> i1

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
    %rhs_u2_sel0_0 = "transfer.select"(%rhs_u2_feas0, %const_res0, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %rhs_u2_sel0_1 = "transfer.select"(%rhs_u2_feas1, %rhs_u2_res0_1, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %rhs_u2_sel0_2 = "transfer.select"(%rhs_u2_feas2, %rhs_u2_res0_2, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %rhs_u2_sel0_3 = "transfer.select"(%rhs_u2_feas3, %rhs_u2_res0_3, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %rhs_u2_acc0_01 = "transfer.and"(%rhs_u2_sel0_0, %rhs_u2_sel0_1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %rhs_u2_acc0_23 = "transfer.and"(%rhs_u2_sel0_2, %rhs_u2_sel0_3) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %rhs_u2_acc0 = "transfer.and"(%rhs_u2_acc0_01, %rhs_u2_acc0_23) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %rhs_u2_case_res0 = "transfer.select"(%rhs_u2_any, %rhs_u2_acc0, %const0) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer

    %rhs_u2_res1_1 = "transfer.shl"(%lhs1, %rhs_u2_val1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %rhs_u2_res1_2 = "transfer.shl"(%lhs1, %rhs_u2_val2) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %rhs_u2_res1_3 = "transfer.shl"(%lhs1, %rhs_u2_val3) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %rhs_u2_sel1_0 = "transfer.select"(%rhs_u2_feas0, %const_res1, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %rhs_u2_sel1_1 = "transfer.select"(%rhs_u2_feas1, %rhs_u2_res1_1, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %rhs_u2_sel1_2 = "transfer.select"(%rhs_u2_feas2, %rhs_u2_res1_2, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %rhs_u2_sel1_3 = "transfer.select"(%rhs_u2_feas3, %rhs_u2_res1_3, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %rhs_u2_acc1_01 = "transfer.and"(%rhs_u2_sel1_0, %rhs_u2_sel1_1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %rhs_u2_acc1_23 = "transfer.and"(%rhs_u2_sel1_2, %rhs_u2_sel1_3) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %rhs_u2_acc1 = "transfer.and"(%rhs_u2_acc1_01, %rhs_u2_acc1_23) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %rhs_u2_case_res1 = "transfer.select"(%rhs_u2_any, %rhs_u2_acc1, %const0) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer

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

    %rhs_u3_feas0 = "arith.andi"(%rhs_three_unknown, %rhs_u3_v0_le_bw) : (i1, i1) -> i1
    %rhs_u3_feas1 = "arith.andi"(%rhs_three_unknown, %rhs_u3_v1_le_bw) : (i1, i1) -> i1
    %rhs_u3_feas2 = "arith.andi"(%rhs_three_unknown, %rhs_u3_v2_le_bw) : (i1, i1) -> i1
    %rhs_u3_feas3 = "arith.andi"(%rhs_three_unknown, %rhs_u3_v3_le_bw) : (i1, i1) -> i1
    %rhs_u3_feas4 = "arith.andi"(%rhs_three_unknown, %rhs_u3_v4_le_bw) : (i1, i1) -> i1
    %rhs_u3_feas5 = "arith.andi"(%rhs_three_unknown, %rhs_u3_v5_le_bw) : (i1, i1) -> i1
    %rhs_u3_feas6 = "arith.andi"(%rhs_three_unknown, %rhs_u3_v6_le_bw) : (i1, i1) -> i1
    %rhs_u3_feas7 = "arith.andi"(%rhs_three_unknown, %rhs_u3_v7_le_bw) : (i1, i1) -> i1

    %rhs_u3_any01 = "arith.ori"(%rhs_u3_feas0, %rhs_u3_feas1) : (i1, i1) -> i1
    %rhs_u3_any23 = "arith.ori"(%rhs_u3_feas2, %rhs_u3_feas3) : (i1, i1) -> i1
    %rhs_u3_any45 = "arith.ori"(%rhs_u3_feas4, %rhs_u3_feas5) : (i1, i1) -> i1
    %rhs_u3_any67 = "arith.ori"(%rhs_u3_feas6, %rhs_u3_feas7) : (i1, i1) -> i1
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

    %rhs_u3_sel0_0 = "transfer.select"(%rhs_u3_feas0, %const_res0, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %rhs_u3_sel0_1 = "transfer.select"(%rhs_u3_feas1, %rhs_u3_res0_1, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %rhs_u3_sel0_2 = "transfer.select"(%rhs_u3_feas2, %rhs_u3_res0_2, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %rhs_u3_sel0_3 = "transfer.select"(%rhs_u3_feas3, %rhs_u3_res0_3, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %rhs_u3_sel0_4 = "transfer.select"(%rhs_u3_feas4, %rhs_u3_res0_4, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %rhs_u3_sel0_5 = "transfer.select"(%rhs_u3_feas5, %rhs_u3_res0_5, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %rhs_u3_sel0_6 = "transfer.select"(%rhs_u3_feas6, %rhs_u3_res0_6, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %rhs_u3_sel0_7 = "transfer.select"(%rhs_u3_feas7, %rhs_u3_res0_7, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer

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

    %rhs_u3_sel1_0 = "transfer.select"(%rhs_u3_feas0, %const_res1, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %rhs_u3_sel1_1 = "transfer.select"(%rhs_u3_feas1, %rhs_u3_res1_1, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %rhs_u3_sel1_2 = "transfer.select"(%rhs_u3_feas2, %rhs_u3_res1_2, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %rhs_u3_sel1_3 = "transfer.select"(%rhs_u3_feas3, %rhs_u3_res1_3, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %rhs_u3_sel1_4 = "transfer.select"(%rhs_u3_feas4, %rhs_u3_res1_4, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %rhs_u3_sel1_5 = "transfer.select"(%rhs_u3_feas5, %rhs_u3_res1_5, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %rhs_u3_sel1_6 = "transfer.select"(%rhs_u3_feas6, %rhs_u3_res1_6, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %rhs_u3_sel1_7 = "transfer.select"(%rhs_u3_feas7, %rhs_u3_res1_7, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer

    %rhs_u3_acc1_01 = "transfer.and"(%rhs_u3_sel1_0, %rhs_u3_sel1_1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %rhs_u3_acc1_23 = "transfer.and"(%rhs_u3_sel1_2, %rhs_u3_sel1_3) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %rhs_u3_acc1_45 = "transfer.and"(%rhs_u3_sel1_4, %rhs_u3_sel1_5) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %rhs_u3_acc1_67 = "transfer.and"(%rhs_u3_sel1_6, %rhs_u3_sel1_7) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %rhs_u3_acc1_0123 = "transfer.and"(%rhs_u3_acc1_01, %rhs_u3_acc1_23) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %rhs_u3_acc1_4567 = "transfer.and"(%rhs_u3_acc1_45, %rhs_u3_acc1_67) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %rhs_u3_acc1 = "transfer.and"(%rhs_u3_acc1_0123, %rhs_u3_acc1_4567) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %rhs_u3_case_res1 = "transfer.select"(%rhs_u3_any, %rhs_u3_acc1, %const0) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer

    %var_base_intro = "transfer.select"(%rhs_max_lt_bw, %const_intro_zero, %const0) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %var_res0 = "transfer.add"(%var_base_intro, %const0) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %var_res1 = "transfer.add"(%const0, %const0) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %var_res0_dyn1 = "transfer.select"(%rhs_one_unknown, %two_case_res0, %var_res0) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %var_res1_dyn1 = "transfer.select"(%rhs_one_unknown, %two_case_res1, %var_res1) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %var_res0_dyn2 = "transfer.select"(%rhs_two_unknown, %rhs_u2_case_res0, %var_res0_dyn1) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %var_res1_dyn2 = "transfer.select"(%rhs_two_unknown, %rhs_u2_case_res1, %var_res1_dyn1) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %var_res0_dyn = "transfer.select"(%rhs_three_unknown, %rhs_u3_case_res0, %var_res0_dyn2) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %var_res1_dyn = "transfer.select"(%rhs_three_unknown, %rhs_u3_case_res1, %var_res1_dyn2) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer

    %res0_const_sel = "transfer.select"(%rhs_is_const, %const_res0, %var_res0_dyn) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %res1_const_sel = "transfer.select"(%rhs_is_const, %const_res1, %var_res1_dyn) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer

    %lhs0_all_ones = "transfer.cmp"(%lhs0, %all_ones) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %lhs1_is_zero = "transfer.cmp"(%lhs1, %const0) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %lhs_is_zero = "arith.andi"(%lhs0_all_ones, %lhs1_is_zero) : (i1, i1) -> i1
    %res0 = "transfer.select"(%lhs_is_zero, %all_ones, %res0_const_sel) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %res1 = "transfer.select"(%lhs_is_zero, %const0, %res1_const_sel) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer

    %res0_final = "transfer.select"(%has_feasible_pair, %res0, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %res1_final = "transfer.select"(%has_feasible_pair, %res1, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer

    %r = "transfer.make"(%res0_final, %res1_final) : (!transfer.integer, !transfer.integer) -> !transfer.abs_value<[!transfer.integer, !transfer.integer]>
    "func.return"(%r) : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> ()
}) {"sym_name" = "kb_shl", "function_type" = (!transfer.abs_value<[!transfer.integer, !transfer.integer]>, !transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.abs_value<[!transfer.integer, !transfer.integer]>} : () -> ()
