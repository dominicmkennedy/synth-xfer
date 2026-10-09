import SynthXfer.SIntRange.Witnesses

/-!
# Select in SIntRange
-/

namespace SynthXfer.LLVM

open SIntRange

private def selectIntervals8 :
    (operand : SelectOperand) → SIntRange (operand.width 8)
  | .condition => SIntRange.ofBounds 1 0 (by decide)
  | .trueValue => SIntRange.ofBounds 0 0 (by decide)
  | .falseValue => SIntRange.ofBounds 2 2 (by decide)

private def selectTrueInputs8 :
    (operand : SelectOperand) → SignedBitVec (operand.width 8)
  | .condition => ⟨1⟩
  | .trueValue => ⟨0⟩
  | .falseValue => ⟨2⟩

private def selectFalseInputs8 :
    (operand : SelectOperand) → SignedBitVec (operand.width 8)
  | .condition => ⟨0⟩
  | .trueValue => ⟨0⟩
  | .falseValue => ⟨2⟩

theorem sintRange_select_i8_not_forwardComplete :
    ¬ NaryForwardComplete
      (fun operand : SelectOperand ↦ SIntRange.domain (operand.width 8))
      (SIntRange.domain 8) (select (n := 8)) := by
  rw [SIntRange.naryForwardComplete_iff_ordConnected]
  intro hcomplete
  have hconnected := hcomplete selectIntervals8
  have hzero : (SignedBitVec.equiv 8 0) ∈
      NaryConcreteOp.lift (SIntRange.orderedNaryRelational (select (n := 8)))
        (fun k ↦ (selectIntervals8 k : Set _)) := by
    refine ⟨selectTrueInputs8, ?_, ?_⟩
    · intro k
      cases k with
      | condition =>
          simp [selectTrueInputs8, selectIntervals8, SIntRange.ofBounds]
          decide
      | trueValue =>
          simp [selectTrueInputs8, selectIntervals8, SIntRange.ofBounds]
      | falseValue =>
          simp [selectTrueInputs8, selectIntervals8, SIntRange.ofBounds]
    · simp [SIntRange.orderedNaryRelational, NaryConcreteOp.transport,
        select, selectFn, selectTrueInputs8]
  have htwo : (SignedBitVec.equiv 8 2) ∈
      NaryConcreteOp.lift (SIntRange.orderedNaryRelational (select (n := 8)))
        (fun k ↦ (selectIntervals8 k : Set _)) := by
    refine ⟨selectFalseInputs8, ?_, ?_⟩
    · intro k
      cases k with
      | condition =>
          simp [selectFalseInputs8, selectIntervals8, SIntRange.ofBounds]
          decide
      | trueValue =>
          simp [selectFalseInputs8, selectIntervals8, SIntRange.ofBounds]
      | falseValue =>
          simp [selectFalseInputs8, selectIntervals8, SIntRange.ofBounds]
    · simp [SIntRange.orderedNaryRelational, NaryConcreteOp.transport,
        select, selectFn, selectFalseInputs8]
  have hone := hconnected.out hzero htwo
    (show SignedBitVec.equiv 8 1 ∈
      Set.Icc (SignedBitVec.equiv 8 0) (SignedBitVec.equiv 8 2) by decide)
  rcases hone with ⟨inputs, hinputs, hresult⟩
  have htrue := hinputs SelectOperand.trueValue
  have hfalse := hinputs SelectOperand.falseValue
  have htrueEq : (inputs SelectOperand.trueValue).bitvec = 0 := by
    apply BitVec.eq_of_toInt_eq
    change (0 : BitVec 8).toInt ≤
      (inputs SelectOperand.trueValue).bitvec.toInt ∧
      (inputs SelectOperand.trueValue).bitvec.toInt ≤ (0 : BitVec 8).toInt at htrue
    omega
  have hfalseEq : (inputs SelectOperand.falseValue).bitvec = 2 := by
    apply BitVec.eq_of_toInt_eq
    change (2 : BitVec 8).toInt ≤
      (inputs SelectOperand.falseValue).bitvec.toInt ∧
      (inputs SelectOperand.falseValue).bitvec.toInt ≤ (2 : BitVec 8).toInt at hfalse
    omega
  have hcond : (inputs SelectOperand.condition).bitvec = 0 ∨
      (inputs SelectOperand.condition).bitvec = 1 := by
    have hlt := (inputs SelectOperand.condition).bitvec.isLt
    change (inputs SelectOperand.condition).bitvec.toNat < 2 at hlt
    have : (inputs SelectOperand.condition).bitvec.toNat = 0 ∨
        (inputs SelectOperand.condition).bitvec.toNat = 1 := by omega
    exact this.imp BitVec.eq_of_toNat_eq BitVec.eq_of_toNat_eq
  rcases hcond with hcond | hcond <;>
    simp [SIntRange.orderedNaryRelational, NaryConcreteOp.transport,
      select, selectFn, hcond, htrueEq, hfalseEq] at hresult
  all_goals
    change (1 : BitVec 8) = (2 : BitVec 8) at hresult
    have hne : (1 : BitVec 8) ≠ 2 := by decide
    exact hne hresult

