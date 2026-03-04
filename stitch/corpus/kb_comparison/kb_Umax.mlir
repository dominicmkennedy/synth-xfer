"func.func"() ({
  ^0(%lhs : !transfer.abs_value<[!transfer.integer, !transfer.integer]>, %rhs : !transfer.abs_value<[!transfer.integer, !transfer.integer]>):
    %lhs0 = "transfer.get"(%lhs) {index = 0} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %lhs1 = "transfer.get"(%lhs) {index = 1} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %rhs0 = "transfer.get"(%rhs) {index = 0} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %rhs1 = "transfer.get"(%rhs) {index = 1} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer

    %all_ones = "transfer.get_all_ones"(%lhs0) : (!transfer.integer) -> !transfer.integer
    %const0 = "transfer.constant"(%lhs0) {value = 0 : index} : (!transfer.integer) -> !transfer.integer
    %const1 = "transfer.constant"(%lhs0) {value = 1 : index} : (!transfer.integer) -> !transfer.integer

    %lhs_conflict = "transfer.and"(%lhs0, %lhs1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %rhs_conflict = "transfer.and"(%rhs0, %rhs1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %any_conflict = "transfer.or"(%lhs_conflict, %rhs_conflict) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %consistent = "transfer.cmp"(%any_conflict, %const0) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1

    %lhs_max = "transfer.xor"(%lhs0, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %rhs_max = "transfer.xor"(%rhs0, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer

    // unsigned bounds for umax over product sets
    %lb = "transfer.umax"(%lhs1, %rhs1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %ub = "transfer.umax"(%lhs_max, %rhs_max) : (!transfer.integer, !transfer.integer) -> !transfer.integer

    // convert [lb, ub] to known bits by shared prefix
    %diff = "transfer.xor"(%lb, %ub) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %common_lz = "transfer.countl_zero"(%diff) : (!transfer.integer) -> !transfer.integer
    %bitwidth = "transfer.get_bit_width"(%lhs0) : (!transfer.integer) -> !transfer.integer
    %common_inv = "transfer.sub"(%bitwidth, %common_lz) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %common_mask = "transfer.shl"(%all_ones, %common_inv) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %lb_not = "transfer.xor"(%lb, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %iv0 = "transfer.and"(%lb_not, %common_mask) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %iv1 = "transfer.and"(%lb, %common_mask) : (!transfer.integer, !transfer.integer) -> !transfer.integer

    // result is either lhs or rhs, so shared known bits are always preserved
    %shared0 = "transfer.and"(%lhs0, %rhs0) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %shared1 = "transfer.and"(%lhs1, %rhs1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %ov0 = "transfer.or"(%iv0, %shared0) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %ov1 = "transfer.or"(%iv1, %shared1) : (!transfer.integer, !transfer.integer) -> !transfer.integer

    // branch-conditioned clipping: selected lhs/rhs values must be >= lb
    %lhs_clip_diff = "transfer.xor"(%lb, %lhs_max) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %lhs_clip_common_lz = "transfer.countl_zero"(%lhs_clip_diff) : (!transfer.integer) -> !transfer.integer
    %lhs_clip_common_inv = "transfer.sub"(%bitwidth, %lhs_clip_common_lz) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %lhs_clip_common_mask = "transfer.shl"(%all_ones, %lhs_clip_common_inv) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %lhs_clip_lb_not = "transfer.xor"(%lb, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %lhs_clip_iv0 = "transfer.and"(%lhs_clip_lb_not, %lhs_clip_common_mask) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %lhs_clip_iv1 = "transfer.and"(%lb, %lhs_clip_common_mask) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %lhs_clip0 = "transfer.or"(%lhs0, %lhs_clip_iv0) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %lhs_clip1 = "transfer.or"(%lhs1, %lhs_clip_iv1) : (!transfer.integer, !transfer.integer) -> !transfer.integer

    %rhs_clip_diff = "transfer.xor"(%lb, %rhs_max) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %rhs_clip_common_lz = "transfer.countl_zero"(%rhs_clip_diff) : (!transfer.integer) -> !transfer.integer
    %rhs_clip_common_inv = "transfer.sub"(%bitwidth, %rhs_clip_common_lz) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %rhs_clip_common_mask = "transfer.shl"(%all_ones, %rhs_clip_common_inv) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %rhs_clip_lb_not = "transfer.xor"(%lb, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %rhs_clip_iv0 = "transfer.and"(%rhs_clip_lb_not, %rhs_clip_common_mask) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %rhs_clip_iv1 = "transfer.and"(%lb, %rhs_clip_common_mask) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %rhs_clip0 = "transfer.or"(%rhs0, %rhs_clip_iv0) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %rhs_clip1 = "transfer.or"(%rhs1, %rhs_clip_iv1) : (!transfer.integer, !transfer.integer) -> !transfer.integer

    %lhs_possible = "transfer.cmp"(%lb, %lhs_max) {predicate = 7 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %rhs_possible = "transfer.cmp"(%lb, %rhs_max) {predicate = 7 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %both_possible = "arith.andi"(%lhs_possible, %rhs_possible) : (i1, i1) -> i1
    %branch0_both = "transfer.and"(%lhs_clip0, %rhs_clip0) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %branch1_both = "transfer.and"(%lhs_clip1, %rhs_clip1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %branch0_one = "transfer.select"(%lhs_possible, %lhs_clip0, %rhs_clip0) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %branch1_one = "transfer.select"(%lhs_possible, %lhs_clip1, %rhs_clip1) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %branch0 = "transfer.select"(%both_possible, %branch0_both, %branch0_one) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %branch1 = "transfer.select"(%both_possible, %branch1_both, %branch1_one) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer

    %ov0_refined = "transfer.or"(%ov0, %branch0) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %ov1_refined = "transfer.or"(%ov1, %branch1) : (!transfer.integer, !transfer.integer) -> !transfer.integer

    // exact dominance by bounds
    %lhs_ge_rhs_bounds = "transfer.cmp"(%lhs1, %rhs_max) {predicate = 9 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %rhs_ge_lhs_bounds = "transfer.cmp"(%rhs1, %lhs_max) {predicate = 9 : i64} : (!transfer.integer, !transfer.integer) -> i1

    // exact dominance by first guaranteed-different bit in the leading equal prefix
    %eq_known = "transfer.or"(%shared0, %shared1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %leading_eq = "transfer.countl_one"(%eq_known) : (!transfer.integer) -> !transfer.integer
    %has_decisive_bit = "transfer.cmp"(%leading_eq, %bitwidth) {predicate = 6 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %remaining = "transfer.sub"(%bitwidth, %leading_eq) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %dec_shift = "transfer.sub"(%remaining, %const1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %dec_mask_raw = "transfer.shl"(%const1, %dec_shift) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %dec_mask = "transfer.select"(%has_decisive_bit, %dec_mask_raw, %const0) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %lhs_gt_bits = "transfer.and"(%lhs1, %rhs0) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %rhs_gt_bits = "transfer.and"(%rhs1, %lhs0) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %lhs_decisive = "transfer.and"(%lhs_gt_bits, %dec_mask) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %rhs_decisive = "transfer.and"(%rhs_gt_bits, %dec_mask) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %lhs_ge_rhs_prefix = "transfer.cmp"(%lhs_decisive, %const0) {predicate = 1 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %rhs_ge_lhs_prefix = "transfer.cmp"(%rhs_decisive, %const0) {predicate = 1 : i64} : (!transfer.integer, !transfer.integer) -> i1

    %lhs_ge_rhs_always = "arith.ori"(%lhs_ge_rhs_bounds, %lhs_ge_rhs_prefix) : (i1, i1) -> i1
    %rhs_ge_lhs_always = "arith.ori"(%rhs_ge_lhs_bounds, %rhs_ge_lhs_prefix) : (i1, i1) -> i1

    %res0_nonconst = "transfer.select"(%rhs_ge_lhs_always, %rhs0, %ov0_refined) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %res1_nonconst = "transfer.select"(%rhs_ge_lhs_always, %rhs1, %ov1_refined) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %res0 = "transfer.select"(%lhs_ge_rhs_always, %lhs0, %res0_nonconst) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %res1 = "transfer.select"(%lhs_ge_rhs_always, %lhs1, %res1_nonconst) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer

    %res0_final = "transfer.select"(%consistent, %res0, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %res1_final = "transfer.select"(%consistent, %res1, %all_ones) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer

    %r = "transfer.make"(%res0_final, %res1_final) : (!transfer.integer, !transfer.integer) -> !transfer.abs_value<[!transfer.integer, !transfer.integer]>
    "func.return"(%r) : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> ()
}) {"sym_name" = "kb_umax", "function_type" = (!transfer.abs_value<[!transfer.integer, !transfer.integer]>, !transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.abs_value<[!transfer.integer, !transfer.integer]>} : () -> ()
