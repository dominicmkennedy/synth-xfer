func.func @getTop(%arg0: !transfer.abs_value<[i7]>) -> !transfer.abs_value<[i7]> {
  %0 = "transfer.get"(%arg0) {index = 0 : index} : (!transfer.abs_value<[i7]>) -> i7
  %1 = "transfer.get_all_ones"(%0) {value = 0 : index} : (i7) -> i7
  %2 = "transfer.make"(%1) : (i7) -> !transfer.abs_value<[i7]>
  return %2 : !transfer.abs_value<[i7]>
}
