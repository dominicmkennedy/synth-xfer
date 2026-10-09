import SynthXfer.IntervalWitnesses
import SynthXfer.LLVMOps

/-!
# UIntRange incompleteness witnesses

Convenience adapters from ordinary bitvectors to the order-generic interval
witness theorems. Counterexamples in this project are standardized on i8.
-/

namespace SynthXfer.UIntRange

/-- Choose one unsigned monotonicity direction for each binary operand. -/
def binaryVariances (left right : IntervalDomain.OrderVariance) :
    BinaryOperand → IntervalDomain.OrderVariance :=
  fun operand ↦ if operand = BinaryOperand.left then left else right

/-- The scalar order selected by a variance. -/
def orderedBy (variance : IntervalDomain.OrderVariance) (x y : Nat) : Prop :=
  match variance with
  | .increasing => x ≤ y
  | .decreasing => y ≤ x

/-- Binary convenience form of the canonical n-ary variance theorem. -/
theorem binaryBackwardComplete_of_monotoneWithVariances
    {n m : Nat} (left right : IntervalDomain.OrderVariance)
    (f : BitVec n → BitVec n → BitVec m)
    (hf : ∀ x₁ x₂ y₁ y₂,
      orderedBy left x₁.toNat x₂.toNat →
      orderedBy right y₁.toNat y₂.toNat →
      (f x₁ y₁).toNat ≤ (f x₂ y₂).toNat) :
    BinaryBackwardComplete (domain n) (domain n) (domain m)
      (BinaryConcreteOp.ofTotal f) := by
  rw [SynthXfer.binaryBackwardComplete_iff_nary]
  change NaryBackwardComplete (fun _ : BinaryOperand ↦ domain n) (domain m)
    (NaryConcreteOp.ofTotal fun inputs ↦
      f (inputs BinaryOperand.left) (inputs BinaryOperand.right))
  apply naryBackwardComplete_of_monotoneWithVariances
    (binaryVariances left right)
  intro x y hxy
  have hleft := hxy BinaryOperand.left
  have hright := hxy BinaryOperand.right
  cases left <;> cases right <;>
    simpa [orderedNary, IntervalDomain.VarianceLE, orderedBy, binaryVariances,
      BinaryOperand.left, BinaryOperand.right] using
      hf (x BinaryOperand.left).bitvec (y BinaryOperand.left).bitvec
        (x BinaryOperand.right).bitvec (y BinaryOperand.right).bitvec
        (by simpa [IntervalDomain.VarianceLE, orderedBy, binaryVariances,
          BinaryOperand.left, BinaryOperand.right] using hleft)
        (by simpa [IntervalDomain.VarianceLE, orderedBy, binaryVariances,
          BinaryOperand.left, BinaryOperand.right] using hright)

/-- Every total n-ary operation returning i1 is forward complete in
`UIntRange`, because the unsigned i1 order has no value strictly between its
two elements. -/
theorem naryForwardComplete_i1Result
    {I : Type*} {width : I → Nat}
    (f : ((k : I) → BitVec (width k)) → BitVec 1) :
    NaryForwardComplete (fun k ↦ domain (width k)) (domain 1)
      (NaryConcreteOp.ofTotal f) := by
  rw [naryForwardComplete_ofTotal_iff_ordConnected]
  intro intervals
  constructor
  rintro a ha b hb z hz
  have haLt := a.bitvec.isLt
  have hbLt := b.bitvec.isLt
  have hzLt := z.bitvec.isLt
  have hzEq : z = a ∨ z = b := by
    change a.bitvec.toNat ≤ z.bitvec.toNat ∧
      z.bitvec.toNat ≤ b.bitvec.toNat at hz
    have hn : z.bitvec.toNat = a.bitvec.toNat ∨
        z.bitvec.toNat = b.bitvec.toNat := by omega
    exact hn.imp
      (fun h ↦ UnsignedBitVec.ext (BitVec.eq_of_toNat_eq h))
      (fun h ↦ UnsignedBitVec.ext (BitVec.eq_of_toNat_eq h))
  rcases hzEq with rfl | rfl
  · exact ha
  · exact hb

