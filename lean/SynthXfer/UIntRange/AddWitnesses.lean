import SynthXfer.UIntRange.Witnesses
import Std.Tactic.BVDecide

namespace SynthXfer.LLVM

open UIntRange

theorem uintRange_add_i8_not_forwardComplete :
    ¬ BinaryForwardComplete (UIntRange.domain 8) (UIntRange.domain 8)
      (UIntRange.domain 8)
      (add : BinaryConcreteOp (BitVec 8) (BitVec 8) (BitVec 8)) := by
  apply binaryForwardIncompleteOfGap_i8 add
    0 2 255 255 0 2 255 (by bv_decide) (by bv_decide) (by bv_decide)
    1 255 0 255 (by bv_decide) (by bv_decide)
  · simp [add, addFn]
  · simp [add, addFn]
  · simp [add, addFn, BinaryConcreteOp.ofTotal]
    decide

theorem uintRange_add_i8_not_backwardComplete :
    ¬ BinaryBackwardComplete (UIntRange.domain 8) (UIntRange.domain 8)
      (UIntRange.domain 8)
      (add : BinaryConcreteOp (BitVec 8) (BitVec 8) (BitVec 8)) := by
  apply binaryBackwardIncompleteOfCorner_i8 add
    0 2 255 255 1 255 0 1 255
    (by bv_decide) (by bv_decide) (by bv_decide)
  · simp [add, addFn]
  · bv_decide
  · bv_decide
  · intro x y z hx hy hz
    rcases hx with rfl | rfl <;> rcases hy with rfl | rfl <;>
      simp [add, addFn] at hz <;> subst z <;> bv_decide

theorem uintRange_addNsw_i8_not_forwardComplete :
    ¬ BinaryForwardComplete (UIntRange.domain 8) (UIntRange.domain 8)
      (UIntRange.domain 8)
      (addNsw : BinaryConcreteOp (BitVec 8) (BitVec 8) (BitVec 8)) := by
  apply binaryForwardIncompleteOfGap_i8 addNsw
    0 2 255 255 0 2 255 (by bv_decide) (by bv_decide) (by bv_decide)
    1 255 0 255 (by bv_decide) (by bv_decide)
  · simp [addNsw, addNsw?, poisonIf] <;> bv_decide
  · simp [addNsw, addNsw?, poisonIf] <;> bv_decide
  · simp [addNsw, addNsw?, poisonIf, BinaryConcreteOp.ofOption]
    decide

theorem uintRange_addNsw_i8_not_backwardComplete :
    ¬ BinaryBackwardComplete (UIntRange.domain 8) (UIntRange.domain 8)
      (UIntRange.domain 8)
      (addNsw : BinaryConcreteOp (BitVec 8) (BitVec 8) (BitVec 8)) := by
  apply binaryBackwardIncompleteOfCorner_i8 addNsw
    0 2 255 255 1 255 0 1 255
    (by bv_decide) (by bv_decide) (by bv_decide)
  · simp [addNsw, addNsw?, poisonIf] <;> bv_decide
  · bv_decide
  · bv_decide
  · intro x y z hx hy hz
    rcases hx with rfl | rfl <;> rcases hy with rfl | rfl <;>
      simp [addNsw, addNsw?, poisonIf] at hz <;>
      rcases hz with ⟨_, rfl⟩ <;> bv_decide

theorem uintRange_addNuw_i8_not_backwardComplete :
    ¬ BinaryBackwardComplete (UIntRange.domain 8) (UIntRange.domain 8)
      (UIntRange.domain 8)
      (addNuw : BinaryConcreteOp (BitVec 8) (BitVec 8) (BitVec 8)) := by
  apply binaryBackwardIncompleteOfCorner_i8
    (addNuw : BinaryConcreteOp (BitVec 8) (BitVec 8) (BitVec 8))
    0 2 0 254 1 254 255 0 254
    (by bv_decide) (by bv_decide) (by bv_decide)
  · simp [addNuw, addNuw?, poisonIf] <;> bv_decide
  · bv_decide
  · bv_decide
  · intro x y z hx hy hz
    rcases hx with rfl | rfl <;> rcases hy with rfl | rfl <;>
      simp [addNuw, addNuw?, poisonIf] at hz <;>
      rcases hz with ⟨_, rfl⟩ <;> bv_decide

theorem uintRange_addNswNuw_i8_not_forwardComplete :
    ¬ BinaryForwardComplete (UIntRange.domain 8) (UIntRange.domain 8)
      (UIntRange.domain 8)
      (addNswNuw : BinaryConcreteOp (BitVec 8) (BitVec 8) (BitVec 8)) := by
  apply binaryForwardIncompleteOfGap_i8
    (addNswNuw : BinaryConcreteOp (BitVec 8) (BitVec 8) (BitVec 8))
    126 128 1 1 127 128 129 (by bv_decide) (by bv_decide) (by bv_decide)
    126 1 128 1 (by bv_decide) (by bv_decide)
  · simp [addNswNuw, addNswNuw?, poisonIf] <;> bv_decide
  · simp [addNswNuw, addNswNuw?, poisonIf] <;> bv_decide
  · intro x y hxLower hxUpper hyLower hyUpper
    have h126 : (126 : BitVec 8).toNat = 126 := by bv_decide
    have h128 : (128 : BitVec 8).toNat = 128 := by bv_decide
    have h1 : (1 : BitVec 8).toNat = 1 := by bv_decide
    rw [h126] at hxLower
    rw [h128] at hxUpper
    rw [h1] at hyLower hyUpper
    have hy : y = (1 : BitVec 8) :=
      BitVec.eq_of_toNat_eq (by omega)
    have hx : x = (126 : BitVec 8) ∨ x = (127 : BitVec 8) ∨
        x = (128 : BitVec 8) := by
      have : x.toNat = 126 ∨ x.toNat = 127 ∨ x.toNat = 128 := by omega
      exact this.imp BitVec.eq_of_toNat_eq
        (fun h ↦ Or.imp BitVec.eq_of_toNat_eq BitVec.eq_of_toNat_eq h)
    rcases hx with rfl | rfl | rfl
    all_goals simp [hy, addNswNuw, addNswNuw?, poisonIf,
      BinaryConcreteOp.ofOption] <;> bv_decide

theorem uintRange_addNswNuw_i8_not_backwardComplete :
    ¬ BinaryBackwardComplete (UIntRange.domain 8) (UIntRange.domain 8)
      (UIntRange.domain 8)
      (addNswNuw : BinaryConcreteOp (BitVec 8) (BitVec 8) (BitVec 8)) := by
  apply binaryBackwardIncompleteOfCorner_i8
    (addNswNuw : BinaryConcreteOp (BitVec 8) (BitVec 8) (BitVec 8))
    0 2 0 126 1 126 127 0 126
    (by bv_decide) (by bv_decide) (by bv_decide)
  · simp [addNswNuw, addNswNuw?, poisonIf] <;> bv_decide
  · bv_decide
  · bv_decide
  · intro x y z hx hy hz
    rcases hx with rfl | rfl <;> rcases hy with rfl | rfl <;>
      simp [addNswNuw, addNswNuw?, poisonIf] at hz <;>
      rcases hz with ⟨_, rfl⟩ <;> bv_decide

end SynthXfer.LLVM
