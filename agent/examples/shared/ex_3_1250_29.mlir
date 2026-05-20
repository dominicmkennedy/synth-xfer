func.func @partial_solution_8_body(%0 : !transfer.abs_value<[!transfer.integer, !transfer.integer]>, %1 : !transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.abs_value<[!transfer.integer, !transfer.integer]> attributes {number = "3_1250_29"} {
  %2 = transfer.get %0[1] : !transfer.abs_value<[!transfer.integer, !transfer.integer]> -> !transfer.integer
  %3 = transfer.get %1[1] : !transfer.abs_value<[!transfer.integer, !transfer.integer]> -> !transfer.integer
  %4 = transfer.constant %3, 0 : !transfer.integer
  %5 = transfer.constant %3, 1 : !transfer.integer
  %6 = transfer.get_bit_width %3 : !transfer.integer
  %7 = transfer.add %5, %3 : !transfer.integer
  %8 = transfer.smax %7, %4 : !transfer.integer
  %9 = transfer.clear_high_bits %5, %6 : !transfer.integer
  %10 = transfer.add %3, %2 : !transfer.integer
  %11 = transfer.srem %7, %8 : !transfer.integer
  %12 = transfer.or %9, %10 : !transfer.integer
  %13 = transfer.neg %12 : !transfer.integer
  %14 = transfer.or %5, %5 : !transfer.integer
  %15 = transfer.shl %12, %13 : !transfer.integer
  %16 = transfer.srem %11, %14 : !transfer.integer
  %17 = transfer.make %16, %15 : (!transfer.integer, !transfer.integer) -> !transfer.abs_value<[!transfer.integer, !transfer.integer]>
  func.return %17 : !transfer.abs_value<[!transfer.integer, !transfer.integer]>
}
