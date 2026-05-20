func.func @UConstRange_top(%lhs : !transfer.abs_value<[!transfer.integer, !transfer.integer]>, %rhs : !transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.abs_value<[!transfer.integer, !transfer.integer]> {
  %lhs0 = transfer.get %lhs[0] : !transfer.abs_value<[!transfer.integer, !transfer.integer]> -> !transfer.integer
  %zero = transfer.constant %lhs0, 0 : !transfer.integer
  %one = transfer.constant %lhs0, 1 : !transfer.integer
  %umax = transfer.sub %zero, %one : !transfer.integer
  %r = transfer.make %zero, %umax : (!transfer.integer, !transfer.integer) -> !transfer.abs_value<[!transfer.integer, !transfer.integer]>
  func.return %r : !transfer.abs_value<[!transfer.integer, !transfer.integer]>
}
