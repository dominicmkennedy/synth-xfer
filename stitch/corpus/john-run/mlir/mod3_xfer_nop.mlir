func.func @xfer_nop(%arg0: !transfer.abs_value<[i3]>) -> !transfer.abs_value<[i3]> {
  return %arg0 : !transfer.abs_value<[i3]>
}