theorem sintRange_select_backwardComplete (n : Nat) :
    NaryBackwardComplete
      (fun operand : SelectOperand ↦ SIntRange.domain (operand.width n))
      (SIntRange.domain n) (select (n := n)) := by
  change NaryBackwardComplete
    (fun operand : SelectOperand ↦ SIntRange.domain (operand.width n))
    (SIntRange.domain n) (NaryConcreteOp.ofTotal selectFn)
  rw [SIntRange.naryBackwardComplete_ofTotal_iff_boundedByCornerImages]
  intro lower upper hlowerUpper x hx
  let condition := (x SelectOperand.condition).bitvec
  by_cases hc : condition = 1
  · have hlCond : (lower SelectOperand.condition).bitvec = 1 := by
      apply BitVec.eq_of_toInt_eq
      have hxLower := (hx SelectOperand.condition).1
      change (lower SelectOperand.condition).bitvec.toInt ≤ condition.toInt at hxLower
      have hcInt : condition.toInt = (1 : BitVec 1).toInt :=
        congrArg BitVec.toInt hc
      have hminimum : (1 : BitVec 1).toInt ≤
          (lower SelectOperand.condition).bitvec.toInt := by
        simpa using BitVec.le_toInt (lower SelectOperand.condition).bitvec
      omega
    let low : (k : SelectOperand) → SignedBitVec (k.width n) := fun k ↦
      match k with
      | .condition => lower .condition
      | .trueValue => lower .trueValue
      | .falseValue => lower .falseValue
    let high : (k : SelectOperand) → SignedBitVec (k.width n) := fun k ↦
      match k with
      | .condition => lower .condition
      | .trueValue => upper .trueValue
      | .falseValue => lower .falseValue
    apply IntervalDomain.mem_hull_of_between
      (a := SIntRange.orderedNary selectFn low)
      (b := SIntRange.orderedNary selectFn high)
    · exact ⟨low, by intro k; cases k <;> simp [low], rfl⟩
    · exact ⟨high, by intro k; cases k <;> simp [high], rfl⟩
    · have hbetween := hx SelectOperand.trueValue
      have horder : SIntRange.orderedNary selectFn low ≤
          SIntRange.orderedNary selectFn high := by
        simpa [SIntRange.orderedNary, selectFn, low, high, hlCond] using
          hlowerUpper SelectOperand.trueValue
      rw [min_eq_left horder, max_eq_right horder]
      simpa [SIntRange.orderedNary, selectFn, low, high, condition, hc,
        hlCond] using hbetween
  · have hcZero : condition = 0 := by
      rcases BitVec.eq_zero_or_eq_one condition with hzero | hone
      · exact hzero
      · exact (hc hone).elim
    have huCond : (upper SelectOperand.condition).bitvec = 0 := by
      apply BitVec.eq_of_toInt_eq
      have hxUpper := (hx SelectOperand.condition).2
      change condition.toInt ≤ (upper SelectOperand.condition).bitvec.toInt at hxUpper
      have hcInt : condition.toInt = (0 : BitVec 1).toInt :=
        congrArg BitVec.toInt hcZero
      have hmaximum : (upper SelectOperand.condition).bitvec.toInt ≤
          (0 : BitVec 1).toInt := by
        simpa using BitVec.toInt_le
          (x := (upper SelectOperand.condition).bitvec)
      omega
    let low : (k : SelectOperand) → SignedBitVec (k.width n) := fun k ↦
      match k with
      | .condition => upper .condition
      | .trueValue => lower .trueValue
      | .falseValue => lower .falseValue
    let high : (k : SelectOperand) → SignedBitVec (k.width n) := fun k ↦
      match k with
      | .condition => upper .condition
      | .trueValue => lower .trueValue
      | .falseValue => upper .falseValue
    apply IntervalDomain.mem_hull_of_between
      (a := SIntRange.orderedNary selectFn low)
      (b := SIntRange.orderedNary selectFn high)
    · exact ⟨low, by intro k; cases k <;> simp [low], rfl⟩
    · exact ⟨high, by intro k; cases k <;> simp [high], rfl⟩
    · have hbetween := hx SelectOperand.falseValue
      have horder : SIntRange.orderedNary selectFn low ≤
          SIntRange.orderedNary selectFn high := by
        simpa [SIntRange.orderedNary, selectFn, low, high, huCond] using
          hlowerUpper SelectOperand.falseValue
      rw [min_eq_left horder, max_eq_right horder]
      simpa [SIntRange.orderedNary, selectFn, low, high, condition, hcZero,
        huCond] using hbetween

end SynthXfer.LLVM
