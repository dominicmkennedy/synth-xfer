func.func @getConstraint(%abst_val: !transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer<1> {
  %known_z = "transfer.get"(%abst_val) {index = 0 : index} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
  %known_o = "transfer.get"(%abst_val) {index = 1 : index} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
  %known_conflicts = "transfer.and"(%known_z, %known_o) : (!transfer.integer, !transfer.integer) -> !transfer.integer
  %const_0 = "transfer.constant"(%known_z) {value = 0 : index} : (!transfer.integer) -> !transfer.integer
  %result = "transfer.cmp"(%known_conflicts, %const_0) {predicate = 0 : index} : (!transfer.integer, !transfer.integer) -> !transfer.integer<1>
  return %result : !transfer.integer<1>
}
