import SynthXfer.ConcreteOps

/-!
# LLVM integer operations

Concrete scalar semantics for the operations in the project's DSL.  Poison
and undefined behavior produce `none`; after embedding with `ofOption`, such
an input contributes no result to collecting semantics.

The definitions are available at every Lean `Nat` width.  Statements relating
them to well-formed LLVM IR should assume positive integer widths, and the
strict source/destination width inequalities required by LLVM casts.
-/

namespace SynthXfer.LLVM

/-- LLVM scalar integer types have a positive bit width. -/
def ValidIntegerWidth (n : Nat) : Prop :=
  0 < n

/-- Well-formed width relation for LLVM's `trunc`. -/
def ValidTruncWidths (sourceWidth destinationWidth : Nat) : Prop :=
  0 < destinationWidth ∧ destinationWidth < sourceWidth

/-- Well-formed width relation for LLVM's `zext` and `sext`. -/
def ValidExtensionWidths (sourceWidth destinationWidth : Nat) : Prop :=
  0 < sourceWidth ∧ sourceWidth < destinationWidth

/-- Return poison, represented by `none`, when `condition` is true. -/
def poisonIf (condition : Bool) (result : α) : Option α :=
  if condition then none else some result

@[simp]
theorem poisonIf_false (result : α) : poisonIf false result = some result :=
  rfl

@[simp]
theorem poisonIf_true (result : α) : poisonIf true result = none :=
  rfl

@[simp]
theorem poisonIf_eq_none {condition : Bool} {result : α} :
    poisonIf condition result = none ↔ condition = true := by
  cases condition <;> simp

@[simp]
theorem poisonIf_eq_some {condition : Bool} {result output : α} :
    poisonIf condition result = some output ↔
      condition = false ∧ result = output := by
  cases condition <;> simp

def unsignedMax (n : Nat) : Nat :=
  2 ^ n - 1

def signedMin (n : Nat) : Int :=
  if n = 0 then 0 else -(2 ^ (n - 1) : Nat)

def signedMax (n : Nat) : Int :=
  if n = 0 then 0 else (2 ^ (n - 1) : Nat) - 1

def clampUnsigned (n value : Nat) : BitVec n :=
  BitVec.ofNat n (min value (unsignedMax n))

def clampSigned (n : Nat) (value : Int) : BitVec n :=
  BitVec.ofInt n (max (signedMin n) (min value (signedMax n)))

def signedFits (n : Nat) (value : Int) : Bool :=
  decide (signedMin n ≤ value ∧ value ≤ signedMax n)

def validShift {n : Nat} (amount : BitVec n) : Bool :=
  decide (amount.toNat < n)

def shiftedOutBitsAreZero {n : Nat}
    (x amount : BitVec n) : Bool :=
  decide (x.toNat % (2 ^ amount.toNat) = 0)

/-! ## Unary operations -/

/-- `llvm.abs` with `is_int_min_poison = false`. -/
def abs {n : Nat} : ConcreteOp (BitVec n) (BitVec n) :=
  ConcreteOp.ofTotal BitVec.abs

/-- Deterministic semantics of `llvm.abs` with
`is_int_min_poison = true`. -/
def absUndef? {n : Nat} (x : BitVec n) : Option (BitVec n) :=
  poisonIf x.negOverflow x.abs

/-- `llvm.abs` with `is_int_min_poison = true`.

The DSL's historical `Undef` suffix denotes the intrinsic mode that actually
produces poison at the minimum signed value. -/
def absUndef {n : Nat} : ConcreteOp (BitVec n) (BitVec n) :=
  ConcreteOp.ofOption absUndef?

/-- `llvm.ctpop`. -/
def popCount {n : Nat} : ConcreteOp (BitVec n) (BitVec n) :=
  ConcreteOp.ofTotal BitVec.cpop

/-- `llvm.ctlz` with `is_zero_poison = false`. -/
def ctlz {n : Nat} : ConcreteOp (BitVec n) (BitVec n) :=
  ConcreteOp.ofTotal BitVec.clz

/-- Deterministic semantics of `llvm.ctlz` with
`is_zero_poison = true`. -/
def ctlzUndef? {n : Nat} (x : BitVec n) : Option (BitVec n) :=
  poisonIf (x == 0) x.clz