/-- Unary convenience form of `naryForwardComplete_i1Result`. -/
theorem unaryForwardComplete_i1Result {n : Nat}
    (f : BitVec n → BitVec 1) :
    ForwardComplete (domain n) (domain 1) (ConcreteOp.ofTotal f) := by
  rw [forwardComplete_iff_nary]
  change NaryForwardComplete (fun _ : Fin 1 ↦ domain n) (domain 1)
    (NaryConcreteOp.ofTotal fun inputs ↦ f (inputs 0))
  exact naryForwardComplete_i1Result _

/-- Binary convenience form of `naryForwardComplete_i1Result`. -/
theorem binaryForwardComplete_i1Result {n : Nat}
    (f : BitVec n → BitVec n → BitVec 1) :
    BinaryForwardComplete (domain n) (domain n) (domain 1)
      (BinaryConcreteOp.ofTotal f) := by
  rw [SynthXfer.binaryForwardComplete_iff_nary]
  change NaryForwardComplete (fun _ : BinaryOperand ↦ domain n) (domain 1)
    (NaryConcreteOp.ofTotal fun inputs ↦
      f (inputs BinaryOperand.left) (inputs BinaryOperand.right))
  exact naryForwardComplete_i1Result _

theorem unaryForwardIncompleteOfGap_i8 {m : Nat}
    (f : ConcreteOp (BitVec 8) (BitVec m))
    (lower upper : BitVec 8) (below gap above : BitVec m)
    (belowInput aboveInput : BitVec 8)
    (hlowerUpper : lower.toNat ≤ upper.toNat)
    (hbetween : below.toNat ≤ gap.toNat ∧ gap.toNat ≤ above.toNat)
    (hbelowInput : lower.toNat ≤ belowInput.toNat ∧
      belowInput.toNat ≤ upper.toNat)
    (haboveInput : lower.toNat ≤ aboveInput.toNat ∧
      aboveInput.toNat ≤ upper.toNat)
    (hbelow : below ∈ f belowInput) (habove : above ∈ f aboveInput)
    (hgap : ∀ x, lower.toNat ≤ x.toNat → x.toNat ≤ upper.toNat →
      gap ∉ f x) :
    ¬ ForwardComplete (domain 8) (domain m) f := by
  change ¬ ForwardComplete
    ((IntervalDomain.domain : AbstractDomain (UnsignedBitVec 8) _) |>.comapEquiv
      (UnsignedBitVec.equiv 8))
    ((IntervalDomain.domain : AbstractDomain (UnsignedBitVec m) _) |>.comapEquiv
      (UnsignedBitVec.equiv m)) f
  rw [forwardComplete_transport_iff]
  let input : Interval (UnsignedBitVec 8) :=
    ofBounds lower upper hlowerUpper
  apply IntervalDomain.forwardIncomplete_of_gap
    (orderedRelational f) input ⟨below⟩ ⟨gap⟩ ⟨above⟩
  · exact ⟨⟨belowInput⟩, hbelowInput, by
      simpa [orderedRelational, ConcreteOp.transport] using hbelow⟩
  · exact ⟨⟨aboveInput⟩, haboveInput, by
      simpa [orderedRelational, ConcreteOp.transport] using habove⟩
  · exact hbetween
  · rintro ⟨⟨x⟩, hx, hr⟩
    apply hgap x hx.1 hx.2
    simpa [orderedRelational, ConcreteOp.transport] using hr

