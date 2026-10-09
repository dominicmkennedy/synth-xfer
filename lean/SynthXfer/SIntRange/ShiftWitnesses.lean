import SynthXfer.SIntRange.Witnesses
import Std.Tactic.BVDecide

namespace SynthXfer.LLVM

open SIntRange

attribute [local simp] validShift signedFits signedMin signedMax unsignedMax
  clampUnsigned clampSigned shiftedOutBitsAreZero

private theorem bitvec8_eq_zero_or_one {x : BitVec 8}
    (hlower : (0 : BitVec 8).toInt ≤ x.toInt)
    (hupper : x.toInt ≤ (1 : BitVec 8).toInt) : x = 0 ∨ x = 1 := by
  have h0 : (0 : BitVec 8).toInt = 0 := by bv_decide
  have h1 : (1 : BitVec 8).toInt = 1 := by bv_decide
  rw [h0] at hlower
  rw [h1] at hupper
  have hx : x.toInt = 0 ∨ x.toInt = 1 := by omega
  exact hx.imp BitVec.eq_of_toInt_eq BitVec.eq_of_toInt_eq

private theorem bitvec8_eq_zero_or_one_or_two {x : BitVec 8}
    (hlower : (0 : BitVec 8).toInt ≤ x.toInt)
    (hupper : x.toInt ≤ (2 : BitVec 8).toInt) :
    x = 0 ∨ x = 1 ∨ x = 2 := by
  have h0 : (0 : BitVec 8).toInt = 0 := by bv_decide
  have h2 : (2 : BitVec 8).toInt = 2 := by bv_decide
  rw [h0] at hlower
  rw [h2] at hupper
  have hx : x.toInt = 0 ∨ x.toInt = 1 ∨ x.toInt = 2 := by omega
  exact hx.imp BitVec.eq_of_toInt_eq
    (fun h ↦ Or.imp BitVec.eq_of_toInt_eq BitVec.eq_of_toInt_eq h)

private theorem shiftLeftForwardIncomplete
    (f : BinaryConcreteOp (BitVec 8) (BitVec 8) (BitVec 8))
    (hgap : ∀ x amount, (x = 0 ∨ x = 1) →
      (amount = 0 ∨ amount = 1 ∨ amount = 2) → 3 ∉ f x amount)
    (hbelow : 2 ∈ f 1 1) (habove : 4 ∈ f 1 2) :
    ¬ BinaryForwardComplete (SIntRange.domain 8) (SIntRange.domain 8)
      (SIntRange.domain 8) f := by
  apply binaryForwardIncompleteOfGap_i8 f
    0 1 0 2 2 3 4 (by bv_decide) (by bv_decide) (by bv_decide)
    1 1 1 2 (by bv_decide) (by bv_decide) hbelow habove
  intro x amount hxLower hxUpper haLower haUpper
  exact hgap x amount (bitvec8_eq_zero_or_one hxLower hxUpper)
    (bitvec8_eq_zero_or_one_or_two haLower haUpper)

theorem sintRange_shl_i8_not_forwardComplete :
    ¬ BinaryForwardComplete (SIntRange.domain 8) (SIntRange.domain 8)
      (SIntRange.domain 8)
      (shl : BinaryConcreteOp (BitVec 8) (BitVec 8) (BitVec 8)) := by
  apply shiftLeftForwardIncomplete shl
  · intro x amount hx ha
    rcases hx with rfl | rfl <;> rcases ha with rfl | rfl | rfl <;>
      simp [shl, shl?, poisonIf]
  · simp [shl, shl?, poisonIf]
  · simp [shl, shl?, poisonIf]

theorem sintRange_shlNsw_i8_not_forwardComplete :
    ¬ BinaryForwardComplete (SIntRange.domain 8) (SIntRange.domain 8)
      (SIntRange.domain 8)
      (shlNsw : BinaryConcreteOp (BitVec 8) (BitVec 8) (BitVec 8)) := by
  apply shiftLeftForwardIncomplete shlNsw
  · intro x amount hx ha
    rcases hx with rfl | rfl <;> rcases ha with rfl | rfl | rfl <;>
      simp [shlNsw, shlNsw?, poisonIf]
  · simp [shlNsw, shlNsw?, poisonIf]
  · simp [shlNsw, shlNsw?, poisonIf]

