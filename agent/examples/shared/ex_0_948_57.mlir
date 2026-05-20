func.func @partial_solution_12_body(%0 : !transfer.abs_value<[!transfer.integer, !transfer.integer]>, %1 : !transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.abs_value<[!transfer.integer, !transfer.integer]> attributes {number = "0_948_57"} {
  %2 = transfer.get %0[0] : !transfer.abs_value<[!transfer.integer, !transfer.integer]> -> !transfer.integer
  %3 = transfer.get %1[0] : !transfer.abs_value<[!transfer.integer, !transfer.integer]> -> !transfer.integer
  %4 = transfer.get %1[1] : !transfer.abs_value<[!transfer.integer, !transfer.integer]> -> !transfer.integer
  %5 = transfer.constant %4, 0 : !transfer.integer
  %6 = transfer.constant %4, 1 : !transfer.integer
  %7 = transfer.get_bit_width %4 : !transfer.integer
  %8 = transfer.ashr %3, %5 : !transfer.integer
  %9 = transfer.or %8, %2 : !transfer.integer
  %10 = transfer.clear_sign_bit %2 : !transfer.integer
  %11 = transfer.set_high_bits %7, %7 : !transfer.integer
  %12 = transfer.shl %11, %6 : !transfer.integer
  %13 = transfer.cmp ult, %9, %12 : !transfer.integer
  %14 = transfer.and %6, %9 : !transfer.integer
  %15 = transfer.countl_one %7 : !transfer.integer
  %16 = transfer.select %13, %14, %10 : !transfer.integer
  %17 = transfer.make %16, %15 : (!transfer.integer, !transfer.integer) -> !transfer.abs_value<[!transfer.integer, !transfer.integer]>
  func.return %17 : !transfer.abs_value<[!transfer.integer, !transfer.integer]>
}
