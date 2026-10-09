import SynthXfer.UIntRange.Witnesses
import SynthXfer.NatBox
import SynthXfer.UIntRange.NoWrapArithmetic
import Std.Tactic.BVDecide

/-!
# Saturating arithmetic in UIntRange
-/

namespace SynthXfer.LLVM

open UIntRange

@[simp] theorem clampUnsigned_toNat {n value : Nat}
    (_hn : ValidIntegerWidth n) :
    (clampUnsigned n value).toNat = min value (unsignedMax n) := by
  have hmaxLt : unsignedMax n < 2 ^ n := by
    simp only [unsignedMax]
    exact Nat.sub_lt (Nat.two_pow_pos n) (by omega)
  rw [clampUnsigned, BitVec.toNat_ofNat,
    Nat.mod_eq_of_lt (lt_of_le_of_lt (min_le_right _ _) hmaxLt)]

@[simp] theorem usubSatFn_toNat {n : Nat} (x y : BitVec n) :
    (usubSatFn x y).toNat = x.toNat - y.toNat := by
  have hlt : x.toNat - y.toNat < 2 ^ n :=
    lt_of_le_of_lt (Nat.sub_le _ _) x.isLt
  rw [usubSatFn, BitVec.toNat_ofNat, Nat.mod_eq_of_lt hlt]

theorem uintRange_uaddSat_backwardComplete {n : Nat}
    (hn : ValidIntegerWidth n) :
    BinaryBackwardComplete (UIntRange.domain n) (UIntRange.domain n)
      (UIntRange.domain n)
      (uaddSat : BinaryConcreteOp (BitVec n) (BitVec n) (BitVec n)) := by
  apply UIntRange.binaryBackwardComplete_of_monotoneWithVariances
    .increasing .increasing uaddSatFn
  intro x₁ x₂ y₁ y₂ hx hy
  rw [uaddSatFn, uaddSatFn, clampUnsigned_toNat hn,
    clampUnsigned_toNat hn]
  exact min_le_min (Nat.add_le_add hx hy) le_rfl

theorem uintRange_usubSat_backwardComplete {n : Nat}
    (_hn : ValidIntegerWidth n) :
    BinaryBackwardComplete (UIntRange.domain n) (UIntRange.domain n)
      (UIntRange.domain n)
      (usubSat : BinaryConcreteOp (BitVec n) (BitVec n) (BitVec n)) := by
  apply UIntRange.binaryBackwardComplete_of_monotoneWithVariances
    .increasing .decreasing usubSatFn
  intro x₁ x₂ y₁ y₂ hx hy
  rw [usubSatFn_toNat, usubSatFn_toNat]
  exact (Nat.sub_le_sub_right hx y₁.toNat).trans
    (Nat.sub_le_sub_left hy x₂.toNat)

theorem uintRange_umulSat_backwardComplete {n : Nat}
    (hn : ValidIntegerWidth n) :
    BinaryBackwardComplete (UIntRange.domain n) (UIntRange.domain n)
      (UIntRange.domain n)
      (umulSat : BinaryConcreteOp (BitVec n) (BitVec n) (BitVec n)) := by
  apply UIntRange.binaryBackwardComplete_of_monotoneWithVariances
    .increasing .increasing umulSatFn
  intro x₁ x₂ y₁ y₂ hx hy
  rw [umulSatFn, umulSatFn, clampUnsigned_toNat hn,
    clampUnsigned_toNat hn]
  exact min_le_min (Nat.mul_le_mul hx hy) le_rfl

