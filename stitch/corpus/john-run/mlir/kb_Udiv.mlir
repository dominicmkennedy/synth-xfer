"func.func"() ({
  ^0(%lhs : !transfer.abs_value<[!transfer.integer, !transfer.integer]>, %rhs : !transfer.abs_value<[!transfer.integer, !transfer.integer]>):
    %lhs0 = "transfer.get"(%lhs) {index = 0} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %lhs1 = "transfer.get"(%lhs) {index = 1} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %rhs0 = "transfer.get"(%rhs) {index = 0} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %rhs1 = "transfer.get"(%rhs) {index = 1} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer

    %all_ones = "transfer.get_all_ones"(%lhs0) : (!transfer.integer) -> !transfer.integer
    %const0 = "transfer.constant"(%lhs0) {value = 0 : index} : (!transfer.integer) -> !transfer.integer
    %const1 = "transfer.constant"(%lhs0) {value = 1 : index} : (!transfer.integer) -> !transfer.integer
    %bitwidth = "transfer.get_bit_width"(%lhs0) : (!transfer.integer) -> !transfer.integer

    %lhs_conflict = "transfer.and"(%lhs0, %lhs1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %rhs_conflict = "transfer.and"(%rhs0, %rhs1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %lhs_consistent = "transfer.cmp"(%lhs_conflict, %const0) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %rhs_consistent = "transfer.cmp"(%rhs_conflict, %const0) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %inputs_consistent = "arith.andi"(%lhs_consistent, %rhs_consistent) : (i1, i1) -> i1

    %rhs0_all_ones = "transfer.cmp"(%rhs0, %all_ones) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %rhs1_is_zero = "transfer.cmp"(%rhs1, %const0) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %rhs0_not_all_ones = "transfer.cmp"(%rhs0, %all_ones) {predicate = 1 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %rhs1_nonzero = "transfer.cmp"(%rhs1, %const0) {predicate = 1 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %rhs_has_nonzero = "arith.ori"(%rhs0_not_all_ones, %rhs1_nonzero) : (i1, i1) -> i1
    %has_feasible_pair = "arith.andi"(%inputs_consistent, %rhs_has_nonzero) : (i1, i1) -> i1

    %lhs0_all_ones = "transfer.cmp"(%lhs0, %all_ones) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %lhs1_is_zero = "transfer.cmp"(%lhs1, %const0) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %lhs_is_zero = "arith.andi"(%lhs0_all_ones, %lhs1_is_zero) : (i1, i1) -> i1

    %not_const1 = "transfer.xor"(%const1, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %rhs0_is_not1 = "transfer.cmp"(%rhs0, %not_const1) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %rhs1_is_1 = "transfer.cmp"(%rhs1, %const1) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %rhs_is_one = "arith.andi"(%rhs0_is_not1, %rhs1_is_1) : (i1, i1) -> i1

    %lhs1_not = "transfer.xor"(%lhs1, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %lhs_is_const = "transfer.cmp"(%lhs0, %lhs1_not) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %rhs1_not = "transfer.xor"(%rhs1, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %rhs_is_const = "transfer.cmp"(%rhs0, %rhs1_not) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %both_const = "arith.andi"(%lhs_is_const, %rhs_is_const) : (i1, i1) -> i1

    %lhs_max = "transfer.xor"(%lhs0, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %rhs_max = "transfer.xor"(%rhs0, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %rhs_min_tz = "transfer.countr_one"(%rhs0) : (!transfer.integer) -> !transfer.integer
    %rhs_min_nonzero_pow2 = "transfer.shl"(%const1, %rhs_min_tz) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %rhs_min_nonzero = "transfer.select"(%rhs1_nonzero, %rhs1, %rhs_min_nonzero_pow2) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %rhs_max_is_zero = "transfer.cmp"(%rhs_max, %const0) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %rhs_max_safe = "transfer.select"(%rhs_max_is_zero, %const1, %rhs_max) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer

    %max_res = "transfer.udiv"(%lhs_max, %rhs_min_nonzero) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %min_res = "transfer.udiv"(%lhs1, %rhs_max_safe) : (!transfer.integer, !transfer.integer) -> !transfer.integer

    %max_res_lz = "transfer.countl_zero"(%max_res) : (!transfer.integer) -> !transfer.integer
    %max_res_lz_inv = "transfer.sub"(%bitwidth, %max_res_lz) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %high_zero_mask_raw = "transfer.shl"(%all_ones, %max_res_lz_inv) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %high_zero_mask = "transfer.select"(%has_feasible_pair, %high_zero_mask_raw, %const0) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer

    %range_valid_0 = "transfer.cmp"(%min_res, %max_res) {predicate = 7 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %range_valid = "arith.andi"(%has_feasible_pair, %range_valid_0) : (i1, i1) -> i1
    %range_diff = "transfer.xor"(%min_res, %max_res) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %range_common_lz = "transfer.countl_zero"(%range_diff) : (!transfer.integer) -> !transfer.integer
    %range_common_inv = "transfer.sub"(%bitwidth, %range_common_lz) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %range_common_mask = "transfer.shl"(%all_ones, %range_common_inv) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %min_res_not = "transfer.xor"(%min_res, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %range_res0_raw = "transfer.and"(%min_res_not, %range_common_mask) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %range_res1_raw = "transfer.and"(%min_res, %range_common_mask) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %range_res0 = "transfer.select"(%range_valid, %range_res0_raw, %const0) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %range_res1 = "transfer.select"(%range_valid, %range_res1_raw, %const0) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer

    %lhs_zero_feasible = "arith.andi"(%has_feasible_pair, %lhs_is_zero) : (i1, i1) -> i1
    %lhs_zero_res0 = "transfer.select"(%lhs_zero_feasible, %all_ones, %const0) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %lhs_zero_res1 = "transfer.select"(%lhs_zero_feasible, %const0, %const0) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer

    %rhs_one_feasible = "arith.andi"(%has_feasible_pair, %rhs_is_one) : (i1, i1) -> i1
    %rhs_one_res0 = "transfer.select"(%rhs_one_feasible, %lhs0, %const0) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %rhs_one_res1 = "transfer.select"(%rhs_one_feasible, %lhs1, %const0) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer

    %lhs_lt_rhs_0 = "transfer.cmp"(%lhs_max, %rhs_min_nonzero) {predicate = 6 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %lhs_lt_rhs = "arith.andi"(%has_feasible_pair, %lhs_lt_rhs_0) : (i1, i1) -> i1
    %lhs_lt_rhs_res0 = "transfer.select"(%lhs_lt_rhs, %all_ones, %const0) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %lhs_lt_rhs_res1 = "transfer.select"(%lhs_lt_rhs, %const0, %const0) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer

    %both_const_feasible = "arith.andi"(%has_feasible_pair, %both_const) : (i1, i1) -> i1
    %rhs_const_is_zero = "transfer.cmp"(%rhs1, %const0) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %rhs_const_safe = "transfer.select"(%rhs_const_is_zero, %const1, %rhs1) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %const_q = "transfer.udiv"(%lhs1, %rhs_const_safe) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %const_res0_raw = "transfer.xor"(%const_q, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %const_res0 = "transfer.select"(%both_const_feasible, %const_res0_raw, %const0) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %const_res1 = "transfer.select"(%both_const_feasible, %const_q, %const0) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer

    %res0_0 = "transfer.or"(%high_zero_mask, %range_res0) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %res0_1 = "transfer.or"(%res0_0, %lhs_zero_res0) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %res0_2 = "transfer.or"(%res0_1, %rhs_one_res0) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %res0_3 = "transfer.or"(%res0_2, %lhs_lt_rhs_res0) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %res0 = "transfer.or"(%res0_3, %const_res0) : (!transfer.integer, !transfer.integer) -> !transfer.integer

    %res1_0 = "transfer.or"(%range_res1, %lhs_zero_res1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %res1_1 = "transfer.or"(%res1_0, %rhs_one_res1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %res1_2 = "transfer.or"(%res1_1, %lhs_lt_rhs_res1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %res1 = "transfer.or"(%res1_2, %const_res1) : (!transfer.integer, !transfer.integer) -> !transfer.integer

    %res0_final = "transfer.select"(%has_feasible_pair, %res0, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %res1_final = "transfer.select"(%has_feasible_pair, %res1, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer

    %r = "transfer.make"(%res0_final, %res1_final) : (!transfer.integer, !transfer.integer) -> !transfer.abs_value<[!transfer.integer, !transfer.integer]>
    "func.return"(%r) : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> ()
}) {"sym_name" = "kb_udiv", "function_type" = (!transfer.abs_value<[!transfer.integer, !transfer.integer]>, !transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.abs_value<[!transfer.integer, !transfer.integer]>} : () -> ()
