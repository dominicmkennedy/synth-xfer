func.func @xfer_nop(%arg0: !transfer.abs_value<[i5]>) -> !transfer.abs_value<[i5]> {
  return %arg0 : !transfer.abs_value<[i5]>
}