theorem uintRange_uaddSat_forwardComplete {n : Nat}
    (hn : ValidIntegerWidth n) :
    BinaryForwardComplete (UIntRange.domain n) (UIntRange.domain n)
      (UIntRange.domain n)
      (uaddSat : BinaryConcreteOp (BitVec n) (BitVec n) (BitVec n)) := by
  rw [SynthXfer.binaryForwardComplete_iff_nary]
  rw [UIntRange.naryForwardComplete_iff_ordConnected]
  intro intervals
  constructor
  rintro a ⟨inputsA, hinputsA, ha⟩ b ⟨inputsB, hinputsB, hb⟩ z hz
  let xa := inputsA BinaryOperand.left
  let ya := inputsA BinaryOperand.right
  let xb := inputsB BinaryOperand.left
  let yb := inputsB BinaryOperand.right
  have haEq : a.bitvec = uaddSatFn xa.bitvec ya.bitvec := by
    simpa [xa, ya, UIntRange.orderedNaryRelational,
      NaryConcreteOp.transport, BinaryConcreteOp.asNary,
      BinaryOperand.left, BinaryOperand.right, uaddSat] using ha
  have hbEq : b.bitvec = uaddSatFn xb.bitvec yb.bitvec := by
    simpa [xb, yb, UIntRange.orderedNaryRelational,
      NaryConcreteOp.transport, BinaryConcreteOp.asNary,
      BinaryOperand.left, BinaryOperand.right, uaddSat] using hb
  have haNat : a.bitvec.toNat = min (xa.bitvec.toNat + ya.bitvec.toNat)
      (unsignedMax n) := by
    rw [haEq, uaddSatFn, clampUnsigned_toNat hn]
  have hbNat : b.bitvec.toNat = min (xb.bitvec.toNat + yb.bitvec.toNat)
      (unsignedMax n) := by
    rw [hbEq, uaddSatFn, clampUnsigned_toNat hn]
  by_cases hzMax : z.bitvec.toNat = unsignedMax n
  · have hbMax : b.bitvec.toNat = unsignedMax n := by
      have hbBound : b.bitvec.toNat ≤ unsignedMax n := by
        rw [hbNat]
        exact min_le_right _ _
      exact le_antisymm hbBound (hzMax ▸ hz.2)
    have hzb : z = b := UnsignedBitVec.ext (BitVec.eq_of_toNat_eq (by omega))
    subst z
    exact ⟨inputsB, hinputsB, hb⟩
  · have hzLtMax : z.bitvec.toNat < unsignedMax n := by
      have hzLe : z.bitvec.toNat ≤ unsignedMax n := by
        simp only [unsignedMax]
        omega
      omega
    have hrawLower : xa.bitvec.toNat + ya.bitvec.toNat ≤
        z.bitvec.toNat := by
      have hzLower : a.bitvec.toNat ≤ z.bitvec.toNat := hz.1
      rw [haNat] at hzLower
      omega
    have hrawUpper : z.bitvec.toNat ≤
        xb.bitvec.toNat + yb.bitvec.toNat := by
      have hzUpper : z.bitvec.toNat ≤ b.bitvec.toNat := hz.2
      apply hzUpper.trans
      rw [hbNat]
      exact min_le_left _ _
    obtain ⟨xNat, yNat, hxLower, hxUpper, hyLower, hyUpper, hsum⟩ :=
      NatBox.exists_add hrawLower hrawUpper
    have hxLt : xNat < 2 ^ n := lt_of_le_of_lt hxUpper
      (max_lt xa.bitvec.isLt xb.bitvec.isLt)
    have hyLt : yNat < 2 ^ n := lt_of_le_of_lt hyUpper
      (max_lt ya.bitvec.isLt yb.bitvec.isLt)
    let x : UnsignedBitVec n := ⟨BitVec.ofNat n xNat⟩
    let y : UnsignedBitVec n := ⟨BitVec.ofNat n yNat⟩
    have hxNat : x.bitvec.toNat = xNat := by
      simp [x, BitVec.toNat_ofNat, Nat.mod_eq_of_lt hxLt]
    have hyNat : y.bitvec.toNat = yNat := by
      simp [y, BitVec.toNat_ofNat, Nat.mod_eq_of_lt hyLt]
    have hxMem : x ∈ (intervals BinaryOperand.left : Set (UnsignedBitVec n)) := by
      apply IntervalDomain.mem_interval_of_between
        (hinputsA BinaryOperand.left) (hinputsB BinaryOperand.left)
      simpa [xa, xb, hxNat] using And.intro hxLower hxUpper
    have hyMem : y ∈ (intervals BinaryOperand.right : Set (UnsignedBitVec n)) := by
      apply IntervalDomain.mem_interval_of_between
        (hinputsA BinaryOperand.right) (hinputsB BinaryOperand.right)
      simpa [ya, yb, hyNat] using And.intro hyLower hyUpper
    let inputs : BinaryOperand → UnsignedBitVec n := fun k ↦
      if k = BinaryOperand.left then x else y
    refine ⟨inputs, ?_, ?_⟩
    · intro k
      rcases BinaryOperand.eq_left_or_right k with rfl | rfl <;>
        simp [inputs, BinaryOperand.left, BinaryOperand.right, hxMem, hyMem]
    · have hout : uaddSatFn x.bitvec y.bitvec = z.bitvec := by
        apply BitVec.eq_of_toNat_eq
        rw [uaddSatFn, clampUnsigned_toNat hn, hxNat, hyNat, hsum,
          min_eq_left hzLtMax.le]
      simp [inputs, UIntRange.orderedNaryRelational,
        NaryConcreteOp.transport, BinaryConcreteOp.asNary,
        BinaryOperand.left, BinaryOperand.right, uaddSat, hout]