theorem unaryBackwardIncompleteOfEndpoint_i8 {m : Nat}
    (f : ConcreteOp (BitVec 8) (BitVec m))
    (lower upper inside : BitVec 8)
    (result endpointLower endpointUpper : BitVec m)
    (hlowerUpper : lower.toNat ≤ upper.toNat)
    (hinside : lower.toNat ≤ inside.toNat ∧ inside.toNat ≤ upper.toNat)
    (hresult : result ∈ f inside)
    (hendpointOrder : endpointLower.toNat ≤ endpointUpper.toNat)
    (houtside : result.toNat < endpointLower.toNat ∨
      endpointUpper.toNat < result.toNat)
    (hendpoints : ∀ x z, (x = lower ∨ x = upper) → z ∈ f x →
      endpointLower.toNat ≤ z.toNat ∧ z.toNat ≤ endpointUpper.toNat) :
    ¬ BackwardComplete (domain 8) (domain m) f := by
  change ¬ BackwardComplete
    ((IntervalDomain.domain : AbstractDomain (UnsignedBitVec 8) _) |>.comapEquiv
      (UnsignedBitVec.equiv 8))
    ((IntervalDomain.domain : AbstractDomain (UnsignedBitVec m) _) |>.comapEquiv
      (UnsignedBitVec.equiv m)) f
  rw [backwardComplete_transport_iff]
  apply IntervalDomain.backwardIncomplete_of_endpointWitness
    (orderedRelational f) ⟨lower⟩ ⟨upper⟩ ⟨inside⟩
      ⟨result⟩ ⟨endpointLower⟩ ⟨endpointUpper⟩
      hlowerUpper hinside
  · simpa [orderedRelational, ConcreteOp.transport] using hresult
  · exact hendpointOrder
  · exact houtside
  · rintro z (hz | hz)
    · exact hendpoints lower z.bitvec (Or.inl rfl)
        (by simpa [orderedRelational, ConcreteOp.transport] using hz)
    · exact hendpoints upper z.bitvec (Or.inr rfl)
        (by simpa [orderedRelational, ConcreteOp.transport] using hz)

private def binaryIntervals8
    (leftLower leftUpper rightLower rightUpper : BitVec 8)
    (hleft : leftLower.toNat ≤ leftUpper.toNat)
    (hright : rightLower.toNat ≤ rightUpper.toNat) :
    BinaryOperand → UIntRange 8 :=
  fun operand ↦ if operand = BinaryOperand.left then
    ofBounds leftLower leftUpper hleft
  else ofBounds rightLower rightUpper hright

