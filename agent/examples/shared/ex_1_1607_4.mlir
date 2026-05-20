func.func @partial_solution_1_body(%0 : !transfer.abs_value<[!transfer.integer, !transfer.integer]>, %1 : !transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.abs_value<[!transfer.integer, !transfer.integer]> attributes {number = "1_1607_4"} {
  %2 = transfer.get %0[0] : !transfer.abs_value<[!transfer.integer, !transfer.integer]> -> !transfer.integer
  %3 = transfer.get %0[1] : !transfer.abs_value<[!transfer.integer, !transfer.integer]> -> !transfer.integer
  %4 = transfer.get %1[1] : !transfer.abs_value<[!transfer.integer, !transfer.integer]> -> !transfer.integer
  %5 = transfer.constant %4, 0 : !transfer.integer
  %6 = transfer.get_bit_width %4 : !transfer.integer
  %7 = transfer.urem %2, %2 : !transfer.integer
  %8 = transfer.set_sign_bit %5 : !transfer.integer
  %9 = transfer.add %4, %3 : !transfer.integer
  %10 = transfer.and %9, %8 : !transfer.integer
  %11 = transfer.udiv %7, %6 : !transfer.integer
  %12 = transfer.make %11, %10 : (!transfer.integer, !transfer.integer) -> !transfer.abs_value<[!transfer.integer, !transfer.integer]>
  func.return %12 : !transfer.abs_value<[!transfer.integer, !transfer.integer]>
}
