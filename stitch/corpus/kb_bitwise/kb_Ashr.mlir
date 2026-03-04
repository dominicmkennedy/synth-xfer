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
    // A sufficient feasibility check for op_constraint rhs in [0, bw]:
    // if min(rhs) = known-one mask is already > bw, there is no feasible rhs.
    %rhs_min_le_bw = "transfer.cmp"(%rhs1, %bitwidth) {predicate = 7 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %inputs_consistent = "arith.andi"(%lhs_consistent, %rhs_consistent) : (i1, i1) -> i1
    %has_feasible_pair = "arith.andi"(%inputs_consistent, %rhs_min_le_bw) : (i1, i1) -> i1

    %bw_minus_1 = "transfer.sub"(%bitwidth, %const1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %sign_mask = "transfer.shl"(%const1, %bw_minus_1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %bw_clz = "transfer.countl_zero"(%bitwidth) : (!transfer.integer) -> !transfer.integer
    %rhs_bound_low_mask = "transfer.lshr"(%all_ones, %bw_clz) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %rhs_bound_high_zero = "transfer.xor"(%rhs_bound_low_mask, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %rhs0_c = "transfer.or"(%rhs0, %rhs_bound_high_zero) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %rhs1_c = "transfer.and"(%rhs1, %rhs_bound_low_mask) : (!transfer.integer, !transfer.integer) -> !transfer.integer

    %const_res0 = "transfer.ashr"(%lhs0, %rhs1_c) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %const_res1 = "transfer.ashr"(%lhs1, %rhs1_c) : (!transfer.integer, !transfer.integer) -> !transfer.integer

    %rhs1_not = "transfer.xor"(%rhs1_c, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %rhs_is_const = "transfer.cmp"(%rhs0_c, %rhs1_not) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1

    %lhs_sign_zero = "transfer.and"(%lhs0, %sign_mask) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %lhs_sign_one = "transfer.and"(%lhs1, %sign_mask) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %lhs_nonneg = "transfer.cmp"(%lhs_sign_zero, %sign_mask) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %lhs_neg = "transfer.cmp"(%lhs_sign_one, %sign_mask) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1

    %lhs_mlz = "transfer.countl_one"(%lhs0) : (!transfer.integer) -> !transfer.integer
    %lhs_mlo = "transfer.countl_one"(%lhs1) : (!transfer.integer) -> !transfer.integer

    %lz_keep = "transfer.umax"(%lhs_mlz, %rhs1_c) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %lo_keep = "transfer.umax"(%lhs_mlo, %rhs1_c) : (!transfer.integer, !transfer.integer) -> !transfer.integer

    %lz_inv = "transfer.sub"(%bitwidth, %lz_keep) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %lo_inv = "transfer.sub"(%bitwidth, %lo_keep) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %high_zero_mask = "transfer.shl"(%all_ones, %lz_inv) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %high_one_mask = "transfer.shl"(%all_ones, %lo_inv) : (!transfer.integer, !transfer.integer) -> !transfer.integer

    %var_res0 = "transfer.select"(%lhs_nonneg, %high_zero_mask, %const0) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %var_res1 = "transfer.select"(%lhs_neg, %high_one_mask, %const0) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer

    %rhs_known_union = "transfer.or"(%rhs0_c, %rhs1_c) : (!transfer.integer, !transfer.integer) -> !transfer.integer
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

    %rhs_alt = "transfer.add"(%rhs1_c, %rhs_unknown_mask) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %rhs_alt_le_bw = "transfer.cmp"(%rhs_alt, %bitwidth) {predicate = 6 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %rhs_val0_le_bw = "transfer.cmp"(%rhs1_c, %bitwidth) {predicate = 6 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %rhs_feas0 = "arith.andi"(%rhs_one_unknown, %rhs_val0_le_bw) : (i1, i1) -> i1
    %rhs_feas2 = "arith.andi"(%rhs_one_unknown, %rhs_alt_le_bw) : (i1, i1) -> i1
    %rhs_any_feas = "arith.ori"(%rhs_feas0, %rhs_feas2) : (i1, i1) -> i1

    %alt_res0 = "transfer.ashr"(%lhs0, %rhs_alt) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %alt_res1 = "transfer.ashr"(%lhs1, %rhs_alt) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %two_sel0_0 = "transfer.select"(%rhs_feas0, %const_res0, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %two_sel0_2 = "transfer.select"(%rhs_feas2, %alt_res0, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %two_acc0 = "transfer.and"(%two_sel0_0, %two_sel0_2) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %two_case_res0 = "transfer.select"(%rhs_any_feas, %two_acc0, %const0) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer

    %two_sel1_0 = "transfer.select"(%rhs_feas0, %const_res1, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %two_sel1_2 = "transfer.select"(%rhs_feas2, %alt_res1, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %two_acc1 = "transfer.and"(%two_sel1_0, %two_sel1_2) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %two_case_res1 = "transfer.select"(%rhs_any_feas, %two_acc1, %const0) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer

    %rhs_u2_rem_not = "transfer.xor"(%rhs_u2_rem, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %rhs_u2_lowbit = "transfer.and"(%rhs_unknown_mask, %rhs_u2_rem_not) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %rhs_u2_highbit = "transfer.xor"(%rhs_unknown_mask, %rhs_u2_lowbit) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %rhs_u2_val1 = "transfer.add"(%rhs1_c, %rhs_u2_lowbit) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %rhs_u2_val2 = "transfer.add"(%rhs1_c, %rhs_u2_highbit) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %rhs_u2_val3 = "transfer.add"(%rhs1_c, %rhs_unknown_mask) : (!transfer.integer, !transfer.integer) -> !transfer.integer

    %rhs_u2_v0_le_bw = "transfer.cmp"(%rhs1_c, %bitwidth) {predicate = 6 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %rhs_u2_v1_le_bw = "transfer.cmp"(%rhs_u2_val1, %bitwidth) {predicate = 6 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %rhs_u2_v2_le_bw = "transfer.cmp"(%rhs_u2_val2, %bitwidth) {predicate = 6 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %rhs_u2_v3_le_bw = "transfer.cmp"(%rhs_u2_val3, %bitwidth) {predicate = 6 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %rhs_u2_feas0 = "arith.andi"(%rhs_two_unknown, %rhs_u2_v0_le_bw) : (i1, i1) -> i1
    %rhs_u2_feas1 = "arith.andi"(%rhs_two_unknown, %rhs_u2_v1_le_bw) : (i1, i1) -> i1
    %rhs_u2_feas2 = "arith.andi"(%rhs_two_unknown, %rhs_u2_v2_le_bw) : (i1, i1) -> i1
    %rhs_u2_feas3 = "arith.andi"(%rhs_two_unknown, %rhs_u2_v3_le_bw) : (i1, i1) -> i1
    %rhs_u2_any01 = "arith.ori"(%rhs_u2_feas0, %rhs_u2_feas1) : (i1, i1) -> i1
    %rhs_u2_any23 = "arith.ori"(%rhs_u2_feas2, %rhs_u2_feas3) : (i1, i1) -> i1
    %rhs_u2_any = "arith.ori"(%rhs_u2_any01, %rhs_u2_any23) : (i1, i1) -> i1

    %rhs_u2_res0_1 = "transfer.ashr"(%lhs0, %rhs_u2_val1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %rhs_u2_res0_2 = "transfer.ashr"(%lhs0, %rhs_u2_val2) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %rhs_u2_res0_3 = "transfer.ashr"(%lhs0, %rhs_u2_val3) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %rhs_u2_sel0_0 = "transfer.select"(%rhs_u2_feas0, %const_res0, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %rhs_u2_sel0_1 = "transfer.select"(%rhs_u2_feas1, %rhs_u2_res0_1, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %rhs_u2_sel0_2 = "transfer.select"(%rhs_u2_feas2, %rhs_u2_res0_2, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %rhs_u2_sel0_3 = "transfer.select"(%rhs_u2_feas3, %rhs_u2_res0_3, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %rhs_u2_acc0_01 = "transfer.and"(%rhs_u2_sel0_0, %rhs_u2_sel0_1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %rhs_u2_acc0_23 = "transfer.and"(%rhs_u2_sel0_2, %rhs_u2_sel0_3) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %rhs_u2_acc0 = "transfer.and"(%rhs_u2_acc0_01, %rhs_u2_acc0_23) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %rhs_u2_case_res0 = "transfer.select"(%rhs_u2_any, %rhs_u2_acc0, %const0) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer

    %rhs_u2_res1_1 = "transfer.ashr"(%lhs1, %rhs_u2_val1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %rhs_u2_res1_2 = "transfer.ashr"(%lhs1, %rhs_u2_val2) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %rhs_u2_res1_3 = "transfer.ashr"(%lhs1, %rhs_u2_val3) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %rhs_u2_sel1_0 = "transfer.select"(%rhs_u2_feas0, %const_res1, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %rhs_u2_sel1_1 = "transfer.select"(%rhs_u2_feas1, %rhs_u2_res1_1, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %rhs_u2_sel1_2 = "transfer.select"(%rhs_u2_feas2, %rhs_u2_res1_2, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %rhs_u2_sel1_3 = "transfer.select"(%rhs_u2_feas3, %rhs_u2_res1_3, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %rhs_u2_acc1_01 = "transfer.and"(%rhs_u2_sel1_0, %rhs_u2_sel1_1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %rhs_u2_acc1_23 = "transfer.and"(%rhs_u2_sel1_2, %rhs_u2_sel1_3) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %rhs_u2_acc1 = "transfer.and"(%rhs_u2_acc1_01, %rhs_u2_acc1_23) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %rhs_u2_case_res1 = "transfer.select"(%rhs_u2_any, %rhs_u2_acc1, %const0) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer

    %var_res0_dyn1 = "transfer.select"(%rhs_one_unknown, %two_case_res0, %var_res0) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %var_res1_dyn1 = "transfer.select"(%rhs_one_unknown, %two_case_res1, %var_res1) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %var_res0_dyn = "transfer.select"(%rhs_two_unknown, %rhs_u2_case_res0, %var_res0_dyn1) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %var_res1_dyn = "transfer.select"(%rhs_two_unknown, %rhs_u2_case_res1, %var_res1_dyn1) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer

    %res0_const_sel = "transfer.select"(%rhs_is_const, %const_res0, %var_res0_dyn) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %res1_const_sel = "transfer.select"(%rhs_is_const, %const_res1, %var_res1_dyn) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer

    %lhs0_all_ones = "transfer.cmp"(%lhs0, %all_ones) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %lhs1_is_zero = "transfer.cmp"(%lhs1, %const0) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %lhs_is_zero = "arith.andi"(%lhs0_all_ones, %lhs1_is_zero) : (i1, i1) -> i1

    %lhs0_is_zero = "transfer.cmp"(%lhs0, %const0) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %lhs1_all_ones = "transfer.cmp"(%lhs1, %all_ones) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %lhs_is_all_ones = "arith.andi"(%lhs0_is_zero, %lhs1_all_ones) : (i1, i1) -> i1

    %res0_zero_sel = "transfer.select"(%lhs_is_zero, %all_ones, %res0_const_sel) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %res1_zero_sel = "transfer.select"(%lhs_is_zero, %const0, %res1_const_sel) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %res0 = "transfer.select"(%lhs_is_all_ones, %const0, %res0_zero_sel) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %res1 = "transfer.select"(%lhs_is_all_ones, %all_ones, %res1_zero_sel) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer

    %res0_final = "transfer.select"(%has_feasible_pair, %res0, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %res1_final = "transfer.select"(%has_feasible_pair, %res1, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer

    %r = "transfer.make"(%res0_final, %res1_final) : (!transfer.integer, !transfer.integer) -> !transfer.abs_value<[!transfer.integer, !transfer.integer]>
    "func.return"(%r) : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> ()
}) {"sym_name" = "kb_ashr", "function_type" = (!transfer.abs_value<[!transfer.integer, !transfer.integer]>, !transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.abs_value<[!transfer.integer, !transfer.integer]>} : () -> ()