theorem sintRange_shlNuw_i8_not_forwardComplete :
    ¬ BinaryForwardComplete (SIntRange.domain 8) (SIntRange.domain 8)
      (SIntRange.domain 8)
      (shlNuw : BinaryConcreteOp (BitVec 8) (BitVec 8) (BitVec 8)) := by
  apply shiftLeftForwardIncomplete shlNuw
  · intro x amount hx ha
    rcases hx with rfl | rfl <;> rcases ha with rfl | rfl | rfl <;>
      simp [shlNuw, shlNuw?, poisonIf]
  · simp [shlNuw, shlNuw?, poisonIf]
  · simp [shlNuw, shlNuw?, poisonIf]

theorem sintRange_shlNswNuw_i8_not_forwardComplete :
    ¬ BinaryForwardComplete (SIntRange.domain 8) (SIntRange.domain 8)
      (SIntRange.domain 8)
      (shlNswNuw : BinaryConcreteOp (BitVec 8) (BitVec 8) (BitVec 8)) := by
  apply shiftLeftForwardIncomplete shlNswNuw
  · intro x amount hx ha
    rcases hx with rfl | rfl <;> rcases ha with rfl | rfl | rfl <;>
      simp [shlNswNuw, shlNswNuw?, poisonIf]
  · simp [shlNswNuw, shlNswNuw?, poisonIf]
  · simp [shlNswNuw, shlNswNuw?, poisonIf]

theorem sintRange_ushlSat_i8_not_forwardComplete :
    ¬ BinaryForwardComplete (SIntRange.domain 8) (SIntRange.domain 8)
      (SIntRange.domain 8)
      (ushlSat : BinaryConcreteOp (BitVec 8) (BitVec 8) (BitVec 8)) := by
  apply shiftLeftForwardIncomplete ushlSat
  · intro x amount hx ha
    rcases hx with rfl | rfl <;> rcases ha with rfl | rfl | rfl <;>
      simp [ushlSat, ushlSat?]
  · simp [ushlSat, ushlSat?]
  · simp [ushlSat, ushlSat?]

theorem sintRange_sshlSat_i8_not_forwardComplete :
    ¬ BinaryForwardComplete (SIntRange.domain 8) (SIntRange.domain 8)
      (SIntRange.domain 8)
      (sshlSat : BinaryConcreteOp (BitVec 8) (BitVec 8) (BitVec 8)) := by
  apply shiftLeftForwardIncomplete sshlSat
  · intro x amount hx ha
    rcases hx with rfl | rfl <;> rcases ha with rfl | rfl | rfl <;>
      simp [sshlSat, sshlSat?]
  · simp [sshlSat, sshlSat?]
  · simp [sshlSat, sshlSat?]

private theorem rightShiftForwardIncomplete
    (f : BinaryConcreteOp (BitVec 8) (BitVec 8) (BitVec 8))
    (value below gap above : BitVec 8)
    (hbetween : below.toInt ≤ gap.toInt ∧ gap.toInt ≤ above.toInt)
    (hzero : gap ∉ f value 0) (hone : gap ∉ f value 1)
    (hbelow : below ∈ f value 1) (habove : above ∈ f value 0) :
    ¬ BinaryForwardComplete (SIntRange.domain 8) (SIntRange.domain 8)
      (SIntRange.domain 8) f := by
  apply binaryForwardIncompleteOfGap_i8 f
    value value 0 1 below gap above (by simp) (by bv_decide) hbetween
    value 1 value 0 (by simp) (by simp) hbelow habove
  intro x amount hxLower hxUpper haLower haUpper
  have hx : x = value := BitVec.eq_of_toInt_eq (by omega)
  rcases bitvec8_eq_zero_or_one haLower haUpper with ha | ha
  · simpa [hx, ha] using hzero
  · simpa [hx, ha] using hone

