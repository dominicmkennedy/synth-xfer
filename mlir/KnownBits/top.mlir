func.func @getTop(%abst_val: !transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.abs_value<[!transfer.integer, !transfer.integer]> {
  %known_z = "transfer.get"(%abst_val) {index = 0 : index} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
  %const_0 = "transfer.constant"(%known_z) {value = 0 : index} : (!transfer.integer) -> !transfer.integer
  %result = "transfer.make"(%const_0, %const_0) : (!transfer.integer, !transfer.integer) -> !transfer.abs_value<[!transfer.integer, !transfer.integer]>
  return %result : !transfer.abs_value<[!transfer.integer, !transfer.integer]>
}
