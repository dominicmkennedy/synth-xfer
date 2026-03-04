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

    %lhs_max = "transfer.xor"(%lhs0, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %rhs_max = "transfer.xor"(%rhs0, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %min_ov = "transfer.uadd_overflow"(%lhs1, %rhs1) : (!transfer.integer, !transfer.integer) -> i1
    %max_ov = "transfer.uadd_overflow"(%lhs_max, %rhs_max) : (!transfer.integer, !transfer.integer) -> i1
    %never_ov = "arith.xori"(%max_ov, %const_true) : (i1, i1) -> i1
    %ov_ones = "transfer.select"(%min_ov, %all_ones, %const0) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer

    // KnownBits transfer for plain add.
    %sum_min = "transfer.add"(%lhs1, %rhs1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %sum_max = "transfer.add"(%lhs_max, %rhs_max) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %min_and = "transfer.and"(%lhs1, %rhs1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %min_or = "transfer.or"(%lhs1, %rhs1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %sum_min_not = "transfer.xor"(%sum_min, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %min_or_and_sum_not = "transfer.and"(%min_or, %sum_min_not) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %carry_out_min = "transfer.or"(%min_and, %min_or_and_sum_not) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %max_and = "transfer.and"(%lhs_max, %rhs_max) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %max_or = "transfer.or"(%lhs_max, %rhs_max) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %sum_max_not = "transfer.xor"(%sum_max, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %max_or_and_sum_not = "transfer.and"(%max_or, %sum_max_not) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %carry_out_max = "transfer.or"(%max_and, %max_or_and_sum_not) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %carry_one = "transfer.shl"(%carry_out_min, %const1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %carry_may_one = "transfer.shl"(%carry_out_max, %const1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %carry_zero = "transfer.xor"(%carry_may_one, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %xor0_lhs_rhs_00 = "transfer.and"(%lhs0, %rhs0) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %xor0_lhs_rhs_11 = "transfer.and"(%lhs1, %rhs1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %xor1_lhs_rhs_01 = "transfer.and"(%lhs0, %rhs1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %xor1_lhs_rhs_10 = "transfer.and"(%lhs1, %rhs0) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %xor_lhs_rhs_0 = "transfer.or"(%xor0_lhs_rhs_00, %xor0_lhs_rhs_11) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %xor_lhs_rhs_1 = "transfer.or"(%xor1_lhs_rhs_01, %xor1_lhs_rhs_10) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %xor0_sum_carry_00 = "transfer.and"(%xor_lhs_rhs_0, %carry_zero) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %xor0_sum_carry_11 = "transfer.and"(%xor_lhs_rhs_1, %carry_one) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %xor1_sum_carry_01 = "transfer.and"(%xor_lhs_rhs_0, %carry_one) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %xor1_sum_carry_10 = "transfer.and"(%xor_lhs_rhs_1, %carry_zero) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %add0 = "transfer.or"(%xor0_sum_carry_00, %xor0_sum_carry_11) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %add1 = "transfer.or"(%xor1_sum_carry_01, %xor1_sum_carry_10) : (!transfer.integer, !transfer.integer) -> !transfer.integer

    %sat0 = "transfer.select"(%never_ov, %add0, %const0) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %sat1_add = "transfer.or"(%add1, %ov_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer

    %id_res0_l = "transfer.select"(%lhs_is_zero, %rhs0, %const0) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %id_res1_l = "transfer.select"(%lhs_is_zero, %rhs1, %const0) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %id_res0 = "transfer.select"(%rhs_is_zero, %lhs0, %id_res0_l) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %id_res1 = "transfer.select"(%rhs_is_zero, %lhs1, %id_res1_l) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %res0_base = "transfer.or"(%sat0, %id_res0) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %res1_base = "transfer.or"(%sat1_add, %id_res1) : (!transfer.integer, !transfer.integer) -> !transfer.integer

    %const_add = "transfer.add"(%lhs1, %rhs1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %const_ov = "transfer.uadd_overflow"(%lhs1, %rhs1) : (!transfer.integer, !transfer.integer) -> i1
    %const_res1 = "transfer.select"(%const_ov, %all_ones, %const_add) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %const_res0 = "transfer.xor"(%const_res1, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %range_ub = "transfer.select"(%max_ov, %all_ones, %sum_max) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %range_diff = "transfer.xor"(%const_res1, %range_ub) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %common_lz = "transfer.countl_zero"(%range_diff) : (!transfer.integer) -> !transfer.integer
    %bitwidth = "transfer.get_bit_width"(%lhs0) : (!transfer.integer) -> !transfer.integer
    %common_inv = "transfer.sub"(%bitwidth, %common_lz) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %common_mask = "transfer.shl"(%all_ones, %common_inv) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %range0 = "transfer.and"(%const_res0, %common_mask) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %range1 = "transfer.and"(%const_res1, %common_mask) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    // Enumerate one/two unknown bits when one side is constant.
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
    %lhs_rhs_one_two = "arith.andi"(%lhs_one_unknown, %rhs_two_unknown) : (i1, i1) -> i1
    %lhs_rhs_two_one = "arith.andi"(%lhs_two_unknown, %rhs_one_unknown) : (i1, i1) -> i1
    %lhs_rhs_two_two = "arith.andi"(%lhs_two_unknown, %rhs_two_unknown) : (i1, i1) -> i1

    // lhs const, rhs one unknown.
    %lhs_const_rhs_one_unknown = "arith.andi"(%lhs_is_const, %rhs_one_unknown) : (i1, i1) -> i1
    %rhs_alt = "transfer.add"(%rhs1, %rhs_unknown_mask) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %g_val1_add = "transfer.add"(%lhs1, %rhs_alt) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %g_val1_ov = "transfer.uadd_overflow"(%lhs1, %rhs_alt) : (!transfer.integer, !transfer.integer) -> i1
    %g_val1 = "transfer.select"(%g_val1_ov, %all_ones, %g_val1_add) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %g_val0_not = "transfer.xor"(%const_res1, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %g_val1_not = "transfer.xor"(%g_val1, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %g0_raw = "transfer.and"(%g_val0_not, %g_val1_not) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %g1_raw = "transfer.and"(%const_res1, %g_val1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %g0 = "transfer.select"(%lhs_const_rhs_one_unknown, %g0_raw, %const0) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %g1 = "transfer.select"(%lhs_const_rhs_one_unknown, %g1_raw, %const0) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer

    // lhs const, rhs two unknown.
    %lhs_const_rhs_two_unknown = "arith.andi"(%lhs_is_const, %rhs_two_unknown) : (i1, i1) -> i1
    %rhs_alt1 = "transfer.add"(%rhs1, %rhs_unknown_lowbit) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %rhs_alt2 = "transfer.add"(%rhs1, %rhs_unknown_rest) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %rhs_alt3 = "transfer.add"(%rhs1, %rhs_unknown_mask) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %h_val1_add = "transfer.add"(%lhs1, %rhs_alt1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %h_val1_ov = "transfer.uadd_overflow"(%lhs1, %rhs_alt1) : (!transfer.integer, !transfer.integer) -> i1
    %h_val1 = "transfer.select"(%h_val1_ov, %all_ones, %h_val1_add) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %h_val2_add = "transfer.add"(%lhs1, %rhs_alt2) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %h_val2_ov = "transfer.uadd_overflow"(%lhs1, %rhs_alt2) : (!transfer.integer, !transfer.integer) -> i1
    %h_val2 = "transfer.select"(%h_val2_ov, %all_ones, %h_val2_add) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %h_val3_add = "transfer.add"(%lhs1, %rhs_alt3) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %h_val3_ov = "transfer.uadd_overflow"(%lhs1, %rhs_alt3) : (!transfer.integer, !transfer.integer) -> i1
    %h_val3 = "transfer.select"(%h_val3_ov, %all_ones, %h_val3_add) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %h_val0_not = "transfer.xor"(%const_res1, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %h_val1_not = "transfer.xor"(%h_val1, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %h_val2_not = "transfer.xor"(%h_val2, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %h_val3_not = "transfer.xor"(%h_val3, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %h0_01 = "transfer.and"(%h_val0_not, %h_val1_not) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %h0_23 = "transfer.and"(%h_val2_not, %h_val3_not) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %h0_raw = "transfer.and"(%h0_01, %h0_23) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %h1_01 = "transfer.and"(%const_res1, %h_val1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %h1_23 = "transfer.and"(%h_val2, %h_val3) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %h1_raw = "transfer.and"(%h1_01, %h1_23) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %h0 = "transfer.select"(%lhs_const_rhs_two_unknown, %h0_raw, %const0) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %h1 = "transfer.select"(%lhs_const_rhs_two_unknown, %h1_raw, %const0) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer

    // rhs const, lhs one unknown.
    %rhs_const_lhs_one_unknown = "arith.andi"(%rhs_is_const, %lhs_one_unknown) : (i1, i1) -> i1
    %lhs_alt = "transfer.add"(%lhs1, %lhs_unknown_mask) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %i_val1_add = "transfer.add"(%lhs_alt, %rhs1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %i_val1_ov = "transfer.uadd_overflow"(%lhs_alt, %rhs1) : (!transfer.integer, !transfer.integer) -> i1
    %i_val1 = "transfer.select"(%i_val1_ov, %all_ones, %i_val1_add) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %i_val0_not = "transfer.xor"(%const_res1, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %i_val1_not = "transfer.xor"(%i_val1, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %i0_raw = "transfer.and"(%i_val0_not, %i_val1_not) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %i1_raw = "transfer.and"(%const_res1, %i_val1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %i0 = "transfer.select"(%rhs_const_lhs_one_unknown, %i0_raw, %const0) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %i1 = "transfer.select"(%rhs_const_lhs_one_unknown, %i1_raw, %const0) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer

    // rhs const, lhs two unknown.
    %rhs_const_lhs_two_unknown = "arith.andi"(%rhs_is_const, %lhs_two_unknown) : (i1, i1) -> i1
    %lhs_alt1 = "transfer.add"(%lhs1, %lhs_unknown_lowbit) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %lhs_alt2 = "transfer.add"(%lhs1, %lhs_unknown_rest) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %lhs_alt3 = "transfer.add"(%lhs1, %lhs_unknown_mask) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %j_val1_add = "transfer.add"(%lhs_alt1, %rhs1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %j_val1_ov = "transfer.uadd_overflow"(%lhs_alt1, %rhs1) : (!transfer.integer, !transfer.integer) -> i1
    %j_val1 = "transfer.select"(%j_val1_ov, %all_ones, %j_val1_add) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %j_val2_add = "transfer.add"(%lhs_alt2, %rhs1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %j_val2_ov = "transfer.uadd_overflow"(%lhs_alt2, %rhs1) : (!transfer.integer, !transfer.integer) -> i1
    %j_val2 = "transfer.select"(%j_val2_ov, %all_ones, %j_val2_add) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %j_val3_add = "transfer.add"(%lhs_alt3, %rhs1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %j_val3_ov = "transfer.uadd_overflow"(%lhs_alt3, %rhs1) : (!transfer.integer, !transfer.integer) -> i1
    %j_val3 = "transfer.select"(%j_val3_ov, %all_ones, %j_val3_add) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %j_val0_not = "transfer.xor"(%const_res1, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %j_val1_not = "transfer.xor"(%j_val1, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %j_val2_not = "transfer.xor"(%j_val2, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %j_val3_not = "transfer.xor"(%j_val3, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %j0_01 = "transfer.and"(%j_val0_not, %j_val1_not) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %j0_23 = "transfer.and"(%j_val2_not, %j_val3_not) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %j0_raw = "transfer.and"(%j0_01, %j0_23) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %j1_01 = "transfer.and"(%const_res1, %j_val1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %j1_23 = "transfer.and"(%j_val2, %j_val3) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %j1_raw = "transfer.and"(%j1_01, %j1_23) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %j0 = "transfer.select"(%rhs_const_lhs_two_unknown, %j0_raw, %const0) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %j1 = "transfer.select"(%rhs_const_lhs_two_unknown, %j1_raw, %const0) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer

    // lhs one unknown, rhs one unknown.
    %n_val11_add = "transfer.add"(%lhs_alt, %rhs_alt) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %n_val11_ov = "transfer.uadd_overflow"(%lhs_alt, %rhs_alt) : (!transfer.integer, !transfer.integer) -> i1
    %n_val11 = "transfer.select"(%n_val11_ov, %all_ones, %n_val11_add) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %n_val00_not = "transfer.xor"(%const_res1, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %n_val01_not = "transfer.xor"(%g_val1, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %n_val10_not = "transfer.xor"(%i_val1, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %n_val11_not = "transfer.xor"(%n_val11, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %n0_01 = "transfer.and"(%n_val00_not, %n_val01_not) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %n0_23 = "transfer.and"(%n_val10_not, %n_val11_not) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %n0_raw = "transfer.and"(%n0_01, %n0_23) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %n1_01 = "transfer.and"(%const_res1, %g_val1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %n1_23 = "transfer.and"(%i_val1, %n_val11) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %n1_raw = "transfer.and"(%n1_01, %n1_23) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %n0 = "transfer.select"(%lhs_rhs_one_one, %n0_raw, %const0) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %n1 = "transfer.select"(%lhs_rhs_one_one, %n1_raw, %const0) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer

    // lhs one unknown, rhs two unknown.
    %p11_add = "transfer.add"(%lhs_alt, %rhs_alt1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %p11_ov = "transfer.uadd_overflow"(%lhs_alt, %rhs_alt1) : (!transfer.integer, !transfer.integer) -> i1
    %p11 = "transfer.select"(%p11_ov, %all_ones, %p11_add) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %p12_add = "transfer.add"(%lhs_alt, %rhs_alt2) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %p12_ov = "transfer.uadd_overflow"(%lhs_alt, %rhs_alt2) : (!transfer.integer, !transfer.integer) -> i1
    %p12 = "transfer.select"(%p12_ov, %all_ones, %p12_add) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %p13_add = "transfer.add"(%lhs_alt, %rhs_alt3) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %p13_ov = "transfer.uadd_overflow"(%lhs_alt, %rhs_alt3) : (!transfer.integer, !transfer.integer) -> i1
    %p13 = "transfer.select"(%p13_ov, %all_ones, %p13_add) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %p00_not = "transfer.xor"(%const_res1, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %p01_not = "transfer.xor"(%h_val1, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %p02_not = "transfer.xor"(%h_val2, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %p03_not = "transfer.xor"(%h_val3, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %p10_not = "transfer.xor"(%i_val1, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %p11_not = "transfer.xor"(%p11, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %p12_not = "transfer.xor"(%p12, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %p13_not = "transfer.xor"(%p13, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %p0_01 = "transfer.and"(%p00_not, %p01_not) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %p0_23 = "transfer.and"(%p02_not, %p03_not) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %p0_45 = "transfer.and"(%p10_not, %p11_not) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %p0_67 = "transfer.and"(%p12_not, %p13_not) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %p0_0123 = "transfer.and"(%p0_01, %p0_23) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %p0_4567 = "transfer.and"(%p0_45, %p0_67) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %p0_raw = "transfer.and"(%p0_0123, %p0_4567) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %p1_01 = "transfer.and"(%const_res1, %h_val1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %p1_23 = "transfer.and"(%h_val2, %h_val3) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %p1_45 = "transfer.and"(%i_val1, %p11) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %p1_67 = "transfer.and"(%p12, %p13) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %p1_0123 = "transfer.and"(%p1_01, %p1_23) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %p1_4567 = "transfer.and"(%p1_45, %p1_67) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %p1_raw = "transfer.and"(%p1_0123, %p1_4567) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %p0 = "transfer.select"(%lhs_rhs_one_two, %p0_raw, %const0) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %p1 = "transfer.select"(%lhs_rhs_one_two, %p1_raw, %const0) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer

    // lhs two unknown, rhs one unknown.
    %q11_add = "transfer.add"(%lhs_alt1, %rhs_alt) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %q11_ov = "transfer.uadd_overflow"(%lhs_alt1, %rhs_alt) : (!transfer.integer, !transfer.integer) -> i1
    %q11 = "transfer.select"(%q11_ov, %all_ones, %q11_add) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %q12_add = "transfer.add"(%lhs_alt2, %rhs_alt) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %q12_ov = "transfer.uadd_overflow"(%lhs_alt2, %rhs_alt) : (!transfer.integer, !transfer.integer) -> i1
    %q12 = "transfer.select"(%q12_ov, %all_ones, %q12_add) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %q13_add = "transfer.add"(%lhs_alt3, %rhs_alt) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %q13_ov = "transfer.uadd_overflow"(%lhs_alt3, %rhs_alt) : (!transfer.integer, !transfer.integer) -> i1
    %q13 = "transfer.select"(%q13_ov, %all_ones, %q13_add) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %q00_not = "transfer.xor"(%const_res1, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %q01_not = "transfer.xor"(%g_val1, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %q02_not = "transfer.xor"(%j_val1, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %q03_not = "transfer.xor"(%j_val2, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %q04_not = "transfer.xor"(%j_val3, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %q05_not = "transfer.xor"(%q11, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %q06_not = "transfer.xor"(%q12, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %q07_not = "transfer.xor"(%q13, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %q0_01 = "transfer.and"(%q00_not, %q01_not) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %q0_23 = "transfer.and"(%q02_not, %q03_not) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %q0_45 = "transfer.and"(%q04_not, %q05_not) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %q0_67 = "transfer.and"(%q06_not, %q07_not) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %q0_0123 = "transfer.and"(%q0_01, %q0_23) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %q0_4567 = "transfer.and"(%q0_45, %q0_67) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %q0_raw = "transfer.and"(%q0_0123, %q0_4567) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %q1_01 = "transfer.and"(%const_res1, %g_val1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %q1_23 = "transfer.and"(%j_val1, %j_val2) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %q1_45 = "transfer.and"(%j_val3, %q11) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %q1_67 = "transfer.and"(%q12, %q13) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %q1_0123 = "transfer.and"(%q1_01, %q1_23) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %q1_4567 = "transfer.and"(%q1_45, %q1_67) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %q1_raw = "transfer.and"(%q1_0123, %q1_4567) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %q0 = "transfer.select"(%lhs_rhs_two_one, %q0_raw, %const0) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %q1 = "transfer.select"(%lhs_rhs_two_one, %q1_raw, %const0) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer

    // lhs two unknown, rhs two unknown.
    %r21_add = "transfer.add"(%lhs_alt2, %rhs_alt1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %r21_ov = "transfer.uadd_overflow"(%lhs_alt2, %rhs_alt1) : (!transfer.integer, !transfer.integer) -> i1
    %r21 = "transfer.select"(%r21_ov, %all_ones, %r21_add) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %r22_add = "transfer.add"(%lhs_alt2, %rhs_alt2) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %r22_ov = "transfer.uadd_overflow"(%lhs_alt2, %rhs_alt2) : (!transfer.integer, !transfer.integer) -> i1
    %r22 = "transfer.select"(%r22_ov, %all_ones, %r22_add) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %r23_add = "transfer.add"(%lhs_alt2, %rhs_alt3) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %r23_ov = "transfer.uadd_overflow"(%lhs_alt2, %rhs_alt3) : (!transfer.integer, !transfer.integer) -> i1
    %r23 = "transfer.select"(%r23_ov, %all_ones, %r23_add) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %r31_add = "transfer.add"(%lhs_alt3, %rhs_alt1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %r31_ov = "transfer.uadd_overflow"(%lhs_alt3, %rhs_alt1) : (!transfer.integer, !transfer.integer) -> i1
    %r31 = "transfer.select"(%r31_ov, %all_ones, %r31_add) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %r32_add = "transfer.add"(%lhs_alt3, %rhs_alt2) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %r32_ov = "transfer.uadd_overflow"(%lhs_alt3, %rhs_alt2) : (!transfer.integer, !transfer.integer) -> i1
    %r32 = "transfer.select"(%r32_ov, %all_ones, %r32_add) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %r33_add = "transfer.add"(%lhs_alt3, %rhs_alt3) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %r33_ov = "transfer.uadd_overflow"(%lhs_alt3, %rhs_alt3) : (!transfer.integer, !transfer.integer) -> i1
    %r33 = "transfer.select"(%r33_ov, %all_ones, %r33_add) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %r00_not = "transfer.xor"(%const_res1, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %r01_not = "transfer.xor"(%h_val1, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %r02_not = "transfer.xor"(%h_val2, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %r03_not = "transfer.xor"(%h_val3, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %r10_not = "transfer.xor"(%j_val1, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %r11_not = "transfer.xor"(%p11, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %r12_not = "transfer.xor"(%p12, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %r13_not = "transfer.xor"(%p13, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %r20_not = "transfer.xor"(%j_val2, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %r21_not = "transfer.xor"(%r21, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %r22_not = "transfer.xor"(%r22, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %r23_not = "transfer.xor"(%r23, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %r30_not = "transfer.xor"(%j_val3, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %r31_not = "transfer.xor"(%r31, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %r32_not = "transfer.xor"(%r32, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %r33_not = "transfer.xor"(%r33, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %r0_01 = "transfer.and"(%r00_not, %r01_not) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %r0_23 = "transfer.and"(%r02_not, %r03_not) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %r0_45 = "transfer.and"(%r10_not, %r11_not) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %r0_67 = "transfer.and"(%r12_not, %r13_not) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %r0_89 = "transfer.and"(%r20_not, %r21_not) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %r0_1011 = "transfer.and"(%r22_not, %r23_not) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %r0_1213 = "transfer.and"(%r30_not, %r31_not) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %r0_1415 = "transfer.and"(%r32_not, %r33_not) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %r0_0123 = "transfer.and"(%r0_01, %r0_23) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %r0_4567 = "transfer.and"(%r0_45, %r0_67) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %r0_891011 = "transfer.and"(%r0_89, %r0_1011) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %r0_12131415 = "transfer.and"(%r0_1213, %r0_1415) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %r0_0to7 = "transfer.and"(%r0_0123, %r0_4567) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %r0_8to15 = "transfer.and"(%r0_891011, %r0_12131415) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %r0_raw = "transfer.and"(%r0_0to7, %r0_8to15) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %r1_01 = "transfer.and"(%const_res1, %h_val1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %r1_23 = "transfer.and"(%h_val2, %h_val3) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %r1_45 = "transfer.and"(%j_val1, %p11) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %r1_67 = "transfer.and"(%p12, %p13) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %r1_89 = "transfer.and"(%j_val2, %r21) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %r1_1011 = "transfer.and"(%r22, %r23) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %r1_1213 = "transfer.and"(%j_val3, %r31) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %r1_1415 = "transfer.and"(%r32, %r33) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %r1_0123 = "transfer.and"(%r1_01, %r1_23) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %r1_4567 = "transfer.and"(%r1_45, %r1_67) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %r1_891011 = "transfer.and"(%r1_89, %r1_1011) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %r1_12131415 = "transfer.and"(%r1_1213, %r1_1415) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %r1_0to7 = "transfer.and"(%r1_0123, %r1_4567) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %r1_8to15 = "transfer.and"(%r1_891011, %r1_12131415) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %r1_raw = "transfer.and"(%r1_0to7, %r1_8to15) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %r0 = "transfer.select"(%lhs_rhs_two_two, %r0_raw, %const0) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %r1 = "transfer.select"(%lhs_rhs_two_two, %r1_raw, %const0) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer

    %res0_g = "transfer.or"(%res0_base, %g0) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %res0_h = "transfer.or"(%res0_g, %h0) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %res0_i = "transfer.or"(%res0_h, %i0) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %res0_j = "transfer.or"(%res0_i, %j0) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %res0_n = "transfer.or"(%res0_j, %n0) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %res0_p = "transfer.or"(%res0_n, %p0) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %res0_q = "transfer.or"(%res0_p, %q0) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %res0_r = "transfer.or"(%res0_q, %r0) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %res1_g = "transfer.or"(%res1_base, %g1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %res1_h = "transfer.or"(%res1_g, %h1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %res1_i = "transfer.or"(%res1_h, %i1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %res1_j = "transfer.or"(%res1_i, %j1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %res1_n = "transfer.or"(%res1_j, %n1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %res1_p = "transfer.or"(%res1_n, %p1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %res1_q = "transfer.or"(%res1_p, %q1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %res1_r = "transfer.or"(%res1_q, %r1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %res0_range = "transfer.or"(%res0_r, %range0) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %res1_range = "transfer.or"(%res1_r, %range1) : (!transfer.integer, !transfer.integer) -> !transfer.integer

    %res0 = "transfer.select"(%both_const, %const_res0, %res0_range) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %res1 = "transfer.select"(%both_const, %const_res1, %res1_range) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer

    %r = "transfer.make"(%res0, %res1) : (!transfer.integer, !transfer.integer) -> !transfer.abs_value<[!transfer.integer, !transfer.integer]>
    "func.return"(%r) : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> ()
}) {"sym_name" = "kb_uaddsat", "function_type" = (!transfer.abs_value<[!transfer.integer, !transfer.integer]>, !transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.abs_value<[!transfer.integer, !transfer.integer]>} : () -> ()
