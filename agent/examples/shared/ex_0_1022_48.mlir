func.func @partial_solution_5_body(%0 : !transfer.abs_value<[!transfer.integer, !transfer.integer]>, %1 : !transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.abs_value<[!transfer.integer, !transfer.integer]> attributes {number = "0_1022_48"} {
  %2 = transfer.get %0[0] : !transfer.abs_value<[!transfer.integer, !transfer.integer]> -> !transfer.integer
  %3 = transfer.get %0[1] : !transfer.abs_value<[!transfer.integer, !transfer.integer]> -> !transfer.integer
  %4 = transfer.get %1[0] : !transfer.abs_value<[!transfer.integer, !transfer.integer]> -> !transfer.integer
  %5 = transfer.get %1[1] : !transfer.abs_value<[!transfer.integer, !transfer.integer]> -> !transfer.integer
  %6 = transfer.constant %5, 1 : !transfer.integer
  %7 = transfer.get_bit_width %5 : !transfer.integer
  %8 = transfer.or %7, %7 : !transfer.integer
  %9 = transfer.and %4, %6 : !transfer.integer
  %10 = transfer.clear_sign_bit %2 : !transfer.integer
  %11 = transfer.clear_high_bits %5, %3 : !transfer.integer
  %12 = transfer.cmp ult, %4, %11 : !transfer.integer
  %13 = transfer.select %12, %5, %5 : !transfer.integer
  %14 = transfer.shl %13, %8 : !transfer.integer
  %15 = transfer.and %9, %10 : !transfer.integer
  %16 = transfer.make %15, %14 : (!transfer.integer, !transfer.integer) -> !transfer.abs_value<[!transfer.integer, !transfer.integer]>
  func.return %16 : !transfer.abs_value<[!transfer.integer, !transfer.integer]>
}
