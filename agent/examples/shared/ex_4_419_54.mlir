func.func @partial_solution_6_body(%0 : !transfer.abs_value<[!transfer.integer, !transfer.integer]>, %1 : !transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.abs_value<[!transfer.integer, !transfer.integer]> attributes {number = "4_419_54"} {
  %2 = transfer.get %0[0] : !transfer.abs_value<[!transfer.integer, !transfer.integer]> -> !transfer.integer
  %3 = transfer.get %0[1] : !transfer.abs_value<[!transfer.integer, !transfer.integer]> -> !transfer.integer
  %4 = transfer.get %1[1] : !transfer.abs_value<[!transfer.integer, !transfer.integer]> -> !transfer.integer
  %5 = transfer.constant %4, 1 : !transfer.integer
  %6 = transfer.get_bit_width %4 : !transfer.integer
  %7 = transfer.shl %5, %4 : !transfer.integer
  %8 = transfer.countl_one %6 : !transfer.integer
  %9 = transfer.sub %7, %8 : !transfer.integer
  %10 = transfer.udiv %3, %9 : !transfer.integer
  %11 = transfer.ashr %2, %4 : !transfer.integer
  %12 = transfer.make %11, %10 : (!transfer.integer, !transfer.integer) -> !transfer.abs_value<[!transfer.integer, !transfer.integer]>
  func.return %12 : !transfer.abs_value<[!transfer.integer, !transfer.integer]>
}
