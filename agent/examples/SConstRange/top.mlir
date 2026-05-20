func.func @SConstRange_top(%lhs : !transfer.abs_value<[!transfer.integer, !transfer.integer]>, %rhs : !transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.abs_value<[!transfer.integer, !transfer.integer]> {
  %lhs0 = transfer.get %lhs[0] : !transfer.abs_value<[!transfer.integer, !transfer.integer]> -> !transfer.integer
  %smin = transfer.get_signed_min_value %lhs0 : !transfer.integer
  %smax = transfer.get_signed_max_value %lhs0 : !transfer.integer
  %r = transfer.make %smin, %smax : (!transfer.integer, !transfer.integer) -> !transfer.abs_value<[!transfer.integer, !transfer.integer]>
  func.return %r : !transfer.abs_value<[!transfer.integer, !transfer.integer]>
}
