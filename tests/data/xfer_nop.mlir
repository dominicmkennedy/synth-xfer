func.func @xfer_nop(%x : !transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.abs_value<[!transfer.integer, !transfer.integer]> {
  func.return %x : !transfer.abs_value<[!transfer.integer, !transfer.integer]>
}
