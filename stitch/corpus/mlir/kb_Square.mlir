"func.func"() ({
  ^0(%arg : !transfer.abs_value<[!transfer.integer, !transfer.integer]>):
    %x0 = "transfer.get"(%arg) {index = 0} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %x1 = "transfer.get"(%arg) {index = 1} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer

    %all_ones = "transfer.get_all_ones"(%x0) : (!transfer.integer) -> !transfer.integer
    %const0 = "transfer.constant"(%x0) {value = 0 : index} : (!transfer.integer) -> !transfer.integer
    %const1 = "transfer.constant"(%x0) {value = 1 : index} : (!transfer.integer) -> !transfer.integer
    %bitwidth = "transfer.get_bit_width"(%x0) : (!transfer.integer) -> !transfer.integer
    %bit1_mask_raw = "transfer.shl"(%const1, %const1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %bw_gt_1 = "transfer.cmp"(%const1, %bitwidth) {predicate = 6 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %bit1_mask = "transfer.select"(%bw_gt_1, %bit1_mask_raw, %const0) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %bit2_mask = "transfer.shl"(%bit1_mask_raw, %const1) : (!transfer.integer, !transfer.integer) -> !transfer.integer

    // Fallback: trailing-zero and low-bit facts that hold for all squares.
    %min_tz = "transfer.countr_one"(%x0) : (!transfer.integer) -> !transfer.integer
    %tz2 = "transfer.add"(%min_tz, %min_tz) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %tz2_le_bw = "transfer.cmp"(%tz2, %bitwidth) {predicate = 6 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %tz2_clamped = "transfer.select"(%tz2_le_bw, %tz2, %bitwidth) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %tz2_inv = "transfer.sub"(%bitwidth, %tz2_clamped) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %low_zero_mask = "transfer.lshr"(%all_ones, %tz2_inv) : (!transfer.integer, !transfer.integer) -> !transfer.integer

    %lsb_one = "transfer.and"(%x1, %const1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %x_is_odd = "transfer.cmp"(%lsb_one, %const1) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %bit2_zero_if_odd = "transfer.select"(%x_is_odd, %bit2_mask, %const0) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %res0_fb_0 = "transfer.or"(%low_zero_mask, %bit1_mask) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %res0_fb = "transfer.or"(%res0_fb_0, %bit2_zero_if_odd) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %res1_fb = "transfer.and"(%lsb_one, %const1) : (!transfer.integer, !transfer.integer) -> !transfer.integer

    // Exact constant case.
    %x1_not = "transfer.xor"(%x1, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %x_is_const = "transfer.cmp"(%x0, %x1_not) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %const_sq = "transfer.mul"(%x1, %x1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %const_sq_not = "transfer.xor"(%const_sq, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %res0_const = "transfer.select"(%x_is_const, %const_sq_not, %res0_fb) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %res1_const = "transfer.select"(%x_is_const, %const_sq, %res1_fb) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer

    // Enumerate exactly when there are <= 4 unknown bits.
    %known_union = "transfer.or"(%x0, %x1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %unknown = "transfer.xor"(%known_union, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %unknown_m1 = "transfer.sub"(%unknown, %const1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %rem1 = "transfer.and"(%unknown, %unknown_m1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %rem1_m1 = "transfer.sub"(%rem1, %const1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %rem2 = "transfer.and"(%rem1, %rem1_m1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %rem2_m1 = "transfer.sub"(%rem2, %const1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %rem3 = "transfer.and"(%rem2, %rem2_m1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %rem3_m1 = "transfer.sub"(%rem3, %const1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %rem4 = "transfer.and"(%rem3, %rem3_m1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %unknown_le4 = "transfer.cmp"(%rem4, %const0) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1

    %b1 = "transfer.xor"(%unknown, %rem1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %b2 = "transfer.xor"(%rem1, %rem2) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %b3 = "transfer.xor"(%rem2, %rem3) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %b4 = "transfer.xor"(%rem3, %rem4) : (!transfer.integer, !transfer.integer) -> !transfer.integer

    %v0 = "transfer.add"(%x1, %const0) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %v1 = "transfer.add"(%v0, %b1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %v2 = "transfer.add"(%v0, %b2) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %v3 = "transfer.add"(%v1, %b2) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %v4 = "transfer.add"(%v0, %b3) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %v5 = "transfer.add"(%v1, %b3) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %v6 = "transfer.add"(%v2, %b3) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %v7 = "transfer.add"(%v3, %b3) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %v8 = "transfer.add"(%v0, %b4) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %v9 = "transfer.add"(%v1, %b4) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %v10 = "transfer.add"(%v2, %b4) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %v11 = "transfer.add"(%v3, %b4) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %v12 = "transfer.add"(%v4, %b4) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %v13 = "transfer.add"(%v5, %b4) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %v14 = "transfer.add"(%v6, %b4) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %v15 = "transfer.add"(%v7, %b4) : (!transfer.integer, !transfer.integer) -> !transfer.integer

    %sq0 = "transfer.mul"(%v0, %v0) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %sq0_not = "transfer.xor"(%sq0, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %acc0_0 = "transfer.and"(%all_ones, %sq0_not) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %acc1_0 = "transfer.and"(%all_ones, %sq0) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %sq1 = "transfer.mul"(%v1, %v1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %sq1_not = "transfer.xor"(%sq1, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %acc0_1 = "transfer.and"(%acc0_0, %sq1_not) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %acc1_1 = "transfer.and"(%acc1_0, %sq1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %sq2 = "transfer.mul"(%v2, %v2) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %sq2_not = "transfer.xor"(%sq2, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %acc0_2 = "transfer.and"(%acc0_1, %sq2_not) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %acc1_2 = "transfer.and"(%acc1_1, %sq2) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %sq3 = "transfer.mul"(%v3, %v3) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %sq3_not = "transfer.xor"(%sq3, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %acc0_3 = "transfer.and"(%acc0_2, %sq3_not) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %acc1_3 = "transfer.and"(%acc1_2, %sq3) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %sq4 = "transfer.mul"(%v4, %v4) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %sq4_not = "transfer.xor"(%sq4, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %acc0_4 = "transfer.and"(%acc0_3, %sq4_not) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %acc1_4 = "transfer.and"(%acc1_3, %sq4) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %sq5 = "transfer.mul"(%v5, %v5) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %sq5_not = "transfer.xor"(%sq5, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %acc0_5 = "transfer.and"(%acc0_4, %sq5_not) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %acc1_5 = "transfer.and"(%acc1_4, %sq5) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %sq6 = "transfer.mul"(%v6, %v6) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %sq6_not = "transfer.xor"(%sq6, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %acc0_6 = "transfer.and"(%acc0_5, %sq6_not) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %acc1_6 = "transfer.and"(%acc1_5, %sq6) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %sq7 = "transfer.mul"(%v7, %v7) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %sq7_not = "transfer.xor"(%sq7, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %acc0_7 = "transfer.and"(%acc0_6, %sq7_not) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %acc1_7 = "transfer.and"(%acc1_6, %sq7) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %sq8 = "transfer.mul"(%v8, %v8) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %sq8_not = "transfer.xor"(%sq8, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %acc0_8 = "transfer.and"(%acc0_7, %sq8_not) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %acc1_8 = "transfer.and"(%acc1_7, %sq8) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %sq9 = "transfer.mul"(%v9, %v9) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %sq9_not = "transfer.xor"(%sq9, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %acc0_9 = "transfer.and"(%acc0_8, %sq9_not) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %acc1_9 = "transfer.and"(%acc1_8, %sq9) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %sq10 = "transfer.mul"(%v10, %v10) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %sq10_not = "transfer.xor"(%sq10, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %acc0_10 = "transfer.and"(%acc0_9, %sq10_not) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %acc1_10 = "transfer.and"(%acc1_9, %sq10) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %sq11 = "transfer.mul"(%v11, %v11) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %sq11_not = "transfer.xor"(%sq11, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %acc0_11 = "transfer.and"(%acc0_10, %sq11_not) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %acc1_11 = "transfer.and"(%acc1_10, %sq11) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %sq12 = "transfer.mul"(%v12, %v12) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %sq12_not = "transfer.xor"(%sq12, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %acc0_12 = "transfer.and"(%acc0_11, %sq12_not) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %acc1_12 = "transfer.and"(%acc1_11, %sq12) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %sq13 = "transfer.mul"(%v13, %v13) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %sq13_not = "transfer.xor"(%sq13, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %acc0_13 = "transfer.and"(%acc0_12, %sq13_not) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %acc1_13 = "transfer.and"(%acc1_12, %sq13) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %sq14 = "transfer.mul"(%v14, %v14) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %sq14_not = "transfer.xor"(%sq14, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %acc0_14 = "transfer.and"(%acc0_13, %sq14_not) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %acc1_14 = "transfer.and"(%acc1_13, %sq14) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %sq15 = "transfer.mul"(%v15, %v15) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %sq15_not = "transfer.xor"(%sq15, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %acc0_15 = "transfer.and"(%acc0_14, %sq15_not) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %acc1_15 = "transfer.and"(%acc1_14, %sq15) : (!transfer.integer, !transfer.integer) -> !transfer.integer

    %res0 = "transfer.select"(%unknown_le4, %acc0_15, %res0_const) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %res1 = "transfer.select"(%unknown_le4, %acc1_15, %res1_const) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer

    %r = "transfer.make"(%res0, %res1) : (!transfer.integer, !transfer.integer) -> !transfer.abs_value<[!transfer.integer, !transfer.integer]>
    "func.return"(%r) : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> ()
}) {"sym_name" = "kb_square", "function_type" = (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.abs_value<[!transfer.integer, !transfer.integer]>} : () -> ()
