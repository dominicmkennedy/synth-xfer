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
    %lhs_max = "transfer.xor"(%lhs0, %const_all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %rhs_max = "transfer.xor"(%rhs0, %const_all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %min_res = "transfer.umax"(%lhs1, %rhs1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %max_res = "transfer.umax"(%lhs_max, %rhs_max) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %xor_min_max = "transfer.xor"(%min_res, %max_res) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %lz = "transfer.countl_zero"(%xor_min_max) : (!transfer.integer) -> !transfer.integer
    %bw_minus_lz = "transfer.sub"(%bw, %lz) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %mask = "transfer.shl"(%const_all_ones, %bw_minus_lz) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %prefix1 = "transfer.and"(%min_res, %mask) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %min_not = "transfer.xor"(%min_res, %const_all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %prefix0 = "transfer.and"(%min_not, %mask) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %both1 = "transfer.and"(%lhs1, %rhs1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %both0 = "transfer.and"(%lhs0, %rhs0) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %over1 = "transfer.or"(%prefix1, %both1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %over0 = "transfer.or"(%prefix0, %both0) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %umax_lmin_rmax = "transfer.umax"(%lhs1, %rhs_max) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %cond_lhs = "transfer.cmp"(%umax_lmin_rmax, %lhs1) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %umax_rmin_lmax = "transfer.umax"(%rhs1, %lhs_max) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %cond_rhs = "transfer.cmp"(%umax_rmin_lmax, %rhs1) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %tmp1 = "transfer.select"(%cond_rhs, %rhs1, %over1) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %res1 = "transfer.select"(%cond_lhs, %lhs1, %tmp1) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %tmp0 = "transfer.select"(%cond_rhs, %rhs0, %over0) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %res0 = "transfer.select"(%cond_lhs, %lhs0, %tmp0) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
    %r = "transfer.make"(%res0, %res1) : (!transfer.integer, !transfer.integer) -> !transfer.abs_value<[!transfer.integer, !transfer.integer]>
    "func.return"(%r) : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> ()
}) {"sym_name" = "kb_umax", "function_type" = (!transfer.abs_value<[!transfer.integer, !transfer.integer]>, !transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.abs_value<[!transfer.integer, !transfer.integer]>} : () -> ()