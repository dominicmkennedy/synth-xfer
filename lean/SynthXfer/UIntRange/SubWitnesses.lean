import SynthXfer.UIntRange.Witnesses
import Std.Tactic.BVDecide

namespace SynthXfer.LLVM

open UIntRange

theorem uintRange_sub_i8_not_forwardComplete :
    ¬ BinaryForwardComplete (UIntRange.domain 8) (UIntRange.domain 8)
      (UIntRange.domain 8)
      (sub : BinaryConcreteOp (BitVec 8) (BitVec 8) (BitVec 8)) := by
  apply binaryForwardIncompleteOfGap_i8
    (sub : BinaryConcreteOp (BitVec 8) (BitVec 8) (BitVec 8))
    0 0 0 1 0 1 255 (by bv_decide) (by bv_decide) (by bv_decide)
    0 0 0 1 (by bv_decide) (by bv_decide)
  · simp [sub, subFn]
  · simp [sub, subFn]
  · intro x y hxLower hxUpper hyLower hyUpper
    have h0 : (0 : BitVec 8).toNat = 0 := by bv_decide
    have h1 : (1 : BitVec 8).toNat = 1 := by bv_decide
    rw [h0] at hxLower hxUpper hyLower
    rw [h1] at hyUpper
    have hx : x = (0 : BitVec 8) := BitVec.eq_of_toNat_eq (by omega)
    have hy : y = (0 : BitVec 8) ∨ y = (1 : BitVec 8) := by
      have : y.toNat = 0 ∨ y.toNat = 1 := by omega
      exact this.imp BitVec.eq_of_toNat_eq BitVec.eq_of_toNat_eq
    rcases hy with rfl | rfl <;> simp [hx, sub, subFn]

theorem uintRange_sub_i8_not_backwardComplete :
    ¬ BinaryBackwardComplete (UIntRange.domain 8) (UIntRange.domain 8)
      (UIntRange.domain 8)
      (sub : BinaryConcreteOp (BitVec 8) (BitVec 8) (BitVec 8)) := by
  apply binaryBackwardIncompleteOfCorner_i8
    (sub : BinaryConcreteOp (BitVec 8) (BitVec 8) (BitVec 8))
    0 0 0 2 0 1 255 0 254
    (by bv_decide) (by bv_decide) (by bv_decide)
  · simp [sub, subFn]
  · bv_decide
  · bv_decide
  · intro x y z hx hy hz
    rcases hx with rfl | rfl <;> rcases hy with rfl | rfl <;>
      simp [sub, subFn] at hz <;> subst z <;> bv_decide

theorem uintRange_subNsw_i8_not_forwardComplete :
    ¬ BinaryForwardComplete (UIntRange.domain 8) (UIntRange.domain 8)
      (UIntRange.domain 8)
      (subNsw : BinaryConcreteOp (BitVec 8) (BitVec 8) (BitVec 8)) := by
  apply binaryForwardIncompleteOfGap_i8
    (subNsw : BinaryConcreteOp (BitVec 8) (BitVec 8) (BitVec 8))
    0 0 0 1 0 1 255 (by bv_decide) (by bv_decide) (by bv_decide)
    0 0 0 1 (by bv_decide) (by bv_decide)
  · simp [subNsw, subNsw?, poisonIf] <;> bv_decide
  · simp [subNsw, subNsw?, poisonIf] <;> bv_decide
  · intro x y hxLower hxUpper hyLower hyUpper
    have h0 : (0 : BitVec 8).toNat = 0 := by bv_decide
    have h1 : (1 : BitVec 8).toNat = 1 := by bv_decide
    rw [h0] at hxLower hxUpper hyLower
    rw [h1] at hyUpper
    have hx : x = (0 : BitVec 8) := BitVec.eq_of_toNat_eq (by omega)
    have hy : y = (0 : BitVec 8) ∨ y = (1 : BitVec 8) := by
      have : y.toNat = 0 ∨ y.toNat = 1 := by omega
      exact this.imp BitVec.eq_of_toNat_eq BitVec.eq_of_toNat_eq
    rcases hy with rfl | rfl
    all_goals simp [hx, subNsw, subNsw?, poisonIf,
      BinaryConcreteOp.ofOption] <;> bv_decide

