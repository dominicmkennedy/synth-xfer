"func.func"() ({
  ^0(%lhs : !transfer.abs_value<[!transfer.integer, !transfer.integer]>, %rhs : !transfer.abs_value<[!transfer.integer, !transfer.integer]>):
    %lhs0 = "transfer.get"(%lhs) {index = 0} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %lhs1 = "transfer.get"(%lhs) {index = 1} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %rhs0 = "transfer.get"(%rhs) {index = 0} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %rhs1 = "transfer.get"(%rhs) {index = 1} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %const0 = "transfer.constant"(%lhs0) {value = 0 : index} : (!transfer.integer) -> !transfer.integer
    %const1 = "transfer.constant"(%lhs0) {value = 1 : index} : (!transfer.integer) -> !transfer.integer
    %const_all_ones = "transfer.get_all_ones"(%lhs0) : (!transfer.integer) -> !transfer.integer
    %bw = "transfer.get_bit_width"(%lhs0) : (!transfer.integer) -> !transfer.integer
    %true = "transfer.cmp"(%const0, %const0) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %lhs_known = "transfer.or"(%lhs0, %lhs1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %rhs_known = "transfer.or"(%rhs0, %rhs1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %lhs_full = "transfer.cmp"(%lhs_known, %const_all_ones) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %rhs_full = "transfer.cmp"(%rhs_known, %const_all_ones) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %lhs1_zero = "transfer.cmp"(%lhs1, %const0) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %rhs1_zero = "transfer.cmp"(%rhs1, %const0) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %lhs_is_zero = "arith.andi"(%lhs_full, %lhs1_zero) : (i1, i1) -> i1
    %rhs_is_zero = "arith.andi"(%rhs_full, %rhs1_zero) : (i1, i1) -> i1
    %either_zero = "arith.ori"(%lhs_is_zero, %rhs_is_zero) : (i1, i1) -> i1
    %lhs1_minus1 = "transfer.sub"(%lhs1, %const1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %rhs1_minus1 = "transfer.sub"(%rhs1, %const1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %lhs1_and = "transfer.and"(%lhs1, %lhs1_minus1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %rhs1_and = "transfer.and"(%rhs1, %rhs1_minus1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %lhs1_and_zero = "transfer.cmp"(%lhs1_and, %const0) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %rhs1_and_zero = "transfer.cmp"(%rhs1_and, %const0) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %lhs1_nonzero = "arith.xori"(%lhs1_zero, %true) : (i1, i1) -> i1
    %rhs1_nonzero = "arith.xori"(%rhs1_zero, %true) : (i1, i1) -> i1
    %lhs_pow2_pre = "arith.andi"(%lhs1_and_zero, %lhs1_nonzero) : (i1, i1) -> i1
    %rhs_pow2_pre = "arith.andi"(%rhs1_and_zero, %rhs1_nonzero) : (i1, i1) -> i1
    %lhs_pow2 = "arith.andi"(%lhs_full, %lhs_pow2_pre) : (i1, i1) -> i1
    %rhs_pow2 = "arith.andi"(%rhs_full, %rhs_pow2_pre) : (i1, i1) -> i1
    %exact = "arith.andi"(%lhs_full, %rhs_full) : (i1, i1) -> i1
    %exact_val = "transfer.mul"(%lhs1, %rhs1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %res0_exact = "transfer.xor"(%exact_val, %const_all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %res1_exact = "transfer.or"(%exact_val, %const0) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %tz_lhs = "transfer.countr_one"(%lhs0) : (!transfer.integer) -> !transfer.integer
    %tz_rhs = "transfer.countr_one"(%rhs0) : (!transfer.integer) -> !transfer.integer
    %tz_sum = "transfer.add"(%tz_lhs, %tz_rhs) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %tz_cap = "transfer.umin"(%tz_sum, %bw) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %mask_low = "transfer.set_low_bits"(%const0, %tz_cap) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %lz_lhs = "transfer.countl_one"(%lhs0) : (!transfer.integer) -> !transfer.integer
    %lz_rhs = "transfer.countl_one"(%rhs0) : (!transfer.integer) -> !transfer.integer
    %lz_sum = "transfer.add"(%lz_lhs, %lz_rhs) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %lz_sum_minus_bw = "transfer.sub"(%lz_sum, %bw) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %lz_prod = "transfer.smax"(%lz_sum_minus_bw, %const0) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %mask_high = "transfer.set_high_bits"(%const0, %lz_prod) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %lhs_known_low = "transfer.countr_one"(%lhs_known) : (!transfer.integer) -> !transfer.integer
    %rhs_known_low = "transfer.countr_one"(%rhs_known) : (!transfer.integer) -> !transfer.integer
    %known_low = "transfer.umin"(%lhs_known_low, %rhs_known_low) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %low_mask = "transfer.set_low_bits"(%const0, %known_low) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %lhs_low = "transfer.and"(%lhs1, %low_mask) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %rhs_low = "transfer.and"(%rhs1, %low_mask) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %prod_low = "transfer.mul"(%lhs_low, %rhs_low) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %prod_low_mask = "transfer.and"(%prod_low, %low_mask) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %low_zero = "transfer.xor"(%prod_low_mask, %low_mask) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %base0_pre = "transfer.or"(%mask_low, %mask_high) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %base0 = "transfer.or"(%base0_pre, %low_zero) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %base1 = "transfer.or"(%prod_low_mask, %const0) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %lhs_shift = "transfer.countr_zero"(%lhs1) : (!transfer.integer) -> !transfer.integer
    %rhs_shift = "transfer.countr_zero"(%rhs1) : (!transfer.integer) -> !transfer.integer
    %lhs0_shl = "transfer.shl"(%rhs0, %lhs_shift) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %lhs1_shl = "transfer.shl"(%rhs1, %lhs_shift) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %rhs0_shl = "transfer.shl"(%lhs0, %rhs_shift) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %rhs1_shl = "transfer.shl"(%lhs1, %rhs_shift) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %lhs_mask_low = "transfer.set_low_bits"(%const0, %lhs_shift) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %rhs_mask_low = "transfer.set_low_bits"(%const0, %rhs_shift) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %lhs0_pow2 = "transfer.or"(%lhs0_shl, %lhs_mask_low) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %rhs0_pow2 = "transfer.or"(%rhs0_shl, %rhs_mask_low) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %res0_r1 = "transfer.select"(%rhs_pow2, %rhs0_pow2, %base0) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %res1_r1 = "transfer.select"(%rhs_pow2, %rhs1_shl, %base1) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %res0_r2 = "transfer.select"(%lhs_pow2, %lhs0_pow2, %res0_r1) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %res1_r2 = "transfer.select"(%lhs_pow2, %lhs1_shl, %res1_r1) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %res0_r3 = "transfer.select"(%either_zero, %const_all_ones, %res0_r2) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %res1_r3 = "transfer.select"(%either_zero, %const0, %res1_r2) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %res0 = "transfer.select"(%exact, %res0_exact, %res0_r3) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %res1 = "transfer.select"(%exact, %res1_exact, %res1_r3) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %r = "transfer.make"(%res0, %res1) : (!transfer.integer, !transfer.integer) -> !transfer.abs_value<[!transfer.integer, !transfer.integer]>
    "func.return"(%r) : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> ()
}) {"sym_name" = "kb_mul", "function_type" = (!transfer.abs_value<[!transfer.integer, !transfer.integer]>, !transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.abs_value<[!transfer.integer, !transfer.integer]>} : () -> ()