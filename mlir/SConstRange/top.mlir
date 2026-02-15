func.func @getTop(%abst_val: !transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.abs_value<[!transfer.integer, !transfer.integer]> {
  %lb = "transfer.get"(%abst_val) {index = 0 : index} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
  %int_min = "transfer.get_signed_min_value"(%lb) {value = 0 : index} : (!transfer.integer) -> !transfer.integer
  %int_max = "transfer.get_signed_max_value"(%lb) {value = 0 : index} : (!transfer.integer) -> !transfer.integer
  %result = "transfer.make"(%int_min, %int_max) : (!transfer.integer, !transfer.integer) -> !transfer.abs_value<[!transfer.integer, !transfer.integer]>
  return %result : !transfer.abs_value<[!transfer.integer, !transfer.integer]>
}
