builtin.module {
  func.func @shift_by_1(%0 : !transfer.integer) -> !transfer.integer {
    // This is a simple function that shifts an integer left by 1.
    %one = "transfer.constant"(%0) {value = 1} : () -> !transfer.integer
    %res = "transfer.shl"(%0, %one) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    func.return %res : !transfer.integer
  }

  func.func @get_max_value(%0 : !transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer {
    // This function gets the maximum value of the given KnownBits value.
    %known0 = "transfer.get"(%0) {index = 0} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %max_value = "transfer.neg"(%known0) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    func.return %max_value : !transfer.integer
  }

  func.func @get_min_value(%0 : !transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer {
    // This function gets the minimum value of the given KnownBits value.
    %known1 = "transfer.get"(%0) {index = 1} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    func.return %known1 : !transfer.integer
  }

}
