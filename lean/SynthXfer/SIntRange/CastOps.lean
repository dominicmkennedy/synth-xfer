import SynthXfer.SIntRange.NoWrapArithmetic
import Std.Tactic.BVDecide

/-!
# Cast operations in SIntRange
-/

namespace SynthXfer.LLVM

open SIntRange

private theorem orderedSignExtend_monotone {n m : Nat} (h : n ≤ m) :
    Monotone
      (SIntRange.orderedUnary (BitVec.signExtend m : BitVec n → BitVec m)) := by
  intro x y hxy
  change (x.bitvec.signExtend m).toInt ≤ (y.bitvec.signExtend m).toInt
  simpa [BitVec.toInt_signExtend_of_le h] using hxy

theorem sintRange_sext_forwardComplete (n m : Nat)
    (hwidths : ValidExtensionWidths n m) :
    ForwardComplete (SIntRange.domain n) (SIntRange.domain m) (sext n m) := by
  change ForwardComplete (SIntRange.domain n) (SIntRange.domain m)
    (ConcreteOp.ofTotal (BitVec.signExtend m : BitVec n → BitVec m))
  rw [SIntRange.forwardComplete_ofTotal_iff_ordConnected]
  intro interval
  constructor
  rintro _ ⟨x, hx, rfl⟩ _ ⟨y, hy, rfl⟩ z hz
  have hnm : n ≤ m := Nat.le_of_lt hwidths.2
  have hzInt : x.bitvec.toInt ≤ z.bitvec.toInt ∧
      z.bitvec.toInt ≤ y.bitvec.toInt := by
    simpa [SIntRange.orderedUnary, BitVec.toInt_signExtend_of_le hnm] using hz
  let source : BitVec n := BitVec.ofInt n z.bitvec.toInt
  have hxy : x.bitvec.toInt ≤ y.bitvec.toInt := hzInt.1.trans hzInt.2
  have hsourceInt : source.toInt = z.bitvec.toInt := by
    apply toInt_ofInt_eq_of_between hwidths.1 z.bitvec.toInt
      x.bitvec y.bitvec
    · simpa [min_eq_left hxy] using hzInt.1
    · simpa [max_eq_right hxy] using hzInt.2
  have hsourceMem : SignedBitVec.equiv n source ∈
      (interval : Set (SignedBitVec n)) := by
    cases interval with
    | none => exact False.elim (show False from hx)
    | some bounds =>
        have hlower : x.bitvec.toInt ≤ source.toInt := by
          simpa [hsourceInt] using hzInt.1
        have hupper : source.toInt ≤ y.bitvec.toInt := by
          simpa [hsourceInt] using hzInt.2
        exact ⟨hx.1.trans hlower, hupper.trans hy.2⟩
  refine ⟨⟨source⟩, hsourceMem, ?_⟩
  apply SignedBitVec.ext
  apply BitVec.eq_of_toInt_eq
  change (source.signExtend m).toInt = z.bitvec.toInt
  rw [BitVec.toInt_signExtend_of_le hnm, hsourceInt]

theorem sintRange_sext_backwardComplete (n m : Nat)
    (hwidths : ValidExtensionWidths n m) :
    BackwardComplete (SIntRange.domain n) (SIntRange.domain m) (sext n m) := by
  change BackwardComplete (SIntRange.domain n) (SIntRange.domain m)
    (ConcreteOp.ofTotal (BitVec.signExtend m : BitVec n → BitVec m))
  exact SIntRange.backwardComplete_of_monotone _
    (orderedSignExtend_monotone (Nat.le_of_lt hwidths.2))

private theorem bitvec8_eq_neg_one_or_zero {x : BitVec 8}
    (hlower : (255 : BitVec 8).toInt ≤ x.toInt)
    (hupper : x.toInt ≤ (0 : BitVec 8).toInt) : x = 255 ∨ x = 0 := by
  have h255 : (255 : BitVec 8).toInt = -1 := by bv_decide
  have h0 : (0 : BitVec 8).toInt = 0 := by bv_decide
  rw [h255] at hlower
  rw [h0] at hupper
  have hx : x.toInt = -1 ∨ x.toInt = 0 := by omega
  rcases hx with hx | hx
  · exact Or.inl (BitVec.eq_of_toInt_eq (by simpa using hx))
  · exact Or.inr (BitVec.eq_of_toInt_eq hx)

theorem sintRange_zext_i8_i16_not_forwardComplete :
    ¬ ForwardComplete (SIntRange.domain 8) (SIntRange.domain 16)
      (zext 8 16) := by
  apply unaryForwardIncompleteOfGap_i8 (zext 8 16)
    255 0 0 1 255 0 255 (by bv_decide) (by bv_decide)
      (by bv_decide) (by bv_decide)
  · simp [zext]
  · simp [zext]
  · intro x hxLower hxUpper
    rcases bitvec8_eq_neg_one_or_zero hxLower hxUpper with rfl | rfl <;>
      simp [zext]

