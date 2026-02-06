func.func @getInstanceConstraint(%x_abst: !transfer.abs_value<[i7]>, %inst: !transfer.integer) -> i1 {
  %x = "transfer.get"(%x_abst) {index = 0 : index} : (!transfer.abs_value<[i7]>) -> i7

  %const7 = "transfer.constant"(%inst) {value = 7 : index} : (!transfer.integer) -> !transfer.integer
  %residue = "transfer.urem"(%inst, %const7) : (!transfer.integer, !transfer.integer) -> !transfer.integer

  %const1 = "transfer.constant"(%inst) {value = 1 : index} : (!transfer.integer) -> !transfer.integer
  %residue_bit = "transfer.shl"(%const1, %residue) : (!transfer.integer, !transfer.integer) -> !transfer.integer

  %const0 = "transfer.constant"(%x) {value = 0 : index} : (i7) -> i7
  %residue_bit_trunc = "transfer.extract"(%residue_bit, %const7, %const0) : (!transfer.integer, !transfer.integer, i7) -> i7

  %bitSet = "transfer.and"(%residue_bit_trunc, %x) : (i7, i7) -> i7
  %result = "transfer.cmp"(%bitSet, %const0) {predicate = 1 : i64} : (i7, i7) -> i1

  return %result : i1
}
