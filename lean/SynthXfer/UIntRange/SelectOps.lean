import SynthXfer.UIntRange.Witnesses
import Std.Tactic.BVDecide

/-!
# Select in UIntRange
-/

namespace SynthXfer.LLVM

open UIntRange

private def selectIntervals8 :
    (operand : SelectOperand) → UIntRange (operand.width 8)
  | .condition => UIntRange.ofBounds 0 1 (by decide)
  | .trueValue => UIntRange.ofBounds 0 0 (by decide)
  | .falseValue => UIntRange.ofBounds 2 2 (by decide)

private def selectTrueInputs8 :
    (operand : SelectOperand) → UnsignedBitVec (operand.width 8)
  | .condition => ⟨1⟩
  | .trueValue => ⟨0⟩
  | .falseValue => ⟨2⟩

private def selectFalseInputs8 :
    (operand : SelectOperand) → UnsignedBitVec (operand.width 8)
  | .condition => ⟨0⟩
  | .trueValue => ⟨0⟩
  | .falseValue => ⟨2⟩

theorem uintRange_select_i8_not_forwardComplete :
    ¬ NaryForwardComplete
      (fun operand : SelectOperand ↦ UIntRange.domain (operand.width 8))
      (UIntRange.domain 8) (select (n := 8)) := by
  rw [UIntRange.naryForwardComplete_iff_ordConnected]
  intro hcomplete
  have hconnected := hcomplete selectIntervals8
  have hzero : (UnsignedBitVec.equiv 8 0) ∈
      NaryConcreteOp.lift (UIntRange.orderedNaryRelational (select (n := 8)))
        (fun k ↦ (selectIntervals8 k : Set _)) := by
    refine ⟨selectTrueInputs8, ?_, ?_⟩
    · intro k
      cases k <;> simp [selectTrueInputs8, selectIntervals8,
        UIntRange.ofBounds]
    · simp [UIntRange.orderedNaryRelational, NaryConcreteOp.transport,
        select, selectFn, selectTrueInputs8]
  have htwo : (UnsignedBitVec.equiv 8 2) ∈
      NaryConcreteOp.lift (UIntRange.orderedNaryRelational (select (n := 8)))
        (fun k ↦ (selectIntervals8 k : Set _)) := by
    refine ⟨selectFalseInputs8, ?_, ?_⟩
    · intro k
      cases k <;> simp [selectFalseInputs8, selectIntervals8,
        UIntRange.ofBounds]
    · simp [UIntRange.orderedNaryRelational, NaryConcreteOp.transport,
        select, selectFn, selectFalseInputs8]
  have hone := hconnected.out hzero htwo
    (show UnsignedBitVec.equiv 8 1 ∈
      Set.Icc (UnsignedBitVec.equiv 8 0) (UnsignedBitVec.equiv 8 2) by decide)
  rcases hone with ⟨inputs, hinputs, hresult⟩
  have htrue := hinputs SelectOperand.trueValue
  have hfalse := hinputs SelectOperand.falseValue
  have htrueEq : (inputs SelectOperand.trueValue).bitvec = 0 := by
    apply BitVec.eq_of_toNat_eq
    change (0 : BitVec 8).toNat ≤
      (inputs SelectOperand.trueValue).bitvec.toNat ∧
      (inputs SelectOperand.trueValue).bitvec.toNat ≤ (0 : BitVec 8).toNat at htrue
    omega
  have hfalseEq : (inputs SelectOperand.falseValue).bitvec = 2 := by
    apply BitVec.eq_of_toNat_eq
    change (2 : BitVec 8).toNat ≤
      (inputs SelectOperand.falseValue).bitvec.toNat ∧
      (inputs SelectOperand.falseValue).bitvec.toNat ≤ (2 : BitVec 8).toNat at hfalse
    omega
  have hcond : (inputs SelectOperand.condition).bitvec = 0 ∨
      (inputs SelectOperand.condition).bitvec = 1 := by
    have hlt := (inputs SelectOperand.condition).bitvec.isLt
    change (inputs SelectOperand.condition).bitvec.toNat < 2 at hlt
    have : (inputs SelectOperand.condition).bitvec.toNat = 0 ∨
        (inputs SelectOperand.condition).bitvec.toNat = 1 := by omega
    exact this.imp BitVec.eq_of_toNat_eq BitVec.eq_of_toNat_eq
  rcases hcond with hcond | hcond <;>
    simp [UIntRange.orderedNaryRelational, NaryConcreteOp.transport,
      select, selectFn, hcond, htrueEq, hfalseEq] at hresult
  all_goals
    change (1 : BitVec 8) = (2 : BitVec 8) at hresult
    bv_decide

