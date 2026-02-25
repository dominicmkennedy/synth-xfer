"func.func"() ({
  ^0(%lhs : !transfer.abs_value<[!transfer.integer, !transfer.integer]>, %rhs : !transfer.abs_value<[!transfer.integer, !transfer.integer]>):
    %lhs0 = "transfer.get"(%lhs) {index = 0} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %lhs1 = "transfer.get"(%lhs) {index = 1} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %rhs0 = "transfer.get"(%rhs) {index = 0} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %rhs1 = "transfer.get"(%rhs) {index = 1} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %const0 = "transfer.constant"(%lhs0) {value = 0 : index} : (!transfer.integer) -> !transfer.integer
    %const1 = "transfer.constant"(%lhs0) {value = 1 : index} : (!transfer.integer) -> !transfer.integer
    %const2 = "transfer.constant"(%lhs0) {value = 2 : index} : (!transfer.integer) -> !transfer.integer
    %const4 = "transfer.constant"(%lhs0) {value = 4 : index} : (!transfer.integer) -> !transfer.integer
    %const8 = "transfer.constant"(%lhs0) {value = 8 : index} : (!transfer.integer) -> !transfer.integer
    %const16 = "transfer.constant"(%lhs0) {value = 16 : index} : (!transfer.integer) -> !transfer.integer
    %const32 = "transfer.constant"(%lhs0) {value = 32 : index} : (!transfer.integer) -> !transfer.integer
    %const_all_ones = "transfer.get_all_ones"(%lhs0) : (!transfer.integer) -> !transfer.integer
    %bw = "transfer.get_bit_width"(%lhs0) : (!transfer.integer) -> !transfer.integer
    %clz_bw = "transfer.countl_zero"(%bw) : (!transfer.integer) -> !transfer.integer
    %bw_high_zero = "transfer.set_high_bits"(%const0, %clz_bw) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %rhs0_ref = "transfer.or"(%rhs0, %bw_high_zero) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %rhs_known = "transfer.or"(%rhs0_ref, %rhs1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %rhs_unknown = "transfer.xor"(%const_all_ones, %rhs_known) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %rhs_min = "transfer.or"(%rhs1, %const0) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %rhs_max = "transfer.or"(%rhs1, %rhs_unknown) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %is_const = "transfer.cmp"(%rhs_known, %const_all_ones) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %lhs0_shl = "transfer.shl"(%lhs0, %rhs1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %lhs1_shl = "transfer.shl"(%lhs1, %rhs1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %lowmask_const = "transfer.set_low_bits"(%const0, %rhs1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %res0_const = "transfer.or"(%lhs0_shl, %lowmask_const) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %res1_const = "transfer.or"(%lhs1_shl, %const0) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %lo_lhs1 = "transfer.countl_one"(%lhs1) : (!transfer.integer) -> !transfer.integer
    %cmp_lo = "transfer.cmp"(%lo_lhs1, %rhs_max) {predicate = 9 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %lo_minus = "transfer.sub"(%lo_lhs1, %rhs_max) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %lo_sat = "transfer.select"(%cmp_lo, %lo_minus, %const0) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %highmask_one = "transfer.set_high_bits"(%const0, %lo_sat) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %lhs_possible_one = "transfer.xor"(%const_all_ones, %lhs0) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %base = "transfer.shl"(%lhs_possible_one, %rhs_min) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %delta_raw = "transfer.sub"(%rhs_max, %rhs_min) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %bw_minus_one = "transfer.sub"(%bw, %const1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %delta = "transfer.umin"(%delta_raw, %bw_minus_one) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %d1 = "transfer.and"(%delta, %const1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %c1 = "transfer.cmp"(%d1, %const0) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %s1 = "transfer.shl"(%base, %const1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %o1 = "transfer.or"(%base, %s1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %y1 = "transfer.select"(%c1, %base, %o1) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %d2 = "transfer.and"(%delta, %const2) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %c2 = "transfer.cmp"(%d2, %const0) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %s2 = "transfer.shl"(%y1, %const2) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %o2 = "transfer.or"(%y1, %s2) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %y2 = "transfer.select"(%c2, %y1, %o2) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %d4 = "transfer.and"(%delta, %const4) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %c4 = "transfer.cmp"(%d4, %const0) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %s4 = "transfer.shl"(%y2, %const4) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %o4 = "transfer.or"(%y2, %s4) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %y4 = "transfer.select"(%c4, %y2, %o4) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %d8 = "transfer.and"(%delta, %const8) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %c8 = "transfer.cmp"(%d8, %const0) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %s8 = "transfer.shl"(%y4, %const8) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %o8 = "transfer.or"(%y4, %s8) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %y8 = "transfer.select"(%c8, %y4, %o8) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %d16 = "transfer.and"(%delta, %const16) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %c16 = "transfer.cmp"(%d16, %const0) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %s16 = "transfer.shl"(%y8, %const16) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %o16 = "transfer.or"(%y8, %s16) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %y16 = "transfer.select"(%c16, %y8, %o16) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %d32 = "transfer.and"(%delta, %const32) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %c32 = "transfer.cmp"(%d32, %const0) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %s32 = "transfer.shl"(%y16, %const32) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %o32 = "transfer.or"(%y16, %s32) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %y32 = "transfer.select"(%c32, %y16, %o32) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %res0_non = "transfer.xor"(%const_all_ones, %y32) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %res1_non = "transfer.or"(%highmask_one, %const0) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %res0 = "transfer.select"(%is_const, %res0_const, %res0_non) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %res1 = "transfer.select"(%is_const, %res1_const, %res1_non) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %r = "transfer.make"(%res0, %res1) : (!transfer.integer, !transfer.integer) -> !transfer.abs_value<[!transfer.integer, !transfer.integer]>
    "func.return"(%r) : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> ()
}) {"sym_name" = "kb_shl", "function_type" = (!transfer.abs_value<[!transfer.integer, !transfer.integer]>, !transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.abs_value<[!transfer.integer, !transfer.integer]>} : () -> ()