theorem uintRange_usubSat_forwardComplete {n : Nat}
    (_hn : ValidIntegerWidth n) :
    BinaryForwardComplete (UIntRange.domain n) (UIntRange.domain n)
      (UIntRange.domain n)
      (usubSat : BinaryConcreteOp (BitVec n) (BitVec n) (BitVec n)) := by
  rw [SynthXfer.binaryForwardComplete_iff_nary]
  rw [UIntRange.naryForwardComplete_iff_ordConnected]
  intro intervals
  constructor
  rintro a ⟨inputsA, hinputsA, ha⟩ b ⟨inputsB, hinputsB, hb⟩ z hz
  let xa := inputsA BinaryOperand.left
  let ya := inputsA BinaryOperand.right
  let xb := inputsB BinaryOperand.left
  let yb := inputsB BinaryOperand.right
  have haEq : a.bitvec = usubSatFn xa.bitvec ya.bitvec := by
    simpa [xa, ya, UIntRange.orderedNaryRelational,
      NaryConcreteOp.transport, BinaryConcreteOp.asNary,
      BinaryOperand.left, BinaryOperand.right, usubSat] using ha
  have hbEq : b.bitvec = usubSatFn xb.bitvec yb.bitvec := by
    simpa [xb, yb, UIntRange.orderedNaryRelational,
      NaryConcreteOp.transport, BinaryConcreteOp.asNary,
      BinaryOperand.left, BinaryOperand.right, usubSat] using hb
  have haNat : a.bitvec.toNat = xa.bitvec.toNat - ya.bitvec.toNat := by
    rw [haEq, usubSatFn_toNat]
  have hbNat : b.bitvec.toNat = xb.bitvec.toNat - yb.bitvec.toNat := by
    rw [hbEq, usubSatFn_toNat]
  by_cases hzZero : z.bitvec.toNat = 0
  · have haZero : a.bitvec.toNat = 0 := by
      exact Nat.eq_zero_of_le_zero (hzZero ▸ hz.1)
    have hza : z = a := UnsignedBitVec.ext (BitVec.eq_of_toNat_eq (by omega))
    subst z
    exact ⟨inputsA, hinputsA, ha⟩
  · have hzPos : 0 < z.bitvec.toNat := Nat.pos_of_ne_zero hzZero
    have hzLower : xa.bitvec.toNat - ya.bitvec.toNat ≤ z.bitvec.toNat := by
      rw [← haNat]
      exact hz.1
    have hzUpper : z.bitvec.toNat ≤ xb.bitvec.toNat - yb.bitvec.toNat := by
      rw [← hbNat]
      exact hz.2
    have hybLeXb : yb.bitvec.toNat ≤ xb.bitvec.toNat := by omega
    obtain ⟨xNat, yNat, hxLower, hxUpper, hyLower, hyUpper, hyLeX, hdiff⟩ :=
      NatBox.exists_sub hybLeXb hzLower hzUpper
    have hxLt : xNat < 2 ^ n := lt_of_le_of_lt hxUpper
      (max_lt xa.bitvec.isLt xb.bitvec.isLt)
    have hyLt : yNat < 2 ^ n := lt_of_le_of_lt hyUpper
      (max_lt ya.bitvec.isLt yb.bitvec.isLt)
    let x : UnsignedBitVec n := ⟨BitVec.ofNat n xNat⟩
    let y : UnsignedBitVec n := ⟨BitVec.ofNat n yNat⟩
    have hxNat : x.bitvec.toNat = xNat := by
      simp [x, BitVec.toNat_ofNat, Nat.mod_eq_of_lt hxLt]
    have hyNat : y.bitvec.toNat = yNat := by
      simp [y, BitVec.toNat_ofNat, Nat.mod_eq_of_lt hyLt]
    have hxMem : x ∈ (intervals BinaryOperand.left : Set (UnsignedBitVec n)) := by
      apply IntervalDomain.mem_interval_of_between
        (hinputsA BinaryOperand.left) (hinputsB BinaryOperand.left)
      simpa [xa, xb, hxNat] using And.intro hxLower hxUpper
    have hyMem : y ∈ (intervals BinaryOperand.right : Set (UnsignedBitVec n)) := by
      apply IntervalDomain.mem_interval_of_between
        (hinputsA BinaryOperand.right) (hinputsB BinaryOperand.right)
      simpa [ya, yb, hyNat] using And.intro hyLower hyUpper
    let inputs : BinaryOperand → UnsignedBitVec n := fun k ↦
      if k = BinaryOperand.left then x else y
    refine ⟨inputs, ?_, ?_⟩
    · intro k
      rcases BinaryOperand.eq_left_or_right k with rfl | rfl <;>
        simp [inputs, BinaryOperand.left, BinaryOperand.right, hxMem, hyMem]
    · have hout : usubSatFn x.bitvec y.bitvec = z.bitvec := by
        apply BitVec.eq_of_toNat_eq
        rw [usubSatFn_toNat, hxNat, hyNat, hdiff]
      simp [inputs, UIntRange.orderedNaryRelational,
        NaryConcreteOp.transport, BinaryConcreteOp.asNary,
        BinaryOperand.left, BinaryOperand.right, usubSat, hout]

