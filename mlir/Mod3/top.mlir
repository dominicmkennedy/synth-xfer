func.func @getTop(%arg0: !transfer.abs_value<[i3]>) -> !transfer.abs_value<[i3]> {
  %0 = "transfer.get"(%arg0) {index = 0 : index} : (!transfer.abs_value<[i3]>) -> i3
  %1 = "transfer.get_all_ones"(%0) {value = 0 : index} : (i3) -> i3
  %2 = "transfer.make"(%1) : (i3) -> !transfer.abs_value<[i3]>
  return %2 : !transfer.abs_value<[i3]>
}