theorem sintRange_lshr_i8_not_forwardComplete :
    ¬ BinaryForwardComplete (SIntRange.domain 8) (SIntRange.domain 8)
      (SIntRange.domain 8)
      (lshr : BinaryConcreteOp (BitVec 8) (BitVec 8) (BitVec 8)) := by
  apply rightShiftForwardIncomplete lshr 3 1 2 3 (by bv_decide)
  all_goals simp [lshr, lshr?, poisonIf]

theorem sintRange_ashr_i8_not_forwardComplete :
    ¬ BinaryForwardComplete (SIntRange.domain 8) (SIntRange.domain 8)
      (SIntRange.domain 8)
      (ashr : BinaryConcreteOp (BitVec 8) (BitVec 8) (BitVec 8)) := by
  apply rightShiftForwardIncomplete ashr 3 1 2 3 (by bv_decide)
  all_goals simp [ashr, ashr?, poisonIf]

theorem sintRange_lshrExact_i8_not_forwardComplete :
    ¬ BinaryForwardComplete (SIntRange.domain 8) (SIntRange.domain 8)
      (SIntRange.domain 8)
      (lshrExact : BinaryConcreteOp (BitVec 8) (BitVec 8) (BitVec 8)) := by
  apply rightShiftForwardIncomplete lshrExact 4 2 3 4 (by bv_decide)
  all_goals simp [lshrExact, lshrExact?, poisonIf]

theorem sintRange_ashrExact_i8_not_forwardComplete :
    ¬ BinaryForwardComplete (SIntRange.domain 8) (SIntRange.domain 8)
      (SIntRange.domain 8)
      (ashrExact : BinaryConcreteOp (BitVec 8) (BitVec 8) (BitVec 8)) := by
  apply rightShiftForwardIncomplete ashrExact 4 2 3 4 (by bv_decide)
  all_goals simp [ashrExact, ashrExact?, poisonIf]

private theorem shiftLeftBackwardIncomplete
    (f : BinaryConcreteOp (BitVec 8) (BitVec 8) (BitVec 8))
    (amountUpper : BitVec 8)
    (hamount : (1 : BitVec 8).toInt ≤ amountUpper.toInt)
    (hinside : (2 : BitVec 8) ∈ f 1 1)
    (hcorners : ∀ x amount z,
      (x = (0 : BitVec 8) ∨ x = 1) →
      (amount = (0 : BitVec 8) ∨ amount = amountUpper) →
      z ∈ f x amount →
      (0 : BitVec 8).toInt ≤ z.toInt ∧ z.toInt ≤ (1 : BitVec 8).toInt) :
    ¬ BinaryBackwardComplete (SIntRange.domain 8) (SIntRange.domain 8)
      (SIntRange.domain 8) f := by
  apply binaryBackwardIncompleteOfCorner_i8 f
    0 1 0 amountUpper 1 1 2 0 1
    (by bv_decide) (le_trans (by decide) hamount)
    (by exact ⟨by decide, by decide, by decide, hamount⟩) hinside
    (by bv_decide) (by bv_decide) hcorners

theorem sintRange_shl_i8_not_backwardComplete :
    ¬ BinaryBackwardComplete (SIntRange.domain 8) (SIntRange.domain 8)
      (SIntRange.domain 8)
      (shl : BinaryConcreteOp (BitVec 8) (BitVec 8) (BitVec 8)) := by
  apply shiftLeftBackwardIncomplete shl 8 (by bv_decide)
    (by simp [shl, shl?, poisonIf])
  intro x amount z hx ha hz
  rcases hx with rfl | rfl <;> rcases ha with rfl | rfl <;>
    simp [shl, shl?, poisonIf] at hz <;>
    rcases hz with ⟨_, rfl⟩ <;> simp_all