theorem uintRange_umulSat_i8_not_forwardComplete :
    ¬ BinaryForwardComplete (UIntRange.domain 8) (UIntRange.domain 8)
      (UIntRange.domain 8)
      (umulSat : BinaryConcreteOp (BitVec 8) (BitVec 8) (BitVec 8)) := by
  apply binaryForwardIncompleteOfGap_i8 umulSat
    0 1 2 2 0 1 2 (by bv_decide) (by bv_decide) (by bv_decide)
    0 2 1 2 (by bv_decide) (by bv_decide)
  · simp [umulSat, umulSatFn, clampUnsigned, unsignedMax]
  · simp [umulSat, umulSatFn, clampUnsigned, unsignedMax]
  · intro x y hxLower hxUpper hyLower hyUpper
    have h0 : (0 : BitVec 8).toNat = 0 := by bv_decide
    have h1 : (1 : BitVec 8).toNat = 1 := by bv_decide
    have h2 : (2 : BitVec 8).toNat = 2 := by bv_decide
    have hx : x = 0 ∨ x = 1 := by
      have : x.toNat = 0 ∨ x.toNat = 1 := by
        rw [h0] at hxLower
        rw [h1] at hxUpper
        omega
      exact this.imp BitVec.eq_of_toNat_eq BitVec.eq_of_toNat_eq
    have hy : y = 2 := BitVec.eq_of_toNat_eq (by
      rw [h2] at hyLower hyUpper
      omega)
    rcases hx with rfl | rfl <;>
      simp [hy, umulSat, umulSatFn, clampUnsigned, unsignedMax]