/-- `llvm.ctlz` with `is_zero_poison = true`. -/
def ctlzUndef {n : Nat} : ConcreteOp (BitVec n) (BitVec n) :=
  ConcreteOp.ofOption ctlzUndef?

/-- `llvm.cttz` with `is_zero_poison = false`. -/
def cttz {n : Nat} : ConcreteOp (BitVec n) (BitVec n) :=
  ConcreteOp.ofTotal BitVec.ctz

/-- Deterministic semantics of `llvm.cttz` with
`is_zero_poison = true`. -/
def cttzUndef? {n : Nat} (x : BitVec n) : Option (BitVec n) :=
  poisonIf (x == 0) x.ctz

/-- `llvm.cttz` with `is_zero_poison = true`. -/
def cttzUndef {n : Nat} : ConcreteOp (BitVec n) (BitVec n) :=
  ConcreteOp.ofOption cttzUndef?

/-! ## Arithmetic and bitwise operations -/

def addFn {n : Nat} (x y : BitVec n) : BitVec n := x + y

def add {n : Nat} : BinaryConcreteOp (BitVec n) (BitVec n) (BitVec n) :=
  BinaryConcreteOp.ofTotal addFn

def addNsw? {n : Nat} (x y : BitVec n) : Option (BitVec n) :=
  poisonIf (x.saddOverflow y) (x + y)

def addNsw {n : Nat} : BinaryConcreteOp (BitVec n) (BitVec n) (BitVec n) :=
  BinaryConcreteOp.ofOption addNsw?

def addNuw? {n : Nat} (x y : BitVec n) : Option (BitVec n) :=
  poisonIf (x.uaddOverflow y) (x + y)

def addNuw {n : Nat} : BinaryConcreteOp (BitVec n) (BitVec n) (BitVec n) :=
  BinaryConcreteOp.ofOption addNuw?

def addNswNuw? {n : Nat} (x y : BitVec n) : Option (BitVec n) :=
  poisonIf (x.saddOverflow y || x.uaddOverflow y) (x + y)

def addNswNuw {n : Nat} :
    BinaryConcreteOp (BitVec n) (BitVec n) (BitVec n) :=
  BinaryConcreteOp.ofOption addNswNuw?

def andFn {n : Nat} (x y : BitVec n) : BitVec n := x &&& y

def and {n : Nat} : BinaryConcreteOp (BitVec n) (BitVec n) (BitVec n) :=
  BinaryConcreteOp.ofTotal andFn

def mulFn {n : Nat} (x y : BitVec n) : BitVec n := x * y

def mul {n : Nat} : BinaryConcreteOp (BitVec n) (BitVec n) (BitVec n) :=
  BinaryConcreteOp.ofTotal mulFn

def mulNsw? {n : Nat} (x y : BitVec n) : Option (BitVec n) :=
  poisonIf (x.smulOverflow y) (x * y)

def mulNsw {n : Nat} : BinaryConcreteOp (BitVec n) (BitVec n) (BitVec n) :=
  BinaryConcreteOp.ofOption mulNsw?

def mulNuw? {n : Nat} (x y : BitVec n) : Option (BitVec n) :=
  poisonIf (x.umulOverflow y) (x * y)

def mulNuw {n : Nat} : BinaryConcreteOp (BitVec n) (BitVec n) (BitVec n) :=
  BinaryConcreteOp.ofOption mulNuw?

def mulNswNuw? {n : Nat} (x y : BitVec n) : Option (BitVec n) :=
  poisonIf (x.smulOverflow y || x.umulOverflow y) (x * y)

def mulNswNuw {n : Nat} :
    BinaryConcreteOp (BitVec n) (BitVec n) (BitVec n) :=
  BinaryConcreteOp.ofOption mulNswNuw?

def subFn {n : Nat} (x y : BitVec n) : BitVec n := x - y

def sub {n : Nat} : BinaryConcreteOp (BitVec n) (BitVec n) (BitVec n) :=
  BinaryConcreteOp.ofTotal subFn

def subNsw? {n : Nat} (x y : BitVec n) : Option (BitVec n) :=
  poisonIf (x.ssubOverflow y) (x - y)

