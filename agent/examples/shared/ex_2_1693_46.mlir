func.func @partial_solution_6_body(%0 : !transfer.abs_value<[!transfer.integer, !transfer.integer]>, %1 : !transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.abs_value<[!transfer.integer, !transfer.integer]> attributes {number = "2_1693_46"} {
  %2 = transfer.get %0[0] : !transfer.abs_value<[!transfer.integer, !transfer.integer]> -> !transfer.integer
  %3 = transfer.get %0[1] : !transfer.abs_value<[!transfer.integer, !transfer.integer]> -> !transfer.integer
  %4 = transfer.get %1[0] : !transfer.abs_value<[!transfer.integer, !transfer.integer]> -> !transfer.integer
  %5 = transfer.get %1[1] : !transfer.abs_value<[!transfer.integer, !transfer.integer]> -> !transfer.integer
  %6 = transfer.constant %5, 1 : !transfer.integer
  %7 = transfer.get_bit_width %5 : !transfer.integer
  %8 = transfer.set_sign_bit %2 : !transfer.integer
  %9 = transfer.or %6, %8 : !transfer.integer
  %10 = transfer.and %9, %4 : !transfer.integer
  %11 = transfer.and %10, %3 : !transfer.integer
  %12 = transfer.clear_high_bits %7, %8 : !transfer.integer
  %13 = transfer.make %12, %11 : (!transfer.integer, !transfer.integer) -> !transfer.abs_value<[!transfer.integer, !transfer.integer]>
  func.return %13 : !transfer.abs_value<[!transfer.integer, !transfer.integer]>
}