theorem uintRange_saddSat_i8_not_forwardComplete :
    ¬ BinaryForwardComplete (UIntRange.domain 8) (UIntRange.domain 8)
      (UIntRange.domain 8)
      (saddSat : BinaryConcreteOp (BitVec 8) (BitVec 8) (BitVec 8)) := by
  apply binaryForwardIncompleteOfGap_i8 saddSat
    0 1 255 255 0 1 255 (by bv_decide) (by bv_decide) (by bv_decide)
    1 255 0 255 (by bv_decide) (by bv_decide)
  · simp [saddSat, saddSatFn, clampSigned, signedMin, signedMax]
  · simp [saddSat, saddSatFn, clampSigned, signedMin, signedMax]
  · intro x y hxLower hxUpper hyLower hyUpper
    have h0 : (0 : BitVec 8).toNat = 0 := by bv_decide
    have h1 : (1 : BitVec 8).toNat = 1 := by bv_decide
    have h255 : (255 : BitVec 8).toNat = 255 := by bv_decide
    have hx : x = 0 ∨ x = 1 := by
      have : x.toNat = 0 ∨ x.toNat = 1 := by
        rw [h0] at hxLower
        rw [h1] at hxUpper
        omega
      exact this.imp BitVec.eq_of_toNat_eq BitVec.eq_of_toNat_eq
    have hy : y = 255 := BitVec.eq_of_toNat_eq (by
      rw [h255] at hyLower hyUpper
      omega)
    rcases hx with rfl | rfl <;>
      simp [hy, saddSat, saddSatFn, clampSigned, signedMin, signedMax]

theorem uintRange_saddSat_i8_not_backwardComplete :
    ¬ BinaryBackwardComplete (UIntRange.domain 8) (UIntRange.domain 8)
      (UIntRange.domain 8)
      (saddSat : BinaryConcreteOp (BitVec 8) (BitVec 8) (BitVec 8)) := by
  apply binaryBackwardIncompleteOfCorner_i8 saddSat
    0 2 252 254 1 254 255 0 254
      (by bv_decide) (by bv_decide) (by bv_decide)
  · simp [saddSat, saddSatFn, clampSigned, signedMin, signedMax]
  · bv_decide
  · bv_decide
  · intro x y z hx hy hz
    rcases hx with rfl | rfl <;> rcases hy with rfl | rfl <;>
      simp [saddSat, saddSatFn, clampSigned, signedMin, signedMax] at hz <;>
      rcases hz with ⟨_, rfl⟩ <;> decide

theorem uintRange_ssubSat_i8_not_forwardComplete :
    ¬ BinaryForwardComplete (UIntRange.domain 8) (UIntRange.domain 8)
      (UIntRange.domain 8)
      (ssubSat : BinaryConcreteOp (BitVec 8) (BitVec 8) (BitVec 8)) := by
  apply binaryForwardIncompleteOfGap_i8 ssubSat
    0 0 0 1 0 1 255 (by bv_decide) (by bv_decide) (by bv_decide)
    0 0 0 1 (by bv_decide) (by bv_decide)
  · simp [ssubSat, ssubSatFn, clampSigned, signedMin, signedMax]
  · simp [ssubSat, ssubSatFn, clampSigned, signedMin, signedMax]
  · intro x y hxLower hxUpper hyLower hyUpper
    have h0 : (0 : BitVec 8).toNat = 0 := by bv_decide
    have h1 : (1 : BitVec 8).toNat = 1 := by bv_decide
    have hx : x = 0 := BitVec.eq_of_toNat_eq (by
      rw [h0] at hxLower hxUpper
      omega)
    have hy : y = 0 ∨ y = 1 := by
      have : y.toNat = 0 ∨ y.toNat = 1 := by
        rw [h0] at hyLower
        rw [h1] at hyUpper
        omega
      exact this.imp BitVec.eq_of_toNat_eq BitVec.eq_of_toNat_eq
    rcases hy with rfl | rfl <;>
      simp [hx, ssubSat, ssubSatFn, clampSigned, signedMin, signedMax]

