import SynthXfer.SIntRange.Witnesses
import Std.Tactic.BVDecide

namespace SynthXfer.LLVM

open SIntRange

private theorem addWrapGapInputs
    (x y : BitVec 8)
    (hxLower : (128 : BitVec 8).toInt ≤ x.toInt)
    (hxUpper : x.toInt ≤ (128 : BitVec 8).toInt)
    (hyLower : (254 : BitVec 8).toInt ≤ y.toInt)
    (hyUpper : y.toInt ≤ (0 : BitVec 8).toInt) :
    x = 128 ∧ (y = 254 ∨ y = 255 ∨ y = 0) := by
  have hxValue : (128 : BitVec 8).toInt = -128 := by bv_decide
  have hyLowerValue : (254 : BitVec 8).toInt = -2 := by bv_decide
  have hyUpperValue : (0 : BitVec 8).toInt = 0 := by bv_decide
  rw [hxValue] at hxLower hxUpper
  rw [hyLowerValue] at hyLower
  rw [hyUpperValue] at hyUpper
  constructor
  · apply BitVec.eq_of_toInt_eq
    rw [hxValue]
    omega
  · have hy : y.toInt = -2 ∨ y.toInt = -1 ∨ y.toInt = 0 := by omega
    rcases hy with hy | hy | hy
    · left; apply BitVec.eq_of_toInt_eq; simpa using hy
    · right; left; apply BitVec.eq_of_toInt_eq; simpa using hy
    · right; right; apply BitVec.eq_of_toInt_eq; simpa using hy

theorem sintRange_add_i8_not_forwardComplete :
    ¬ BinaryForwardComplete (SIntRange.domain 8) (SIntRange.domain 8)
      (SIntRange.domain 8)
      (add : BinaryConcreteOp (BitVec 8) (BitVec 8) (BitVec 8)) := by
  apply binaryForwardIncompleteOfGap_i8 add
    128 128 254 0 128 129 127
    (by bv_decide) (by bv_decide) (by bv_decide)
    128 0 128 255 (by bv_decide) (by bv_decide)
  · simp [add, addFn]
  · simp [add, addFn]
  · intro x y hxLower hxUpper hyLower hyUpper
    obtain ⟨rfl, hy⟩ := addWrapGapInputs x y hxLower hxUpper hyLower hyUpper
    rcases hy with rfl | rfl | rfl <;> simp [add, addFn] <;> bv_decide

theorem sintRange_addNuw_i8_not_forwardComplete :
    ¬ BinaryForwardComplete (SIntRange.domain 8) (SIntRange.domain 8)
      (SIntRange.domain 8)
      (addNuw : BinaryConcreteOp (BitVec 8) (BitVec 8) (BitVec 8)) := by
  apply binaryForwardIncompleteOfGap_i8 addNuw
    254 0 1 1 255 0 1
    (by bv_decide) (by bv_decide) (by bv_decide)
    254 1 0 1 (by bv_decide) (by bv_decide)
  · simp [addNuw, addNuw?, poisonIf] <;> bv_decide
  · simp [addNuw, addNuw?, poisonIf] <;> bv_decide
  · intro x y hxLower hxUpper hyLower hyUpper
    have hxLowerValue : (254 : BitVec 8).toInt = -2 := by bv_decide
    have hxUpperValue : (0 : BitVec 8).toInt = 0 := by bv_decide
    have hyValue : (1 : BitVec 8).toInt = 1 := by bv_decide
    rw [hxLowerValue] at hxLower
    rw [hxUpperValue] at hxUpper
    rw [hyValue] at hyLower hyUpper
    have hx : x = 254 ∨ x = 255 ∨ x = 0 := by
      have h : x.toInt = -2 ∨ x.toInt = -1 ∨ x.toInt = 0 := by omega
      rcases h with h | h | h
      · left; apply BitVec.eq_of_toInt_eq; simpa using h
      · right; left; apply BitVec.eq_of_toInt_eq; simpa using h
      · right; right; apply BitVec.eq_of_toInt_eq; simpa using h
    have hy : y = 1 := by
      apply BitVec.eq_of_toInt_eq
      rw [hyValue]
      omega
    rcases hx with rfl | rfl | rfl <;>
      simp [hy, addNuw, addNuw?, poisonIf] <;> bv_decide

