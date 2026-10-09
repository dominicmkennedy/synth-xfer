import SynthXfer.UIntRange.Witnesses
import Std.Tactic.BVDecide

namespace SynthXfer.LLVM

open UIntRange

attribute [local simp] validShift signedFits signedMin signedMax unsignedMax
  clampUnsigned clampSigned shiftedOutBitsAreZero

private theorem bitvec8_eq_zero_or_one {x : BitVec 8}
    (hlower : (0 : BitVec 8).toNat ≤ x.toNat)
    (hupper : x.toNat ≤ (1 : BitVec 8).toNat) : x = 0 ∨ x = 1 := by
  have h0 : (0 : BitVec 8).toNat = 0 := by bv_decide
  have h1 : (1 : BitVec 8).toNat = 1 := by bv_decide
  rw [h0] at hlower
  rw [h1] at hupper
  have hx : x.toNat = 0 ∨ x.toNat = 1 := by omega
  exact hx.imp BitVec.eq_of_toNat_eq BitVec.eq_of_toNat_eq

private theorem bitvec8_eq_zero_or_one_or_two {x : BitVec 8}
    (hlower : (0 : BitVec 8).toNat ≤ x.toNat)
    (hupper : x.toNat ≤ (2 : BitVec 8).toNat) :
    x = 0 ∨ x = 1 ∨ x = 2 := by
  have h0 : (0 : BitVec 8).toNat = 0 := by bv_decide
  have h2 : (2 : BitVec 8).toNat = 2 := by bv_decide
  rw [h0] at hlower
  rw [h2] at hupper
  have hx : x.toNat = 0 ∨ x.toNat = 1 ∨ x.toNat = 2 := by omega
  exact hx.imp BitVec.eq_of_toNat_eq
    (fun h ↦ Or.imp BitVec.eq_of_toNat_eq BitVec.eq_of_toNat_eq h)

private theorem shiftLeftGap
    (f : BinaryConcreteOp (BitVec 8) (BitVec 8) (BitVec 8))
    (hzero : ∀ x amount, (x = 0 ∨ x = 1) →
      (amount = 0 ∨ amount = 1 ∨ amount = 2) → 3 ∉ f x amount)
    (hbelow : 2 ∈ f 1 1) (habove : 4 ∈ f 1 2) :
    ¬ BinaryForwardComplete (UIntRange.domain 8) (UIntRange.domain 8)
      (UIntRange.domain 8) f := by
  apply binaryForwardIncompleteOfGap_i8 f
    0 1 0 2 2 3 4 (by bv_decide) (by bv_decide) (by bv_decide)
    1 1 1 2 (by bv_decide) (by bv_decide) hbelow habove
  intro x amount hxLower hxUpper haLower haUpper
  exact hzero x amount (bitvec8_eq_zero_or_one hxLower hxUpper)
    (bitvec8_eq_zero_or_one_or_two haLower haUpper)

theorem uintRange_shl_i8_not_forwardComplete :
    ¬ BinaryForwardComplete (UIntRange.domain 8) (UIntRange.domain 8)
      (UIntRange.domain 8)
      (shl : BinaryConcreteOp (BitVec 8) (BitVec 8) (BitVec 8)) := by
  apply shiftLeftGap shl
  · intro x amount hx ha
    rcases hx with rfl | rfl <;> rcases ha with rfl | rfl | rfl <;>
      simp [shl, shl?, poisonIf]
  · simp [shl, shl?, poisonIf]
  · simp [shl, shl?, poisonIf]

theorem uintRange_shlNsw_i8_not_forwardComplete :
    ¬ BinaryForwardComplete (UIntRange.domain 8) (UIntRange.domain 8)
      (UIntRange.domain 8)
      (shlNsw : BinaryConcreteOp (BitVec 8) (BitVec 8) (BitVec 8)) := by
  apply shiftLeftGap shlNsw
  · intro x amount hx ha
    rcases hx with rfl | rfl <;> rcases ha with rfl | rfl | rfl <;>
      simp [shlNsw, shlNsw?, poisonIf]
  · simp [shlNsw, shlNsw?, poisonIf]
  · simp [shlNsw, shlNsw?, poisonIf]

theorem uintRange_shlNuw_i8_not_forwardComplete :
    ¬ BinaryForwardComplete (UIntRange.domain 8) (UIntRange.domain 8)
      (UIntRange.domain 8)
      (shlNuw : BinaryConcreteOp (BitVec 8) (BitVec 8) (BitVec 8)) := by
  apply shiftLeftGap shlNuw
  · intro x amount hx ha
    rcases hx with rfl | rfl <;> rcases ha with rfl | rfl | rfl <;>
      simp [shlNuw, shlNuw?, poisonIf]
  · simp [shlNuw, shlNuw?, poisonIf]
  · simp [shlNuw, shlNuw?, poisonIf]

