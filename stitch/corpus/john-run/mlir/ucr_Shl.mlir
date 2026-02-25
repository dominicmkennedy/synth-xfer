"func.func"() ({
  ^0(%lhs : !transfer.abs_value<[!transfer.integer, !transfer.integer]>, %rhs : !transfer.abs_value<[!transfer.integer, !transfer.integer]>):
    %lhs_lower = "transfer.get"(%lhs) {index = 0} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %lhs_upper = "transfer.get"(%lhs) {index = 1} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %rhs_lower = "transfer.get"(%rhs) {index = 0} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %rhs_upper = "transfer.get"(%rhs) {index = 1} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer

    %const0 = "transfer.constant"(%lhs_lower) {value = 0 : index} : (!transfer.integer) -> !transfer.integer
    %const1 = "transfer.constant"(%lhs_lower) {value = 1 : index} : (!transfer.integer) -> !transfer.integer
    %const_true = "arith.constant"() {value = 1 : i1} : () -> i1
    %all_ones = "transfer.get_all_ones"(%lhs_lower) : (!transfer.integer) -> !transfer.integer
    %bw = "transfer.get_bit_width"(%lhs_lower) : (!transfer.integer) -> !transfer.integer

    %has_valid_rhs = "transfer.cmp"(%rhs_lower, %bw) {predicate = 7 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %rhs_upper_le_bw = "transfer.cmp"(%rhs_upper, %bw) {predicate = 7 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %rhs_eff_upper = "transfer.select"(%rhs_upper_le_bw, %rhs_upper, %bw) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer

    %y0 = "transfer.add"(%rhs_lower, %const0) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %y1 = "transfer.add"(%y0, %const1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %y2 = "transfer.add"(%y1, %const1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %y3 = "transfer.add"(%y2, %const1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %y4 = "transfer.add"(%y3, %const1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %y5 = "transfer.add"(%y4, %const1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %y6 = "transfer.add"(%y5, %const1) : (!transfer.integer, !transfer.integer) -> !transfer.integer

    %bw_minus_y0 = "transfer.sub"(%bw, %y0) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %lhs_lower_q0 = "transfer.lshr"(%lhs_lower, %bw_minus_y0) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %lhs_upper_q0 = "transfer.lshr"(%lhs_upper, %bw_minus_y0) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %cross0 = "transfer.cmp"(%lhs_lower_q0, %lhs_upper_q0) {predicate = 1 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %nowrap_low0 = "transfer.shl"(%lhs_lower, %y0) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %nowrap_hi0 = "transfer.shl"(%lhs_upper, %y0) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %wrap_hi0 = "transfer.clear_low_bits"(%all_ones, %y0) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %low_nonbw0 = "transfer.select"(%cross0, %const0, %nowrap_low0) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %hi_nonbw0 = "transfer.select"(%cross0, %wrap_hi0, %nowrap_hi0) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %y0_is_bw = "transfer.cmp"(%y0, %bw) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %low0 = "transfer.select"(%y0_is_bw, %const0, %low_nonbw0) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %hi0 = "transfer.select"(%y0_is_bw, %const0, %hi_nonbw0) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer

    %bw_minus_y1 = "transfer.sub"(%bw, %y1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %lhs_lower_q1 = "transfer.lshr"(%lhs_lower, %bw_minus_y1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %lhs_upper_q1 = "transfer.lshr"(%lhs_upper, %bw_minus_y1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %cross1 = "transfer.cmp"(%lhs_lower_q1, %lhs_upper_q1) {predicate = 1 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %nowrap_low1 = "transfer.shl"(%lhs_lower, %y1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %nowrap_hi1 = "transfer.shl"(%lhs_upper, %y1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %wrap_hi1 = "transfer.clear_low_bits"(%all_ones, %y1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %low_nonbw1 = "transfer.select"(%cross1, %const0, %nowrap_low1) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %hi_nonbw1 = "transfer.select"(%cross1, %wrap_hi1, %nowrap_hi1) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %y1_is_bw = "transfer.cmp"(%y1, %bw) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %low1 = "transfer.select"(%y1_is_bw, %const0, %low_nonbw1) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %hi1 = "transfer.select"(%y1_is_bw, %const0, %hi_nonbw1) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer

    %bw_minus_y2 = "transfer.sub"(%bw, %y2) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %lhs_lower_q2 = "transfer.lshr"(%lhs_lower, %bw_minus_y2) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %lhs_upper_q2 = "transfer.lshr"(%lhs_upper, %bw_minus_y2) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %cross2 = "transfer.cmp"(%lhs_lower_q2, %lhs_upper_q2) {predicate = 1 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %nowrap_low2 = "transfer.shl"(%lhs_lower, %y2) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %nowrap_hi2 = "transfer.shl"(%lhs_upper, %y2) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %wrap_hi2 = "transfer.clear_low_bits"(%all_ones, %y2) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %low_nonbw2 = "transfer.select"(%cross2, %const0, %nowrap_low2) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %hi_nonbw2 = "transfer.select"(%cross2, %wrap_hi2, %nowrap_hi2) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %y2_is_bw = "transfer.cmp"(%y2, %bw) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %low2 = "transfer.select"(%y2_is_bw, %const0, %low_nonbw2) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %hi2 = "transfer.select"(%y2_is_bw, %const0, %hi_nonbw2) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer

    %bw_minus_y3 = "transfer.sub"(%bw, %y3) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %lhs_lower_q3 = "transfer.lshr"(%lhs_lower, %bw_minus_y3) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %lhs_upper_q3 = "transfer.lshr"(%lhs_upper, %bw_minus_y3) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %cross3 = "transfer.cmp"(%lhs_lower_q3, %lhs_upper_q3) {predicate = 1 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %nowrap_low3 = "transfer.shl"(%lhs_lower, %y3) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %nowrap_hi3 = "transfer.shl"(%lhs_upper, %y3) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %wrap_hi3 = "transfer.clear_low_bits"(%all_ones, %y3) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %low_nonbw3 = "transfer.select"(%cross3, %const0, %nowrap_low3) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %hi_nonbw3 = "transfer.select"(%cross3, %wrap_hi3, %nowrap_hi3) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %y3_is_bw = "transfer.cmp"(%y3, %bw) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %low3 = "transfer.select"(%y3_is_bw, %const0, %low_nonbw3) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %hi3 = "transfer.select"(%y3_is_bw, %const0, %hi_nonbw3) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer

    %bw_minus_y4 = "transfer.sub"(%bw, %y4) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %lhs_lower_q4 = "transfer.lshr"(%lhs_lower, %bw_minus_y4) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %lhs_upper_q4 = "transfer.lshr"(%lhs_upper, %bw_minus_y4) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %cross4 = "transfer.cmp"(%lhs_lower_q4, %lhs_upper_q4) {predicate = 1 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %nowrap_low4 = "transfer.shl"(%lhs_lower, %y4) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %nowrap_hi4 = "transfer.shl"(%lhs_upper, %y4) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %wrap_hi4 = "transfer.clear_low_bits"(%all_ones, %y4) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %low_nonbw4 = "transfer.select"(%cross4, %const0, %nowrap_low4) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %hi_nonbw4 = "transfer.select"(%cross4, %wrap_hi4, %nowrap_hi4) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %y4_is_bw = "transfer.cmp"(%y4, %bw) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %low4 = "transfer.select"(%y4_is_bw, %const0, %low_nonbw4) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %hi4 = "transfer.select"(%y4_is_bw, %const0, %hi_nonbw4) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer

    %bw_minus_y5 = "transfer.sub"(%bw, %y5) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %lhs_lower_q5 = "transfer.lshr"(%lhs_lower, %bw_minus_y5) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %lhs_upper_q5 = "transfer.lshr"(%lhs_upper, %bw_minus_y5) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %cross5 = "transfer.cmp"(%lhs_lower_q5, %lhs_upper_q5) {predicate = 1 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %nowrap_low5 = "transfer.shl"(%lhs_lower, %y5) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %nowrap_hi5 = "transfer.shl"(%lhs_upper, %y5) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %wrap_hi5 = "transfer.clear_low_bits"(%all_ones, %y5) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %low_nonbw5 = "transfer.select"(%cross5, %const0, %nowrap_low5) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %hi_nonbw5 = "transfer.select"(%cross5, %wrap_hi5, %nowrap_hi5) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %y5_is_bw = "transfer.cmp"(%y5, %bw) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %low5 = "transfer.select"(%y5_is_bw, %const0, %low_nonbw5) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %hi5 = "transfer.select"(%y5_is_bw, %const0, %hi_nonbw5) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer

    %lower_acc0 = "transfer.add"(%low0, %const0) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %upper_acc0 = "transfer.add"(%hi0, %const0) : (!transfer.integer, !transfer.integer) -> !transfer.integer

    %present1 = "transfer.cmp"(%y0, %rhs_eff_upper) {predicate = 6 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %lower_join1 = "transfer.umin"(%lower_acc0, %low1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %upper_join1 = "transfer.umax"(%upper_acc0, %hi1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %lower_acc1 = "transfer.select"(%present1, %lower_join1, %lower_acc0) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %upper_acc1 = "transfer.select"(%present1, %upper_join1, %upper_acc0) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer

    %present2 = "transfer.cmp"(%y1, %rhs_eff_upper) {predicate = 6 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %lower_join2 = "transfer.umin"(%lower_acc1, %low2) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %upper_join2 = "transfer.umax"(%upper_acc1, %hi2) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %lower_acc2 = "transfer.select"(%present2, %lower_join2, %lower_acc1) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %upper_acc2 = "transfer.select"(%present2, %upper_join2, %upper_acc1) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer

    %present3 = "transfer.cmp"(%y2, %rhs_eff_upper) {predicate = 6 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %lower_join3 = "transfer.umin"(%lower_acc2, %low3) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %upper_join3 = "transfer.umax"(%upper_acc2, %hi3) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %lower_acc3 = "transfer.select"(%present3, %lower_join3, %lower_acc2) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %upper_acc3 = "transfer.select"(%present3, %upper_join3, %upper_acc2) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer

    %present4 = "transfer.cmp"(%y3, %rhs_eff_upper) {predicate = 6 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %lower_join4 = "transfer.umin"(%lower_acc3, %low4) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %upper_join4 = "transfer.umax"(%upper_acc3, %hi4) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %lower_acc4 = "transfer.select"(%present4, %lower_join4, %lower_acc3) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %upper_acc4 = "transfer.select"(%present4, %upper_join4, %upper_acc3) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer

    %present5 = "transfer.cmp"(%y4, %rhs_eff_upper) {predicate = 6 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %lower_join5 = "transfer.umin"(%lower_acc4, %low5) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %upper_join5 = "transfer.umax"(%upper_acc4, %hi5) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %lower_acc5 = "transfer.select"(%present5, %lower_join5, %lower_acc4) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %upper_acc5 = "transfer.select"(%present5, %upper_join5, %upper_acc4) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer

    %present6 = "transfer.cmp"(%y5, %rhs_eff_upper) {predicate = 6 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %no_more = "arith.xori"(%present6, %const_true) : (i1, i1) -> i1
    %safe_known = "arith.ori"(%no_more, %cross5) : (i1, i1) -> i1

    %tail_mask = "transfer.clear_low_bits"(%all_ones, %y6) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %upper_tail_bound = "transfer.umax"(%upper_acc5, %tail_mask) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %lower_known = "transfer.select"(%safe_known, %lower_acc5, %const0) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %upper_known = "transfer.select"(%safe_known, %upper_acc5, %upper_tail_bound) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer

    %ret_lower = "transfer.select"(%has_valid_rhs, %lower_known, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %ret_upper = "transfer.select"(%has_valid_rhs, %upper_known, %const0) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer

    %r = "transfer.make"(%ret_lower, %ret_upper) : (!transfer.integer, !transfer.integer) -> !transfer.abs_value<[!transfer.integer, !transfer.integer]>
    "func.return"(%r) : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> ()
}) {"sym_name" = "ucr_shl", "function_type" = (!transfer.abs_value<[!transfer.integer, !transfer.integer]>, !transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.abs_value<[!transfer.integer, !transfer.integer]>} : () -> ()
