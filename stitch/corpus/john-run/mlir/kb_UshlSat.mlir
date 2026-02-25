"func.func"() ({
  ^0(%lhs : !transfer.abs_value<[!transfer.integer, !transfer.integer]>, %rhs : !transfer.abs_value<[!transfer.integer, !transfer.integer]>):
    %lhs0 = "transfer.get"(%lhs) {index = 0} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %lhs1 = "transfer.get"(%lhs) {index = 1} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %rhs0 = "transfer.get"(%rhs) {index = 0} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %rhs1 = "transfer.get"(%rhs) {index = 1} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer

    %all_ones = "transfer.get_all_ones"(%lhs0) : (!transfer.integer) -> !transfer.integer
    %const0 = "transfer.constant"(%lhs0) {value = 0 : index} : (!transfer.integer) -> !transfer.integer
    %const_true = "arith.constant"() {value = 1 : i1} : () -> i1
    %const1 = "transfer.constant"(%lhs0) {value = 1 : index} : (!transfer.integer) -> !transfer.integer
    %bitwidth = "transfer.get_bit_width"(%lhs0) : (!transfer.integer) -> !transfer.integer

    %lhs_max = "transfer.xor"(%lhs0, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %rhs_max = "transfer.xor"(%rhs0, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer

    // Endpoint interval candidate: lb = f(lhs_min, rhs_min), ub = f(lhs_max, rhs_max).
    %lb_shl = "transfer.shl"(%lhs1, %rhs1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %lb_ov = "transfer.ushl_overflow"(%lhs1, %rhs1) {predicate = 9 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %lb = "transfer.select"(%lb_ov, %all_ones, %lb_shl) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer

    %ub_shl = "transfer.shl"(%lhs_max, %rhs_max) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %ub_ov = "transfer.ushl_overflow"(%lhs_max, %rhs_max) {predicate = 9 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %ub = "transfer.select"(%ub_ov, %all_ones, %ub_shl) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer

    %diff = "transfer.xor"(%lb, %ub) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %common_lz = "transfer.countl_zero"(%diff) : (!transfer.integer) -> !transfer.integer
    %common_inv = "transfer.sub"(%bitwidth, %common_lz) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %common_mask = "transfer.shl"(%all_ones, %common_inv) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %lb_not = "transfer.xor"(%lb, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %a0 = "transfer.and"(%lb_not, %common_mask) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %a1 = "transfer.and"(%lb, %common_mask) : (!transfer.integer, !transfer.integer) -> !transfer.integer

    %rhs1_not = "transfer.xor"(%rhs1, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %rhs_is_const = "transfer.cmp"(%rhs0, %rhs1_not) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %lhs1_not = "transfer.xor"(%lhs1, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %lhs_is_const = "transfer.cmp"(%lhs0, %lhs1_not) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1

    // Constant-rhs candidate: keep exact shifted one-bits; keep zero-bits only if never-overflow.
    %c_shl1 = "transfer.shl"(%lhs1, %rhs1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %c_shl0 = "transfer.shl"(%lhs0, %rhs1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %c_ov_max = "transfer.ushl_overflow"(%lhs_max, %rhs1) {predicate = 9 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %c_never_ov = "arith.xori"(%c_ov_max, %const_true) : (i1, i1) -> i1
    %c0_raw = "transfer.select"(%c_never_ov, %c_shl0, %const0) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %b0 = "transfer.select"(%rhs_is_const, %c0_raw, %const0) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %b1 = "transfer.select"(%rhs_is_const, %c_shl1, %const0) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer

    // rhs == 0 => exact passthrough.
    %rhs0_all_ones = "transfer.cmp"(%rhs0, %all_ones) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %rhs1_is_zero = "transfer.cmp"(%rhs1, %const0) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %rhs_is_zero = "arith.andi"(%rhs0_all_ones, %rhs1_is_zero) : (i1, i1) -> i1
    %c0 = "transfer.select"(%rhs_is_zero, %lhs0, %const0) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %c1 = "transfer.select"(%rhs_is_zero, %lhs1, %const0) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer

    // rhs_min >= bw => always overflow => exact all ones.
    %rhs_ge_bw = "transfer.cmp"(%rhs1, %bitwidth) {predicate = 9 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %d1 = "transfer.select"(%rhs_ge_bw, %all_ones, %const0) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    // Also overflow-always when rhs has nonzero lower bound and lhs has a guaranteed
    // one in bits that must be shifted out for that lower bound.
    %rhs_min_nonzero = "transfer.cmp"(%rhs1, %const0) {predicate = 1 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %rhs1_inv = "transfer.sub"(%bitwidth, %rhs1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %rhs1_top_mask = "transfer.shl"(%all_ones, %rhs1_inv) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %lhs_top_for_rhs1 = "transfer.and"(%lhs1, %rhs1_top_mask) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %lhs_top_nonzero = "transfer.cmp"(%lhs_top_for_rhs1, %const0) {predicate = 1 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %ov_by_high = "arith.andi"(%rhs_min_nonzero, %lhs_top_nonzero) : (i1, i1) -> i1
    %d2 = "transfer.select"(%ov_by_high, %all_ones, %const0) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer

    // lhs == 0 and rhs_max < bw => exact zero.
    %lhs0_all_ones = "transfer.cmp"(%lhs0, %all_ones) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %lhs1_is_zero = "transfer.cmp"(%lhs1, %const0) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %lhs_is_zero = "arith.andi"(%lhs0_all_ones, %lhs1_is_zero) : (i1, i1) -> i1
    %rhs_max_lt_bw = "transfer.cmp"(%rhs_max, %bitwidth) {predicate = 6 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %lhs_zero_safe = "arith.andi"(%lhs_is_zero, %rhs_max_lt_bw) : (i1, i1) -> i1
    %e0 = "transfer.select"(%lhs_zero_safe, %all_ones, %const0) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer

    // Exact-constant candidate.
    %both_const = "arith.andi"(%lhs_is_const, %rhs_is_const) : (i1, i1) -> i1
    %k_shl = "transfer.shl"(%lhs1, %rhs1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %k_ov = "transfer.ushl_overflow"(%lhs1, %rhs1) {predicate = 9 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %k_val = "transfer.select"(%k_ov, %all_ones, %k_shl) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %k_val_not = "transfer.xor"(%k_val, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %f0 = "transfer.select"(%both_const, %k_val_not, %const0) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %f1 = "transfer.select"(%both_const, %k_val, %const0) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer

    // Enumerate 1-2 unknown bits when one side is constant.
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

    %rhs_known_union = "transfer.or"(%rhs0, %rhs1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %rhs_unknown_mask = "transfer.xor"(%rhs_known_union, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %rhs_unknown_nonzero = "transfer.cmp"(%rhs_unknown_mask, %const0) {predicate = 1 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %rhs_unknown_minus_1 = "transfer.sub"(%rhs_unknown_mask, %const1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %rhs_unknown_and_minus_1 = "transfer.and"(%rhs_unknown_mask, %rhs_unknown_minus_1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %rhs_unknown_pow2ish = "transfer.cmp"(%rhs_unknown_and_minus_1, %const0) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %rhs_one_unknown = "arith.andi"(%rhs_unknown_nonzero, %rhs_unknown_pow2ish) : (i1, i1) -> i1
    %rhs_unknown_neg = "transfer.neg"(%rhs_unknown_mask) : (!transfer.integer) -> !transfer.integer
    %rhs_unknown_lowbit = "transfer.and"(%rhs_unknown_mask, %rhs_unknown_neg) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %rhs_unknown_rest = "transfer.xor"(%rhs_unknown_mask, %rhs_unknown_lowbit) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %rhs_rest_nonzero = "transfer.cmp"(%rhs_unknown_rest, %const0) {predicate = 1 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %rhs_rest_minus_1 = "transfer.sub"(%rhs_unknown_rest, %const1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %rhs_rest_and_minus_1 = "transfer.and"(%rhs_unknown_rest, %rhs_rest_minus_1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %rhs_rest_pow2ish = "transfer.cmp"(%rhs_rest_and_minus_1, %const0) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %rhs_two_unknown = "arith.andi"(%rhs_rest_nonzero, %rhs_rest_pow2ish) : (i1, i1) -> i1
    %lhs_rhs_one_one = "arith.andi"(%lhs_one_unknown, %rhs_one_unknown) : (i1, i1) -> i1
    %rhs_unknown_rest_neg = "transfer.neg"(%rhs_unknown_rest) : (!transfer.integer) -> !transfer.integer
    %rhs_unknown_midbit = "transfer.and"(%rhs_unknown_rest, %rhs_unknown_rest_neg) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %rhs_unknown_highbit = "transfer.xor"(%rhs_unknown_rest, %rhs_unknown_midbit) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %rhs_high_nonzero = "transfer.cmp"(%rhs_unknown_highbit, %const0) {predicate = 1 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %rhs_high_minus_1 = "transfer.sub"(%rhs_unknown_highbit, %const1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %rhs_high_and_minus_1 = "transfer.and"(%rhs_unknown_highbit, %rhs_high_minus_1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %rhs_high_pow2ish = "transfer.cmp"(%rhs_high_and_minus_1, %const0) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %rhs_three_unknown = "arith.andi"(%rhs_high_nonzero, %rhs_high_pow2ish) : (i1, i1) -> i1
    %lhs_const_rhs_three_unknown = "arith.andi"(%lhs_is_const, %rhs_three_unknown) : (i1, i1) -> i1
    %rhs_01 = "transfer.add"(%rhs_unknown_lowbit, %rhs_unknown_midbit) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %rhs_02 = "transfer.add"(%rhs_unknown_lowbit, %rhs_unknown_highbit) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %rhs_12 = "transfer.add"(%rhs_unknown_midbit, %rhs_unknown_highbit) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %rhs3_val2 = "transfer.add"(%rhs1, %rhs_unknown_midbit) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %rhs3_val3 = "transfer.add"(%rhs1, %rhs_01) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %rhs3_val4 = "transfer.add"(%rhs1, %rhs_unknown_highbit) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %rhs3_val5 = "transfer.add"(%rhs1, %rhs_02) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %rhs3_val6 = "transfer.add"(%rhs1, %rhs_12) : (!transfer.integer, !transfer.integer) -> !transfer.integer

    // lhs const, rhs has exactly 1 unknown bit.
    %lhs_const_rhs_one_unknown = "arith.andi"(%lhs_is_const, %rhs_one_unknown) : (i1, i1) -> i1
    %rhs_one_alt = "transfer.add"(%rhs1, %rhs_unknown_mask) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %g_val0_shl = "transfer.shl"(%lhs1, %rhs1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %g_val0_ov = "transfer.ushl_overflow"(%lhs1, %rhs1) {predicate = 9 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %g_val0 = "transfer.select"(%g_val0_ov, %all_ones, %g_val0_shl) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %g_val1_shl = "transfer.shl"(%lhs1, %rhs_one_alt) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %g_val1_ov = "transfer.ushl_overflow"(%lhs1, %rhs_one_alt) {predicate = 9 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %g_val1 = "transfer.select"(%g_val1_ov, %all_ones, %g_val1_shl) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %g_val0_not = "transfer.xor"(%g_val0, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %g_val1_not = "transfer.xor"(%g_val1, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %g0_raw = "transfer.and"(%g_val0_not, %g_val1_not) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %g1_raw = "transfer.and"(%g_val0, %g_val1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %g0 = "transfer.select"(%lhs_const_rhs_one_unknown, %g0_raw, %const0) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %g1 = "transfer.select"(%lhs_const_rhs_one_unknown, %g1_raw, %const0) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer

    // lhs const, rhs has exactly 2 unknown bits.
    %lhs_const_rhs_two_unknown = "arith.andi"(%lhs_is_const, %rhs_two_unknown) : (i1, i1) -> i1
    %rhs_two_alt1 = "transfer.add"(%rhs1, %rhs_unknown_lowbit) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %rhs_two_alt2 = "transfer.add"(%rhs1, %rhs_unknown_rest) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %rhs_two_alt3 = "transfer.add"(%rhs1, %rhs_unknown_mask) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %h_val1_shl = "transfer.shl"(%lhs1, %rhs_two_alt1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %h_val1_ov = "transfer.ushl_overflow"(%lhs1, %rhs_two_alt1) {predicate = 9 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %h_val1 = "transfer.select"(%h_val1_ov, %all_ones, %h_val1_shl) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %h_val2_shl = "transfer.shl"(%lhs1, %rhs_two_alt2) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %h_val2_ov = "transfer.ushl_overflow"(%lhs1, %rhs_two_alt2) {predicate = 9 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %h_val2 = "transfer.select"(%h_val2_ov, %all_ones, %h_val2_shl) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %h_val3_shl = "transfer.shl"(%lhs1, %rhs_two_alt3) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %h_val3_ov = "transfer.ushl_overflow"(%lhs1, %rhs_two_alt3) {predicate = 9 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %h_val3 = "transfer.select"(%h_val3_ov, %all_ones, %h_val3_shl) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %h_val0_not = "transfer.xor"(%g_val0, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %h_val1_not = "transfer.xor"(%h_val1, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %h_val2_not = "transfer.xor"(%h_val2, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %h_val3_not = "transfer.xor"(%h_val3, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %h0_01 = "transfer.and"(%h_val0_not, %h_val1_not) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %h0_23 = "transfer.and"(%h_val2_not, %h_val3_not) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %h0_raw = "transfer.and"(%h0_01, %h0_23) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %h1_01 = "transfer.and"(%g_val0, %h_val1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %h1_23 = "transfer.and"(%h_val2, %h_val3) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %h1_raw = "transfer.and"(%h1_01, %h1_23) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %h0 = "transfer.select"(%lhs_const_rhs_two_unknown, %h0_raw, %const0) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %h1 = "transfer.select"(%lhs_const_rhs_two_unknown, %h1_raw, %const0) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer

    // lhs const, rhs has exactly 3 unknown bits.
    %m_val2_shl = "transfer.shl"(%lhs1, %rhs3_val2) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %m_val2_ov = "transfer.ushl_overflow"(%lhs1, %rhs3_val2) {predicate = 9 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %m_val2 = "transfer.select"(%m_val2_ov, %all_ones, %m_val2_shl) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %m_val3_shl = "transfer.shl"(%lhs1, %rhs3_val3) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %m_val3_ov = "transfer.ushl_overflow"(%lhs1, %rhs3_val3) {predicate = 9 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %m_val3 = "transfer.select"(%m_val3_ov, %all_ones, %m_val3_shl) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %m_val4_shl = "transfer.shl"(%lhs1, %rhs3_val4) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %m_val4_ov = "transfer.ushl_overflow"(%lhs1, %rhs3_val4) {predicate = 9 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %m_val4 = "transfer.select"(%m_val4_ov, %all_ones, %m_val4_shl) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %m_val5_shl = "transfer.shl"(%lhs1, %rhs3_val5) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %m_val5_ov = "transfer.ushl_overflow"(%lhs1, %rhs3_val5) {predicate = 9 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %m_val5 = "transfer.select"(%m_val5_ov, %all_ones, %m_val5_shl) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %m_val6_shl = "transfer.shl"(%lhs1, %rhs3_val6) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %m_val6_ov = "transfer.ushl_overflow"(%lhs1, %rhs3_val6) {predicate = 9 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %m_val6 = "transfer.select"(%m_val6_ov, %all_ones, %m_val6_shl) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %m_val0_not = "transfer.xor"(%g_val0, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %m_val1_not = "transfer.xor"(%h_val1, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %m_val2_not = "transfer.xor"(%m_val2, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %m_val3_not = "transfer.xor"(%m_val3, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %m_val4_not = "transfer.xor"(%m_val4, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %m_val5_not = "transfer.xor"(%m_val5, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %m_val6_not = "transfer.xor"(%m_val6, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %m_val7_not = "transfer.xor"(%h_val3, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %m0_01 = "transfer.and"(%m_val0_not, %m_val1_not) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %m0_23 = "transfer.and"(%m_val2_not, %m_val3_not) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %m0_45 = "transfer.and"(%m_val4_not, %m_val5_not) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %m0_67 = "transfer.and"(%m_val6_not, %m_val7_not) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %m0_0123 = "transfer.and"(%m0_01, %m0_23) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %m0_4567 = "transfer.and"(%m0_45, %m0_67) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %m0_raw = "transfer.and"(%m0_0123, %m0_4567) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %m1_01 = "transfer.and"(%g_val0, %h_val1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %m1_23 = "transfer.and"(%m_val2, %m_val3) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %m1_45 = "transfer.and"(%m_val4, %m_val5) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %m1_67 = "transfer.and"(%m_val6, %h_val3) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %m1_0123 = "transfer.and"(%m1_01, %m1_23) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %m1_4567 = "transfer.and"(%m1_45, %m1_67) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %m1_raw = "transfer.and"(%m1_0123, %m1_4567) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %m0 = "transfer.select"(%lhs_const_rhs_three_unknown, %m0_raw, %const0) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %m1 = "transfer.select"(%lhs_const_rhs_three_unknown, %m1_raw, %const0) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer

    // rhs const, lhs has exactly 1 unknown bit.
    %rhs_const_lhs_one_unknown = "arith.andi"(%rhs_is_const, %lhs_one_unknown) : (i1, i1) -> i1
    %lhs_one_alt = "transfer.add"(%lhs1, %lhs_unknown_mask) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %i_val0_shl = "transfer.shl"(%lhs1, %rhs1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %i_val0_ov = "transfer.ushl_overflow"(%lhs1, %rhs1) {predicate = 9 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %i_val0 = "transfer.select"(%i_val0_ov, %all_ones, %i_val0_shl) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %i_val1_shl = "transfer.shl"(%lhs_one_alt, %rhs1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %i_val1_ov = "transfer.ushl_overflow"(%lhs_one_alt, %rhs1) {predicate = 9 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %i_val1 = "transfer.select"(%i_val1_ov, %all_ones, %i_val1_shl) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %i_val0_not = "transfer.xor"(%i_val0, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %i_val1_not = "transfer.xor"(%i_val1, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %i0_raw = "transfer.and"(%i_val0_not, %i_val1_not) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %i1_raw = "transfer.and"(%i_val0, %i_val1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %i0 = "transfer.select"(%rhs_const_lhs_one_unknown, %i0_raw, %const0) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %i1 = "transfer.select"(%rhs_const_lhs_one_unknown, %i1_raw, %const0) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer

    // rhs const, lhs has exactly 2 unknown bits.
    %rhs_const_lhs_two_unknown = "arith.andi"(%rhs_is_const, %lhs_two_unknown) : (i1, i1) -> i1
    %lhs_two_alt1 = "transfer.add"(%lhs1, %lhs_unknown_lowbit) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %lhs_two_alt2 = "transfer.add"(%lhs1, %lhs_unknown_rest) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %lhs_two_alt3 = "transfer.add"(%lhs1, %lhs_unknown_mask) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %j_val1_shl = "transfer.shl"(%lhs_two_alt1, %rhs1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %j_val1_ov = "transfer.ushl_overflow"(%lhs_two_alt1, %rhs1) {predicate = 9 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %j_val1 = "transfer.select"(%j_val1_ov, %all_ones, %j_val1_shl) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %j_val2_shl = "transfer.shl"(%lhs_two_alt2, %rhs1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %j_val2_ov = "transfer.ushl_overflow"(%lhs_two_alt2, %rhs1) {predicate = 9 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %j_val2 = "transfer.select"(%j_val2_ov, %all_ones, %j_val2_shl) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %j_val3_shl = "transfer.shl"(%lhs_two_alt3, %rhs1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %j_val3_ov = "transfer.ushl_overflow"(%lhs_two_alt3, %rhs1) {predicate = 9 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %j_val3 = "transfer.select"(%j_val3_ov, %all_ones, %j_val3_shl) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %j_val0_not = "transfer.xor"(%i_val0, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %j_val1_not = "transfer.xor"(%j_val1, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %j_val2_not = "transfer.xor"(%j_val2, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %j_val3_not = "transfer.xor"(%j_val3, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %j0_01 = "transfer.and"(%j_val0_not, %j_val1_not) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %j0_23 = "transfer.and"(%j_val2_not, %j_val3_not) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %j0_raw = "transfer.and"(%j0_01, %j0_23) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %j1_01 = "transfer.and"(%i_val0, %j_val1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %j1_23 = "transfer.and"(%j_val2, %j_val3) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %j1_raw = "transfer.and"(%j1_01, %j1_23) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %j0 = "transfer.select"(%rhs_const_lhs_two_unknown, %j0_raw, %const0) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %j1 = "transfer.select"(%rhs_const_lhs_two_unknown, %j1_raw, %const0) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer

    // lhs and rhs each have exactly 1 unknown bit.
    %n_val3_shl = "transfer.shl"(%lhs_one_alt, %rhs_one_alt) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %n_val3_ov = "transfer.ushl_overflow"(%lhs_one_alt, %rhs_one_alt) {predicate = 9 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %n_val3 = "transfer.select"(%n_val3_ov, %all_ones, %n_val3_shl) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %n_val0_not = "transfer.xor"(%i_val0, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %n_val1_not = "transfer.xor"(%g_val1, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %n_val2_not = "transfer.xor"(%i_val1, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %n_val3_not = "transfer.xor"(%n_val3, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %n0_01 = "transfer.and"(%n_val0_not, %n_val1_not) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %n0_23 = "transfer.and"(%n_val2_not, %n_val3_not) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %n0_raw = "transfer.and"(%n0_01, %n0_23) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %n1_01 = "transfer.and"(%i_val0, %g_val1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %n1_23 = "transfer.and"(%i_val1, %n_val3) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %n1_raw = "transfer.and"(%n1_01, %n1_23) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %n0 = "transfer.select"(%lhs_rhs_one_one, %n0_raw, %const0) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %n1 = "transfer.select"(%lhs_rhs_one_one, %n1_raw, %const0) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer

    %ab0 = "transfer.or"(%a0, %b0) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %abc0 = "transfer.or"(%ab0, %c0) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %abce0 = "transfer.or"(%abc0, %e0) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %abcef0 = "transfer.or"(%abce0, %f0) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %abcefg0 = "transfer.or"(%abcef0, %g0) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %abcefgh0 = "transfer.or"(%abcefg0, %h0) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %abcefghm0 = "transfer.or"(%abcefgh0, %m0) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %abcefghmi0 = "transfer.or"(%abcefghm0, %i0) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %abcefghmij0 = "transfer.or"(%abcefghmi0, %j0) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %res0 = "transfer.or"(%abcefghmij0, %n0) : (!transfer.integer, !transfer.integer) -> !transfer.integer

    %ab1 = "transfer.or"(%a1, %b1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %abc1 = "transfer.or"(%ab1, %c1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %abcd1 = "transfer.or"(%abc1, %d1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %abcdd1 = "transfer.or"(%abcd1, %d2) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %abcdf1 = "transfer.or"(%abcdd1, %f1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %abcdfg1 = "transfer.or"(%abcdf1, %g1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %abcdfgh1 = "transfer.or"(%abcdfg1, %h1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %abcdfghm1 = "transfer.or"(%abcdfgh1, %m1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %abcdfghmi1 = "transfer.or"(%abcdfghm1, %i1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %abcdfghmij1 = "transfer.or"(%abcdfghmi1, %j1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %res1 = "transfer.or"(%abcdfghmij1, %n1) : (!transfer.integer, !transfer.integer) -> !transfer.integer

    %r = "transfer.make"(%res0, %res1) : (!transfer.integer, !transfer.integer) -> !transfer.abs_value<[!transfer.integer, !transfer.integer]>
    "func.return"(%r) : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> ()
}) {"sym_name" = "kb_ushlsat", "function_type" = (!transfer.abs_value<[!transfer.integer, !transfer.integer]>, !transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.abs_value<[!transfer.integer, !transfer.integer]>} : () -> ()
