func.func @getConstraint(%abst_val: !transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer<1> {
  %lb = "transfer.get"(%abst_val) {index = 0 : index} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
  %ub = "transfer.get"(%abst_val) {index = 1 : index} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
  %result = "transfer.cmp"(%lb, %ub) {predicate = 3 : index} : (!transfer.integer, !transfer.integer) -> !transfer.integer<1>
  return %result : !transfer.integer<1>
}
