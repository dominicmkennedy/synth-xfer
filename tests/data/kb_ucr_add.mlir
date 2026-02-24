"func.func"() ({
^0(%lhs: !transfer.abs_value<[!transfer.abs_value<[!transfer.integer, !transfer.integer]>, !transfer.abs_value<[!transfer.integer, !transfer.integer]>]>, %rhs: !transfer.abs_value<[!transfer.abs_value<[!transfer.integer, !transfer.integer]>, !transfer.abs_value<[!transfer.integer, !transfer.integer]>]>):
  // Split relational inputs
  %lhs_kb = "transfer.get"(%lhs) {index = 0} : (!transfer.abs_value<[!transfer.abs_value<[!transfer.integer, !transfer.integer]>, !transfer.abs_value<[!transfer.integer, !transfer.integer]>]>) -> !transfer.abs_value<[!transfer.integer, !transfer.integer]>
  %lhs_ucr = "transfer.get"(%lhs) {index = 1} : (!transfer.abs_value<[!transfer.abs_value<[!transfer.integer, !transfer.integer]>, !transfer.abs_value<[!transfer.integer, !transfer.integer]>]>) -> !transfer.abs_value<[!transfer.integer, !transfer.integer]>
  %rhs_kb = "transfer.get"(%rhs) {index = 0} : (!transfer.abs_value<[!transfer.abs_value<[!transfer.integer, !transfer.integer]>, !transfer.abs_value<[!transfer.integer, !transfer.integer]>]>) -> !transfer.abs_value<[!transfer.integer, !transfer.integer]>
  %rhs_ucr = "transfer.get"(%rhs) {index = 1} : (!transfer.abs_value<[!transfer.abs_value<[!transfer.integer, !transfer.integer]>, !transfer.abs_value<[!transfer.integer, !transfer.integer]>]>) -> !transfer.abs_value<[!transfer.integer, !transfer.integer]>

  // KnownBits component
  %lhs_kb0 = "transfer.get"(%lhs_kb) {index = 0} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
  %lhs_kb1 = "transfer.get"(%lhs_kb) {index = 1} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
  %rhs_kb0 = "transfer.get"(%rhs_kb) {index = 0} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
  %rhs_kb1 = "transfer.get"(%rhs_kb) {index = 1} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer

  %kb_const0 = "transfer.constant"(%lhs_kb0) {value = 0 : index} : (!transfer.integer) -> !transfer.integer
  %kb_const1 = "transfer.constant"(%lhs_kb0) {value = 1 : index} : (!transfer.integer) -> !transfer.integer
  %kb_constMax = "transfer.sub"(%kb_const0, %kb_const1) : (!transfer.integer, !transfer.integer) -> !transfer.integer

  %lhs_kb_known = "transfer.or"(%lhs_kb0, %lhs_kb1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
  %rhs_kb_known = "transfer.or"(%rhs_kb0, %rhs_kb1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
  %lhs_kb_full = "transfer.cmp"(%lhs_kb_known, %kb_constMax) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
  %rhs_kb_full = "transfer.cmp"(%rhs_kb_known, %kb_constMax) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
  %kb_full = "arith.andi"(%lhs_kb_full, %rhs_kb_full) : (i1, i1) -> i1

  %kb_sum = "transfer.add"(%lhs_kb1, %rhs_kb1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
  %kb_sum_zeros = "transfer.neg"(%kb_sum) : (!transfer.integer) -> !transfer.integer
  %kb_sel_zeros = "transfer.select"(%kb_full, %kb_sum_zeros, %kb_const0) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
  %kb_sel_ones = "transfer.select"(%kb_full, %kb_sum, %kb_const0) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
  %kb_out = "transfer.make"(%kb_sel_zeros, %kb_sel_ones) : (!transfer.integer, !transfer.integer) -> !transfer.abs_value<[!transfer.integer, !transfer.integer]>

  // UConstRange component
  %lhs_ucr0 = "transfer.get"(%lhs_ucr) {index = 0} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
  %lhs_ucr1 = "transfer.get"(%lhs_ucr) {index = 1} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
  %rhs_ucr0 = "transfer.get"(%rhs_ucr) {index = 0} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
  %rhs_ucr1 = "transfer.get"(%rhs_ucr) {index = 1} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer

  %ucr_const0 = "transfer.constant"(%lhs_ucr0) {value = 0 : index} : (!transfer.integer) -> !transfer.integer
  %ucr_const1 = "transfer.constant"(%lhs_ucr0) {value = 1 : index} : (!transfer.integer) -> !transfer.integer
  %ucr_constMax = "transfer.sub"(%ucr_const0, %ucr_const1) : (!transfer.integer, !transfer.integer) -> !transfer.integer

  %ucr_sum_lo = "transfer.add"(%lhs_ucr0, %rhs_ucr0) : (!transfer.integer, !transfer.integer) -> !transfer.integer
  %ucr_sum_hi = "transfer.add"(%lhs_ucr1, %rhs_ucr1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
  %ucr_overflow = "transfer.cmp"(%ucr_sum_hi, %lhs_ucr1) {predicate = 6 : i64} : (!transfer.integer, !transfer.integer) -> i1
  %ucr_out_lo = "transfer.select"(%ucr_overflow, %ucr_const0, %ucr_sum_lo) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
  %ucr_out_hi = "transfer.select"(%ucr_overflow, %ucr_constMax, %ucr_sum_hi) : (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
  %ucr_out = "transfer.make"(%ucr_out_lo, %ucr_out_hi) : (!transfer.integer, !transfer.integer) -> !transfer.abs_value<[!transfer.integer, !transfer.integer]>

  %out = "transfer.make"(%kb_out, %ucr_out) : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>, !transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.abs_value<[!transfer.abs_value<[!transfer.integer, !transfer.integer]>, !transfer.abs_value<[!transfer.integer, !transfer.integer]>]>
  "func.return"(%out) : (!transfer.abs_value<[!transfer.abs_value<[!transfer.integer, !transfer.integer]>, !transfer.abs_value<[!transfer.integer, !transfer.integer]>]>) -> ()
}) {"sym_name" = "kb_ucr_add", "function_type" = (!transfer.abs_value<[!transfer.abs_value<[!transfer.integer, !transfer.integer]>, !transfer.abs_value<[!transfer.integer, !transfer.integer]>]>, !transfer.abs_value<[!transfer.abs_value<[!transfer.integer, !transfer.integer]>, !transfer.abs_value<[!transfer.integer, !transfer.integer]>]>) -> !transfer.abs_value<[!transfer.abs_value<[!transfer.integer, !transfer.integer]>, !transfer.abs_value<[!transfer.integer, !transfer.integer]>]>} : () -> ()