def subNsw {n : Nat} : BinaryConcreteOp (BitVec n) (BitVec n) (BitVec n) :=
  BinaryConcreteOp.ofOption subNsw?

def subNuw? {n : Nat} (x y : BitVec n) : Option (BitVec n) :=
  poisonIf (x.usubOverflow y) (x - y)

def subNuw {n : Nat} : BinaryConcreteOp (BitVec n) (BitVec n) (BitVec n) :=
  BinaryConcreteOp.ofOption subNuw?

def subNswNuw? {n : Nat} (x y : BitVec n) : Option (BitVec n) :=
  poisonIf (x.ssubOverflow y || x.usubOverflow y) (x - y)

def subNswNuw {n : Nat} :
    BinaryConcreteOp (BitVec n) (BitVec n) (BitVec n) :=
  BinaryConcreteOp.ofOption subNswNuw?

def orFn {n : Nat} (x y : BitVec n) : BitVec n := x ||| y

def or {n : Nat} : BinaryConcreteOp (BitVec n) (BitVec n) (BitVec n) :=
  BinaryConcreteOp.ofTotal orFn

def orDisjoint? {n : Nat} (x y : BitVec n) : Option (BitVec n) :=
  poisonIf ((x &&& y) != 0) (x ||| y)

def orDisjoint {n : Nat} :
    BinaryConcreteOp (BitVec n) (BitVec n) (BitVec n) :=
  BinaryConcreteOp.ofOption orDisjoint?

def xorFn {n : Nat} (x y : BitVec n) : BitVec n := x ^^^ y

def xor {n : Nat} : BinaryConcreteOp (BitVec n) (BitVec n) (BitVec n) :=
  BinaryConcreteOp.ofTotal xorFn

/-! ## Shifts -/

def shl? {n : Nat} (x amount : BitVec n) : Option (BitVec n) :=
  poisonIf (!validShift amount) (x <<< amount.toNat)

def shl {n : Nat} : BinaryConcreteOp (BitVec n) (BitVec n) (BitVec n) :=
  BinaryConcreteOp.ofOption shl?

def shlNsw? {n : Nat} (x amount : BitVec n) : Option (BitVec n) :=
  poisonIf
    (!validShift amount ||
      !signedFits n (x.toInt * (2 ^ amount.toNat : Nat)))
    (x <<< amount.toNat)

def shlNsw {n : Nat} : BinaryConcreteOp (BitVec n) (BitVec n) (BitVec n) :=
  BinaryConcreteOp.ofOption shlNsw?

def shlNuw? {n : Nat} (x amount : BitVec n) : Option (BitVec n) :=
  poisonIf
    (!validShift amount ||
      decide (unsignedMax n < x.toNat * 2 ^ amount.toNat))
    (x <<< amount.toNat)

def shlNuw {n : Nat} : BinaryConcreteOp (BitVec n) (BitVec n) (BitVec n) :=
  BinaryConcreteOp.ofOption shlNuw?

def shlNswNuw? {n : Nat} (x amount : BitVec n) : Option (BitVec n) :=
  poisonIf
    (!validShift amount ||
      !signedFits n (x.toInt * (2 ^ amount.toNat : Nat)) ||
      decide (unsignedMax n < x.toNat * 2 ^ amount.toNat))
    (x <<< amount.toNat)

def shlNswNuw {n : Nat} :
    BinaryConcreteOp (BitVec n) (BitVec n) (BitVec n) :=
  BinaryConcreteOp.ofOption shlNswNuw?

def lshr? {n : Nat} (x amount : BitVec n) : Option (BitVec n) :=
  poisonIf (!validShift amount) (x >>> amount.toNat)

def lshr {n : Nat} : BinaryConcreteOp (BitVec n) (BitVec n) (BitVec n) :=
  BinaryConcreteOp.ofOption lshr?

def lshrExact? {n : Nat} (x amount : BitVec n) : Option (BitVec n) :=
  poisonIf
    (!validShift amount || !shiftedOutBitsAreZero x amount)
    (x >>> amount.toNat)

def lshrExact {n : Nat} :
    BinaryConcreteOp (BitVec n) (BitVec n) (BitVec n) :=
  BinaryConcreteOp.ofOption lshrExact?

