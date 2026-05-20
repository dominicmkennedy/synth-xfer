func.func @partial_solution_5_body(%0 : !transfer.abs_value<[!transfer.integer, !transfer.integer]>, %1 : !transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.abs_value<[!transfer.integer, !transfer.integer]> attributes {number = "1_1608_54"} {
  %2 = transfer.get %0[0] : !transfer.abs_value<[!transfer.integer, !transfer.integer]> -> !transfer.integer
  %3 = transfer.get %0[1] : !transfer.abs_value<[!transfer.integer, !transfer.integer]> -> !transfer.integer
  %4 = transfer.get %1[1] : !transfer.abs_value<[!transfer.integer, !transfer.integer]> -> !transfer.integer
  %5 = transfer.constant %4, 1 : !transfer.integer
  %6 = transfer.get_bit_width %4 : !transfer.integer
  %7 = transfer.set_high_bits %2, %5 : !transfer.integer
  %8 = transfer.and %5, %7 : !transfer.integer
  %9 = transfer.sdiv %8, %7 : !transfer.integer
  %10 = transfer.mul %3, %4 : !transfer.integer
  %11 = transfer.xor %9, %5 : !transfer.integer
  %12 = transfer.shl %4, %6 : !transfer.integer
  %13 = transfer.and %10, %11 : !transfer.integer
  %14 = transfer.make %13, %12 : (!transfer.integer, !transfer.integer) -> !transfer.abs_value<[!transfer.integer, !transfer.integer]>
  func.return %14 : !transfer.abs_value<[!transfer.integer, !transfer.integer]>
}