theorem uintRange_shlNswNuw_i8_not_forwardComplete :
    ¬ BinaryForwardComplete (UIntRange.domain 8) (UIntRange.domain 8)
      (UIntRange.domain 8)
      (shlNswNuw : BinaryConcreteOp (BitVec 8) (BitVec 8) (BitVec 8)) := by
  apply shiftLeftGap shlNswNuw
  · intro x amount hx ha
    rcases hx with rfl | rfl <;> rcases ha with rfl | rfl | rfl <;>
      simp [shlNswNuw, shlNswNuw?, poisonIf]
  · simp [shlNswNuw, shlNswNuw?, poisonIf]
  · simp [shlNswNuw, shlNswNuw?, poisonIf]

theorem uintRange_ushlSat_i8_not_forwardComplete :
    ¬ BinaryForwardComplete (UIntRange.domain 8) (UIntRange.domain 8)
      (UIntRange.domain 8)
      (ushlSat : BinaryConcreteOp (BitVec 8) (BitVec 8) (BitVec 8)) := by
  apply shiftLeftGap ushlSat
  · intro x amount hx ha
    rcases hx with rfl | rfl <;> rcases ha with rfl | rfl | rfl <;>
      simp [ushlSat, ushlSat?]
  · simp [ushlSat, ushlSat?]
  · simp [ushlSat, ushlSat?]

theorem uintRange_sshlSat_i8_not_forwardComplete :
    ¬ BinaryForwardComplete (UIntRange.domain 8) (UIntRange.domain 8)
      (UIntRange.domain 8)
      (sshlSat : BinaryConcreteOp (BitVec 8) (BitVec 8) (BitVec 8)) := by
  apply shiftLeftGap sshlSat
  · intro x amount hx ha
    rcases hx with rfl | rfl <;> rcases ha with rfl | rfl | rfl <;>
      simp [sshlSat, sshlSat?]
  · simp [sshlSat, sshlSat?]
  · simp [sshlSat, sshlSat?]

private theorem rightShiftGap
    (f : BinaryConcreteOp (BitVec 8) (BitVec 8) (BitVec 8))
    (value below gap above : BitVec 8)
    (hbetween : below.toNat ≤ gap.toNat ∧ gap.toNat ≤ above.toNat)
    (hzero : gap ∉ f value 0) (hone : gap ∉ f value 1)
    (hbelow : below ∈ f value 1) (habove : above ∈ f value 0) :
    ¬ BinaryForwardComplete (UIntRange.domain 8) (UIntRange.domain 8)
      (UIntRange.domain 8) f := by
  apply binaryForwardIncompleteOfGap_i8 f
    value value 0 1 below gap above (by simp) (by bv_decide) hbetween
    value 1 value 0 (by simp) (by simp) hbelow habove
  intro x amount hxLower hxUpper haLower haUpper
  have hx : x = value := BitVec.eq_of_toNat_eq (by omega)
  have ha := bitvec8_eq_zero_or_one haLower haUpper
  rcases ha with ha | ha
  · simpa [hx, ha] using hzero
  · simpa [hx, ha] using hone

theorem uintRange_lshr_i8_not_forwardComplete :
    ¬ BinaryForwardComplete (UIntRange.domain 8) (UIntRange.domain 8)
      (UIntRange.domain 8)
      (lshr : BinaryConcreteOp (BitVec 8) (BitVec 8) (BitVec 8)) := by
  apply rightShiftGap lshr 3 1 2 3 (by bv_decide)
  all_goals simp [lshr, lshr?, poisonIf]

theorem uintRange_ashr_i8_not_forwardComplete :
    ¬ BinaryForwardComplete (UIntRange.domain 8) (UIntRange.domain 8)
      (UIntRange.domain 8)
      (ashr : BinaryConcreteOp (BitVec 8) (BitVec 8) (BitVec 8)) := by
  apply rightShiftGap ashr 3 1 2 3 (by bv_decide)
  all_goals simp [ashr, ashr?, poisonIf]

theorem uintRange_lshrExact_i8_not_forwardComplete :
    ¬ BinaryForwardComplete (UIntRange.domain 8) (UIntRange.domain 8)
      (UIntRange.domain 8)
      (lshrExact : BinaryConcreteOp (BitVec 8) (BitVec 8) (BitVec 8)) := by
  apply rightShiftGap lshrExact 4 2 3 4 (by bv_decide)
  all_goals simp [lshrExact, lshrExact?, poisonIf]

