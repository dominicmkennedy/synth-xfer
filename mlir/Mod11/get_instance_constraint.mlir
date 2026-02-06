func.func @getInstanceConstraint(%x_abst: !transfer.abs_value<[i11]>, %inst: !transfer.integer) -> i1 {
  %x = "transfer.get"(%x_abst) {index = 0 : index} : (!transfer.abs_value<[i11]>) -> i11

  %const11 = "transfer.constant"(%inst) {value = 11 : index} : (!transfer.integer) -> !transfer.integer
  %residue = "transfer.urem"(%inst, %const11) : (!transfer.integer, !transfer.integer) -> !transfer.integer

  %const1 = "transfer.constant"(%inst) {value = 1 : index} : (!transfer.integer) -> !transfer.integer
  %residue_bit = "transfer.shl"(%const1, %residue) : (!transfer.integer, !transfer.integer) -> !transfer.integer

  %const0 = "transfer.constant"(%x) {value = 0 : index} : (i11) -> i11
  %residue_bit_trunc = "transfer.extract"(%residue_bit, %const11, %const0) : (!transfer.integer, !transfer.integer, i11) -> i11

  %bitSet = "transfer.and"(%residue_bit_trunc, %x) : (i11, i11) -> i11
  %result = "transfer.cmp"(%bitSet, %const0) {predicate = 1 : i64} : (i11, i11) -> i1

  return %result : i1
}
