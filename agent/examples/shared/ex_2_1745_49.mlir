func.func @partial_solution_8_body(%0 : !transfer.abs_value<[!transfer.integer, !transfer.integer]>, %1 : !transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.abs_value<[!transfer.integer, !transfer.integer]> attributes {number = "2_1745_49"} {
  %2 = transfer.get %0[1] : !transfer.abs_value<[!transfer.integer, !transfer.integer]> -> !transfer.integer
  %3 = transfer.get %1[1] : !transfer.abs_value<[!transfer.integer, !transfer.integer]> -> !transfer.integer
  %4 = transfer.constant %3, 1 : !transfer.integer
  %5 = transfer.get_bit_width %3 : !transfer.integer
  %6 = transfer.umin %2, %2 : !transfer.integer
  %7 = transfer.and %3, %4 : !transfer.integer
  %8 = transfer.countl_one %5 : !transfer.integer
  %9 = transfer.and %7, %6 : !transfer.integer
  %10 = transfer.make %9, %8 : (!transfer.integer, !transfer.integer) -> !transfer.abs_value<[!transfer.integer, !transfer.integer]>
  func.return %10 : !transfer.abs_value<[!transfer.integer, !transfer.integer]>
}