theorem uintRange_ashrExact_i8_not_forwardComplete :
    ¬ BinaryForwardComplete (UIntRange.domain 8) (UIntRange.domain 8)
      (UIntRange.domain 8)
      (ashrExact : BinaryConcreteOp (BitVec 8) (BitVec 8) (BitVec 8)) := by
  apply rightShiftGap ashrExact 4 2 3 4 (by bv_decide)
  all_goals simp [ashrExact, ashrExact?, poisonIf]

theorem uintRange_shl_i8_not_backwardComplete :
    ¬ BinaryBackwardComplete (UIntRange.domain 8) (UIntRange.domain 8)
      (UIntRange.domain 8)
      (shl : BinaryConcreteOp (BitVec 8) (BitVec 8) (BitVec 8)) := by
  apply binaryBackwardIncompleteOfCorner_i8 shl
    0 1 0 8 1 1 2 0 1 (by bv_decide) (by bv_decide) (by bv_decide)
  · simp [shl, shl?, poisonIf]
  · bv_decide
  · bv_decide
  · intro x amount z hx ha hz
    rcases hx with rfl | rfl <;> rcases ha with rfl | rfl <;>
      simp [shl, shl?, poisonIf] at hz <;>
      rcases hz with ⟨_, rfl⟩ <;> simp_all

theorem uintRange_shlNsw_i8_not_backwardComplete :
    ¬ BinaryBackwardComplete (UIntRange.domain 8) (UIntRange.domain 8)
      (UIntRange.domain 8)
      (shlNsw : BinaryConcreteOp (BitVec 8) (BitVec 8) (BitVec 8)) := by
  apply binaryBackwardIncompleteOfCorner_i8 shlNsw
    0 1 0 7 1 1 2 0 1 (by bv_decide) (by bv_decide) (by bv_decide)
  · simp [shlNsw, shlNsw?, poisonIf]
  · bv_decide
  · bv_decide
  · intro x amount z hx ha hz
    rcases hx with rfl | rfl <;> rcases ha with rfl | rfl <;>
      simp [shlNsw, shlNsw?, poisonIf] at hz <;>
      rcases hz with ⟨_, rfl⟩ <;> simp_all

theorem uintRange_shlNuw_i8_not_backwardComplete :
    ¬ BinaryBackwardComplete (UIntRange.domain 8) (UIntRange.domain 8)
      (UIntRange.domain 8)
      (shlNuw : BinaryConcreteOp (BitVec 8) (BitVec 8) (BitVec 8)) := by
  apply binaryBackwardIncompleteOfCorner_i8 shlNuw
    0 1 0 8 1 1 2 0 1 (by bv_decide) (by bv_decide) (by bv_decide)
  · simp [shlNuw, shlNuw?, poisonIf]
  · bv_decide
  · bv_decide
  · intro x amount z hx ha hz
    rcases hx with rfl | rfl <;> rcases ha with rfl | rfl <;>
      simp [shlNuw, shlNuw?, poisonIf] at hz <;>
      rcases hz with ⟨_, rfl⟩ <;> simp_all

theorem uintRange_shlNswNuw_i8_not_backwardComplete :
    ¬ BinaryBackwardComplete (UIntRange.domain 8) (UIntRange.domain 8)
      (UIntRange.domain 8)
      (shlNswNuw : BinaryConcreteOp (BitVec 8) (BitVec 8) (BitVec 8)) := by
  apply binaryBackwardIncompleteOfCorner_i8 shlNswNuw
    0 1 0 7 1 1 2 0 1 (by bv_decide) (by bv_decide) (by bv_decide)
  · simp [shlNswNuw, shlNswNuw?, poisonIf]
  · bv_decide
  · bv_decide
  · intro x amount z hx ha hz
    rcases hx with rfl | rfl <;> rcases ha with rfl | rfl <;>
      simp [shlNswNuw, shlNswNuw?, poisonIf] at hz <;>
      rcases hz with ⟨_, rfl⟩ <;> simp_all

theorem uintRange_ushlSat_i8_not_backwardComplete :
    ¬ BinaryBackwardComplete (UIntRange.domain 8) (UIntRange.domain 8)
      (UIntRange.domain 8)
      (ushlSat : BinaryConcreteOp (BitVec 8) (BitVec 8) (BitVec 8)) := by
  apply binaryBackwardIncompleteOfCorner_i8 ushlSat
    0 1 0 8 1 1 2 0 1 (by bv_decide) (by bv_decide) (by bv_decide)
  · simp [ushlSat, ushlSat?]
  · bv_decide
  · bv_decide
  · intro x amount z hx ha hz
    rcases hx with rfl | rfl <;> rcases ha with rfl | rfl <;>
      simp [ushlSat, ushlSat?] at hz <;>
      rcases hz with ⟨_, rfl⟩ <;> simp_all

