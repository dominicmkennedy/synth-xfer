func.func @partial_solution_4_body(%0 : !transfer.abs_value<[!transfer.integer, !transfer.integer]>, %1 : !transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.abs_value<[!transfer.integer, !transfer.integer]> attributes {number = "0_981_92"} {
  %2 = transfer.get %0[1] : !transfer.abs_value<[!transfer.integer, !transfer.integer]> -> !transfer.integer
  %3 = transfer.get %1[1] : !transfer.abs_value<[!transfer.integer, !transfer.integer]> -> !transfer.integer
  %4 = transfer.constant %3, 0 : !transfer.integer
  %5 = transfer.constant %3, 1 : !transfer.integer
  %6 = transfer.get_all_ones %3 : !transfer.integer
  %7 = transfer.get_bit_width %3 : !transfer.integer
  %8 = transfer.cmp ule, %7, %4 : !transfer.integer
  %9 = transfer.select %8, %5, %5 : !transfer.integer
  %10 = transfer.mul %2, %6 : !transfer.integer
  %11 = transfer.set_low_bits %7, %9 : !transfer.integer
  %12 = transfer.smin %10, %11 : !transfer.integer
  %13 = transfer.umin %12, %5 : !transfer.integer
  %14 = transfer.neg %5 : !transfer.integer
  %15 = transfer.make %14, %13 : (!transfer.integer, !transfer.integer) -> !transfer.abs_value<[!transfer.integer, !transfer.integer]>
  func.return %15 : !transfer.abs_value<[!transfer.integer, !transfer.integer]>
}