theorem sintRange_shlNsw_i8_not_backwardComplete :
    ¬ BinaryBackwardComplete (SIntRange.domain 8) (SIntRange.domain 8)
      (SIntRange.domain 8)
      (shlNsw : BinaryConcreteOp (BitVec 8) (BitVec 8) (BitVec 8)) := by
  apply shiftLeftBackwardIncomplete shlNsw 7 (by bv_decide)
    (by simp [shlNsw, shlNsw?, poisonIf])
  intro x amount z hx ha hz
  rcases hx with rfl | rfl <;> rcases ha with rfl | rfl <;>
    simp [shlNsw, shlNsw?, poisonIf] at hz <;>
    rcases hz with ⟨_, rfl⟩ <;> simp_all

theorem sintRange_shlNuw_i8_not_backwardComplete :
    ¬ BinaryBackwardComplete (SIntRange.domain 8) (SIntRange.domain 8)
      (SIntRange.domain 8)
      (shlNuw : BinaryConcreteOp (BitVec 8) (BitVec 8) (BitVec 8)) := by
  apply shiftLeftBackwardIncomplete shlNuw 8 (by bv_decide)
    (by simp [shlNuw, shlNuw?, poisonIf])
  intro x amount z hx ha hz
  rcases hx with rfl | rfl <;> rcases ha with rfl | rfl <;>
    simp [shlNuw, shlNuw?, poisonIf] at hz <;>
    rcases hz with ⟨_, rfl⟩ <;> simp_all

theorem sintRange_shlNswNuw_i8_not_backwardComplete :
    ¬ BinaryBackwardComplete (SIntRange.domain 8) (SIntRange.domain 8)
      (SIntRange.domain 8)
      (shlNswNuw : BinaryConcreteOp (BitVec 8) (BitVec 8) (BitVec 8)) := by
  apply shiftLeftBackwardIncomplete shlNswNuw 7 (by bv_decide)
    (by simp [shlNswNuw, shlNswNuw?, poisonIf])
  intro x amount z hx ha hz
  rcases hx with rfl | rfl <;> rcases ha with rfl | rfl <;>
    simp [shlNswNuw, shlNswNuw?, poisonIf] at hz <;>
    rcases hz with ⟨_, rfl⟩ <;> simp_all

theorem sintRange_ushlSat_i8_not_backwardComplete :
    ¬ BinaryBackwardComplete (SIntRange.domain 8) (SIntRange.domain 8)
      (SIntRange.domain 8)
      (ushlSat : BinaryConcreteOp (BitVec 8) (BitVec 8) (BitVec 8)) := by
  apply shiftLeftBackwardIncomplete ushlSat 8 (by bv_decide)
    (by simp [ushlSat, ushlSat?])
  intro x amount z hx ha hz
  rcases hx with rfl | rfl <;> rcases ha with rfl | rfl <;>
    simp [ushlSat, ushlSat?] at hz <;>
    rcases hz with ⟨_, rfl⟩ <;> simp_all

theorem sintRange_sshlSat_i8_not_backwardComplete :
    ¬ BinaryBackwardComplete (SIntRange.domain 8) (SIntRange.domain 8)
      (SIntRange.domain 8)
      (sshlSat : BinaryConcreteOp (BitVec 8) (BitVec 8) (BitVec 8)) := by
  apply shiftLeftBackwardIncomplete sshlSat 8 (by bv_decide)
    (by simp [sshlSat, sshlSat?])
  intro x amount z hx ha hz
  rcases hx with rfl | rfl <;> rcases ha with rfl | rfl <;>
    simp [sshlSat, sshlSat?] at hz <;>
    rcases hz with ⟨_, rfl⟩ <;> simp_all

private theorem rightShiftBackwardIncomplete
    (f : BinaryConcreteOp (BitVec 8) (BitVec 8) (BitVec 8))
    (hinside : (0 : BitVec 8) ∈ f 1 1)
    (hcorners : ∀ x amount z,
      (x = (1 : BitVec 8) ∨ x = 1) →
      (amount = (0 : BitVec 8) ∨ amount = 8) → z ∈ f x amount →
      (1 : BitVec 8).toInt ≤ z.toInt ∧ z.toInt ≤ (1 : BitVec 8).toInt) :
    ¬ BinaryBackwardComplete (SIntRange.domain 8) (SIntRange.domain 8)
      (SIntRange.domain 8) f := by
  apply binaryBackwardIncompleteOfCorner_i8 f
    1 1 0 8 1 1 0 1 1
    (by bv_decide) (by bv_decide) (by bv_decide) hinside
    (by bv_decide) (by bv_decide) hcorners

