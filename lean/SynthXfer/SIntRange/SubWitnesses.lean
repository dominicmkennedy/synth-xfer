import SynthXfer.SIntRange.Witnesses
import Std.Tactic.BVDecide

namespace SynthXfer.LLVM

open SIntRange

private theorem subWrapGapInputs
    (x y : BitVec 8)
    (hxLower : (128 : BitVec 8).toInt ≤ x.toInt)
    (hxUpper : x.toInt ≤ (128 : BitVec 8).toInt)
    (hyLower : (255 : BitVec 8).toInt ≤ y.toInt)
    (hyUpper : y.toInt ≤ (1 : BitVec 8).toInt) :
    x = 128 ∧ (y = 255 ∨ y = 0 ∨ y = 1) := by
  have hxValue : (128 : BitVec 8).toInt = -128 := by bv_decide
  have hyLowerValue : (255 : BitVec 8).toInt = -1 := by bv_decide
  have hyUpperValue : (1 : BitVec 8).toInt = 1 := by bv_decide
  rw [hxValue] at hxLower hxUpper
  rw [hyLowerValue] at hyLower
  rw [hyUpperValue] at hyUpper
  constructor
  · apply BitVec.eq_of_toInt_eq
    rw [hxValue]
    omega
  · have hy : y.toInt = -1 ∨ y.toInt = 0 ∨ y.toInt = 1 := by omega
    rcases hy with hy | hy | hy
    · left; apply BitVec.eq_of_toInt_eq; simpa using hy
    · right; left; apply BitVec.eq_of_toInt_eq; simpa using hy
    · right; right; apply BitVec.eq_of_toInt_eq; simpa using hy

theorem sintRange_sub_i8_not_forwardComplete :
    ¬ BinaryForwardComplete (SIntRange.domain 8) (SIntRange.domain 8)
      (SIntRange.domain 8)
      (sub : BinaryConcreteOp (BitVec 8) (BitVec 8) (BitVec 8)) := by
  apply binaryForwardIncompleteOfGap_i8 sub
    128 128 255 1 128 130 127
    (by bv_decide) (by bv_decide) (by bv_decide)
    128 0 128 1 (by bv_decide) (by bv_decide)
  · simp [sub, subFn]
  · simp [sub, subFn]
  · intro x y hxLower hxUpper hyLower hyUpper
    obtain ⟨rfl, hy⟩ := subWrapGapInputs x y hxLower hxUpper hyLower hyUpper
    rcases hy with rfl | rfl | rfl <;> simp [sub, subFn]

theorem sintRange_subNuw_i8_not_forwardComplete :
    ¬ BinaryForwardComplete (SIntRange.domain 8) (SIntRange.domain 8)
      (SIntRange.domain 8)
      (subNuw : BinaryConcreteOp (BitVec 8) (BitVec 8) (BitVec 8)) := by
  apply binaryForwardIncompleteOfGap_i8 subNuw
    128 128 255 1 128 129 127
    (by bv_decide) (by bv_decide) (by bv_decide)
    128 0 128 1 (by bv_decide) (by bv_decide)
  · simp [subNuw, subNuw?, poisonIf] <;> bv_decide
  · simp [subNuw, subNuw?, poisonIf] <;> bv_decide
  · intro x y hxLower hxUpper hyLower hyUpper
    obtain ⟨rfl, hy⟩ := subWrapGapInputs x y hxLower hxUpper hyLower hyUpper
    rcases hy with rfl | rfl | rfl <;>
      simp [subNuw, subNuw?, poisonIf, BitVec.usubOverflow_eq]

private theorem threeValues252To254 (x : BitVec 8)
    (hlower : (252 : BitVec 8).toInt ≤ x.toInt)
    (hupper : x.toInt ≤ (254 : BitVec 8).toInt) :
    x = 252 ∨ x = 253 ∨ x = 254 := by
  have hlo : (252 : BitVec 8).toInt = -4 := by bv_decide
  have hhi : (254 : BitVec 8).toInt = -2 := by bv_decide
  rw [hlo] at hlower
  rw [hhi] at hupper
  have hx : x.toInt = -4 ∨ x.toInt = -3 ∨ x.toInt = -2 := by omega
  rcases hx with hx | hx | hx
  · left; apply BitVec.eq_of_toInt_eq; simpa using hx
  · right; left; apply BitVec.eq_of_toInt_eq; simpa using hx
  · right; right; apply BitVec.eq_of_toInt_eq; simpa using hx

private theorem threeValues254To0 (x : BitVec 8)
    (hlower : (254 : BitVec 8).toInt ≤ x.toInt)
    (hupper : x.toInt ≤ (0 : BitVec 8).toInt) :
    x = 254 ∨ x = 255 ∨ x = 0 := by
  have hlo : (254 : BitVec 8).toInt = -2 := by bv_decide
  have hhi : (0 : BitVec 8).toInt = 0 := by bv_decide
  rw [hlo] at hlower
  rw [hhi] at hupper
  have hx : x.toInt = -2 ∨ x.toInt = -1 ∨ x.toInt = 0 := by omega
  rcases hx with hx | hx | hx
  · left; apply BitVec.eq_of_toInt_eq; simpa using hx
  · right; left; apply BitVec.eq_of_toInt_eq; simpa using hx
  · right; right; apply BitVec.eq_of_toInt_eq; simpa using hx

