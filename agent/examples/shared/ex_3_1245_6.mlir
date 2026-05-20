func.func @partial_solution_3_body(%0 : !transfer.abs_value<[!transfer.integer, !transfer.integer]>, %1 : !transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.abs_value<[!transfer.integer, !transfer.integer]> attributes {number = "3_1245_6"} {
  %2 = transfer.get %0[1] : !transfer.abs_value<[!transfer.integer, !transfer.integer]> -> !transfer.integer
  %3 = transfer.get %1[0] : !transfer.abs_value<[!transfer.integer, !transfer.integer]> -> !transfer.integer
  %4 = transfer.get %1[1] : !transfer.abs_value<[!transfer.integer, !transfer.integer]> -> !transfer.integer
  %5 = transfer.constant %4, 1 : !transfer.integer
  %6 = transfer.get_bit_width %4 : !transfer.integer
  %7 = transfer.clear_sign_bit %2 : !transfer.integer
  %8 = transfer.clear_high_bits %2, %6 : !transfer.integer
  %9 = transfer.xor %5, %3 : !transfer.integer
  %10 = transfer.add %7, %9 : !transfer.integer
  %11 = transfer.and %10, %7 : !transfer.integer
  %12 = transfer.and %11, %3 : !transfer.integer
  %13 = transfer.urem %8, %9 : !transfer.integer
  %14 = transfer.make %13, %12 : (!transfer.integer, !transfer.integer) -> !transfer.abs_value<[!transfer.integer, !transfer.integer]>
  func.return %14 : !transfer.abs_value<[!transfer.integer, !transfer.integer]>
}
