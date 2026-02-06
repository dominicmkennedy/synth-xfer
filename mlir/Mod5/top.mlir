func.func @getTop(%arg0: !transfer.abs_value<[i5]>) -> !transfer.abs_value<[i5]> {
  %0 = "transfer.get"(%arg0) {index = 0 : index} : (!transfer.abs_value<[i5]>) -> i5
  %1 = "transfer.get_all_ones"(%0) {value = 0 : index} : (i5) -> i5
  %2 = "transfer.make"(%1) : (i5) -> !transfer.abs_value<[i5]>
  return %2 : !transfer.abs_value<[i5]>
}
