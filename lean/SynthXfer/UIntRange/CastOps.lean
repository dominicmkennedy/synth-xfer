import SynthXfer.UIntRange.UnaryOps
import Std.Tactic.BVDecide

/-!
# Cast operations in UIntRange
-/

namespace SynthXfer.LLVM

open UIntRange

private theorem setWidth_toNat_eq {n m : Nat} (h : n ≤ m) (x : BitVec n) :
    (x.setWidth m).toNat = x.toNat := by
  rw [BitVec.toNat_setWidth, Nat.mod_eq_of_lt]
  exact x.isLt.trans_le (Nat.pow_le_pow_right (by omega) h)

private theorem orderedSetWidth_monotone {n m : Nat} (h : n ≤ m) :
    Monotone (UIntRange.orderedUnary (BitVec.setWidth m : BitVec n → BitVec m)) := by
  intro x y hxy
  change (x.bitvec.setWidth m).toNat ≤ (y.bitvec.setWidth m).toNat
  simpa [setWidth_toNat_eq h] using hxy

theorem uintRange_zext_forwardComplete (n m : Nat)
    (hwidths : ValidExtensionWidths n m) :
    ForwardComplete (UIntRange.domain n) (UIntRange.domain m) (zext n m) := by
  change ForwardComplete (UIntRange.domain n) (UIntRange.domain m)
    (ConcreteOp.ofTotal (BitVec.setWidth m : BitVec n → BitVec m))
  rw [UIntRange.forwardComplete_ofTotal_iff_ordConnected]
  intro interval
  constructor
  rintro _ ⟨x, hx, rfl⟩ _ ⟨y, hy, rfl⟩ z hz
  have hnm : n ≤ m := Nat.le_of_lt hwidths.2
  have hxNat := setWidth_toNat_eq hnm x.bitvec
  have hyNat := setWidth_toNat_eq hnm y.bitvec
  have hzNat : x.bitvec.toNat ≤ z.bitvec.toNat ∧
      z.bitvec.toNat ≤ y.bitvec.toNat := by
    simpa [UIntRange.orderedUnary, hxNat, hyNat] using hz
  have hzLt : z.bitvec.toNat < 2 ^ n := hzNat.2.trans_lt y.bitvec.isLt
  let source : BitVec n := BitVec.ofNat n z.bitvec.toNat
  have hsourceNat : source.toNat = z.bitvec.toNat := by
    simp [source, Nat.mod_eq_of_lt hzLt]
  have hsourceMem : UnsignedBitVec.equiv n source ∈
      (interval : Set (UnsignedBitVec n)) := by
    cases interval with
    | none => exact False.elim (show False from hx)
    | some bounds =>
        have hlower : x.bitvec.toNat ≤ source.toNat := by
          simpa [hsourceNat] using hzNat.1
        have hupper : source.toNat ≤ y.bitvec.toNat := by
          simpa [hsourceNat] using hzNat.2
        exact ⟨hx.1.trans hlower, hupper.trans hy.2⟩
  refine ⟨⟨source⟩, hsourceMem, ?_⟩
  apply UnsignedBitVec.ext
  apply BitVec.eq_of_toNat_eq
  change (source.setWidth m).toNat = z.bitvec.toNat
  rw [setWidth_toNat_eq hnm, hsourceNat]

theorem uintRange_zext_backwardComplete (n m : Nat)
    (hwidths : ValidExtensionWidths n m) :
    BackwardComplete (UIntRange.domain n) (UIntRange.domain m) (zext n m) := by
  change BackwardComplete (UIntRange.domain n) (UIntRange.domain m)
    (ConcreteOp.ofTotal (BitVec.setWidth m : BitVec n → BitVec m))
  exact UIntRange.backwardComplete_of_monotone _
    (orderedSetWidth_monotone (Nat.le_of_lt hwidths.2))

