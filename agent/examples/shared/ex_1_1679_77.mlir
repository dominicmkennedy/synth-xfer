func.func @partial_solution_20_body(%0 : !transfer.abs_value<[!transfer.integer, !transfer.integer]>, %1 : !transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.abs_value<[!transfer.integer, !transfer.integer]> attributes {number = "1_1679_77"} {
  %2 = transfer.get %0[1] : !transfer.abs_value<[!transfer.integer, !transfer.integer]> -> !transfer.integer
  %3 = transfer.get %1[1] : !transfer.abs_value<[!transfer.integer, !transfer.integer]> -> !transfer.integer
  %4 = transfer.get_all_ones %3 : !transfer.integer
  %5 = transfer.get_bit_width %3 : !transfer.integer
  %6 = transfer.countl_one %5 : !transfer.integer
  %7 = transfer.mul %2, %4 : !transfer.integer
  %8 = transfer.add %7, %7 : !transfer.integer
  %9 = transfer.clear_low_bits %2, %8 : !transfer.integer
  %10 = transfer.urem %6, %3 : !transfer.integer
  %11 = transfer.make %10, %9 : (!transfer.integer, !transfer.integer) -> !transfer.abs_value<[!transfer.integer, !transfer.integer]>
  func.return %11 : !transfer.abs_value<[!transfer.integer, !transfer.integer]>
}