theorem sintRange_zext_i8_i16_not_backwardComplete :
    ¬ BackwardComplete (SIntRange.domain 8) (SIntRange.domain 16)
      (zext 8 16) := by
  apply unaryBackwardIncompleteOfEndpoint_i8 (zext 8 16)
    255 1 0 0 1 255 (by bv_decide) (by bv_decide)
  · simp [zext]
  · bv_decide
  · bv_decide
  · intro x z hx hz
    rcases hx with rfl | rfl <;> simp [zext] at hz <;>
      rcases hz with ⟨_, rfl⟩ <;> bv_decide

theorem sintRange_trunc_i8_i4_not_forwardComplete :
    ¬ ForwardComplete (SIntRange.domain 8) (SIntRange.domain 4)
      (trunc 8 4) := by
  apply unaryForwardIncompleteOfGap_i8 (trunc 8 4)
    7 8 8 0 7 8 7 (by bv_decide) (by bv_decide)
      (by bv_decide) (by bv_decide)
  · simp [trunc]
  · simp [trunc]
  · intro x hxLower hxUpper
    have hx : x = 7 ∨ x = 8 := by
      have h7 : (7 : BitVec 8).toInt = 7 := by bv_decide
      have h8 : (8 : BitVec 8).toInt = 8 := by bv_decide
      rw [h7] at hxLower
      rw [h8] at hxUpper
      have : x.toInt = 7 ∨ x.toInt = 8 := by omega
      exact this.imp BitVec.eq_of_toInt_eq BitVec.eq_of_toInt_eq
    rcases hx with rfl | rfl <;> simp [trunc]

theorem sintRange_trunc_i8_i4_not_backwardComplete :
    ¬ BackwardComplete (SIntRange.domain 8) (SIntRange.domain 4)
      (trunc 8 4) := by
  apply unaryBackwardIncompleteOfEndpoint_i8 (trunc 8 4)
    7 9 8 8 9 7 (by bv_decide) (by bv_decide)
  · simp [trunc]
  · bv_decide
  · bv_decide
  · intro x z hx hz
    rcases hx with rfl | rfl <;> simp [trunc] at hz <;>
      rcases hz with ⟨_, rfl⟩ <;> bv_decide

private theorem zextBool_one_toInt {n : Nat}
    (hwidths : ValidExtensionWidths 1 n) :
    ((1 : BitVec 1).setWidth n).toInt = 1 := by
  have hn : 2 ≤ n := Nat.succ_le_iff.mpr hwidths.2
  rw [BitVec.toInt_setWidth]
  change Int.bmod 1 (2 ^ n) = 1
  rw [Int.bmod_eq_of_le]
  · have hpow : 2 ^ 2 ≤ 2 ^ n :=
      Nat.pow_le_pow_right (by decide) hn
    omega
  · have hpow : 2 ^ 2 ≤ 2 ^ n :=
      Nat.pow_le_pow_right (by decide) hn
    omega

private theorem zextBool_toInt {n : Nat}
    (hwidths : ValidExtensionWidths 1 n) (x : BitVec 1) :
    (x.setWidth n).toInt = x.toNat := by
  rcases BitVec.eq_zero_or_eq_one x with hx | hx
  · rw [hx]
    simp
  · rw [hx]
    exact zextBool_one_toInt hwidths

private theorem orderedZextBool_antitone {n : Nat}
    (hwidths : ValidExtensionWidths 1 n) :
    Antitone
      (SIntRange.orderedUnary (BitVec.setWidth n : BitVec 1 → BitVec n)) := by
  rintro ⟨x⟩ ⟨y⟩ hxy
  change (y.setWidth n).toInt ≤ (x.setWidth n).toInt
  rw [zextBool_toInt hwidths, zextBool_toInt hwidths]
  rcases BitVec.eq_zero_or_eq_one x with hx | hx <;>
    rcases BitVec.eq_zero_or_eq_one y with hy | hy
  all_goals simp [hx, hy] at hxy ⊢