private theorem orderedSignExtend_monotone {n m : Nat}
    (hwidths : ValidExtensionWidths n m) :
    Monotone
      (UIntRange.orderedUnary (BitVec.signExtend m : BitVec n → BitVec m)) := by
  intro x y hxy
  change (x.bitvec.signExtend m).toNat ≤ (y.bitvec.signExtend m).toNat
  rw [BitVec.toNat_signExtend, BitVec.toNat_signExtend,
    setWidth_toNat_eq (Nat.le_of_lt hwidths.2),
    setWidth_toNat_eq (Nat.le_of_lt hwidths.2),
    BitVec.msb_eq_decide, BitVec.msb_eq_decide]
  by_cases hxSign : 2 ^ (n - 1) ≤ x.bitvec.toNat
  · have hySign : 2 ^ (n - 1) ≤ y.bitvec.toNat := hxSign.trans hxy
    simp [hxSign, hySign]
    omega
  · by_cases hySign : 2 ^ (n - 1) ≤ y.bitvec.toNat
    · simp [hxSign, hySign]
      omega
    · simp [hxSign, hySign]
      exact hxy

theorem uintRange_sext_backwardComplete (n m : Nat)
    (hwidths : ValidExtensionWidths n m) :
    BackwardComplete (UIntRange.domain n) (UIntRange.domain m) (sext n m) := by
  change BackwardComplete (UIntRange.domain n) (UIntRange.domain m)
    (ConcreteOp.ofTotal (BitVec.signExtend m : BitVec n → BitVec m))
  exact UIntRange.backwardComplete_of_monotone _
    (orderedSignExtend_monotone hwidths)

theorem uintRange_trunc_i8_i4_not_forwardComplete :
    ¬ ForwardComplete (UIntRange.domain 8) (UIntRange.domain 4) (trunc 8 4) := by
  apply unaryForwardIncompleteOfGap_i8 (trunc 8 4)
    15 16 0 1 15 16 15 (by bv_decide) (by bv_decide)
      (by bv_decide) (by bv_decide)
  · simp [trunc]
  · simp [trunc]
  · intro x hxLower hxUpper
    have hx : x = 15 ∨ x = 16 := by
      have : x.toNat = 15 ∨ x.toNat = 16 := by
        simp at hxLower hxUpper
        omega
      exact this.imp BitVec.eq_of_toNat_eq BitVec.eq_of_toNat_eq
    rcases hx with rfl | rfl <;> simp [trunc]

theorem uintRange_trunc_i8_i4_not_backwardComplete :
    ¬ BackwardComplete (UIntRange.domain 8) (UIntRange.domain 4) (trunc 8 4) := by
  apply unaryBackwardIncompleteOfEndpoint_i8 (trunc 8 4)
    0 16 15 15 0 0 (by bv_decide) (by bv_decide)
  · simp [trunc]
  · bv_decide
  · bv_decide
  · intro x z hx hz
    rcases hx with rfl | rfl <;> simp [trunc] at hz <;>
      rcases hz with ⟨_, rfl⟩ <;> decide

theorem uintRange_sext_i8_i16_not_forwardComplete :
    ¬ ForwardComplete (UIntRange.domain 8) (UIntRange.domain 16) (sext 8 16) := by
  apply unaryForwardIncompleteOfGap_i8 (sext 8 16)
    127 128 127 128 65408 127 128 (by bv_decide) (by bv_decide)
      (by bv_decide) (by bv_decide)
  · simp [sext]
  · simp [sext]
  · intro x hxLower hxUpper
    have hx : x = 127 ∨ x = 128 := by
      have : x.toNat = 127 ∨ x.toNat = 128 := by
        simp at hxLower hxUpper
        omega
      exact this.imp BitVec.eq_of_toNat_eq BitVec.eq_of_toNat_eq
    rcases hx with rfl | rfl <;> simp [sext]

