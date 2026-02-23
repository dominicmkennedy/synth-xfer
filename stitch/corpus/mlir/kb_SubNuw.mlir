"func.func"() ({
  ^0(%lhs : !transfer.abs_value<[!transfer.integer, !transfer.integer]>, %rhs : !transfer.abs_value<[!transfer.integer, !transfer.integer]>):
    %lhs0 = "transfer.get"(%lhs) {index = 0} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %lhs1 = "transfer.get"(%lhs) {index = 1} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %rhs0 = "transfer.get"(%rhs) {index = 0} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %rhs1 = "transfer.get"(%rhs) {index = 1} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer

    %all_ones = "transfer.get_all_ones"(%lhs0) : (!transfer.integer) -> !transfer.integer
    %const0 = "transfer.constant"(%lhs0) {value = 0 : index} : (!transfer.integer) -> !transfer.integer
    %const1 = "transfer.constant"(%lhs0) {value = 1 : index} : (!transfer.integer) -> !transfer.integer
    %const2 = "transfer.shl"(%const1, %const1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %const4 = "transfer.shl"(%const2, %const1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %const8 = "transfer.shl"(%const4, %const1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %const16 = "transfer.shl"(%const8, %const1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %const32 = "transfer.shl"(%const16, %const1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %const64 = "transfer.shl"(%const32, %const1) : (!transfer.integer, !transfer.integer) -> !transfer.integer

    %lhs_conflict = "transfer.and"(%lhs0, %lhs1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %rhs_conflict = "transfer.and"(%rhs0, %rhs1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %any_conflict = "transfer.or"(%lhs_conflict, %rhs_conflict) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %consistent = "transfer.cmp"(%any_conflict, %const0) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1

    %lhs_max = "transfer.xor"(%lhs0, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %rhs_max = "transfer.xor"(%rhs0, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %always_underflow = "transfer.cmp"(%lhs_max, %rhs1) {predicate = 6 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %never_underflow = "transfer.cmp"(%lhs1, %rhs_max) {predicate = 9 : i64} : (!transfer.integer, !transfer.integer) -> i1

    %rhs_min_le_lhs_max = "transfer.cmp"(%rhs1, %lhs_max) {predicate = 7 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %ub_non_raw = "transfer.sub"(%lhs_max, %rhs1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %ub_non = "transfer.select"(%rhs_min_le_lhs_max, %ub_non_raw, %const0) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %ub = "transfer.select"(%always_underflow, %const0, %ub_non) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %lb_raw = "transfer.sub"(%lhs1, %rhs_max) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %lb = "transfer.select"(%never_underflow, %lb_raw, %const0) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer

    %diff = "transfer.xor"(%lb, %ub) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %common_lz = "transfer.countl_zero"(%diff) : (!transfer.integer) -> !transfer.integer
    %bitwidth = "transfer.get_bit_width"(%lhs0) : (!transfer.integer) -> !transfer.integer
    %common_inv = "transfer.sub"(%bitwidth, %common_lz) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %common_mask = "transfer.shl"(%all_ones, %common_inv) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %lb_not = "transfer.xor"(%lb, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %range0 = "transfer.and"(%lb_not, %common_mask) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %range1 = "transfer.and"(%lb, %common_mask) : (!transfer.integer, !transfer.integer) -> !transfer.integer

    %lhs1_not = "transfer.xor"(%lhs1, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %lhs_is_const = "transfer.cmp"(%lhs0, %lhs1_not) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %rhs1_not = "transfer.xor"(%rhs1, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %rhs_is_const = "transfer.cmp"(%rhs0, %rhs1_not) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %both_const = "arith.andi"(%lhs_is_const, %rhs_is_const) : (i1, i1) -> i1
    %lhs0_all_ones = "transfer.cmp"(%lhs0, %all_ones) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %lhs1_is_zero = "transfer.cmp"(%lhs1, %const0) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %lhs_is_zero = "arith.andi"(%lhs0_all_ones, %lhs1_is_zero) : (i1, i1) -> i1
    %rhs0_all_ones = "transfer.cmp"(%rhs0, %all_ones) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %rhs1_is_zero = "transfer.cmp"(%rhs1, %const0) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %rhs_is_zero = "arith.andi"(%rhs0_all_ones, %rhs1_is_zero) : (i1, i1) -> i1

    %const_underflow = "transfer.cmp"(%lhs1, %rhs1) {predicate = 6 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %const_sub = "transfer.sub"(%lhs1, %rhs1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %const_res1 = "transfer.select"(%const_underflow, %const0, %const_sub) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %const_res0 = "transfer.xor"(%const_res1, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer

    %res0_uf = "transfer.select"(%always_underflow, %all_ones, %range0) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %res1_uf = "transfer.select"(%always_underflow, %const0, %range1) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %res0_lhs0 = "transfer.select"(%lhs_is_zero, %all_ones, %res0_uf) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %res1_lhs0 = "transfer.select"(%lhs_is_zero, %const0, %res1_uf) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %res0_rhs0 = "transfer.select"(%rhs_is_zero, %lhs0, %res0_lhs0) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %res1_rhs0 = "transfer.select"(%rhs_is_zero, %lhs1, %res1_lhs0) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %res0 = "transfer.select"(%both_const, %const_res0, %res0_rhs0) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %res1 = "transfer.select"(%both_const, %const_res1, %res1_rhs0) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer

    // Compute lhs-rhs (mod 2^bw) known bits using (~rhs + 1) and add-style carry reasoning.
    %const1_not = "transfer.xor"(%const1, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %neg_rhs_a_max = "transfer.xor"(%rhs1, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %neg_rhs_b_max = "transfer.xor"(%const1_not, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %neg_rhs_sum_min = "transfer.add"(%rhs0, %const1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %neg_rhs_sum_max = "transfer.add"(%neg_rhs_a_max, %neg_rhs_b_max) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %neg_rhs_min_and = "transfer.and"(%rhs0, %const1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %neg_rhs_min_or = "transfer.or"(%rhs0, %const1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %neg_rhs_sum_min_not = "transfer.xor"(%neg_rhs_sum_min, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %neg_rhs_min_or_and_sum_not = "transfer.and"(%neg_rhs_min_or, %neg_rhs_sum_min_not) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %neg_rhs_carry_out_min = "transfer.or"(%neg_rhs_min_and, %neg_rhs_min_or_and_sum_not) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %neg_rhs_max_and = "transfer.and"(%neg_rhs_a_max, %neg_rhs_b_max) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %neg_rhs_max_or = "transfer.or"(%neg_rhs_a_max, %neg_rhs_b_max) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %neg_rhs_sum_max_not = "transfer.xor"(%neg_rhs_sum_max, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %neg_rhs_max_or_and_sum_not = "transfer.and"(%neg_rhs_max_or, %neg_rhs_sum_max_not) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %neg_rhs_carry_out_max = "transfer.or"(%neg_rhs_max_and, %neg_rhs_max_or_and_sum_not) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %neg_rhs_carry_one = "transfer.shl"(%neg_rhs_carry_out_min, %const1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %neg_rhs_carry_may_one = "transfer.shl"(%neg_rhs_carry_out_max, %const1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %neg_rhs_carry_zero = "transfer.xor"(%neg_rhs_carry_may_one, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %neg_rhs_xor0_ab_00 = "transfer.and"(%rhs1, %const1_not) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %neg_rhs_xor0_ab_11 = "transfer.and"(%rhs0, %const1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %neg_rhs_xor1_ab_01 = "transfer.and"(%rhs1, %const1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %neg_rhs_xor1_ab_10 = "transfer.and"(%rhs0, %const1_not) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %neg_rhs_xor_ab_0 = "transfer.or"(%neg_rhs_xor0_ab_00, %neg_rhs_xor0_ab_11) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %neg_rhs_xor_ab_1 = "transfer.or"(%neg_rhs_xor1_ab_01, %neg_rhs_xor1_ab_10) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %neg_rhs_xor0_sum_carry_00 = "transfer.and"(%neg_rhs_xor_ab_0, %neg_rhs_carry_zero) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %neg_rhs_xor0_sum_carry_11 = "transfer.and"(%neg_rhs_xor_ab_1, %neg_rhs_carry_one) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %neg_rhs_xor1_sum_carry_01 = "transfer.and"(%neg_rhs_xor_ab_0, %neg_rhs_carry_one) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %neg_rhs_xor1_sum_carry_10 = "transfer.and"(%neg_rhs_xor_ab_1, %neg_rhs_carry_zero) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %rhs_neg0 = "transfer.or"(%neg_rhs_xor0_sum_carry_00, %neg_rhs_xor0_sum_carry_11) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %rhs_neg1 = "transfer.or"(%neg_rhs_xor1_sum_carry_01, %neg_rhs_xor1_sum_carry_10) : (!transfer.integer, !transfer.integer) -> !transfer.integer

    %sub_a_max = "transfer.xor"(%lhs0, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %sub_b_max = "transfer.xor"(%rhs_neg0, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %sub_sum_min = "transfer.add"(%lhs1, %rhs_neg1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %sub_sum_max = "transfer.add"(%sub_a_max, %sub_b_max) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %sub_min_and = "transfer.and"(%lhs1, %rhs_neg1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %sub_min_or = "transfer.or"(%lhs1, %rhs_neg1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %sub_sum_min_not = "transfer.xor"(%sub_sum_min, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %sub_min_or_and_sum_not = "transfer.and"(%sub_min_or, %sub_sum_min_not) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %sub_carry_out_min = "transfer.or"(%sub_min_and, %sub_min_or_and_sum_not) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %sub_max_and = "transfer.and"(%sub_a_max, %sub_b_max) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %sub_max_or = "transfer.or"(%sub_a_max, %sub_b_max) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %sub_sum_max_not = "transfer.xor"(%sub_sum_max, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %sub_max_or_and_sum_not = "transfer.and"(%sub_max_or, %sub_sum_max_not) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %sub_carry_out_max = "transfer.or"(%sub_max_and, %sub_max_or_and_sum_not) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %sub_carry_one = "transfer.shl"(%sub_carry_out_min, %const1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %sub_carry_may_one = "transfer.shl"(%sub_carry_out_max, %const1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %sub_carry_zero = "transfer.xor"(%sub_carry_may_one, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %sub_xor0_ab_00 = "transfer.and"(%lhs0, %rhs_neg0) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %sub_xor0_ab_11 = "transfer.and"(%lhs1, %rhs_neg1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %sub_xor1_ab_01 = "transfer.and"(%lhs0, %rhs_neg1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %sub_xor1_ab_10 = "transfer.and"(%lhs1, %rhs_neg0) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %sub_xor_ab_0 = "transfer.or"(%sub_xor0_ab_00, %sub_xor0_ab_11) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %sub_xor_ab_1 = "transfer.or"(%sub_xor1_ab_01, %sub_xor1_ab_10) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %sub_xor0_sum_carry_00 = "transfer.and"(%sub_xor_ab_0, %sub_carry_zero) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %sub_xor0_sum_carry_11 = "transfer.and"(%sub_xor_ab_1, %sub_carry_one) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %sub_xor1_sum_carry_01 = "transfer.and"(%sub_xor_ab_0, %sub_carry_one) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %sub_xor1_sum_carry_10 = "transfer.and"(%sub_xor_ab_1, %sub_carry_zero) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %sub_lr0 = "transfer.or"(%sub_xor0_sum_carry_00, %sub_xor0_sum_carry_11) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %sub_lr1 = "transfer.or"(%sub_xor1_sum_carry_01, %sub_xor1_sum_carry_10) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %sub_lr1_nouf = "transfer.select"(%consistent, %sub_lr1, %const0) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %res0_sub = "transfer.or"(%res0, %sub_lr0) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %res1_sub = "transfer.or"(%res1, %sub_lr1_nouf) : (!transfer.integer, !transfer.integer) -> !transfer.integer

    // Equal low bits imply trailing zeros in lhs-rhs; parity gives the exact low bit.
    %eq_low_known0 = "transfer.and"(%lhs0, %rhs0) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %eq_low_known1 = "transfer.and"(%lhs1, %rhs1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %eq_low_known = "transfer.or"(%eq_low_known0, %eq_low_known1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %eq_low_count = "transfer.countr_one"(%eq_low_known) : (!transfer.integer) -> !transfer.integer
    %eq_low_inv = "transfer.sub"(%bitwidth, %eq_low_count) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %eq_low_mask = "transfer.lshr"(%all_ones, %eq_low_inv) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %res0_eq = "transfer.or"(%res0_sub, %eq_low_mask) : (!transfer.integer, !transfer.integer) -> !transfer.integer

    %lhs_lsb0 = "transfer.and"(%lhs0, %const1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %lhs_lsb1 = "transfer.and"(%lhs1, %const1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %rhs_lsb0 = "transfer.and"(%rhs0, %const1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %rhs_lsb1 = "transfer.and"(%rhs1, %const1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %lsb_zero00 = "transfer.and"(%lhs_lsb0, %rhs_lsb0) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %lsb_zero11 = "transfer.and"(%lhs_lsb1, %rhs_lsb1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %lsb_one01 = "transfer.and"(%lhs_lsb0, %rhs_lsb1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %lsb_one10 = "transfer.and"(%lhs_lsb1, %rhs_lsb0) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %lsb_zero = "transfer.or"(%lsb_zero00, %lsb_zero11) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %lsb_one = "transfer.or"(%lsb_one01, %lsb_one10) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %lsb_one_nouf = "transfer.select"(%consistent, %lsb_one, %const0) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %res0_lsb = "transfer.or"(%res0_eq, %lsb_zero) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %res1_lsb = "transfer.or"(%res1_sub, %lsb_one_nouf) : (!transfer.integer, !transfer.integer) -> !transfer.integer

    // Low known input bits give exact low bits of lhs-rhs (mod 2^k).
    %lhs_known_mask = "transfer.or"(%lhs0, %lhs1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %rhs_known_mask = "transfer.or"(%rhs0, %rhs1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %lhs_low_known = "transfer.countr_one"(%lhs_known_mask) : (!transfer.integer) -> !transfer.integer
    %rhs_low_known = "transfer.countr_one"(%rhs_known_mask) : (!transfer.integer) -> !transfer.integer
    %low_known = "transfer.umin"(%lhs_low_known, %rhs_low_known) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %low_inv = "transfer.sub"(%bitwidth, %low_known) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %low_mask = "transfer.lshr"(%all_ones, %low_inv) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %lhs_low = "transfer.and"(%lhs1, %low_mask) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %rhs_low = "transfer.and"(%rhs1, %low_mask) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %low_sub = "transfer.sub"(%lhs_low, %rhs_low) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %low_sub_masked = "transfer.and"(%low_sub, %low_mask) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %low_sub_not = "transfer.xor"(%low_sub_masked, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %low0 = "transfer.and"(%low_sub_not, %low_mask) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %low1 = "transfer.select"(%consistent, %low_sub_masked, %const0) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %res0_refined = "transfer.or"(%res0_lsb, %low0) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %res1_refined = "transfer.or"(%res1_lsb, %low1) : (!transfer.integer, !transfer.integer) -> !transfer.integer

    // Borrow-aware low-bit refinement for bits 1..3.
    %lhs0_b0_z = "transfer.and"(%lhs0, %const1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %lhs0_b0_o = "transfer.and"(%lhs1, %const1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %rhs0_b0_z = "transfer.and"(%rhs0, %const1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %rhs0_b0_o = "transfer.and"(%rhs1, %const1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %b1_raw_o = "transfer.and"(%lhs0_b0_z, %rhs0_b0_o) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %b1_raw_z = "transfer.or"(%lhs0_b0_o, %rhs0_b0_z) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %b1_o = "transfer.shl"(%b1_raw_o, %const1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %b1_z = "transfer.shl"(%b1_raw_z, %const1) : (!transfer.integer, !transfer.integer) -> !transfer.integer

    %lhs0_b1_z = "transfer.and"(%lhs0, %const2) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %lhs0_b1_o = "transfer.and"(%lhs1, %const2) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %rhs0_b1_z = "transfer.and"(%rhs0, %const2) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %rhs0_b1_o = "transfer.and"(%rhs1, %const2) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %xy1_00 = "transfer.and"(%lhs0_b1_z, %rhs0_b1_z) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %xy1_11 = "transfer.and"(%lhs0_b1_o, %rhs0_b1_o) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %xy1_01 = "transfer.and"(%lhs0_b1_z, %rhs0_b1_o) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %xy1_10 = "transfer.and"(%lhs0_b1_o, %rhs0_b1_z) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %xy1_0 = "transfer.or"(%xy1_00, %xy1_11) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %xy1_1 = "transfer.or"(%xy1_01, %xy1_10) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %r1_00 = "transfer.and"(%xy1_0, %b1_z) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %r1_11 = "transfer.and"(%xy1_1, %b1_o) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %r1_01 = "transfer.and"(%xy1_0, %b1_o) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %r1_10 = "transfer.and"(%xy1_1, %b1_z) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %r1_0 = "transfer.or"(%r1_00, %r1_11) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %r1_1 = "transfer.or"(%r1_01, %r1_10) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %a1_1 = "transfer.and"(%lhs0_b1_z, %rhs0_b1_o) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %a1_0 = "transfer.or"(%lhs0_b1_o, %rhs0_b1_z) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %b1term_1 = "transfer.and"(%xy1_0, %b1_o) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %b1term_0 = "transfer.or"(%xy1_1, %b1_z) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %b2_raw_o = "transfer.or"(%a1_1, %b1term_1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %b2_raw_z = "transfer.and"(%a1_0, %b1term_0) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %b2_o = "transfer.shl"(%b2_raw_o, %const1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %b2_z = "transfer.shl"(%b2_raw_z, %const1) : (!transfer.integer, !transfer.integer) -> !transfer.integer

    %lhs0_b2_z = "transfer.and"(%lhs0, %const4) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %lhs0_b2_o = "transfer.and"(%lhs1, %const4) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %rhs0_b2_z = "transfer.and"(%rhs0, %const4) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %rhs0_b2_o = "transfer.and"(%rhs1, %const4) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %xy2_00 = "transfer.and"(%lhs0_b2_z, %rhs0_b2_z) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %xy2_11 = "transfer.and"(%lhs0_b2_o, %rhs0_b2_o) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %xy2_01 = "transfer.and"(%lhs0_b2_z, %rhs0_b2_o) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %xy2_10 = "transfer.and"(%lhs0_b2_o, %rhs0_b2_z) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %xy2_0 = "transfer.or"(%xy2_00, %xy2_11) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %xy2_1 = "transfer.or"(%xy2_01, %xy2_10) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %r2_00 = "transfer.and"(%xy2_0, %b2_z) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %r2_11 = "transfer.and"(%xy2_1, %b2_o) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %r2_01 = "transfer.and"(%xy2_0, %b2_o) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %r2_10 = "transfer.and"(%xy2_1, %b2_z) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %r2_0 = "transfer.or"(%r2_00, %r2_11) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %r2_1 = "transfer.or"(%r2_01, %r2_10) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %a2_1 = "transfer.and"(%lhs0_b2_z, %rhs0_b2_o) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %a2_0 = "transfer.or"(%lhs0_b2_o, %rhs0_b2_z) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %b2term_1 = "transfer.and"(%xy2_0, %b2_o) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %b2term_0 = "transfer.or"(%xy2_1, %b2_z) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %b3_raw_o = "transfer.or"(%a2_1, %b2term_1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %b3_raw_z = "transfer.and"(%a2_0, %b2term_0) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %b3_o = "transfer.shl"(%b3_raw_o, %const1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %b3_z = "transfer.shl"(%b3_raw_z, %const1) : (!transfer.integer, !transfer.integer) -> !transfer.integer

    %lhs0_b3_z = "transfer.and"(%lhs0, %const8) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %lhs0_b3_o = "transfer.and"(%lhs1, %const8) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %rhs0_b3_z = "transfer.and"(%rhs0, %const8) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %rhs0_b3_o = "transfer.and"(%rhs1, %const8) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %xy3_00 = "transfer.and"(%lhs0_b3_z, %rhs0_b3_z) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %xy3_11 = "transfer.and"(%lhs0_b3_o, %rhs0_b3_o) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %xy3_01 = "transfer.and"(%lhs0_b3_z, %rhs0_b3_o) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %xy3_10 = "transfer.and"(%lhs0_b3_o, %rhs0_b3_z) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %xy3_0 = "transfer.or"(%xy3_00, %xy3_11) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %xy3_1 = "transfer.or"(%xy3_01, %xy3_10) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %r3_00 = "transfer.and"(%xy3_0, %b3_z) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %r3_11 = "transfer.and"(%xy3_1, %b3_o) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %r3_01 = "transfer.and"(%xy3_0, %b3_o) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %r3_10 = "transfer.and"(%xy3_1, %b3_z) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %r3_0 = "transfer.or"(%r3_00, %r3_11) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %r3_1 = "transfer.or"(%r3_01, %r3_10) : (!transfer.integer, !transfer.integer) -> !transfer.integer

    %a3_1 = "transfer.and"(%lhs0_b3_z, %rhs0_b3_o) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %a3_0 = "transfer.or"(%lhs0_b3_o, %rhs0_b3_z) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %b3term_1 = "transfer.and"(%xy3_0, %b3_o) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %b3term_0 = "transfer.or"(%xy3_1, %b3_z) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %b4_raw_o = "transfer.or"(%a3_1, %b3term_1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %b4_raw_z = "transfer.and"(%a3_0, %b3term_0) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %b4_o = "transfer.shl"(%b4_raw_o, %const1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %b4_z = "transfer.shl"(%b4_raw_z, %const1) : (!transfer.integer, !transfer.integer) -> !transfer.integer

    %lhs0_b4_z = "transfer.and"(%lhs0, %const16) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %lhs0_b4_o = "transfer.and"(%lhs1, %const16) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %rhs0_b4_z = "transfer.and"(%rhs0, %const16) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %rhs0_b4_o = "transfer.and"(%rhs1, %const16) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %xy4_00 = "transfer.and"(%lhs0_b4_z, %rhs0_b4_z) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %xy4_11 = "transfer.and"(%lhs0_b4_o, %rhs0_b4_o) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %xy4_01 = "transfer.and"(%lhs0_b4_z, %rhs0_b4_o) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %xy4_10 = "transfer.and"(%lhs0_b4_o, %rhs0_b4_z) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %xy4_0 = "transfer.or"(%xy4_00, %xy4_11) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %xy4_1 = "transfer.or"(%xy4_01, %xy4_10) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %r4_00 = "transfer.and"(%xy4_0, %b4_z) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %r4_11 = "transfer.and"(%xy4_1, %b4_o) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %r4_01 = "transfer.and"(%xy4_0, %b4_o) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %r4_10 = "transfer.and"(%xy4_1, %b4_z) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %r4_0 = "transfer.or"(%r4_00, %r4_11) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %r4_1 = "transfer.or"(%r4_01, %r4_10) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %a4_1 = "transfer.and"(%lhs0_b4_z, %rhs0_b4_o) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %a4_0 = "transfer.or"(%lhs0_b4_o, %rhs0_b4_z) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %b4term_1 = "transfer.and"(%xy4_0, %b4_o) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %b4term_0 = "transfer.or"(%xy4_1, %b4_z) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %b5_raw_o = "transfer.or"(%a4_1, %b4term_1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %b5_raw_z = "transfer.and"(%a4_0, %b4term_0) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %b5_o = "transfer.shl"(%b5_raw_o, %const1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %b5_z = "transfer.shl"(%b5_raw_z, %const1) : (!transfer.integer, !transfer.integer) -> !transfer.integer

    %lhs0_b5_z = "transfer.and"(%lhs0, %const32) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %lhs0_b5_o = "transfer.and"(%lhs1, %const32) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %rhs0_b5_z = "transfer.and"(%rhs0, %const32) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %rhs0_b5_o = "transfer.and"(%rhs1, %const32) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %xy5_00 = "transfer.and"(%lhs0_b5_z, %rhs0_b5_z) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %xy5_11 = "transfer.and"(%lhs0_b5_o, %rhs0_b5_o) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %xy5_01 = "transfer.and"(%lhs0_b5_z, %rhs0_b5_o) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %xy5_10 = "transfer.and"(%lhs0_b5_o, %rhs0_b5_z) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %xy5_0 = "transfer.or"(%xy5_00, %xy5_11) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %xy5_1 = "transfer.or"(%xy5_01, %xy5_10) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %r5_00 = "transfer.and"(%xy5_0, %b5_z) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %r5_11 = "transfer.and"(%xy5_1, %b5_o) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %r5_01 = "transfer.and"(%xy5_0, %b5_o) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %r5_10 = "transfer.and"(%xy5_1, %b5_z) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %r5_0 = "transfer.or"(%r5_00, %r5_11) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %r5_1 = "transfer.or"(%r5_01, %r5_10) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %a5_1 = "transfer.and"(%lhs0_b5_z, %rhs0_b5_o) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %a5_0 = "transfer.or"(%lhs0_b5_o, %rhs0_b5_z) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %b5term_1 = "transfer.and"(%xy5_0, %b5_o) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %b5term_0 = "transfer.or"(%xy5_1, %b5_z) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %b6_raw_o = "transfer.or"(%a5_1, %b5term_1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %b6_raw_z = "transfer.and"(%a5_0, %b5term_0) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %b6_o = "transfer.shl"(%b6_raw_o, %const1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %b6_z = "transfer.shl"(%b6_raw_z, %const1) : (!transfer.integer, !transfer.integer) -> !transfer.integer

    %lhs0_b6_z = "transfer.and"(%lhs0, %const64) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %lhs0_b6_o = "transfer.and"(%lhs1, %const64) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %rhs0_b6_z = "transfer.and"(%rhs0, %const64) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %rhs0_b6_o = "transfer.and"(%rhs1, %const64) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %xy6_00 = "transfer.and"(%lhs0_b6_z, %rhs0_b6_z) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %xy6_11 = "transfer.and"(%lhs0_b6_o, %rhs0_b6_o) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %xy6_01 = "transfer.and"(%lhs0_b6_z, %rhs0_b6_o) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %xy6_10 = "transfer.and"(%lhs0_b6_o, %rhs0_b6_z) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %xy6_0 = "transfer.or"(%xy6_00, %xy6_11) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %xy6_1 = "transfer.or"(%xy6_01, %xy6_10) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %r6_00 = "transfer.and"(%xy6_0, %b6_z) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %r6_11 = "transfer.and"(%xy6_1, %b6_o) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %r6_01 = "transfer.and"(%xy6_0, %b6_o) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %r6_10 = "transfer.and"(%xy6_1, %b6_z) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %r6_0 = "transfer.or"(%r6_00, %r6_11) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %r6_1 = "transfer.or"(%r6_01, %r6_10) : (!transfer.integer, !transfer.integer) -> !transfer.integer

    %r_low_0a = "transfer.or"(%r1_0, %r2_0) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %r_low_0b = "transfer.or"(%r3_0, %r4_0) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %r_low_0c = "transfer.or"(%r5_0, %r6_0) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %r_low_0d = "transfer.or"(%r_low_0a, %r_low_0b) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %r_low_0 = "transfer.or"(%r_low_0d, %r_low_0c) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %r_low_1a = "transfer.or"(%r1_1, %r2_1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %r_low_1b = "transfer.or"(%r3_1, %r4_1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %r_low_1c = "transfer.or"(%r5_1, %r6_1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %r_low_1d = "transfer.or"(%r_low_1a, %r_low_1b) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %r_low_1 = "transfer.or"(%r_low_1d, %r_low_1c) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %r_low_1_nouf = "transfer.select"(%consistent, %r_low_1, %const0) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %res0_refined2 = "transfer.or"(%res0_refined, %r_low_0) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %res1_refined2 = "transfer.or"(%res1_refined, %r_low_1_nouf) : (!transfer.integer, !transfer.integer) -> !transfer.integer

    %sign_mask_local = "transfer.get_signed_min_value"(%lhs0) : (!transfer.integer) -> !transfer.integer
    %res_sign0_a = "transfer.and"(%lhs0, %sign_mask_local) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %res_sign0_b = "transfer.and"(%rhs1, %sign_mask_local) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %res_sign0 = "transfer.or"(%res_sign0_a, %res_sign0_b) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %res_sign1_a = "transfer.and"(%lhs1, %sign_mask_local) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %res_sign1_b = "transfer.and"(%rhs0, %sign_mask_local) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %res_sign1 = "transfer.and"(%res_sign1_a, %res_sign1_b) : (!transfer.integer, !transfer.integer) -> !transfer.integer

    %res0_refined3 = "transfer.add"(%res0_refined2, %const0) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %res1_refined3 = "transfer.add"(%res1_refined2, %const0) : (!transfer.integer, !transfer.integer) -> !transfer.integer


    %sign_mask = "transfer.get_signed_min_value"(%lhs0) : (!transfer.integer) -> !transfer.integer
    %lhs_sign_zero_known = "transfer.and"(%lhs0, %sign_mask) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %lhs_sign_one_known = "transfer.and"(%lhs1, %sign_mask) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %rhs_sign_zero_known = "transfer.and"(%rhs0, %sign_mask) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %rhs_sign_one_known = "transfer.and"(%rhs1, %sign_mask) : (!transfer.integer, !transfer.integer) -> !transfer.integer

    %lhs_can_nonneg = "transfer.cmp"(%lhs_sign_one_known, %const0) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %lhs_can_neg = "transfer.cmp"(%lhs_sign_zero_known, %const0) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %rhs_can_nonneg = "transfer.cmp"(%rhs_sign_one_known, %const0) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %rhs_can_neg = "transfer.cmp"(%rhs_sign_zero_known, %const0) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1

    %sign_case_nn = "arith.andi"(%lhs_can_nonneg, %rhs_can_nonneg) : (i1, i1) -> i1
    %sign_case_npn = "arith.andi"(%lhs_can_neg, %rhs_can_nonneg) : (i1, i1) -> i1
    %sign_case_pp = "arith.andi"(%lhs_can_neg, %rhs_can_neg) : (i1, i1) -> i1
    %sign_case_any_0 = "arith.ori"(%sign_case_nn, %sign_case_npn) : (i1, i1) -> i1
    %sign_case_any = "arith.ori"(%sign_case_any_0, %sign_case_pp) : (i1, i1) -> i1

    %nuw_possible = "transfer.cmp"(%rhs1, %lhs_max) {predicate = 7 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %feasible_0 = "arith.andi"(%consistent, %nuw_possible) : (i1, i1) -> i1
    %feasible = "arith.andi"(%feasible_0, %sign_case_any) : (i1, i1) -> i1

    %res0_final = "transfer.select"(%feasible, %res0_refined3, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %res1_final = "transfer.select"(%feasible, %res1_refined3, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer

    %r = "transfer.make"(%res0_final, %res1_final) : (!transfer.integer, !transfer.integer) -> !transfer.abs_value<[!transfer.integer, !transfer.integer]>
    "func.return"(%r) : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> ()
}) {"sym_name" = "kb_subnuw", "function_type" = (!transfer.abs_value<[!transfer.integer, !transfer.integer]>, !transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.abs_value<[!transfer.integer, !transfer.integer]>} : () -> ()
