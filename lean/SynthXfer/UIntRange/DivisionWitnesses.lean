import SynthXfer.UIntRange.Witnesses
import Std.Tactic.BVDecide

/-!
# Division and remainder witnesses in UIntRange
-/

namespace SynthXfer.LLVM

open UIntRange

private theorem bitvec8_eq_eight {x : BitVec 8}
    (hlower : (8 : BitVec 8).toNat ≤ x.toNat)
    (hupper : x.toNat ≤ (8 : BitVec 8).toNat) : x = 8 := by
  apply BitVec.eq_of_toNat_eq
  omega

private theorem bitvec8_eq_zero_or_one_or_two {x : BitVec 8}
    (_hlower : (0 : BitVec 8).toNat ≤ x.toNat)
    (hupper : x.toNat ≤ (2 : BitVec 8).toNat) :
    x = 0 ∨ x = 1 ∨ x = 2 := by
  have hx : x.toNat = 0 ∨ x.toNat = 1 ∨ x.toNat = 2 := by
    simp at hupper
    omega
  exact hx.imp BitVec.eq_of_toNat_eq
    (fun h ↦ Or.imp BitVec.eq_of_toNat_eq BitVec.eq_of_toNat_eq h)

private theorem bitvec8_eq_zero_or_one_or_two_or_three {x : BitVec 8}
    (_hlower : (0 : BitVec 8).toNat ≤ x.toNat)
    (hupper : x.toNat ≤ (3 : BitVec 8).toNat) :
    x = 0 ∨ x = 1 ∨ x = 2 ∨ x = 3 := by
  have hx : x.toNat = 0 ∨ x.toNat = 1 ∨ x.toNat = 2 ∨ x.toNat = 3 := by
    simp at hupper
    omega
  rcases hx with h | h | h | h
  · exact Or.inl (BitVec.eq_of_toNat_eq h)
  · exact Or.inr (Or.inl (BitVec.eq_of_toNat_eq h))
  · exact Or.inr (Or.inr (Or.inl (BitVec.eq_of_toNat_eq h)))
  · exact Or.inr (Or.inr (Or.inr (BitVec.eq_of_toNat_eq h)))

private theorem divisionForwardIncomplete
    (f : BinaryConcreteOp (BitVec 8) (BitVec 8) (BitVec 8))
    (hzero : 5 ∉ f 8 0) (hone : 5 ∉ f 8 1) (htwo : 5 ∉ f 8 2)
    (hbelow : 4 ∈ f 8 2) (habove : 8 ∈ f 8 1) :
    ¬ BinaryForwardComplete (UIntRange.domain 8) (UIntRange.domain 8)
      (UIntRange.domain 8) f := by
  apply binaryForwardIncompleteOfGap_i8 f
    8 8 0 2 4 5 8 (by bv_decide) (by bv_decide) (by bv_decide)
    8 2 8 1 (by bv_decide) (by bv_decide) hbelow habove
  intro x y hxLower hxUpper hyLower hyUpper
  have hx := bitvec8_eq_eight hxLower hxUpper
  rcases bitvec8_eq_zero_or_one_or_two hyLower hyUpper with hy | hy | hy
  · simpa [hx, hy] using hzero
  · simpa [hx, hy] using hone
  · simpa [hx, hy] using htwo

private theorem divisionBackwardIncomplete
    (f : BinaryConcreteOp (BitVec 8) (BitVec 8) (BitVec 8))
    (hresult : 8 ∈ f 8 1)
    (hcorners : ∀ x y z, (x = 8 ∨ x = 8) → (y = 0 ∨ y = 2) →
      z ∈ f x y → z = 4) :
    ¬ BinaryBackwardComplete (UIntRange.domain 8) (UIntRange.domain 8)
      (UIntRange.domain 8) f := by
  apply binaryBackwardIncompleteOfCorner_i8 f
    8 8 0 2 8 1 8 4 4 (by bv_decide) (by bv_decide) (by bv_decide)
    hresult (by bv_decide) (by bv_decide)
  intro x y z hx hy hz
  have hzEq := hcorners x y z hx hy hz
  subst z
  bv_decide

