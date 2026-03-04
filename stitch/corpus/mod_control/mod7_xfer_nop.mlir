func.func @xfer_nop(%arg0: !transfer.abs_value<[i7]>) -> !transfer.abs_value<[i7]> {
  return %arg0 : !transfer.abs_value<[i7]>
}