theorem binaryForwardIncompleteOfGap_i8
    (f : BinaryConcreteOp (BitVec 8) (BitVec 8) (BitVec 8))
    (leftLower leftUpper rightLower rightUpper : BitVec 8)
    (below gap above : BitVec 8)
    (hleft : leftLower.toNat ≤ leftUpper.toNat)
    (hright : rightLower.toNat ≤ rightUpper.toNat)
    (hbetween : below.toNat ≤ gap.toNat ∧ gap.toNat ≤ above.toNat)
    (belowLeft belowRight aboveLeft aboveRight : BitVec 8)
    (hbelowInputs : leftLower.toNat ≤ belowLeft.toNat ∧
      belowLeft.toNat ≤ leftUpper.toNat ∧
      rightLower.toNat ≤ belowRight.toNat ∧
      belowRight.toNat ≤ rightUpper.toNat)
    (haboveInputs : leftLower.toNat ≤ aboveLeft.toNat ∧
      aboveLeft.toNat ≤ leftUpper.toNat ∧
      rightLower.toNat ≤ aboveRight.toNat ∧
      aboveRight.toNat ≤ rightUpper.toNat)
    (hbelow : below ∈ f belowLeft belowRight)
    (habove : above ∈ f aboveLeft aboveRight)
    (hgap : ∀ x y, leftLower.toNat ≤ x.toNat →
      x.toNat ≤ leftUpper.toNat → rightLower.toNat ≤ y.toNat →
      y.toNat ≤ rightUpper.toNat → gap ∉ f x y) :
    ¬ BinaryForwardComplete (domain 8) (domain 8) (domain 8) f := by
  rw [SynthXfer.binaryForwardComplete_iff_nary]
  rw [naryForwardComplete_iff_ordConnected]
  intro hcomplete
  let intervals := binaryIntervals8 leftLower leftUpper rightLower rightUpper
    hleft hright
  have produced (x y result : BitVec 8)
      (hinputs : leftLower.toNat ≤ x.toNat ∧ x.toNat ≤ leftUpper.toNat ∧
        rightLower.toNat ≤ y.toNat ∧ y.toNat ≤ rightUpper.toNat)
      (hresult : result ∈ f x y) :
      UnsignedBitVec.equiv 8 result ∈
        NaryConcreteOp.lift (orderedNaryRelational f.asNary)
          (fun k ↦ (intervals k : Set (UnsignedBitVec 8))) := by
    let inputs : BinaryOperand → UnsignedBitVec 8 := fun k ↦
      if k = BinaryOperand.left then ⟨x⟩ else ⟨y⟩
    refine ⟨inputs, ?_, ?_⟩
    · intro k
      rcases BinaryOperand.eq_left_or_right k with rfl | rfl <;>
        simp [inputs, intervals, binaryIntervals8, ofBounds,
          BinaryOperand.left, BinaryOperand.right, hinputs]
    · simpa [inputs, orderedNaryRelational, NaryConcreteOp.transport,
        BinaryConcreteOp.asNary, BinaryOperand.left, BinaryOperand.right]
        using hresult
  have hmissing := (hcomplete intervals).out
    (produced belowLeft belowRight below hbelowInputs hbelow)
    (produced aboveLeft aboveRight above haboveInputs habove) hbetween
  rcases hmissing with ⟨inputs, hinputs, hresult⟩
  have hx := hinputs BinaryOperand.left
  have hy := hinputs BinaryOperand.right
  have hx' : leftLower.toNat ≤ (inputs BinaryOperand.left).bitvec.toNat ∧
      (inputs BinaryOperand.left).bitvec.toNat ≤ leftUpper.toNat := by
    simpa [intervals, binaryIntervals8, ofBounds, BinaryOperand.left,
      BinaryOperand.right] using hx
  have hy' : rightLower.toNat ≤ (inputs BinaryOperand.right).bitvec.toNat ∧
      (inputs BinaryOperand.right).bitvec.toNat ≤ rightUpper.toNat := by
    simpa [intervals, binaryIntervals8, ofBounds, BinaryOperand.left,
      BinaryOperand.right] using hy
  apply hgap (inputs BinaryOperand.left).bitvec
    (inputs BinaryOperand.right).bitvec hx'.1 hx'.2 hy'.1 hy'.2
  simpa [orderedNaryRelational, NaryConcreteOp.transport,
    BinaryConcreteOp.asNary, BinaryOperand.left, BinaryOperand.right]
    using hresult