private theorem remainderForwardIncomplete
    (f : BinaryConcreteOp (BitVec 8) (BitVec 8) (BitVec 8))
    (hzero : 1 ∉ f 8 0) (hone : 1 ∉ f 8 1) (htwo : 1 ∉ f 8 2)
    (hthree : 1 ∉ f 8 3) (hbelow : 0 ∈ f 8 1)
    (habove : 2 ∈ f 8 3) :
    ¬ BinaryForwardComplete (UIntRange.domain 8) (UIntRange.domain 8)
      (UIntRange.domain 8) f := by
  apply binaryForwardIncompleteOfGap_i8 f
    8 8 0 3 0 1 2 (by bv_decide) (by bv_decide) (by bv_decide)
    8 1 8 3 (by bv_decide) (by bv_decide) hbelow habove
  intro x y hxLower hxUpper hyLower hyUpper
  have hx := bitvec8_eq_eight hxLower hxUpper
  rcases bitvec8_eq_zero_or_one_or_two_or_three hyLower hyUpper with
    hy | hy | hy | hy
  · simpa [hx, hy] using hzero
  · simpa [hx, hy] using hone
  · simpa [hx, hy] using htwo
  · simpa [hx, hy] using hthree

private theorem remainderBackwardIncomplete
    (f : BinaryConcreteOp (BitVec 8) (BitVec 8) (BitVec 8))
    (hresult : 0 ∈ f 8 1)
    (hcorners : ∀ x y z, (x = 8 ∨ x = 8) → (y = 0 ∨ y = 3) →
      z ∈ f x y → z = 2) :
    ¬ BinaryBackwardComplete (UIntRange.domain 8) (UIntRange.domain 8)
      (UIntRange.domain 8) f := by
  apply binaryBackwardIncompleteOfCorner_i8 f
    8 8 0 3 8 1 0 2 2 (by bv_decide) (by bv_decide) (by bv_decide)
    hresult (by bv_decide) (by bv_decide)
  intro x y z hx hy hz
  have hzEq := hcorners x y z hx hy hz
  subst z
  bv_decide

theorem uintRange_udiv_i8_not_forwardComplete :
    ¬ BinaryForwardComplete (UIntRange.domain 8) (UIntRange.domain 8)
      (UIntRange.domain 8)
      (udiv : BinaryConcreteOp (BitVec 8) (BitVec 8) (BitVec 8)) := by
  apply divisionForwardIncomplete udiv <;> simp [udiv, udiv?, poisonIf]

theorem uintRange_udiv_i8_not_backwardComplete :
    ¬ BinaryBackwardComplete (UIntRange.domain 8) (UIntRange.domain 8)
      (UIntRange.domain 8)
      (udiv : BinaryConcreteOp (BitVec 8) (BitVec 8) (BitVec 8)) := by
  apply divisionBackwardIncomplete udiv
  · simp [udiv, udiv?, poisonIf]
  · intro x y z hx hy hz
    rcases hx with rfl | rfl <;> rcases hy with rfl | rfl <;>
      simp [udiv, udiv?, poisonIf] at hz <;>
      rcases hz with ⟨_, rfl⟩ <;> rfl

theorem uintRange_udivExact_i8_not_forwardComplete :
    ¬ BinaryForwardComplete (UIntRange.domain 8) (UIntRange.domain 8)
      (UIntRange.domain 8)
      (udivExact : BinaryConcreteOp (BitVec 8) (BitVec 8) (BitVec 8)) := by
  apply divisionForwardIncomplete udivExact <;>
    simp [udivExact, udivExact?, poisonIf]

theorem uintRange_udivExact_i8_not_backwardComplete :
    ¬ BinaryBackwardComplete (UIntRange.domain 8) (UIntRange.domain 8)
      (UIntRange.domain 8)
      (udivExact : BinaryConcreteOp (BitVec 8) (BitVec 8) (BitVec 8)) := by
  apply divisionBackwardIncomplete udivExact
  · simp [udivExact, udivExact?, poisonIf]
  · intro x y z hx hy hz
    rcases hx with rfl | rfl <;> rcases hy with rfl | rfl <;>
      simp [udivExact, udivExact?, poisonIf] at hz <;>
      rcases hz with ⟨_, rfl⟩ <;> rfl