def ashr? {n : Nat} (x amount : BitVec n) : Option (BitVec n) :=
  poisonIf (!validShift amount) (x.sshiftRight amount.toNat)

def ashr {n : Nat} : BinaryConcreteOp (BitVec n) (BitVec n) (BitVec n) :=
  BinaryConcreteOp.ofOption ashr?

def ashrExact? {n : Nat} (x amount : BitVec n) : Option (BitVec n) :=
  poisonIf
    (!validShift amount || !shiftedOutBitsAreZero x amount)
    (x.sshiftRight amount.toNat)

def ashrExact {n : Nat} :
    BinaryConcreteOp (BitVec n) (BitVec n) (BitVec n) :=
  BinaryConcreteOp.ofOption ashrExact?

/-! ## Division and remainder -/

def udiv? {n : Nat} (x y : BitVec n) : Option (BitVec n) :=
  poisonIf (y == 0) (x.udiv y)

def udiv {n : Nat} : BinaryConcreteOp (BitVec n) (BitVec n) (BitVec n) :=
  BinaryConcreteOp.ofOption udiv?

def udivExact? {n : Nat} (x y : BitVec n) : Option (BitVec n) :=
  poisonIf (y == 0 || x.umod y != 0) (x.udiv y)

def udivExact {n : Nat} :
    BinaryConcreteOp (BitVec n) (BitVec n) (BitVec n) :=
  BinaryConcreteOp.ofOption udivExact?

def urem? {n : Nat} (x y : BitVec n) : Option (BitVec n) :=
  poisonIf (y == 0) (x.umod y)

def urem {n : Nat} : BinaryConcreteOp (BitVec n) (BitVec n) (BitVec n) :=
  BinaryConcreteOp.ofOption urem?

def sdiv? {n : Nat} (x y : BitVec n) : Option (BitVec n) :=
  poisonIf (y == 0 || x.sdivOverflow y) (x.sdiv y)

def sdiv {n : Nat} : BinaryConcreteOp (BitVec n) (BitVec n) (BitVec n) :=
  BinaryConcreteOp.ofOption sdiv?

def sdivExact? {n : Nat} (x y : BitVec n) : Option (BitVec n) :=
  poisonIf
    (y == 0 || x.sdivOverflow y || x.srem y != 0)
    (x.sdiv y)

def sdivExact {n : Nat} :
    BinaryConcreteOp (BitVec n) (BitVec n) (BitVec n) :=
  BinaryConcreteOp.ofOption sdivExact?

def srem? {n : Nat} (x y : BitVec n) : Option (BitVec n) :=
  poisonIf (y == 0 || x.sdivOverflow y) (x.srem y)

def srem {n : Nat} : BinaryConcreteOp (BitVec n) (BitVec n) (BitVec n) :=
  BinaryConcreteOp.ofOption srem?

/-! ## Min, max, and saturating arithmetic -/

def umaxFn {n : Nat} (x y : BitVec n) : BitVec n :=
  if x.ule y then y else x

def umax {n : Nat} : BinaryConcreteOp (BitVec n) (BitVec n) (BitVec n) :=
  BinaryConcreteOp.ofTotal umaxFn

def uminFn {n : Nat} (x y : BitVec n) : BitVec n :=
  if x.ule y then x else y

def umin {n : Nat} : BinaryConcreteOp (BitVec n) (BitVec n) (BitVec n) :=
  BinaryConcreteOp.ofTotal uminFn

def smaxFn {n : Nat} (x y : BitVec n) : BitVec n :=
  if x.sle y then y else x

def smax {n : Nat} : BinaryConcreteOp (BitVec n) (BitVec n) (BitVec n) :=
  BinaryConcreteOp.ofTotal smaxFn

def sminFn {n : Nat} (x y : BitVec n) : BitVec n :=
  if x.sle y then x else y

def smin {n : Nat} : BinaryConcreteOp (BitVec n) (BitVec n) (BitVec n) :=
  BinaryConcreteOp.ofTotal sminFn

def uaddSatFn {n : Nat} (x y : BitVec n) : BitVec n :=
  clampUnsigned n (x.toNat + y.toNat)

def uaddSat {n : Nat} : BinaryConcreteOp (BitVec n) (BitVec n) (BitVec n) :=
  BinaryConcreteOp.ofTotal uaddSatFn