theorem binaryBackwardIncompleteOfCorner_i8 {m : Nat}
    (f : BinaryConcreteOp (BitVec 8) (BitVec 8) (BitVec m))
    (leftLower leftUpper rightLower rightUpper : BitVec 8)
    (insideLeft insideRight : BitVec 8)
    (result cornerLower cornerUpper : BitVec m)
    (hleft : leftLower.toNat ≤ leftUpper.toNat)
    (hright : rightLower.toNat ≤ rightUpper.toNat)
    (hinside : leftLower.toNat ≤ insideLeft.toNat ∧
      insideLeft.toNat ≤ leftUpper.toNat ∧
      rightLower.toNat ≤ insideRight.toNat ∧
      insideRight.toNat ≤ rightUpper.toNat)
    (hresult : result ∈ f insideLeft insideRight)
    (hcornerOrder : cornerLower.toNat ≤ cornerUpper.toNat)
    (hresultOutside : result.toNat < cornerLower.toNat ∨
      cornerUpper.toNat < result.toNat)
    (hcorners : ∀ x y z,
      (x = leftLower ∨ x = leftUpper) →
      (y = rightLower ∨ y = rightUpper) → z ∈ f x y →
      cornerLower.toNat ≤ z.toNat ∧ z.toNat ≤ cornerUpper.toNat) :
    ¬ BinaryBackwardComplete (domain 8) (domain 8) (domain m) f := by
  rw [SynthXfer.binaryBackwardComplete_iff_nary]
  rw [naryBackwardComplete_iff_boundedByCornerResults]
  intro hcomplete
  let lower : BinaryOperand → UnsignedBitVec 8 := fun k ↦
    if k = BinaryOperand.left then ⟨leftLower⟩ else ⟨rightLower⟩
  let upper : BinaryOperand → UnsignedBitVec 8 := fun k ↦
    if k = BinaryOperand.left then ⟨leftUpper⟩ else ⟨rightUpper⟩
  have hlowerUpper : ∀ k, lower k ≤ upper k := by
    intro k
    rcases BinaryOperand.eq_left_or_right k with rfl | rfl <;>
      simp [lower, upper, BinaryOperand.left, BinaryOperand.right, hleft,
        hright]
  have hinterior : UnsignedBitVec.equiv m result ∈
      NaryConcreteOp.lift (orderedNaryRelational f.asNary)
        (fun k ↦ Set.Icc (lower k) (upper k)) := by
    let inputs : BinaryOperand → UnsignedBitVec 8 := fun k ↦
      if k = BinaryOperand.left then ⟨insideLeft⟩ else ⟨insideRight⟩
    refine ⟨inputs, ?_, ?_⟩
    · intro k
      rcases BinaryOperand.eq_left_or_right k with rfl | rfl <;>
        simp [inputs, lower, upper, BinaryOperand.left, BinaryOperand.right,
          hinside]
    · simpa [inputs, orderedNaryRelational, NaryConcreteOp.transport,
        BinaryConcreteOp.asNary, BinaryOperand.left, BinaryOperand.right]
        using hresult
  have hinHull := hcomplete lower upper hlowerUpper hinterior
  let bounds : UIntRange m := ofBounds cornerLower cornerUpper hcornerOrder
  have hcornerSubset : NaryConcreteOp.lift
      (orderedNaryRelational f.asNary)
      (fun k ↦ ({lower k, upper k} : Set (UnsignedBitVec 8))) ⊆
      (bounds : Set (UnsignedBitVec m)) := by
    rintro z ⟨inputs, hinputs, hz⟩
    have hxOrdered := hinputs BinaryOperand.left
    have hyOrdered := hinputs BinaryOperand.right
    simp [lower, upper, BinaryOperand.left, BinaryOperand.right] at hxOrdered hyOrdered
    have hz' : z.bitvec ∈ f (inputs BinaryOperand.left).bitvec
        (inputs BinaryOperand.right).bitvec := by
      simpa [orderedNaryRelational, NaryConcreteOp.transport,
        BinaryConcreteOp.asNary, BinaryOperand.left, BinaryOperand.right]
        using hz
    exact hcorners _ _ _
      (hxOrdered.imp (congrArg UnsignedBitVec.bitvec)
        (congrArg UnsignedBitVec.bitvec))
      (hyOrdered.imp (congrArg UnsignedBitVec.bitvec)
        (congrArg UnsignedBitVec.bitvec)) hz'
  have hinBounds := IntervalDomain.hull_minimal hcornerSubset hinHull
  change cornerLower.toNat ≤ result.toNat ∧
    result.toNat ≤ cornerUpper.toNat at hinBounds
  rcases hresultOutside with hout | hout
  · exact (Nat.not_le_of_lt hout) hinBounds.1
  · exact (Nat.not_le_of_lt hout) hinBounds.2

end SynthXfer.UIntRange