theorem uintRange_sdiv_i8_not_forwardComplete :
    ¬ BinaryForwardComplete (UIntRange.domain 8) (UIntRange.domain 8)
      (UIntRange.domain 8)
      (sdiv : BinaryConcreteOp (BitVec 8) (BitVec 8) (BitVec 8)) := by
  apply divisionForwardIncomplete sdiv <;> simp [sdiv, sdiv?, poisonIf]
  all_goals bv_decide

theorem uintRange_sdiv_i8_not_backwardComplete :
    ¬ BinaryBackwardComplete (UIntRange.domain 8) (UIntRange.domain 8)
      (UIntRange.domain 8)
      (sdiv : BinaryConcreteOp (BitVec 8) (BitVec 8) (BitVec 8)) := by
  apply divisionBackwardIncomplete sdiv
  · simp [sdiv, sdiv?, poisonIf]
    bv_decide
  · intro x y z hx hy hz
    rcases hx with rfl | rfl <;> rcases hy with rfl | rfl <;>
      simp [sdiv, sdiv?, poisonIf] at hz <;>
      rcases hz with ⟨_, rfl⟩ <;> rfl

theorem uintRange_sdivExact_i8_not_forwardComplete :
    ¬ BinaryForwardComplete (UIntRange.domain 8) (UIntRange.domain 8)
      (UIntRange.domain 8)
      (sdivExact : BinaryConcreteOp (BitVec 8) (BitVec 8) (BitVec 8)) := by
  apply divisionForwardIncomplete sdivExact <;>
    simp [sdivExact, sdivExact?, poisonIf]
  all_goals bv_decide

theorem uintRange_sdivExact_i8_not_backwardComplete :
    ¬ BinaryBackwardComplete (UIntRange.domain 8) (UIntRange.domain 8)
      (UIntRange.domain 8)
      (sdivExact : BinaryConcreteOp (BitVec 8) (BitVec 8) (BitVec 8)) := by
  apply divisionBackwardIncomplete sdivExact
  · simp [sdivExact, sdivExact?, poisonIf]
    bv_decide
  · intro x y z hx hy hz
    rcases hx with rfl | rfl <;> rcases hy with rfl | rfl <;>
      simp [sdivExact, sdivExact?, poisonIf] at hz <;>
      rcases hz with ⟨_, rfl⟩ <;> rfl

theorem uintRange_urem_i8_not_forwardComplete :
    ¬ BinaryForwardComplete (UIntRange.domain 8) (UIntRange.domain 8)
      (UIntRange.domain 8)
      (urem : BinaryConcreteOp (BitVec 8) (BitVec 8) (BitVec 8)) := by
  apply remainderForwardIncomplete urem <;> simp [urem, urem?, poisonIf]

theorem uintRange_urem_i8_not_backwardComplete :
    ¬ BinaryBackwardComplete (UIntRange.domain 8) (UIntRange.domain 8)
      (UIntRange.domain 8)
      (urem : BinaryConcreteOp (BitVec 8) (BitVec 8) (BitVec 8)) := by
  apply remainderBackwardIncomplete urem
  · simp [urem, urem?, poisonIf]
  · intro x y z hx hy hz
    rcases hx with rfl | rfl <;> rcases hy with rfl | rfl <;>
      simp [urem, urem?, poisonIf] at hz <;>
      rcases hz with ⟨_, rfl⟩ <;> rfl

theorem uintRange_srem_i8_not_forwardComplete :
    ¬ BinaryForwardComplete (UIntRange.domain 8) (UIntRange.domain 8)
      (UIntRange.domain 8)
      (srem : BinaryConcreteOp (BitVec 8) (BitVec 8) (BitVec 8)) := by
  apply remainderForwardIncomplete srem <;> simp [srem, srem?, poisonIf]
  all_goals bv_decide

theorem uintRange_srem_i8_not_backwardComplete :
    ¬ BinaryBackwardComplete (UIntRange.domain 8) (UIntRange.domain 8)
      (UIntRange.domain 8)
      (srem : BinaryConcreteOp (BitVec 8) (BitVec 8) (BitVec 8)) := by
  apply remainderBackwardIncomplete srem
  · simp [srem, srem?, poisonIf]
    bv_decide
  · intro x y z hx hy hz
    rcases hx with rfl | rfl <;> rcases hy with rfl | rfl <;>
      simp [srem, srem?, poisonIf] at hz <;>
      rcases hz with ⟨_, rfl⟩ <;> rfl

end SynthXfer.LLVM
