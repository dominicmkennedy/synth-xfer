import SynthXfer.UIntRange.Witnesses
import SynthXfer.NatBox

namespace SynthXfer.LLVM

theorem uintRange_addNuw_forwardComplete {n : Nat}
    (_hn : ValidIntegerWidth n) :
    BinaryForwardComplete (UIntRange.domain n) (UIntRange.domain n)
      (UIntRange.domain n)
      (addNuw : BinaryConcreteOp (BitVec n) (BitVec n) (BitVec n)) := by
  rw [SynthXfer.binaryForwardComplete_iff_nary]
  rw [UIntRange.naryForwardComplete_iff_ordConnected]
  intro intervals
  constructor
  rintro a ⟨inputsA, hinputsA, ha⟩ b ⟨inputsB, hinputsB, hb⟩ z hz
  let xa := inputsA BinaryOperand.left
  let ya := inputsA BinaryOperand.right
  let xb := inputsB BinaryOperand.left
  let yb := inputsB BinaryOperand.right
  have haData : addNuw? xa.bitvec ya.bitvec = some a.bitvec := by
    simpa [xa, ya, UIntRange.orderedNaryRelational,
      NaryConcreteOp.transport, BinaryConcreteOp.asNary,
      BinaryOperand.left, BinaryOperand.right, addNuw] using ha
  have hbData : addNuw? xb.bitvec yb.bitvec = some b.bitvec := by
    simpa [xb, yb, UIntRange.orderedNaryRelational,
      NaryConcreteOp.transport, BinaryConcreteOp.asNary,
      BinaryOperand.left, BinaryOperand.right, addNuw] using hb
  have haNoOverflow : xa.bitvec.uaddOverflow ya.bitvec = false := by
    simpa [addNuw?, poisonIf] using congrArg Option.isSome haData
  have hbNoOverflow : xb.bitvec.uaddOverflow yb.bitvec = false := by
    simpa [addNuw?, poisonIf] using congrArg Option.isSome hbData
  have haEq : xa.bitvec + ya.bitvec = a.bitvec := by
    simpa [addNuw?, poisonIf, haNoOverflow] using haData
  have hbEq : xb.bitvec + yb.bitvec = b.bitvec := by
    simpa [addNuw?, poisonIf, hbNoOverflow] using hbData
  have haNat : xa.bitvec.toNat + ya.bitvec.toNat = a.bitvec.toNat := by
    rw [← haEq, BitVec.toNat_add_of_not_uaddOverflow]
    simpa using haNoOverflow
  have hbNat : xb.bitvec.toNat + yb.bitvec.toNat = b.bitvec.toNat := by
    rw [← hbEq, BitVec.toNat_add_of_not_uaddOverflow]
    simpa using hbNoOverflow
  have hzNat : a.bitvec.toNat ≤ z.bitvec.toNat ∧
      z.bitvec.toNat ≤ b.bitvec.toNat := hz
  obtain ⟨xNat, yNat, hxLower, hxUpper, hyLower, hyUpper, hsum⟩ :=
    NatBox.exists_add (show xa.bitvec.toNat + ya.bitvec.toNat ≤
      z.bitvec.toNat by omega) (show z.bitvec.toNat ≤
      xb.bitvec.toNat + yb.bitvec.toNat by omega)
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
  · have hsumLt : xNat + yNat < 2 ^ n := by rw [hsum]; exact z.bitvec.isLt
    have hsumEq : x.bitvec + y.bitvec = z.bitvec := by
      apply BitVec.eq_of_toNat_eq
      rw [BitVec.toNat_add_of_lt]
      · simpa [hxNat, hyNat] using hsum
      · simpa [hxNat, hyNat] using hsumLt
    have hnoOverflow : x.bitvec.uaddOverflow y.bitvec = false := by
      simp [BitVec.uaddOverflow, hxNat, hyNat, hsumLt]
    change z ∈ (UnsignedBitVec.equiv n) '' addNuw x.bitvec y.bitvec
    refine ⟨x.bitvec + y.bitvec, ?_, ?_⟩
    · change addNuw? x.bitvec y.bitvec = some (x.bitvec + y.bitvec)
      simp [addNuw?, poisonIf, hnoOverflow]
    · exact UnsignedBitVec.ext hsumEq