theorem uintRange_sshlSat_i8_not_backwardComplete :
    ¬ BinaryBackwardComplete (UIntRange.domain 8) (UIntRange.domain 8)
      (UIntRange.domain 8)
      (sshlSat : BinaryConcreteOp (BitVec 8) (BitVec 8) (BitVec 8)) := by
  apply binaryBackwardIncompleteOfCorner_i8 sshlSat
    0 1 0 8 1 1 2 0 1 (by bv_decide) (by bv_decide) (by bv_decide)
  · simp [sshlSat, sshlSat?]
  · bv_decide
  · bv_decide
  · intro x amount z hx ha hz
    rcases hx with rfl | rfl <;> rcases ha with rfl | rfl <;>
      simp [sshlSat, sshlSat?] at hz <;>
      rcases hz with ⟨_, rfl⟩ <;> simp_all

theorem uintRange_lshr_i8_not_backwardComplete :
    ¬ BinaryBackwardComplete (UIntRange.domain 8) (UIntRange.domain 8)
      (UIntRange.domain 8)
      (lshr : BinaryConcreteOp (BitVec 8) (BitVec 8) (BitVec 8)) := by
  apply binaryBackwardIncompleteOfCorner_i8 lshr
    1 1 0 8 1 1 0 1 1 (by bv_decide) (by bv_decide) (by bv_decide)
  · simp [lshr, lshr?, poisonIf]
  · bv_decide
  · bv_decide
  · intro x amount z hx ha hz
    rcases hx with rfl | rfl <;> rcases ha with rfl | rfl <;>
      simp [lshr, lshr?, poisonIf] at hz <;>
      rcases hz with ⟨_, rfl⟩ <;> simp_all

theorem uintRange_ashr_i8_not_backwardComplete :
    ¬ BinaryBackwardComplete (UIntRange.domain 8) (UIntRange.domain 8)
      (UIntRange.domain 8)
      (ashr : BinaryConcreteOp (BitVec 8) (BitVec 8) (BitVec 8)) := by
  apply binaryBackwardIncompleteOfCorner_i8 ashr
    1 1 0 8 1 1 0 1 1 (by bv_decide) (by bv_decide) (by bv_decide)
  · simp [ashr, ashr?, poisonIf]
  · bv_decide
  · bv_decide
  · intro x amount z hx ha hz
    rcases hx with rfl | rfl <;> rcases ha with rfl | rfl <;>
      simp [ashr, ashr?, poisonIf] at hz <;>
      rcases hz with ⟨_, rfl⟩ <;> simp_all

theorem uintRange_lshrExact_i8_not_backwardComplete :
    ¬ BinaryBackwardComplete (UIntRange.domain 8) (UIntRange.domain 8)
      (UIntRange.domain 8)
      (lshrExact : BinaryConcreteOp (BitVec 8) (BitVec 8) (BitVec 8)) := by
  apply binaryBackwardIncompleteOfCorner_i8 lshrExact
    0 3 1 1 2 1 1 0 0 (by bv_decide) (by bv_decide) (by bv_decide)
  · simp [lshrExact, lshrExact?, poisonIf]
  · bv_decide
  · bv_decide
  · intro x amount z hx ha hz
    rcases hx with rfl | rfl <;> rcases ha with rfl | rfl <;>
      simp [lshrExact, lshrExact?, poisonIf] at hz <;>
      rcases hz with ⟨_, rfl⟩ <;> simp_all

theorem uintRange_ashrExact_i8_not_backwardComplete :
    ¬ BinaryBackwardComplete (UIntRange.domain 8) (UIntRange.domain 8)
      (UIntRange.domain 8)
      (ashrExact : BinaryConcreteOp (BitVec 8) (BitVec 8) (BitVec 8)) := by
  apply binaryBackwardIncompleteOfCorner_i8 ashrExact
    0 3 1 1 2 1 1 0 0 (by bv_decide) (by bv_decide) (by bv_decide)
  · simp [ashrExact, ashrExact?, poisonIf]
  · bv_decide
  · bv_decide
  · intro x amount z hx ha hz
    rcases hx with rfl | rfl <;> rcases ha with rfl | rfl <;>
      simp [ashrExact, ashrExact?, poisonIf] at hz <;>
      rcases hz with ⟨_, rfl⟩ <;> simp_all

end SynthXfer.LLVM