theorem sintRange_zextBool_forwardComplete (n : Nat)
    (hwidths : ValidExtensionWidths 1 n) :
    ForwardComplete (SIntRange.domain 1) (SIntRange.domain n)
      (zextBool n) := by
  change ForwardComplete (SIntRange.domain 1) (SIntRange.domain n)
    (ConcreteOp.ofTotal (BitVec.setWidth n : BitVec 1 → BitVec n))
  rw [SIntRange.forwardComplete_ofTotal_iff_ordConnected]
  intro interval
  constructor
  rintro _ ⟨x, hx, rfl⟩ _ ⟨y, hy, rfl⟩ z hz
  change (x.bitvec.setWidth n).toInt ≤ z.bitvec.toInt ∧
    z.bitvec.toInt ≤ (y.bitvec.setWidth n).toInt at hz
  rw [zextBool_toInt hwidths, zextBool_toInt hwidths] at hz
  rcases BitVec.eq_zero_or_eq_one x.bitvec with hxZero | hxOne <;>
    rcases BitVec.eq_zero_or_eq_one y.bitvec with hyZero | hyOne
  · refine ⟨x, hx, ?_⟩
    apply SignedBitVec.ext
    apply BitVec.eq_of_toInt_eq
    change (x.bitvec.setWidth n).toInt = z.bitvec.toInt
    rw [zextBool_toInt hwidths]
    rw [hxZero, hyZero] at hz
    simp at hz
    simpa [hxZero] using (le_antisymm hz.2 hz.1).symm
  · have hzInt : z.bitvec.toInt = 0 ∨ z.bitvec.toInt = 1 := by
      rw [hxZero, hyOne] at hz
      simp at hz
      omega
    rcases hzInt with hzZero | hzOne
    · refine ⟨x, hx, ?_⟩
      apply SignedBitVec.ext
      apply BitVec.eq_of_toInt_eq
      change (x.bitvec.setWidth n).toInt = z.bitvec.toInt
      rw [zextBool_toInt hwidths]
      simp [hxZero, hzZero]
    · refine ⟨y, hy, ?_⟩
      apply SignedBitVec.ext
      apply BitVec.eq_of_toInt_eq
      change (y.bitvec.setWidth n).toInt = z.bitvec.toInt
      rw [zextBool_toInt hwidths]
      simp [hyOne, hzOne]
  · rw [hxOne, hyZero] at hz
    simp at hz
    omega
  · refine ⟨x, hx, ?_⟩
    apply SignedBitVec.ext
    apply BitVec.eq_of_toInt_eq
    change (x.bitvec.setWidth n).toInt = z.bitvec.toInt
    rw [zextBool_toInt hwidths]
    have hzEq : z.bitvec.toInt = 1 := by
      rw [hxOne, hyOne] at hz
      simp at hz
      omega
    simp [hxOne, hzEq]

theorem sintRange_zextBool_backwardComplete (n : Nat)
    (hwidths : ValidExtensionWidths 1 n) :
    BackwardComplete (SIntRange.domain 1) (SIntRange.domain n)
      (zextBool n) := by
  change BackwardComplete (SIntRange.domain 1) (SIntRange.domain n)
    (ConcreteOp.ofTotal (BitVec.setWidth n : BitVec 1 → BitVec n))
  exact SIntRange.backwardComplete_of_antitone _
    (orderedZextBool_antitone hwidths)

theorem sintRange_sextBool_forwardComplete (n : Nat)
    (hwidths : ValidExtensionWidths 1 n) :
    ForwardComplete (SIntRange.domain 1) (SIntRange.domain n)
      (sextBool n) := by
  simpa [sextBool] using sintRange_sext_forwardComplete 1 n hwidths

theorem sintRange_sextBool_backwardComplete (n : Nat)
    (hwidths : ValidExtensionWidths 1 n) :
    BackwardComplete (SIntRange.domain 1) (SIntRange.domain n)
      (sextBool n) := by
  simpa [sextBool] using sintRange_sext_backwardComplete 1 n hwidths

theorem sintRange_truncToBool_forwardComplete (n : Nat)
    (_hwidths : ValidTruncWidths n 1) :
    ForwardComplete (SIntRange.domain n) (SIntRange.domain 1)
      (truncToBool n) := by
  change ForwardComplete (SIntRange.domain n) (SIntRange.domain 1)
    (ConcreteOp.ofTotal (BitVec.setWidth 1 : BitVec n → BitVec 1))
  exact SIntRange.unaryForwardComplete_i1Result _

theorem sintRange_truncToBool_i8_i1_not_backwardComplete :
    ¬ BackwardComplete (SIntRange.domain 8) (SIntRange.domain 1)
      (truncToBool 8) := by
  apply unaryBackwardIncompleteOfEndpoint_i8 (truncToBool 8)
    0 2 1 1 0 0 (by bv_decide) (by bv_decide)
  · simp [truncToBool, trunc]
  · decide
  · decide
  · intro x z hx hz
    rcases hx with rfl | rfl <;>
      simp [truncToBool, trunc] at hz <;>
      rcases hz with ⟨_, rfl⟩ <;> decide

end SynthXfer.LLVM