def usubSatFn {n : Nat} (x y : BitVec n) : BitVec n :=
  BitVec.ofNat n (x.toNat - y.toNat)

def usubSat {n : Nat} : BinaryConcreteOp (BitVec n) (BitVec n) (BitVec n) :=
  BinaryConcreteOp.ofTotal usubSatFn

def saddSatFn {n : Nat} (x y : BitVec n) : BitVec n :=
  clampSigned n (x.toInt + y.toInt)

def saddSat {n : Nat} : BinaryConcreteOp (BitVec n) (BitVec n) (BitVec n) :=
  BinaryConcreteOp.ofTotal saddSatFn

def ssubSatFn {n : Nat} (x y : BitVec n) : BitVec n :=
  clampSigned n (x.toInt - y.toInt)

def ssubSat {n : Nat} : BinaryConcreteOp (BitVec n) (BitVec n) (BitVec n) :=
  BinaryConcreteOp.ofTotal ssubSatFn

/-- `llvm.umul.fix.sat` at scale zero. -/
def umulSatFn {n : Nat} (x y : BitVec n) : BitVec n :=
  clampUnsigned n (x.toNat * y.toNat)

def umulSat {n : Nat} : BinaryConcreteOp (BitVec n) (BitVec n) (BitVec n) :=
  BinaryConcreteOp.ofTotal umulSatFn

/-- `llvm.smul.fix.sat` at scale zero. -/
def smulSatFn {n : Nat} (x y : BitVec n) : BitVec n :=
  clampSigned n (x.toInt * y.toInt)

def smulSat {n : Nat} : BinaryConcreteOp (BitVec n) (BitVec n) (BitVec n) :=
  BinaryConcreteOp.ofTotal smulSatFn

def ushlSat? {n : Nat} (x amount : BitVec n) : Option (BitVec n) :=
  if validShift amount then
    some (clampUnsigned n (x.toNat * 2 ^ amount.toNat))
  else none

def ushlSat {n : Nat} : BinaryConcreteOp (BitVec n) (BitVec n) (BitVec n) :=
  BinaryConcreteOp.ofOption ushlSat?

def sshlSat? {n : Nat} (x amount : BitVec n) : Option (BitVec n) :=
  if validShift amount then
    some (clampSigned n (x.toInt * (2 ^ amount.toNat : Nat)))
  else none

def sshlSat {n : Nat} : BinaryConcreteOp (BitVec n) (BitVec n) (BitVec n) :=
  BinaryConcreteOp.ofOption sshlSat?

/-! ## Integer comparisons -/

def comparisonFn (p : BitVec n → BitVec n → Bool)
    (x y : BitVec n) : BitVec 1 :=
  BitVec.ofBool (p x y)

def icmpEqFn {n : Nat} : BitVec n → BitVec n → BitVec 1 :=
  comparisonFn (· == ·)
def icmpNeFn {n : Nat} : BitVec n → BitVec n → BitVec 1 :=
  comparisonFn (· != ·)
def icmpSltFn {n : Nat} : BitVec n → BitVec n → BitVec 1 :=
  comparisonFn BitVec.slt
def icmpSleFn {n : Nat} : BitVec n → BitVec n → BitVec 1 :=
  comparisonFn BitVec.sle
def icmpSgtFn {n : Nat} : BitVec n → BitVec n → BitVec 1 :=
  comparisonFn fun x y ↦ y.slt x
def icmpSgeFn {n : Nat} : BitVec n → BitVec n → BitVec 1 :=
  comparisonFn fun x y ↦ y.sle x
def icmpUltFn {n : Nat} : BitVec n → BitVec n → BitVec 1 :=
  comparisonFn BitVec.ult
def icmpUleFn {n : Nat} : BitVec n → BitVec n → BitVec 1 :=
  comparisonFn BitVec.ule
def icmpUgtFn {n : Nat} : BitVec n → BitVec n → BitVec 1 :=
  comparisonFn fun x y ↦ y.ult x
def icmpUgeFn {n : Nat} : BitVec n → BitVec n → BitVec 1 :=
  comparisonFn fun x y ↦ y.ule x

def icmpEq {n : Nat} : BinaryConcreteOp (BitVec n) (BitVec n) (BitVec 1) :=
  BinaryConcreteOp.ofTotal icmpEqFn
