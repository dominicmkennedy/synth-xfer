func.func @getInstanceConstraint(%abst_val: !transfer.abs_value<[!transfer.integer, !transfer.integer]>, %inst: !transfer.integer) -> !transfer.integer<1> {
  %known_z = "transfer.get"(%abst_val) {index = 0 : index} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
  %known_o = "transfer.get"(%abst_val) {index = 1 : index} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
  %inst_not = "transfer.neg"(%inst) : (!transfer.integer) -> !transfer.integer
  %or_0 = "transfer.or"(%inst_not, %known_z) : (!transfer.integer, !transfer.integer) -> !transfer.integer
  %or_1 = "transfer.or"(%inst, %known_o) : (!transfer.integer, !transfer.integer) -> !transfer.integer
  %cmp_0 = "transfer.cmp"(%or_0, %inst_not) {predicate = 0 : index} : (!transfer.integer, !transfer.integer) -> !transfer.integer<1>
  %cmp_1 = "transfer.cmp"(%or_1, %inst) {predicate = 0 : index} : (!transfer.integer, !transfer.integer) -> !transfer.integer<1>
  %result = "transfer.and"(%cmp_0, %cmp_1) : (!transfer.integer<1>, !transfer.integer<1>) -> !transfer.integer<1>
  return %result : !transfer.integer<1>
}