theorem sintRange_lshr_i8_not_backwardComplete :
    ¬ BinaryBackwardComplete (SIntRange.domain 8) (SIntRange.domain 8)
      (SIntRange.domain 8)
      (lshr : BinaryConcreteOp (BitVec 8) (BitVec 8) (BitVec 8)) := by
  apply rightShiftBackwardIncomplete lshr (by simp [lshr, lshr?, poisonIf])
  intro x amount z hx ha hz
  rcases hx with rfl | rfl <;> rcases ha with rfl | rfl <;>
    simp [lshr, lshr?, poisonIf] at hz <;>
    rcases hz with ⟨_, rfl⟩ <;> simp_all

theorem sintRange_ashr_i8_not_backwardComplete :
    ¬ BinaryBackwardComplete (SIntRange.domain 8) (SIntRange.domain 8)
      (SIntRange.domain 8)
      (ashr : BinaryConcreteOp (BitVec 8) (BitVec 8) (BitVec 8)) := by
  apply rightShiftBackwardIncomplete ashr (by simp [ashr, ashr?, poisonIf])
  intro x amount z hx ha hz
  rcases hx with rfl | rfl <;> rcases ha with rfl | rfl <;>
    simp [ashr, ashr?, poisonIf] at hz <;>
    rcases hz with ⟨_, rfl⟩ <;> simp_all

private theorem exactRightShiftBackwardIncomplete
    (f : BinaryConcreteOp (BitVec 8) (BitVec 8) (BitVec 8))
    (hinside : (1 : BitVec 8) ∈ f 2 1)
    (hcorners : ∀ x amount z,
      (x = (0 : BitVec 8) ∨ x = 3) →
      (amount = (1 : BitVec 8) ∨ amount = 1) → z ∈ f x amount →
      (0 : BitVec 8).toInt ≤ z.toInt ∧ z.toInt ≤ (0 : BitVec 8).toInt) :
    ¬ BinaryBackwardComplete (SIntRange.domain 8) (SIntRange.domain 8)
      (SIntRange.domain 8) f := by
  apply binaryBackwardIncompleteOfCorner_i8 f
    0 3 1 1 2 1 1 0 0
    (by bv_decide) (by bv_decide) (by bv_decide) hinside
    (by bv_decide) (by bv_decide) hcorners

theorem sintRange_lshrExact_i8_not_backwardComplete :
    ¬ BinaryBackwardComplete (SIntRange.domain 8) (SIntRange.domain 8)
      (SIntRange.domain 8)
      (lshrExact : BinaryConcreteOp (BitVec 8) (BitVec 8) (BitVec 8)) := by
  apply exactRightShiftBackwardIncomplete lshrExact
    (by simp [lshrExact, lshrExact?, poisonIf])
  intro x amount z hx ha hz
  rcases hx with rfl | rfl <;> rcases ha with rfl | rfl <;>
    simp [lshrExact, lshrExact?, poisonIf] at hz <;>
    rcases hz with ⟨_, rfl⟩ <;> simp_all

theorem sintRange_ashrExact_i8_not_backwardComplete :
    ¬ BinaryBackwardComplete (SIntRange.domain 8) (SIntRange.domain 8)
      (SIntRange.domain 8)
      (ashrExact : BinaryConcreteOp (BitVec 8) (BitVec 8) (BitVec 8)) := by
  apply exactRightShiftBackwardIncomplete ashrExact
    (by simp [ashrExact, ashrExact?, poisonIf])
  intro x amount z hx ha hz
  rcases hx with rfl | rfl <;> rcases ha with rfl | rfl <;>
    simp [ashrExact, ashrExact?, poisonIf] at hz <;>
    rcases hz with ⟨_, rfl⟩ <;> simp_all

end SynthXfer.LLVM
