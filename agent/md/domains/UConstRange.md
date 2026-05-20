## DOMAIN_SEMANTICS
A UConstRange abstract value is a 2-tuple `(lo, hi)` of unsigned `bw`-bit integers, representing the inclusive interval `[lo, hi]` of concrete unsigned values.
  • A concrete value `x` is in the range iff `lo <= x <= hi` (unsigned comparison).
  • `lo > hi` (unsigned) denotes **bottom** — the empty interval / infeasible.
Top is `[0, 2^bw - 1]` (the full unsigned range).
Meet is interval intersection: `(max(lo₁, lo₂), min(hi₁, hi₂))` using **unsigned** max/min.

## BOTTOM_REPR
`lo = 2^bw - 1, hi = 0` (canonical empty interval, since `lo > hi` unsigned)
