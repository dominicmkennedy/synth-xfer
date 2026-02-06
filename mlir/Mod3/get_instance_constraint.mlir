func.func @getInstanceConstraint(%x_abst: !transfer.abs_value<[i3]>, %inst: !transfer.integer) -> i1 {
  %x = "transfer.get"(%x_abst) {index = 0 : index} : (!transfer.abs_value<[i3]>) -> i3

  %const3 = "transfer.constant"(%inst) {value = 3 : index} : (!transfer.integer) -> !transfer.integer
  %residue = "transfer.urem"(%inst, %const3) : (!transfer.integer, !transfer.integer) -> !transfer.integer

  %const1 = "transfer.constant"(%inst) {value = 1 : index} : (!transfer.integer) -> !transfer.integer
  %residue_bit = "transfer.shl"(%const1, %residue) : (!transfer.integer, !transfer.integer) -> !transfer.integer

  %const0 = "transfer.constant"(%x) {value = 0 : index} : (i3) -> i3
  %residue_bit_trunc = "transfer.extract"(%residue_bit, %const3, %const0) : (!transfer.integer, !transfer.integer, i3) -> i3

  %bitSet = "transfer.and"(%residue_bit_trunc, %x) : (i3, i3) -> i3
  %result = "transfer.cmp"(%bitSet, %const0) {predicate = 1 : i64} : (i3, i3) -> i1

  return %result : i1
}
