func.func @partial_solution_2_body(%0 : !transfer.abs_value<[!transfer.integer, !transfer.integer]>, %1 : !transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.abs_value<[!transfer.integer, !transfer.integer]> attributes {from_weighted_dsl, number = "2_1616_102"} {
  %2 = transfer.get %0[0] : !transfer.abs_value<[!transfer.integer, !transfer.integer]> -> !transfer.integer
  %3 = transfer.get %0[1] : !transfer.abs_value<[!transfer.integer, !transfer.integer]> -> !transfer.integer
  %4 = transfer.get %1[1] : !transfer.abs_value<[!transfer.integer, !transfer.integer]> -> !transfer.integer
  %5 = transfer.constant %4, 1 : !transfer.integer
  %6 = transfer.get_bit_width %4 : !transfer.integer
  %7 = transfer.udiv %4, %4 : !transfer.integer
  %8 = transfer.ashr %5, %6 : !transfer.integer
  %9 = transfer.ashr %2, %4 : !transfer.integer
  %10 = transfer.smin %4, %9 : !transfer.integer
  %11 = transfer.and %10, %8 : !transfer.integer
  %12 = transfer.umin %7, %3 : !transfer.integer
  %13 = transfer.clear_low_bits %9, %11 : !transfer.integer
  %14 = transfer.make %13, %12 : (!transfer.integer, !transfer.integer) -> !transfer.abs_value<[!transfer.integer, !transfer.integer]>
  func.return %14 : !transfer.abs_value<[!transfer.integer, !transfer.integer]>
}
