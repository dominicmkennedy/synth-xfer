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

    %bw_minus_y0 = "transfer.sub"(%bw, %rhs_lower) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %lhs_lower_q0 = "transfer.lshr"(%lhs_lower, %bw_minus_y0) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %lhs_upper_q0 = "transfer.lshr"(%lhs_upper, %bw_minus_y0) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %cross0 = "transfer.cmp"(%lhs_lower_q0, %lhs_upper_q0) {predicate = 1 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %nowrap_hi0 = "transfer.shl"(%lhs_upper, %rhs_lower) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %wrap_hi0 = "transfer.clear_low_bits"(%all_ones, %rhs_lower) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %hi0_nonbw = "transfer.select"(%cross0, %wrap_hi0, %nowrap_hi0) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %y0_is_bw = "transfer.cmp"(%rhs_lower, %bw) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %hi0 = "transfer.select"(%y0_is_bw, %const0, %hi0_nonbw) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer

    %y1 = "transfer.add"(%rhs_lower, %const1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %bw_minus_y1 = "transfer.sub"(%bw, %y1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %lhs_lower_q1 = "transfer.lshr"(%lhs_lower, %bw_minus_y1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %lhs_upper_q1 = "transfer.lshr"(%lhs_upper, %bw_minus_y1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %cross1 = "transfer.cmp"(%lhs_lower_q1, %lhs_upper_q1) {predicate = 1 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %nowrap_hi1 = "transfer.shl"(%lhs_upper, %y1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %wrap_hi1 = "transfer.clear_low_bits"(%all_ones, %y1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %hi1_nonbw = "transfer.select"(%cross1, %wrap_hi1, %nowrap_hi1) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %y1_is_bw = "transfer.cmp"(%y1, %bw) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %hi1 = "transfer.select"(%y1_is_bw, %const0, %hi1_nonbw) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer

    %y0_only = "transfer.cmp"(%rhs_lower, %rhs_eff_upper) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %y1_present = "transfer.cmp"(%rhs_lower, %rhs_eff_upper) {predicate = 1 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %y2_present = "transfer.cmp"(%y1, %rhs_eff_upper) {predicate = 6 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %no_y2 = "arith.xori"(%y2_present, %const_true) : (i1, i1) -> i1
    %safe_after_y1 = "arith.ori"(%no_y2, %cross1) : (i1, i1) -> i1
    %upper_safe = "arith.ori"(%y0_only, %safe_after_y1) : (i1, i1) -> i1

    %hi01 = "transfer.umax"(%hi0, %hi1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %upper_01 = "transfer.select"(%y1_present, %hi01, %hi0) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %upper_valid = "transfer.select"(%upper_safe, %upper_01, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %ret_upper = "transfer.select"(%has_valid_rhs, %upper_valid, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer

    %r = "transfer.make"(%const0, %ret_upper) : (!transfer.integer, !transfer.integer) -> !transfer.abs_value<[!transfer.integer, !transfer.integer]>
    "func.return"(%r) : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> ()
}) {"sym_name" = "ucr_shl", "function_type" = (!transfer.abs_value<[!transfer.integer, !transfer.integer]>, !transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.abs_value<[!transfer.integer, !transfer.integer]>} : () -> ()