theorem sintRange_subNswNuw_i8_not_forwardComplete :
    ¬ BinaryForwardComplete (SIntRange.domain 8) (SIntRange.domain 8)
      (SIntRange.domain 8)
      (subNswNuw : BinaryConcreteOp (BitVec 8) (BitVec 8) (BitVec 8)) := by
  apply binaryForwardIncompleteOfGap_i8 subNswNuw
    252 254 254 0 252 255 0
    (by bv_decide) (by bv_decide) (by bv_decide)
    252 0 254 254 (by bv_decide) (by bv_decide)
  · simp [subNswNuw, subNswNuw?, poisonIf] <;> bv_decide
  · simp [subNswNuw, subNswNuw?, poisonIf] <;> bv_decide
  · intro x y hxLower hxUpper hyLower hyUpper
    have hx := threeValues252To254 x hxLower hxUpper
    have hy := threeValues254To0 y hyLower hyUpper
    rcases hx with rfl | rfl | rfl <;> rcases hy with rfl | rfl | rfl <;>
      simp [subNswNuw, subNswNuw?, poisonIf, BitVec.ssubOverflow,
        BitVec.usubOverflow_eq]

theorem sintRange_sub_i8_not_backwardComplete :
    ¬ BinaryBackwardComplete (SIntRange.domain 8) (SIntRange.domain 8)
      (SIntRange.domain 8)
      (sub : BinaryConcreteOp (BitVec 8) (BitVec 8) (BitVec 8)) := by
  apply binaryBackwardIncompleteOfCorner_i8 sub
    128 128 255 1 128 0 128 129 127
    (by bv_decide) (by bv_decide) (by bv_decide)
  · simp [sub, subFn]
  · bv_decide
  · bv_decide
  · intro x y z hx hy hz
    rcases hx with rfl | rfl <;> rcases hy with rfl | rfl <;>
      simp [sub, subFn] at hz <;> subst z <;> decide

theorem sintRange_subNsw_i8_not_backwardComplete :
    ¬ BinaryBackwardComplete (SIntRange.domain 8) (SIntRange.domain 8)
      (SIntRange.domain 8)
      (subNsw : BinaryConcreteOp (BitVec 8) (BitVec 8) (BitVec 8)) := by
  apply binaryBackwardIncompleteOfCorner_i8 subNsw
    128 128 255 1 128 0 128 129 127
    (by bv_decide) (by bv_decide) (by bv_decide)
  · simp [subNsw, subNsw?, poisonIf] <;> bv_decide
  · bv_decide
  · bv_decide
  · intro x y z hx hy hz
    rcases hx with rfl | rfl <;> rcases hy with rfl | rfl <;>
      simp [subNsw, subNsw?, poisonIf, BitVec.ssubOverflow] at hz <;>
      rcases hz with ⟨_, rfl⟩ <;> decide

theorem sintRange_subNuw_i8_not_backwardComplete :
    ¬ BinaryBackwardComplete (SIntRange.domain 8) (SIntRange.domain 8)
      (SIntRange.domain 8)
      (subNuw : BinaryConcreteOp (BitVec 8) (BitVec 8) (BitVec 8)) := by
  apply binaryBackwardIncompleteOfCorner_i8 subNuw
    128 128 255 1 128 0 128 129 127
    (by bv_decide) (by bv_decide) (by bv_decide)
  · simp [subNuw, subNuw?, poisonIf] <;> bv_decide
  · bv_decide
  · bv_decide
  · intro x y z hx hy hz
    rcases hx with rfl | rfl <;> rcases hy with rfl | rfl <;>
      simp [subNuw, subNuw?, poisonIf, BitVec.usubOverflow_eq] at hz <;>
      rcases hz with ⟨_, rfl⟩ <;> decide

theorem sintRange_subNswNuw_i8_not_backwardComplete :
    ¬ BinaryBackwardComplete (SIntRange.domain 8) (SIntRange.domain 8)
      (SIntRange.domain 8)
      (subNswNuw : BinaryConcreteOp (BitVec 8) (BitVec 8) (BitVec 8)) := by
  apply binaryBackwardIncompleteOfCorner_i8 subNswNuw
    128 129 255 1 129 0 129 128 128
    (by bv_decide) (by bv_decide) (by bv_decide)
  · simp [subNswNuw, subNswNuw?, poisonIf] <;> bv_decide
  · bv_decide
  · bv_decide
  · intro x y z hx hy hz
    rcases hx with rfl | rfl <;> rcases hy with rfl | rfl <;>
      simp [subNswNuw, subNswNuw?, poisonIf, BitVec.ssubOverflow,
        BitVec.usubOverflow_eq] at hz <;>
      rcases hz with ⟨_, rfl⟩ <;> decide

end SynthXfer.LLVM
