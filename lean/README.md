# Lean formalization

A Lean 4 / Mathlib formalization of forward and backward completeness of
abstract domains for fixed-width bitvector operations. It covers the
KnownBits, unsigned-range (`UIntRange`), and signed-range (`SIntRange`)
domains, and classifies the LLVM integer operations from the DSL under each.

## Building

Requires [elan](https://github.com/leanprover/elan); it installs the Lean
version pinned in `lean-toolchain`. From this directory:

```sh
lake exe cache get                          # download prebuilt Mathlib
lake build                                  # kernel-check every proof
lake env lean SynthXfer/Certification.lean  # axiom audit + status tables
```

## Semantics

- An operation from `C` to `D` is a relation `C → Set D`, which covers total,
  partial, and nondeterministic operations. Poison and UB give the empty set,
  so undefined executions are discarded by collecting semantics.
- Multi-operand operations take independent abstract operands. The concrete
  meaning ranges over the Cartesian product of their concretizations, so
  correlations between operands are not represented.
- The heterogeneous n-ary definitions are canonical. Unary and binary APIs are
  proved equivalent to their `Fin 1` / `Fin 2` specializations.
- Operand and result types may differ, as for casts, comparisons, and
  `select`.

## Main results

**Generic** (`AbstractDomain.lean`, `ConcreteOps.lean`): completeness is
invariant under changes of concrete representation. Witness theorems turn a
concrete closure mismatch into an incompleteness proof.

**Intervals** (`Interval.lean`): unary backward completeness holds iff every
result produced inside an interval lies in the hull of the results at its
endpoints. The n-ary version uses the corners of the operand box. An undefined
endpoint or corner contributes no result.

**KnownBits** (`KnownBits.lean`):
- forward completeness iff KnownBits-representable input sets always produce
  a representable output set;
- backward completeness iff, for every observable output fact (definedness,
  "bit `i` can be `b`"), the inputs unable to produce it form a representable
  set.

For deterministic total functions, these reduce to dependency conditions:
forward iff distinct output bits depend on disjoint input bits, and backward
iff each output bit depends on at most one input bit (per operand, in each
fixed context).

**Operations** (`KnownBits/LLVMOps.lean`, `UIntRange/`, `SIntRange/`): one
classification per domain, operation, and direction. For example, in
`UIntRange`, `add nuw` is forward complete but not backward complete: for i8
operands `{0, 2}` and `{0, 254}` the defined results span `[0, 254]`, but the
closed operands admit `1 + 254 = 255`. Unsigned saturating add is complete in
both directions.

## Certification

`lake build` succeeding means Lean's kernel has checked every proof.
`SynthXfer/Certification.lean` prints `#print axioms` for the headline
theorems, then renders a status table for each domain. Every classified
cell is a Lean value carrying its proof: `complete` is proved for every width,
and `incomplete i8` carries an explicit 8-bit counterexample. `?` marks an
operation that has not been classified yet.

Every axiom list should contain only `propext`, `Classical.choice`, and
`Quot.sound`. Any `sorryAx`, project axiom, or native-evaluation axiom means a
result is not certified. A quick source check:

```sh
rg -n '\b(sorry|admit|native_decide)\b|^\s*axiom\b' SynthXfer
```

When adding a result, state the theorem as the exact completeness proposition
or its negation, and prove completeness for all widths rather than by
enumeration. Give incompleteness an explicit i8 witness, and add it to the
tables in `Certification.lean`.
