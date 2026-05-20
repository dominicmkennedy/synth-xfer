func.func @partial_solution_9_body(%0 : !transfer.abs_value<[!transfer.integer, !transfer.integer]>, %1 : !transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.abs_value<[!transfer.integer, !transfer.integer]> attributes {from_weighted_dsl, number = "2_1714_98"} {
  %2 = transfer.get %0[0] : !transfer.abs_value<[!transfer.integer, !transfer.integer]> -> !transfer.integer
  %3 = transfer.get %0[1] : !transfer.abs_value<[!transfer.integer, !transfer.integer]> -> !transfer.integer
  %4 = transfer.get %1[0] : !transfer.abs_value<[!transfer.integer, !transfer.integer]> -> !transfer.integer
  %5 = transfer.get %1[1] : !transfer.abs_value<[!transfer.integer, !transfer.integer]> -> !transfer.integer
  %6 = transfer.constant %5, 0 : !transfer.integer
  %7 = transfer.get_all_ones %5 : !transfer.integer
  %8 = transfer.get_bit_width %5 : !transfer.integer
  %9 = transfer.ashr %7, %6 : !transfer.integer
  %10 = transfer.or %5, %8 : !transfer.integer
  %11 = transfer.neg %3 : !transfer.integer
  %12 = transfer.udiv %11, %4 : !transfer.integer
  %13 = transfer.and %9, %12 : !transfer.integer
  %14 = transfer.srem %2, %2 : !transfer.integer
  %15 = transfer.add %4, %10 : !transfer.integer
  %16 = transfer.clear_high_bits %14, %15 : !transfer.integer
  %17 = transfer.shl %9, %13 : !transfer.integer
  %18 = transfer.make %17, %16 : (!transfer.integer, !transfer.integer) -> !transfer.abs_value<[!transfer.integer, !transfer.integer]>
  func.return %18 : !transfer.abs_value<[!transfer.integer, !transfer.integer]>
}