theorem sintRange_addNswNuw_i8_not_forwardComplete :
    ¬ BinaryForwardComplete (SIntRange.domain 8) (SIntRange.domain 8)
      (SIntRange.domain 8)
      (addNswNuw : BinaryConcreteOp (BitVec 8) (BitVec 8) (BitVec 8)) := by
  apply binaryForwardIncompleteOfGap_i8 addNswNuw
    254 0 1 1 255 0 1
    (by bv_decide) (by bv_decide) (by bv_decide)
    254 1 0 1 (by bv_decide) (by bv_decide)
  · simp [addNswNuw, addNswNuw?, poisonIf] <;> bv_decide
  · simp [addNswNuw, addNswNuw?, poisonIf] <;> bv_decide
  · intro x y hxLower hxUpper hyLower hyUpper
    have hxLowerValue : (254 : BitVec 8).toInt = -2 := by bv_decide
    have hxUpperValue : (0 : BitVec 8).toInt = 0 := by bv_decide
    have hyValue : (1 : BitVec 8).toInt = 1 := by bv_decide
    rw [hxLowerValue] at hxLower
    rw [hxUpperValue] at hxUpper
    rw [hyValue] at hyLower hyUpper
    have hx : x = 254 ∨ x = 255 ∨ x = 0 := by
      have h : x.toInt = -2 ∨ x.toInt = -1 ∨ x.toInt = 0 := by omega
      rcases h with h | h | h
      · left; apply BitVec.eq_of_toInt_eq; simpa using h
      · right; left; apply BitVec.eq_of_toInt_eq; simpa using h
      · right; right; apply BitVec.eq_of_toInt_eq; simpa using h
    have hy : y = 1 := by
      apply BitVec.eq_of_toInt_eq
      rw [hyValue]
      omega
    rcases hx with rfl | rfl | rfl <;>
      simp [hy, addNswNuw, addNswNuw?, poisonIf] <;> bv_decide

private theorem addBackwardIncomplete
    (f : BinaryConcreteOp (BitVec 8) (BitVec 8) (BitVec 8))
    (hinside : (128 : BitVec 8) ∈ f 128 0)
    (hcorners : ∀ x y z,
      (x = (128 : BitVec 8) ∨ x = 128) →
      (y = (255 : BitVec 8) ∨ y = 1) → z ∈ f x y →
      (129 : BitVec 8).toInt ≤ z.toInt ∧ z.toInt ≤ (127 : BitVec 8).toInt) :
    ¬ BinaryBackwardComplete (SIntRange.domain 8) (SIntRange.domain 8)
      (SIntRange.domain 8) f := by
  apply binaryBackwardIncompleteOfCorner_i8 f
    128 128 255 1 128 0 128 129 127
    (by bv_decide) (by bv_decide) (by bv_decide) hinside
    (by bv_decide) (by bv_decide) hcorners

theorem sintRange_add_i8_not_backwardComplete :
    ¬ BinaryBackwardComplete (SIntRange.domain 8) (SIntRange.domain 8)
      (SIntRange.domain 8)
      (add : BinaryConcreteOp (BitVec 8) (BitVec 8) (BitVec 8)) := by
  apply binaryBackwardIncompleteOfCorner_i8 add
    128 128 255 1 128 0 128 129 127
    (by bv_decide) (by bv_decide) (by bv_decide)
  · simp [add, addFn]
  · bv_decide
  · bv_decide
  · intro x y z hx hy hz
    rcases hx with rfl | rfl <;> rcases hy with rfl | rfl <;>
      simp [add, addFn] at hz <;> subst z <;> decide

theorem sintRange_addNsw_i8_not_backwardComplete :
    ¬ BinaryBackwardComplete (SIntRange.domain 8) (SIntRange.domain 8)
      (SIntRange.domain 8)
      (addNsw : BinaryConcreteOp (BitVec 8) (BitVec 8) (BitVec 8)) := by
  apply addBackwardIncomplete addNsw
  · simp [addNsw, addNsw?, poisonIf] <;> bv_decide
  · intro x y z hx hy hz
    rcases hx with rfl | rfl <;> rcases hy with rfl | rfl <;>
      simp [addNsw, addNsw?, poisonIf] at hz <;>
      rcases hz with ⟨_, rfl⟩
    all_goals first | bv_decide | decide

theorem sintRange_addNuw_i8_not_backwardComplete :
    ¬ BinaryBackwardComplete (SIntRange.domain 8) (SIntRange.domain 8)
      (SIntRange.domain 8)
      (addNuw : BinaryConcreteOp (BitVec 8) (BitVec 8) (BitVec 8)) := by
  apply addBackwardIncomplete addNuw
  · simp [addNuw, addNuw?, poisonIf] <;> bv_decide
  · intro x y z hx hy hz
    rcases hx with rfl | rfl <;> rcases hy with rfl | rfl <;>
      simp [addNuw, addNuw?, poisonIf] at hz <;>
      rcases hz with ⟨_, rfl⟩
    all_goals first | bv_decide | decide

theorem sintRange_addNswNuw_i8_not_backwardComplete :
    ¬ BinaryBackwardComplete (SIntRange.domain 8) (SIntRange.domain 8)
      (SIntRange.domain 8)
      (addNswNuw : BinaryConcreteOp (BitVec 8) (BitVec 8) (BitVec 8)) := by
  apply addBackwardIncomplete addNswNuw
  · simp [addNswNuw, addNswNuw?, poisonIf] <;> bv_decide
  · intro x y z hx hy hz
    rcases hx with rfl | rfl <;> rcases hy with rfl | rfl <;>
      simp [addNswNuw, addNswNuw?, poisonIf] at hz <;>
      rcases hz with ⟨_, rfl⟩
    all_goals first | bv_decide | decide

end SynthXfer.LLVM