theorem uintRange_subNuw_forwardComplete {n : Nat}
    (_hn : ValidIntegerWidth n) :
    BinaryForwardComplete (UIntRange.domain n) (UIntRange.domain n)
      (UIntRange.domain n)
      (subNuw : BinaryConcreteOp (BitVec n) (BitVec n) (BitVec n)) := by
  rw [SynthXfer.binaryForwardComplete_iff_nary]
  rw [UIntRange.naryForwardComplete_iff_ordConnected]
  intro intervals
  constructor
  rintro a ⟨inputsA, hinputsA, ha⟩ b ⟨inputsB, hinputsB, hb⟩ z hz
  let xa := inputsA BinaryOperand.left
  let ya := inputsA BinaryOperand.right
  let xb := inputsB BinaryOperand.left
  let yb := inputsB BinaryOperand.right
  have haData : subNuw? xa.bitvec ya.bitvec = some a.bitvec := by
    simpa [xa, ya, UIntRange.orderedNaryRelational,
      NaryConcreteOp.transport, BinaryConcreteOp.asNary,
      BinaryOperand.left, BinaryOperand.right, subNuw] using ha
  have hbData : subNuw? xb.bitvec yb.bitvec = some b.bitvec := by
    simpa [xb, yb, UIntRange.orderedNaryRelational,
      NaryConcreteOp.transport, BinaryConcreteOp.asNary,
      BinaryOperand.left, BinaryOperand.right, subNuw] using hb
  have haNoOverflow : xa.bitvec.usubOverflow ya.bitvec = false := by
    simpa [subNuw?, poisonIf] using congrArg Option.isSome haData
  have hbNoOverflow : xb.bitvec.usubOverflow yb.bitvec = false := by
    simpa [subNuw?, poisonIf] using congrArg Option.isSome hbData
  have haEq : xa.bitvec - ya.bitvec = a.bitvec := by
    simpa [subNuw?, poisonIf, haNoOverflow] using haData
  have hbEq : xb.bitvec - yb.bitvec = b.bitvec := by
    simpa [subNuw?, poisonIf, hbNoOverflow] using hbData
  have hyaLeXa : ya.bitvec.toNat ≤ xa.bitvec.toNat := by
    have h : ya.bitvec ≤ xa.bitvec := by
      simpa [BitVec.usubOverflow_eq] using haNoOverflow
    exact h
  have hybLeXb : yb.bitvec.toNat ≤ xb.bitvec.toNat := by
    have h : yb.bitvec ≤ xb.bitvec := by
      simpa [BitVec.usubOverflow_eq] using hbNoOverflow
    exact h
  have haNat : xa.bitvec.toNat - ya.bitvec.toNat = a.bitvec.toNat := by
    rw [← haEq, BitVec.toNat_sub_of_not_usubOverflow]
    simpa using haNoOverflow
  have hbNat : xb.bitvec.toNat - yb.bitvec.toNat = b.bitvec.toNat := by
    rw [← hbEq, BitVec.toNat_sub_of_not_usubOverflow]
    simpa using hbNoOverflow
  have hzNat : a.bitvec.toNat ≤ z.bitvec.toNat ∧
      z.bitvec.toNat ≤ b.bitvec.toNat := hz
  obtain ⟨xNat, yNat, hxLower, hxUpper, hyLower, hyUpper, hyLeX, hdiff⟩ :=
    NatBox.exists_sub (x₁ := xa.bitvec.toNat) (x₂ := xb.bitvec.toNat)
      (y₁ := ya.bitvec.toNat) (y₂ := yb.bitvec.toNat)
      (z := z.bitvec.toNat) hybLeXb
      (by omega) (by omega)
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
  · have hsubEq : x.bitvec - y.bitvec = z.bitvec := by
      apply BitVec.eq_of_toNat_eq
      rw [BitVec.toNat_sub_of_not_usubOverflow]
      · simpa [hxNat, hyNat] using hdiff
      · rw [BitVec.usubOverflow_eq]
        simp only [Bool.not_eq_true, decide_eq_false_iff_not]
        change ¬ x.bitvec.toNat < y.bitvec.toNat
        rw [hxNat, hyNat]
        omega
    have hnoOverflow : x.bitvec.usubOverflow y.bitvec = false := by
      rw [BitVec.usubOverflow_eq]
      simp only [decide_eq_false_iff_not]
      change ¬ x.bitvec.toNat < y.bitvec.toNat
      rw [hxNat, hyNat]
      omega
    change z ∈ (UnsignedBitVec.equiv n) '' subNuw x.bitvec y.bitvec
    refine ⟨x.bitvec - y.bitvec, ?_, ?_⟩
    · change subNuw? x.bitvec y.bitvec = some (x.bitvec - y.bitvec)
      simp [subNuw?, poisonIf, hnoOverflow]
    · exact UnsignedBitVec.ext hsubEq

end SynthXfer.LLVM
