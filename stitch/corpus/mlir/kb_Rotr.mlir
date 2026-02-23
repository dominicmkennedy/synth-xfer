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
    %k = "transfer.urem"(%rhs1, %bitwidth) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %inv_k = "transfer.sub"(%bitwidth, %k) : (!transfer.integer, !transfer.integer) -> !transfer.integer

    %lhs0_lshr = "transfer.lshr"(%lhs0, %k) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %lhs0_shl = "transfer.shl"(%lhs0, %inv_k) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %const_res0 = "transfer.or"(%lhs0_lshr, %lhs0_shl) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %lhs1_lshr = "transfer.lshr"(%lhs1, %k) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %lhs1_shl = "transfer.shl"(%lhs1, %inv_k) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %const_res1 = "transfer.or"(%lhs1_lshr, %lhs1_shl) : (!transfer.integer, !transfer.integer) -> !transfer.integer

    %rhs1_not = "transfer.xor"(%rhs1, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %rhs_is_const = "transfer.cmp"(%rhs0, %rhs1_not) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1

    %rhs_known_union = "transfer.or"(%rhs0, %rhs1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %rhs_unknown_mask = "transfer.xor"(%rhs_known_union, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %rhs_unknown_nonzero = "transfer.cmp"(%rhs_unknown_mask, %const0) {predicate = 1 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %rhs_unknown_minus_1 = "transfer.sub"(%rhs_unknown_mask, %const1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %rhs_unknown_and_minus_1 = "transfer.and"(%rhs_unknown_mask, %rhs_unknown_minus_1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %rhs_unknown_pow2ish = "transfer.cmp"(%rhs_unknown_and_minus_1, %const0) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %rhs_one_unknown = "arith.andi"(%rhs_unknown_nonzero, %rhs_unknown_pow2ish) : (i1, i1) -> i1

    %rhs_alt = "transfer.add"(%rhs1, %rhs_unknown_mask) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %k_alt = "transfer.urem"(%rhs_alt, %bitwidth) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %inv_k_alt = "transfer.sub"(%bitwidth, %k_alt) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %lhs0_lshr_alt = "transfer.lshr"(%lhs0, %k_alt) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %lhs0_shl_alt = "transfer.shl"(%lhs0, %inv_k_alt) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %alt_res0 = "transfer.or"(%lhs0_lshr_alt, %lhs0_shl_alt) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %lhs1_lshr_alt = "transfer.lshr"(%lhs1, %k_alt) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %lhs1_shl_alt = "transfer.shl"(%lhs1, %inv_k_alt) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %alt_res1 = "transfer.or"(%lhs1_lshr_alt, %lhs1_shl_alt) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %one_unknown_res0_raw = "transfer.and"(%const_res0, %alt_res0) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %one_unknown_res1_raw = "transfer.and"(%const_res1, %alt_res1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %one_unknown_res0 = "transfer.select"(%rhs_one_unknown, %one_unknown_res0_raw, %const0) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %one_unknown_res1 = "transfer.select"(%rhs_one_unknown, %one_unknown_res1_raw, %const0) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer

    %res0_nonconst = "transfer.select"(%rhs_one_unknown, %one_unknown_res0, %const0) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %res1_nonconst = "transfer.select"(%rhs_one_unknown, %one_unknown_res1, %const0) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %res0_const_sel = "transfer.select"(%rhs_is_const, %const_res0, %res0_nonconst) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %res1_const_sel = "transfer.select"(%rhs_is_const, %const_res1, %res1_nonconst) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer

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

    %r = "transfer.make"(%res0, %res1) : (!transfer.integer, !transfer.integer) -> !transfer.abs_value<[!transfer.integer, !transfer.integer]>
    "func.return"(%r) : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> ()
}) {"sym_name" = "kb_rotr", "function_type" = (!transfer.abs_value<[!transfer.integer, !transfer.integer]>, !transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.abs_value<[!transfer.integer, !transfer.integer]>} : () -> ()
