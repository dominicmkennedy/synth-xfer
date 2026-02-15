func.func @getInstanceConstraint(%abst_val: !transfer.abs_value<[!transfer.integer, !transfer.integer]>, %inst: !transfer.integer) -> !transfer.integer<1> {
  %lb = "transfer.get"(%abst_val) {index = 0 : index} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
  %ub = "transfer.get"(%abst_val) {index = 1 : index} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
  %cmp_0 = "transfer.cmp"(%lb, %inst) {predicate = 3 : index} : (!transfer.integer, !transfer.integer) -> !transfer.integer<1>
  %cmp_1 = "transfer.cmp"(%inst, %ub) {predicate = 3 : index} : (!transfer.integer, !transfer.integer) -> !transfer.integer<1>
  %result = "transfer.and"(%cmp_0, %cmp_1) : (!transfer.integer<1>, !transfer.integer<1>) -> !transfer.integer<1>
  return %result : !transfer.integer<1>
}
