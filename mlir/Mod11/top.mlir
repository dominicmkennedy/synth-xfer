func.func @getTop(%arg0: !transfer.abs_value<[i11]>) -> !transfer.abs_value<[i11]> {
  %0 = "transfer.get"(%arg0) {index = 0 : index} : (!transfer.abs_value<[i11]>) -> i11
  %1 = "transfer.get_all_ones"(%0) {value = 0 : index} : (i11) -> i11
  %2 = "transfer.make"(%1) : (i11) -> !transfer.abs_value<[i11]>
  return %2 : !transfer.abs_value<[i11]>
}
