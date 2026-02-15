func.func @getTop(%abst_val: !transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.abs_value<[!transfer.integer, !transfer.integer]> {
  %lb = "transfer.get"(%abst_val) {index = 0 : index} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
  %uint_min = "transfer.constant"(%lb) {value = 0 : index} : (!transfer.integer) -> !transfer.integer
  %uint_max = "transfer.get_all_ones"(%lb) {value = 0 : index} : (!transfer.integer) -> !transfer.integer
  %result = "transfer.make"(%uint_min, %uint_max) : (!transfer.integer, !transfer.integer) -> !transfer.abs_value<[!transfer.integer, !transfer.integer]>
  return %result : !transfer.abs_value<[!transfer.integer, !transfer.integer]>
}
