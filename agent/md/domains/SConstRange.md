## DOMAIN_SEMANTICS
A SConstRange abstract value is a 2-tuple `(lo, hi)` of signed `bw`-bit integers (two's complement), representing the inclusive interval `[lo, hi]` of concrete signed values.
  • A concrete value `x` is in the range iff `lo <= x <= hi` (signed comparison).
  • `lo > hi` (signed) denotes **bottom** — the empty interval / infeasible.
Top is `[-2^(bw-1), 2^(bw-1) - 1]` (the full signed range).
Meet is interval intersection: `(smax(lo₁, lo₂), smin(hi₁, hi₂))` using **signed** max/min.

## BOTTOM_REPR
`lo = 2^(bw-1) - 1, hi = -2^(bw-1)` (canonical empty interval, since `lo > hi` signed)