theorem uintRange_zextBool_forwardComplete (n : Nat)
    (hwidths : ValidExtensionWidths 1 n) :
    ForwardComplete (UIntRange.domain 1) (UIntRange.domain n)
      (zextBool n) := by
  simpa [zextBool] using uintRange_zext_forwardComplete 1 n hwidths

theorem uintRange_zextBool_backwardComplete (n : Nat)
    (hwidths : ValidExtensionWidths 1 n) :
    BackwardComplete (UIntRange.domain 1) (UIntRange.domain n)
      (zextBool n) := by
  simpa [zextBool] using uintRange_zext_backwardComplete 1 n hwidths

theorem uintRange_sextBool_i1_i8_not_forwardComplete :
    ¬ ForwardComplete (UIntRange.domain 1) (UIntRange.domain 8)
      (sextBool 8) := by
  change ¬ ForwardComplete (UIntRange.domain 1) (UIntRange.domain 8)
    (ConcreteOp.ofTotal (BitVec.signExtend 8 : BitVec 1 → BitVec 8))
  rw [UIntRange.forwardComplete_ofTotal_iff_ordConnected]
  intro hcomplete
  let input : UIntRange 1 := UIntRange.ofBounds 0 1 (by decide)
  have hconnected := hcomplete input
  have hzero : (UnsignedBitVec.equiv 8 0) ∈
      UIntRange.orderedUnary (BitVec.signExtend 8) ''
        (input : Set (UnsignedBitVec 1)) := by
    refine ⟨UnsignedBitVec.equiv 1 0, ?_, ?_⟩
    · simp [input, UIntRange.ofBounds]
    · apply UnsignedBitVec.ext
      simp [UIntRange.orderedUnary]
  have hmax : (UnsignedBitVec.equiv 8 255) ∈
      UIntRange.orderedUnary (BitVec.signExtend 8) ''
        (input : Set (UnsignedBitVec 1)) := by
    refine ⟨UnsignedBitVec.equiv 1 1, ?_, ?_⟩
    · simp [input, UIntRange.ofBounds]
    · apply UnsignedBitVec.ext
      simp [UIntRange.orderedUnary]
  have hone := hconnected.out hzero hmax
    (show UnsignedBitVec.equiv 8 1 ∈
      Set.Icc (UnsignedBitVec.equiv 8 0)
        (UnsignedBitVec.equiv 8 255) by decide)
  rcases hone with ⟨x, _, hx⟩
  rcases BitVec.eq_zero_or_eq_one x.bitvec with hzero | hone
  · change UnsignedBitVec.equiv 8 (x.bitvec.signExtend 8) =
      UnsignedBitVec.equiv 8 1 at hx
    have hb := congrArg (fun v : UnsignedBitVec 8 ↦ v.bitvec) hx
    simp [hzero] at hb
  · change UnsignedBitVec.equiv 8 (x.bitvec.signExtend 8) =
      UnsignedBitVec.equiv 8 1 at hx
    have hb := congrArg (fun v : UnsignedBitVec 8 ↦ v.bitvec) hx
    simp [hone] at hb

theorem uintRange_sextBool_backwardComplete (n : Nat)
    (hwidths : ValidExtensionWidths 1 n) :
    BackwardComplete (UIntRange.domain 1) (UIntRange.domain n)
      (sextBool n) := by
  simpa [sextBool] using uintRange_sext_backwardComplete 1 n hwidths

theorem uintRange_truncToBool_forwardComplete (n : Nat)
    (_hwidths : ValidTruncWidths n 1) :
    ForwardComplete (UIntRange.domain n) (UIntRange.domain 1)
      (truncToBool n) := by
  change ForwardComplete (UIntRange.domain n) (UIntRange.domain 1)
    (ConcreteOp.ofTotal (BitVec.setWidth 1 : BitVec n → BitVec 1))
  exact UIntRange.unaryForwardComplete_i1Result _

theorem uintRange_truncToBool_i8_i1_not_backwardComplete :
    ¬ BackwardComplete (UIntRange.domain 8) (UIntRange.domain 1)
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
