"func.func"() ({
  ^0(%lhs : !transfer.abs_value<[!transfer.integer, !transfer.integer]>, %rhs : !transfer.abs_value<[!transfer.integer, !transfer.integer]>):
    %lhs0 = "transfer.get"(%lhs) {index = 0} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %lhs1 = "transfer.get"(%lhs) {index = 1} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %rhs0 = "transfer.get"(%rhs) {index = 0} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %rhs1 = "transfer.get"(%rhs) {index = 1} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer

    %all_ones = "transfer.get_all_ones"(%lhs0) : (!transfer.integer) -> !transfer.integer
    %const1 = "transfer.constant"(%lhs0) {value = 1 : index} : (!transfer.integer) -> !transfer.integer
    %bitwidth = "transfer.get_bit_width"(%lhs0) : (!transfer.integer) -> !transfer.integer
    %const_true = "arith.constant"() {value = 1 : i1} : () -> i1

    %lhs_max = "transfer.xor"(%lhs0, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %rhs_max = "transfer.xor"(%rhs0, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer

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
    %base0 = "transfer.or"(%xor0_sum_carry_00, %xor0_sum_carry_11) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %base1 = "transfer.or"(%xor1_sum_carry_01, %xor1_sum_carry_10) : (!transfer.integer, !transfer.integer) -> !transfer.integer

    %nuw_lower = "transfer.add"(%lhs1, %rhs1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %nuw_lower_ov = "transfer.uadd_overflow"(%lhs1, %rhs1) : (!transfer.integer, !transfer.integer) -> i1
    %nuw_exists = "arith.xori"(%nuw_lower_ov, %const_true) : (i1, i1) -> i1
    %nuw_upper_sum = "transfer.add"(%lhs_max, %rhs_max) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %nuw_upper_ov = "transfer.uadd_overflow"(%lhs_max, %rhs_max) : (!transfer.integer, !transfer.integer) -> i1
    %nuw_upper = "transfer.select"(%nuw_upper_ov, %all_ones, %nuw_upper_sum) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer

    %nuw_diff = "transfer.xor"(%nuw_lower, %nuw_upper) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %nuw_lz = "transfer.countl_zero"(%nuw_diff) : (!transfer.integer) -> !transfer.integer
    %nuw_shift = "transfer.sub"(%bitwidth, %nuw_lz) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %nuw_mask = "transfer.shl"(%all_ones, %nuw_shift) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %nuw_not_low = "transfer.xor"(%nuw_lower, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %nuw_k0 = "transfer.and"(%nuw_not_low, %nuw_mask) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %nuw_k1 = "transfer.and"(%nuw_lower, %nuw_mask) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %nuw_k0_use = "transfer.select"(%nuw_exists, %nuw_k0, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %nuw_k1_use = "transfer.select"(%nuw_exists, %nuw_k1, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer

    %res0 = "transfer.or"(%base0, %nuw_k0_use) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %res1 = "transfer.or"(%base1, %nuw_k1_use) : (!transfer.integer, !transfer.integer) -> !transfer.integer

    %r = "transfer.make"(%res0, %res1) : (!transfer.integer, !transfer.integer) -> !transfer.abs_value<[!transfer.integer, !transfer.integer]>
    "func.return"(%r) : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> ()
}) {"sym_name" = "kb_addnuw", "function_type" = (!transfer.abs_value<[!transfer.integer, !transfer.integer]>, !transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.abs_value<[!transfer.integer, !transfer.integer]>} : () -> ()