theorem uintRange_select_backwardComplete (n : Nat) :
    NaryBackwardComplete
      (fun operand : SelectOperand ↦ UIntRange.domain (operand.width n))
      (UIntRange.domain n) (select (n := n)) := by
  change NaryBackwardComplete
    (fun operand : SelectOperand ↦ UIntRange.domain (operand.width n))
    (UIntRange.domain n) (NaryConcreteOp.ofTotal selectFn)
  rw [UIntRange.naryBackwardComplete_ofTotal_iff_boundedByCornerImages]
  intro lower upper hlowerUpper x hx
  let condition := (x SelectOperand.condition).bitvec
  by_cases hc : condition = 1
  · have huCond : (upper SelectOperand.condition).bitvec = 1 := by
      change (upper SelectOperand.condition).bitvec = (1 : BitVec 1)
      have huLt := (upper SelectOperand.condition).bitvec.isLt
      change (upper SelectOperand.condition).bitvec.toNat < 2 at huLt
      have hxUpper := (hx SelectOperand.condition).2
      change condition.toNat ≤ (upper SelectOperand.condition).bitvec.toNat at hxUpper
      have hcNat : condition.toNat = 1 := congrArg BitVec.toNat hc
      change condition.toNat = 1 at hcNat
      have huNat : (upper SelectOperand.condition).bitvec.toNat = 1 := by omega
      apply BitVec.eq_of_toNat_eq
      simpa using huNat
    let low : (k : SelectOperand) → UnsignedBitVec (k.width n) := fun k ↦
      match k with
      | .condition => upper .condition
      | .trueValue => lower .trueValue
      | .falseValue => lower .falseValue
    let high : (k : SelectOperand) → UnsignedBitVec (k.width n) := fun k ↦
      match k with
      | .condition => upper .condition
      | .trueValue => upper .trueValue
      | .falseValue => lower .falseValue
    apply IntervalDomain.mem_hull_of_between
      (a := UIntRange.orderedNary selectFn low)
      (b := UIntRange.orderedNary selectFn high)
    · exact ⟨low, by intro k; cases k <;> simp [low], rfl⟩
    · exact ⟨high, by intro k; cases k <;> simp [high], rfl⟩
    · have hbetween := hx SelectOperand.trueValue
      have horder : UIntRange.orderedNary selectFn low ≤
          UIntRange.orderedNary selectFn high := by
        simpa [UIntRange.orderedNary, selectFn, low, high, huCond] using
          hlowerUpper SelectOperand.trueValue
      rw [min_eq_left horder, max_eq_right horder]
      simpa [UIntRange.orderedNary, selectFn, low, high, condition, hc,
        huCond] using hbetween
  · have hcZero : condition = 0 := by
      change condition = (0 : BitVec 1)
      have hlt := condition.isLt
      change condition.toNat < 2 at hlt
      have hne : condition.toNat ≠ 1 := by
        intro h
        apply hc
        apply BitVec.eq_of_toNat_eq
        simpa using h
      have hzero : condition.toNat = 0 := by omega
      apply BitVec.eq_of_toNat_eq
      simpa using hzero
    have hlCond : (lower SelectOperand.condition).bitvec = 0 := by
      change (lower SelectOperand.condition).bitvec = (0 : BitVec 1)
      have hxLower := (hx SelectOperand.condition).1
      change (lower SelectOperand.condition).bitvec.toNat ≤ condition.toNat at hxLower
      have hcZeroNat : condition.toNat = 0 := congrArg BitVec.toNat hcZero
      change condition.toNat = 0 at hcZeroNat
      have hlNat : (lower SelectOperand.condition).bitvec.toNat = 0 := by omega
      apply BitVec.eq_of_toNat_eq
      simpa using hlNat
    let low : (k : SelectOperand) → UnsignedBitVec (k.width n) := fun k ↦
      match k with
      | .condition => lower .condition
      | .trueValue => lower .trueValue
      | .falseValue => lower .falseValue
    let high : (k : SelectOperand) → UnsignedBitVec (k.width n) := fun k ↦
      match k with
      | .condition => lower .condition
      | .trueValue => lower .trueValue
      | .falseValue => upper .falseValue
    apply IntervalDomain.mem_hull_of_between
      (a := UIntRange.orderedNary selectFn low)
      (b := UIntRange.orderedNary selectFn high)
    · exact ⟨low, by intro k; cases k <;> simp [low], rfl⟩
    · exact ⟨high, by intro k; cases k <;> simp [high], rfl⟩
    · have hbetween := hx SelectOperand.falseValue
      have horder : UIntRange.orderedNary selectFn low ≤
          UIntRange.orderedNary selectFn high := by
        simpa [UIntRange.orderedNary, selectFn, low, high, hlCond] using
          hlowerUpper SelectOperand.falseValue
      rw [min_eq_left horder, max_eq_right horder]
      simpa [UIntRange.orderedNary, selectFn, low, high, condition, hcZero,
        hlCond] using hbetween


end SynthXfer.LLVM