theorem uintRange_subNsw_i8_not_backwardComplete :
    ¬ BinaryBackwardComplete (UIntRange.domain 8) (UIntRange.domain 8)
      (UIntRange.domain 8)
      (subNsw : BinaryConcreteOp (BitVec 8) (BitVec 8) (BitVec 8)) := by
  apply binaryBackwardIncompleteOfCorner_i8
    (subNsw : BinaryConcreteOp (BitVec 8) (BitVec 8) (BitVec 8))
    0 0 0 2 0 1 255 0 254
    (by bv_decide) (by bv_decide) (by bv_decide)
  · simp [subNsw, subNsw?, poisonIf] <;> bv_decide
  · bv_decide
  · bv_decide
  · intro x y z hx hy hz
    rcases hx with rfl | rfl <;> rcases hy with rfl | rfl <;>
      simp [subNsw, subNsw?, poisonIf] at hz <;>
      rcases hz with ⟨_, rfl⟩ <;> bv_decide

theorem uintRange_subNuw_i8_not_backwardComplete :
    ¬ BinaryBackwardComplete (UIntRange.domain 8) (UIntRange.domain 8)
      (UIntRange.domain 8)
      (subNuw : BinaryConcreteOp (BitVec 8) (BitVec 8) (BitVec 8)) := by
  apply binaryBackwardIncompleteOfCorner_i8
    (subNuw : BinaryConcreteOp (BitVec 8) (BitVec 8) (BitVec 8))
    0 2 1 1 1 1 0 1 1
    (by bv_decide) (by bv_decide) (by bv_decide)
  · simp [subNuw, subNuw?, poisonIf] <;> bv_decide
  · bv_decide
  · bv_decide
  · intro x y z hx hy hz
    rcases hx with rfl | rfl <;> rcases hy with rfl | rfl <;>
      simp [subNuw, subNuw?, poisonIf] at hz <;>
      rcases hz with ⟨_, rfl⟩ <;> simp_all [BitVec.usubOverflow_eq]

theorem uintRange_subNswNuw_i8_not_forwardComplete :
    ¬ BinaryForwardComplete (UIntRange.domain 8) (UIntRange.domain 8)
      (UIntRange.domain 8)
      (subNswNuw : BinaryConcreteOp (BitVec 8) (BitVec 8) (BitVec 8)) := by
  apply binaryForwardIncompleteOfGap_i8
    (subNswNuw : BinaryConcreteOp (BitVec 8) (BitVec 8) (BitVec 8))
    127 129 1 1 126 127 128 (by bv_decide) (by bv_decide) (by bv_decide)
    127 1 129 1 (by bv_decide) (by bv_decide)
  · simp [subNswNuw, subNswNuw?, poisonIf] <;> bv_decide
  · simp [subNswNuw, subNswNuw?, poisonIf] <;> bv_decide
  · intro x y hxLower hxUpper hyLower hyUpper
    have h127 : (127 : BitVec 8).toNat = 127 := by bv_decide
    have h129 : (129 : BitVec 8).toNat = 129 := by bv_decide
    have h1 : (1 : BitVec 8).toNat = 1 := by bv_decide
    rw [h127] at hxLower
    rw [h129] at hxUpper
    rw [h1] at hyLower hyUpper
    have hy : y = (1 : BitVec 8) := BitVec.eq_of_toNat_eq (by omega)
    have hx : x = (127 : BitVec 8) ∨ x = (128 : BitVec 8) ∨
        x = (129 : BitVec 8) := by
      have : x.toNat = 127 ∨ x.toNat = 128 ∨ x.toNat = 129 := by omega
      exact this.imp BitVec.eq_of_toNat_eq
        (fun h ↦ Or.imp BitVec.eq_of_toNat_eq BitVec.eq_of_toNat_eq h)
    rcases hx with rfl | rfl | rfl
    all_goals simp [hy, subNswNuw, subNswNuw?, poisonIf,
      BinaryConcreteOp.ofOption] <;> bv_decide

theorem uintRange_subNswNuw_i8_not_backwardComplete :
    ¬ BinaryBackwardComplete (UIntRange.domain 8) (UIntRange.domain 8)
      (UIntRange.domain 8)
      (subNswNuw : BinaryConcreteOp (BitVec 8) (BitVec 8) (BitVec 8)) := by
  apply binaryBackwardIncompleteOfCorner_i8
    (subNswNuw : BinaryConcreteOp (BitVec 8) (BitVec 8) (BitVec 8))
    0 2 1 1 1 1 0 1 1
    (by bv_decide) (by bv_decide) (by bv_decide)
  · simp [subNswNuw, subNswNuw?, poisonIf] <;> bv_decide
  · bv_decide
  · bv_decide
  · intro x y z hx hy hz
    rcases hx with rfl | rfl <;> rcases hy with rfl | rfl <;>
      simp [subNswNuw, subNswNuw?, poisonIf] at hz <;>
      rcases hz with ⟨_, rfl⟩ <;> bv_decide

end SynthXfer.LLVM
