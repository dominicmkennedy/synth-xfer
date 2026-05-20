func.func @partial_solution_0_body(%0 : !transfer.abs_value<[!transfer.integer, !transfer.integer]>, %1 : !transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.abs_value<[!transfer.integer, !transfer.integer]> attributes {from_weighted_dsl, number = "0_976_183"} {
  %2 = transfer.get %0[0] : !transfer.abs_value<[!transfer.integer, !transfer.integer]> -> !transfer.integer
  %3 = transfer.get %0[1] : !transfer.abs_value<[!transfer.integer, !transfer.integer]> -> !transfer.integer
  %4 = transfer.get %1[1] : !transfer.abs_value<[!transfer.integer, !transfer.integer]> -> !transfer.integer
  %5 = transfer.constant %4, 1 : !transfer.integer
  %6 = transfer.get_bit_width %4 : !transfer.integer
  %7 = transfer.shl %5, %6 : !transfer.integer
  %8 = transfer.mul %7, %2 : !transfer.integer
  %9 = transfer.lshr %4, %8 : !transfer.integer
  %10 = transfer.clear_low_bits %3, %5 : !transfer.integer
  %11 = transfer.neg %10 : !transfer.integer
  %12 = transfer.smin %11, %9 : !transfer.integer
  %13 = transfer.ashr %3, %12 : !transfer.integer
  %14 = transfer.set_low_bits %9, %4 : !transfer.integer
  %15 = transfer.make %14, %13 : (!transfer.integer, !transfer.integer) -> !transfer.abs_value<[!transfer.integer, !transfer.integer]>
  func.return %15 : !transfer.abs_value<[!transfer.integer, !transfer.integer]>
}
