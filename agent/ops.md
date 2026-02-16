# Available Operations

## Boolean Operations (i1)

- transfer.cmp: (!transfer.integer, !transfer.integer) -> i1
- arith.andi: (i1, i1) -> i1
- arith.ori: (i1, i1) -> i1
- arith.xori: (i1, i1) -> i1

## Integer Operations

- transfer.neg: (!transfer.integer) -> !transfer.integer
- transfer.and: (!transfer.integer, !transfer.integer) -> !transfer.integer
- transfer.or: (!transfer.integer, !transfer.integer) -> !transfer.integer
- transfer.xor: (!transfer.integer, !transfer.integer) -> !transfer.integer
- transfer.add: (!transfer.integer, !transfer.integer) -> !transfer.integer
- transfer.sub: (!transfer.integer, !transfer.integer) -> !transfer.integer
- transfer.select: (i1, !transfer.integer, !transfer.integer) -> !transfer.integer
- transfer.mul: (!transfer.integer, !transfer.integer) -> !transfer.integer
- transfer.lshr: (!transfer.integer, !transfer.integer) -> !transfer.integer
- transfer.shl: (!transfer.integer, !transfer.integer) -> !transfer.integer
- transfer.umin: (!transfer.integer, !transfer.integer) -> !transfer.integer
- transfer.umax: (!transfer.integer, !transfer.integer) -> !transfer.integer
- transfer.smin: (!transfer.integer, !transfer.integer) -> !transfer.integer
- transfer.smax: (!transfer.integer, !transfer.integer) -> !transfer.integer
- transfer.udiv: (!transfer.integer, !transfer.integer) -> !transfer.integer
- transfer.sdiv: (!transfer.integer, !transfer.integer) -> !transfer.integer
- transfer.urem: (!transfer.integer, !transfer.integer) -> !transfer.integer
- transfer.srem: (!transfer.integer, !transfer.integer) -> !transfer.integer
- transfer.set_high_bits: (!transfer.integer, !transfer.integer) -> !transfer.integer
- transfer.set_low_bits: (!transfer.integer, !transfer.integer) -> !transfer.integer
- transfer.clear_high_bits: (!transfer.integer, !transfer.integer) -> !transfer.integer
- transfer.clear_low_bits: (!transfer.integer, !transfer.integer) -> !transfer.integer
- transfer.set_signed_bits: (!transfer.integer, !transfer.integer) -> !transfer.integer
- transfer.clear_signed_bits: (!transfer.integer, !transfer.integer) -> !transfer.integer
- transfer.count_l_one: (!transfer.integer) -> !transfer.integer
- transfer.count_l_zero: (!transfer.integer) -> !transfer.integer
- transfer.count_r_one: (!transfer.integer) -> !transfer.integer
- transfer.count_r_zero: (!transfer.integer) -> !transfer.integer

## Utility Operations

- transfer.constant: (!transfer.integer) -> !transfer.integer
    - example: `%const0 = "transfer.constant"(%arg){value=42:index} : (!transfer.integer) -> !transfer.integer` provides constant 42.
    - the argument `%arg` is to decide bitwidth
- transfer.get_all_ones: (!transfer.integer) -> !transfer.integer
    - the argument is to decide bitwidth
- transfer.get_bit_width: (!transfer.integer) -> !transfer.integer
