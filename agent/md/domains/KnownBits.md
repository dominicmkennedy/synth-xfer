## DOMAIN_SEMANTICS
A KnownBits abstract value is a 2-tuple `(known_zero, known_one)` of bitvectors of width `bw`:
  • `known_zero[i] = 1` iff bit i of every concretization is 0
  • `known_one[i]  = 1` iff bit i of every concretization is 1
For any concrete bit, at most one of the two masks is set; if both are set the value is **bottom** (the empty set, infeasible).
Top is `(0, 0)` (every bit is `?`/unknown).
Meet is bitwise OR on each component (refines toward fewer concretizations).

## BOTTOM_REPR
`KnownZero = 1...1` and `KnownOne = 1...1` (every bit is forced to be both 0 and 1, which is infeasible)