theorem uintRange_ssubSat_i8_not_backwardComplete :
    ¬ BinaryBackwardComplete (UIntRange.domain 8) (UIntRange.domain 8)
      (UIntRange.domain 8)
      (ssubSat : BinaryConcreteOp (BitVec 8) (BitVec 8) (BitVec 8)) := by
  apply binaryBackwardIncompleteOfCorner_i8 ssubSat
    0 0 0 2 0 1 255 0 254
      (by bv_decide) (by bv_decide) (by bv_decide)
  · simp [ssubSat, ssubSatFn, clampSigned, signedMin, signedMax]
  · bv_decide
  · bv_decide
  · intro x y z hx hy hz
    rcases hx with rfl | rfl <;> rcases hy with rfl | rfl <;>
      simp [ssubSat, ssubSatFn, clampSigned, signedMin, signedMax] at hz <;>
      rcases hz with ⟨_, rfl⟩ <;> decide

theorem uintRange_smulSat_i8_not_forwardComplete :
    ¬ BinaryForwardComplete (UIntRange.domain 8) (UIntRange.domain 8)
      (UIntRange.domain 8)
      (smulSat : BinaryConcreteOp (BitVec 8) (BitVec 8) (BitVec 8)) := by
  apply binaryForwardIncompleteOfGap_i8 smulSat
    0 1 2 2 0 1 2 (by bv_decide) (by bv_decide) (by bv_decide)
    0 2 1 2 (by bv_decide) (by bv_decide)
  · simp [smulSat, smulSatFn, clampSigned, signedMin, signedMax]
  · simp [smulSat, smulSatFn, clampSigned, signedMin, signedMax]
  · intro x y hxLower hxUpper hyLower hyUpper
    have h0 : (0 : BitVec 8).toNat = 0 := by bv_decide
    have h1 : (1 : BitVec 8).toNat = 1 := by bv_decide
    have h2 : (2 : BitVec 8).toNat = 2 := by bv_decide
    have hx : x = 0 ∨ x = 1 := by
      have : x.toNat = 0 ∨ x.toNat = 1 := by
        rw [h0] at hxLower
        rw [h1] at hxUpper
        omega
      exact this.imp BitVec.eq_of_toNat_eq BitVec.eq_of_toNat_eq
    have hy : y = 2 := BitVec.eq_of_toNat_eq (by
      rw [h2] at hyLower hyUpper
      omega)
    rcases hx with rfl | rfl <;>
      simp [hy, smulSat, smulSatFn, clampSigned, signedMin, signedMax]

theorem uintRange_smulSat_i8_not_backwardComplete :
    ¬ BinaryBackwardComplete (UIntRange.domain 8) (UIntRange.domain 8)
      (UIntRange.domain 8)
      (smulSat : BinaryConcreteOp (BitVec 8) (BitVec 8) (BitVec 8)) := by
  apply binaryBackwardIncompleteOfCorner_i8 smulSat
    0 2 127 129 1 129 129 0 128
      (by bv_decide) (by bv_decide) (by bv_decide)
  · simp [smulSat, smulSatFn, clampSigned, signedMin, signedMax]
  · bv_decide
  · bv_decide
  · intro x y z hx hy hz
    rcases hx with rfl | rfl <;> rcases hy with rfl | rfl <;>
      simp [smulSat, smulSatFn, clampSigned, signedMin, signedMax] at hz <;>
      rcases hz with ⟨_, rfl⟩ <;> decide

end SynthXfer.LLVM
