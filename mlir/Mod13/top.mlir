func.func @getTop(%arg0: !transfer.abs_value<[i13]>) -> !transfer.abs_value<[i13]> {
  %0 = "transfer.get"(%arg0) {index = 0 : index} : (!transfer.abs_value<[i13]>) -> i13
  %1 = "transfer.get_all_ones"(%0) {value = 0 : index} : (i13) -> i13
  %2 = "transfer.make"(%1) : (i13) -> !transfer.abs_value<[i13]>
  return %2 : !transfer.abs_value<[i13]>
}
