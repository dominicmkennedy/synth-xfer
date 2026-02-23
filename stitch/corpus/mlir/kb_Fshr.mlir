"func.func"() ({
  ^0(%a : !transfer.abs_value<[!transfer.integer, !transfer.integer]>, %b : !transfer.abs_value<[!transfer.integer, !transfer.integer]>, %s : !transfer.abs_value<[!transfer.integer, !transfer.integer]>):
    %a0 = "transfer.get"(%a) {index = 0} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %a1 = "transfer.get"(%a) {index = 1} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %b0 = "transfer.get"(%b) {index = 0} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %b1 = "transfer.get"(%b) {index = 1} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %s0 = "transfer.get"(%s) {index = 0} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %s1 = "transfer.get"(%s) {index = 1} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer

    %all_ones = "transfer.get_all_ones"(%a0) : (!transfer.integer) -> !transfer.integer
    %const0 = "transfer.constant"(%a0) {value = 0 : index} : (!transfer.integer) -> !transfer.integer
    %const1 = "transfer.constant"(%a0) {value = 1 : index} : (!transfer.integer) -> !transfer.integer

    %a_conflict = "transfer.and"(%a0, %a1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %b_conflict = "transfer.and"(%b0, %b1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %s_conflict = "transfer.and"(%s0, %s1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %a_consistent = "transfer.cmp"(%a_conflict, %const0) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %b_consistent = "transfer.cmp"(%b_conflict, %const0) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %s_consistent = "transfer.cmp"(%s_conflict, %const0) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %ab_consistent = "arith.andi"(%a_consistent, %b_consistent) : (i1, i1) -> i1
    %has_feasible_pair = "arith.andi"(%ab_consistent, %s_consistent) : (i1, i1) -> i1

    %bitwidth = "transfer.get_bit_width"(%a0) : (!transfer.integer) -> !transfer.integer
    %k = "transfer.urem"(%s1, %bitwidth) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %inv_k = "transfer.sub"(%bitwidth, %k) : (!transfer.integer, !transfer.integer) -> !transfer.integer

    %a0_lshr = "transfer.lshr"(%a0, %k) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %b0_shl = "transfer.shl"(%b0, %inv_k) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %const_res0 = "transfer.or"(%a0_lshr, %b0_shl) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %a1_lshr = "transfer.lshr"(%a1, %k) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %b1_shl = "transfer.shl"(%b1, %inv_k) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %const_res1 = "transfer.or"(%a1_lshr, %b1_shl) : (!transfer.integer, !transfer.integer) -> !transfer.integer

    %s1_not = "transfer.xor"(%s1, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %s_is_const = "transfer.cmp"(%s0, %s1_not) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1

    %s_known_union = "transfer.or"(%s0, %s1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %s_unknown_mask = "transfer.xor"(%s_known_union, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %s_unknown_nonzero = "transfer.cmp"(%s_unknown_mask, %const0) {predicate = 1 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %s_unknown_minus_1 = "transfer.sub"(%s_unknown_mask, %const1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %s_unknown_and_minus_1 = "transfer.and"(%s_unknown_mask, %s_unknown_minus_1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %s_unknown_pow2ish = "transfer.cmp"(%s_unknown_and_minus_1, %const0) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %s_one_unknown = "arith.andi"(%s_unknown_nonzero, %s_unknown_pow2ish) : (i1, i1) -> i1

    %s_alt = "transfer.add"(%s1, %s_unknown_mask) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %k_alt = "transfer.urem"(%s_alt, %bitwidth) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %inv_k_alt = "transfer.sub"(%bitwidth, %k_alt) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %a0_lshr_alt = "transfer.lshr"(%a0, %k_alt) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %b0_shl_alt = "transfer.shl"(%b0, %inv_k_alt) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %alt_res0 = "transfer.or"(%a0_lshr_alt, %b0_shl_alt) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %a1_lshr_alt = "transfer.lshr"(%a1, %k_alt) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %b1_shl_alt = "transfer.shl"(%b1, %inv_k_alt) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %alt_res1 = "transfer.or"(%a1_lshr_alt, %b1_shl_alt) : (!transfer.integer, !transfer.integer) -> !transfer.integer

    %two_sel0_0 = "transfer.select"(%s_one_unknown, %const_res0, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %two_sel0_1 = "transfer.select"(%s_one_unknown, %alt_res0, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %two_acc0 = "transfer.and"(%two_sel0_0, %two_sel0_1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %two_case_res0 = "transfer.select"(%s_one_unknown, %two_acc0, %const0) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer

    %two_sel1_0 = "transfer.select"(%s_one_unknown, %const_res1, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %two_sel1_1 = "transfer.select"(%s_one_unknown, %alt_res1, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %two_acc1 = "transfer.and"(%two_sel1_0, %two_sel1_1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %two_case_res1 = "transfer.select"(%s_one_unknown, %two_acc1, %const0) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer

    %res0_const_sel = "transfer.select"(%s_is_const, %const_res0, %two_case_res0) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %res1_const_sel = "transfer.select"(%s_is_const, %const_res1, %two_case_res1) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer

    %a0_all_ones = "transfer.cmp"(%a0, %all_ones) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %a1_is_zero = "transfer.cmp"(%a1, %const0) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %a_is_zero = "arith.andi"(%a0_all_ones, %a1_is_zero) : (i1, i1) -> i1
    %b0_all_ones = "transfer.cmp"(%b0, %all_ones) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %b1_is_zero = "transfer.cmp"(%b1, %const0) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %b_is_zero = "arith.andi"(%b0_all_ones, %b1_is_zero) : (i1, i1) -> i1
    %both_zero = "arith.andi"(%a_is_zero, %b_is_zero) : (i1, i1) -> i1

    %a0_is_zero = "transfer.cmp"(%a0, %const0) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %a1_all_ones = "transfer.cmp"(%a1, %all_ones) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %a_is_all_ones = "arith.andi"(%a0_is_zero, %a1_all_ones) : (i1, i1) -> i1
    %b0_is_zero = "transfer.cmp"(%b0, %const0) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %b1_all_ones = "transfer.cmp"(%b1, %all_ones) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %b_is_all_ones = "arith.andi"(%b0_is_zero, %b1_all_ones) : (i1, i1) -> i1
    %both_all_ones = "arith.andi"(%a_is_all_ones, %b_is_all_ones) : (i1, i1) -> i1

    %res0_zero_sel = "transfer.select"(%both_zero, %all_ones, %res0_const_sel) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %res1_zero_sel = "transfer.select"(%both_zero, %const0, %res1_const_sel) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %res0 = "transfer.select"(%both_all_ones, %const0, %res0_zero_sel) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %res1 = "transfer.select"(%both_all_ones, %all_ones, %res1_zero_sel) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer

    %res0_final = "transfer.select"(%has_feasible_pair, %res0, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %res1_final = "transfer.select"(%has_feasible_pair, %res1, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer

    %r = "transfer.make"(%res0_final, %res1_final) : (!transfer.integer, !transfer.integer) -> !transfer.abs_value<[!transfer.integer, !transfer.integer]>
    "func.return"(%r) : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> ()
}) {"sym_name" = "kb_fshr", "function_type" = (!transfer.abs_value<[!transfer.integer, !transfer.integer]>, !transfer.abs_value<[!transfer.integer, !transfer.integer]>, !transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.abs_value<[!transfer.integer, !transfer.integer]>} : () -> ()
