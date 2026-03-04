builtin.module {
  func.func @unknown_mask_from_knownbits(%kb : !transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer {
    // Computes the mask of bits not known to be zero or one.
    %known0 = "transfer.get"(%kb) {index = 0} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %known1 = "transfer.get"(%kb) {index = 1} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %all_ones = "transfer.get_all_ones"(%known0) : (!transfer.integer) -> !transfer.integer
    %known_union = "transfer.or"(%known0, %known1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %unknown = "transfer.xor"(%known_union, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    func.return %unknown : !transfer.integer
  }
  func.func @knownbits_is_constant(%kb : !transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> i1 {
    // Returns true when the KnownBits value represents an exact constant.
    %known0 = "transfer.get"(%kb) {index = 0} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %known1 = "transfer.get"(%kb) {index = 1} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
    %all_ones = "transfer.get_all_ones"(%known0) : (!transfer.integer) -> !transfer.integer
    %known1_not = "transfer.xor"(%known1, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %is_const = "transfer.cmp"(%known0, %known1_not) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    func.return %is_const : i1
  }
  func.func @unknown_mask_is_single_bit(%mask : !transfer.integer) -> i1 {
    // Tests whether the mask has exactly one bit set, i.e., a single unknown bit.
    %const0 = "transfer.constant"(%mask) {value = 0 : index} : (!transfer.integer) -> !transfer.integer
    %const1 = "transfer.constant"(%mask) {value = 1 : index} : (!transfer.integer) -> !transfer.integer
    %nonzero = "transfer.cmp"(%mask, %const0) {predicate = 1 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %minus1 = "transfer.sub"(%mask, %const1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %and = "transfer.and"(%mask, %minus1) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pow2ish = "transfer.cmp"(%and, %const0) {predicate = 0 : i64} : (!transfer.integer, !transfer.integer) -> i1
    %is_single = "arith.andi"(%nonzero, %pow2ish) : (i1, i1) -> i1
    func.return %is_single : i1
  }
  func.func @split_lowbit_and_rest(%mask : !transfer.integer) -> !transfer.abs_value<[!transfer.integer, !transfer.integer]> {
    // Splits a mask into its lowest set bit and the remaining bits.
    %neg = "transfer.neg"(%mask) : (!transfer.integer) -> !transfer.integer
    %lowbit = "transfer.and"(%mask, %neg) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %rest = "transfer.xor"(%mask, %lowbit) : (!transfer.integer, !transfer.integer) -> !transfer.integer
    %pair = "transfer.make"(%lowbit, %rest) : (!transfer.integer, !transfer.integer) -> !transfer.abs_value<[!transfer.integer, !transfer.integer]>
    func.return %pair : !transfer.abs_value<[!transfer.integer, !transfer.integer]>
  }
}