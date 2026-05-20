func.func @partial_solution_13_body(%0 : !transfer.abs_value<[!transfer.integer, !transfer.integer]>, %1 : !transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.abs_value<[!transfer.integer, !transfer.integer]> attributes {from_weighted_dsl, number = "4_513_149"} {
  %2 = transfer.get %0[0] : !transfer.abs_value<[!transfer.integer, !transfer.integer]> -> !transfer.integer
  %3 = transfer.get %1[1] : !transfer.abs_value<[!transfer.integer, !transfer.integer]> -> !transfer.integer
  %4 = transfer.constant %3, 0 : !transfer.integer
  %5 = transfer.get_bit_width %3 : !transfer.integer
  %6 = transfer.add %3, %2 : !transfer.integer
  %7 = transfer.neg %6 : !transfer.integer
  %8 = transfer.countl_one %5 : !transfer.integer
  %9 = transfer.urem %4, %4 : !transfer.integer
  %10 = transfer.udiv %8, %7 : !transfer.integer
  %11 = transfer.make %10, %9 : (!transfer.integer, !transfer.integer) -> !transfer.abs_value<[!transfer.integer, !transfer.integer]>
  func.return %11 : !transfer.abs_value<[!transfer.integer, !transfer.integer]>
}