def icmpNe {n : Nat} : BinaryConcreteOp (BitVec n) (BitVec n) (BitVec 1) :=
  BinaryConcreteOp.ofTotal icmpNeFn
def icmpSlt {n : Nat} : BinaryConcreteOp (BitVec n) (BitVec n) (BitVec 1) :=
  BinaryConcreteOp.ofTotal icmpSltFn
def icmpSle {n : Nat} : BinaryConcreteOp (BitVec n) (BitVec n) (BitVec 1) :=
  BinaryConcreteOp.ofTotal icmpSleFn
def icmpSgt {n : Nat} : BinaryConcreteOp (BitVec n) (BitVec n) (BitVec 1) :=
  BinaryConcreteOp.ofTotal icmpSgtFn
def icmpSge {n : Nat} : BinaryConcreteOp (BitVec n) (BitVec n) (BitVec 1) :=
  BinaryConcreteOp.ofTotal icmpSgeFn
def icmpUlt {n : Nat} : BinaryConcreteOp (BitVec n) (BitVec n) (BitVec 1) :=
  BinaryConcreteOp.ofTotal icmpUltFn
def icmpUle {n : Nat} : BinaryConcreteOp (BitVec n) (BitVec n) (BitVec 1) :=
  BinaryConcreteOp.ofTotal icmpUleFn
def icmpUgt {n : Nat} : BinaryConcreteOp (BitVec n) (BitVec n) (BitVec 1) :=
  BinaryConcreteOp.ofTotal icmpUgtFn
def icmpUge {n : Nat} : BinaryConcreteOp (BitVec n) (BitVec n) (BitVec 1) :=
  BinaryConcreteOp.ofTotal icmpUgeFn

/-! ## Casts and select -/

def trunc (sourceWidth destinationWidth : Nat) :
    ConcreteOp (BitVec sourceWidth) (BitVec destinationWidth) :=
  ConcreteOp.ofTotal (BitVec.setWidth destinationWidth)

def zext (sourceWidth destinationWidth : Nat) :
    ConcreteOp (BitVec sourceWidth) (BitVec destinationWidth) :=
  ConcreteOp.ofTotal (BitVec.setWidth destinationWidth)

def sext (sourceWidth destinationWidth : Nat) :
    ConcreteOp (BitVec sourceWidth) (BitVec destinationWidth) :=
  ConcreteOp.ofTotal (BitVec.signExtend destinationWidth)

/-- Zero extension specialized to an `i1` source. -/
def zextBool (destinationWidth : Nat) :
    ConcreteOp (BitVec 1) (BitVec destinationWidth) :=
  zext 1 destinationWidth

/-- Sign extension specialized to an `i1` source. -/
def sextBool (destinationWidth : Nat) :
    ConcreteOp (BitVec 1) (BitVec destinationWidth) :=
  sext 1 destinationWidth

/-- Truncation specialized to an `i1` destination. -/
def truncToBool (sourceWidth : Nat) :
    ConcreteOp (BitVec sourceWidth) (BitVec 1) :=
  trunc sourceWidth 1

inductive SelectOperand where
  | condition
  | trueValue
  | falseValue
  deriving DecidableEq

instance : Fintype SelectOperand where
  elems := {.condition, .trueValue, .falseValue}
  complete x := by cases x <;> simp

abbrev SelectOperand.width (n : Nat) : SelectOperand → Nat
  | .condition => 1
  | .trueValue => n
  | .falseValue => n

abbrev SelectOperand.type (n : Nat) (operand : SelectOperand) : Type :=
  BitVec (operand.width n)

def selectFn {n : Nat}
    (args : (i : SelectOperand) → SelectOperand.type n i) : BitVec n :=
  if (show BitVec 1 from args SelectOperand.condition) == 1 then
    (args SelectOperand.trueValue : BitVec n)
  else
    (args SelectOperand.falseValue : BitVec n)

/-- Scalar `select`, represented through the canonical heterogeneous n-ary
operation API. -/
def select {n : Nat} :
    NaryConcreteOp SelectOperand (SelectOperand.type n) (BitVec n) :=
  NaryConcreteOp.ofTotal selectFn

end SynthXfer.LLVM
