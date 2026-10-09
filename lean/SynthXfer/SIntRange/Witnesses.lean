import SynthXfer.IntervalWitnesses
import SynthXfer.LLVMOps

/-!
# SIntRange proof helpers

Adapters from ordinary bitvectors to signed interval theory. Counterexamples
are standardized on i8.
-/

namespace SynthXfer.SIntRange

/-- Choose one signed monotonicity direction for each binary operand. -/
def binaryVariances (left right : IntervalDomain.OrderVariance) :
    BinaryOperand → IntervalDomain.OrderVariance :=
  fun operand ↦ if operand = BinaryOperand.left then left else right

/-- The scalar integer order selected by a variance. -/
def orderedBy (variance : IntervalDomain.OrderVariance) (x y : Int) : Prop :=
  match variance with
  | .increasing => x ≤ y
  | .decreasing => y ≤ x

/-- Binary convenience form of the canonical n-ary signed variance theorem. -/
theorem binaryBackwardComplete_of_monotoneWithVariances
    {n m : Nat} (left right : IntervalDomain.OrderVariance)
    (f : BitVec n → BitVec n → BitVec m)
    (hf : ∀ x₁ x₂ y₁ y₂,
      orderedBy left x₁.toInt x₂.toInt →
      orderedBy right y₁.toInt y₂.toInt →
      (f x₁ y₁).toInt ≤ (f x₂ y₂).toInt) :
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

private theorem signedBitVec1_eq_zero_or_one (x : SignedBitVec 1) :
    x = ⟨0⟩ ∨ x = ⟨1⟩ := by
  have hxLt := x.bitvec.isLt
  have hx : x.bitvec.toNat = 0 ∨ x.bitvec.toNat = 1 := by omega
  exact hx.imp
    (fun h ↦ SignedBitVec.ext (BitVec.eq_of_toNat_eq h))
    (fun h ↦ SignedBitVec.ext (BitVec.eq_of_toNat_eq h))

/-- Every total n-ary operation returning i1 is forward complete in
`SIntRange`, because signed i1 still has only two elements. -/
theorem naryForwardComplete_i1Result
    {I : Type*} {width : I → Nat}
    (f : ((k : I) → BitVec (width k)) → BitVec 1) :
    NaryForwardComplete (fun k ↦ domain (width k)) (domain 1)
      (NaryConcreteOp.ofTotal f) := by
  rw [naryForwardComplete_ofTotal_iff_ordConnected]
  intro intervals
  constructor
  rintro a ha b hb z hz
  rcases signedBitVec1_eq_zero_or_one a with rfl | rfl <;>
    rcases signedBitVec1_eq_zero_or_one b with rfl | rfl <;>
    rcases signedBitVec1_eq_zero_or_one z with rfl | rfl
  all_goals first | exact ha | exact hb |
    simp at hz

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

/-- A missing output between two produced outputs disproves unary forward
completeness in the signed interval domain at i8. -/
theorem unaryForwardIncompleteOfGap_i8 {m : Nat}
    (f : ConcreteOp (BitVec 8) (BitVec m))
    (lower upper : BitVec 8) (below gap above : BitVec m)
    (belowInput aboveInput : BitVec 8)
    (hlowerUpper : lower.toInt ≤ upper.toInt)
    (hbetween : below.toInt ≤ gap.toInt ∧ gap.toInt ≤ above.toInt)
    (hbelowInput : lower.toInt ≤ belowInput.toInt ∧
      belowInput.toInt ≤ upper.toInt)
    (haboveInput : lower.toInt ≤ aboveInput.toInt ∧
      aboveInput.toInt ≤ upper.toInt)
    (hbelow : below ∈ f belowInput) (habove : above ∈ f aboveInput)
    (hgap : ∀ x, lower.toInt ≤ x.toInt → x.toInt ≤ upper.toInt →
      gap ∉ f x) :
    ¬ ForwardComplete (domain 8) (domain m) f := by
  change ¬ ForwardComplete
    ((IntervalDomain.domain : AbstractDomain (SignedBitVec 8) _) |>.comapEquiv
      (SignedBitVec.equiv 8))
    ((IntervalDomain.domain : AbstractDomain (SignedBitVec m) _) |>.comapEquiv
      (SignedBitVec.equiv m)) f
  rw [forwardComplete_transport_iff]
  let input : Interval (SignedBitVec 8) :=
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

/-- An interior output outside the hull of the two endpoint outputs disproves
unary backward completeness in the signed interval domain at i8. -/
theorem unaryBackwardIncompleteOfEndpoint_i8 {m : Nat}
    (f : ConcreteOp (BitVec 8) (BitVec m))
    (lower upper inside : BitVec 8)
    (result endpointLower endpointUpper : BitVec m)
    (hlowerUpper : lower.toInt ≤ upper.toInt)
    (hinside : lower.toInt ≤ inside.toInt ∧ inside.toInt ≤ upper.toInt)
    (hresult : result ∈ f inside)
    (hendpointOrder : endpointLower.toInt ≤ endpointUpper.toInt)
    (houtside : result.toInt < endpointLower.toInt ∨
      endpointUpper.toInt < result.toInt)
    (hendpoints : ∀ x z, (x = lower ∨ x = upper) → z ∈ f x →
      endpointLower.toInt ≤ z.toInt ∧ z.toInt ≤ endpointUpper.toInt) :
    ¬ BackwardComplete (domain 8) (domain m) f := by
  change ¬ BackwardComplete
    ((IntervalDomain.domain : AbstractDomain (SignedBitVec 8) _) |>.comapEquiv
      (SignedBitVec.equiv 8))
    ((IntervalDomain.domain : AbstractDomain (SignedBitVec m) _) |>.comapEquiv
      (SignedBitVec.equiv m)) f
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
    (hleft : leftLower.toInt ≤ leftUpper.toInt)
    (hright : rightLower.toInt ≤ rightUpper.toInt) :
    BinaryOperand → SIntRange 8 :=
  fun operand ↦ if operand = BinaryOperand.left then
    ofBounds leftLower leftUpper hleft
  else ofBounds rightLower rightUpper hright

/-- A missing result between two produced results disproves binary forward
completeness in the signed interval domain at i8. -/
theorem binaryForwardIncompleteOfGap_i8
    (f : BinaryConcreteOp (BitVec 8) (BitVec 8) (BitVec 8))
    (leftLower leftUpper rightLower rightUpper : BitVec 8)
    (below gap above : BitVec 8)
    (hleft : leftLower.toInt ≤ leftUpper.toInt)
    (hright : rightLower.toInt ≤ rightUpper.toInt)
    (hbetween : below.toInt ≤ gap.toInt ∧ gap.toInt ≤ above.toInt)
    (belowLeft belowRight aboveLeft aboveRight : BitVec 8)
    (hbelowInputs : leftLower.toInt ≤ belowLeft.toInt ∧
      belowLeft.toInt ≤ leftUpper.toInt ∧
      rightLower.toInt ≤ belowRight.toInt ∧
      belowRight.toInt ≤ rightUpper.toInt)
    (haboveInputs : leftLower.toInt ≤ aboveLeft.toInt ∧
      aboveLeft.toInt ≤ leftUpper.toInt ∧
      rightLower.toInt ≤ aboveRight.toInt ∧
      aboveRight.toInt ≤ rightUpper.toInt)
    (hbelow : below ∈ f belowLeft belowRight)
    (habove : above ∈ f aboveLeft aboveRight)
    (hgap : ∀ x y, leftLower.toInt ≤ x.toInt →
      x.toInt ≤ leftUpper.toInt → rightLower.toInt ≤ y.toInt →
      y.toInt ≤ rightUpper.toInt → gap ∉ f x y) :
    ¬ BinaryForwardComplete (domain 8) (domain 8) (domain 8) f := by
  rw [SynthXfer.binaryForwardComplete_iff_nary]
  rw [naryForwardComplete_iff_ordConnected]
  intro hcomplete
  let intervals := binaryIntervals8 leftLower leftUpper rightLower rightUpper
    hleft hright
  have produced (x y result : BitVec 8)
      (hinputs : leftLower.toInt ≤ x.toInt ∧ x.toInt ≤ leftUpper.toInt ∧
        rightLower.toInt ≤ y.toInt ∧ y.toInt ≤ rightUpper.toInt)
      (hresult : result ∈ f x y) :
      SignedBitVec.equiv 8 result ∈
        NaryConcreteOp.lift (orderedNaryRelational f.asNary)
          (fun k ↦ (intervals k : Set (SignedBitVec 8))) := by
    let inputs : BinaryOperand → SignedBitVec 8 := fun k ↦
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
  have hx' : leftLower.toInt ≤ (inputs BinaryOperand.left).bitvec.toInt ∧
      (inputs BinaryOperand.left).bitvec.toInt ≤ leftUpper.toInt := by
    simpa [intervals, binaryIntervals8, ofBounds, BinaryOperand.left,
      BinaryOperand.right] using hx
  have hy' : rightLower.toInt ≤ (inputs BinaryOperand.right).bitvec.toInt ∧
      (inputs BinaryOperand.right).bitvec.toInt ≤ rightUpper.toInt := by
    simpa [intervals, binaryIntervals8, ofBounds, BinaryOperand.left,
      BinaryOperand.right] using hy
  apply hgap (inputs BinaryOperand.left).bitvec
    (inputs BinaryOperand.right).bitvec hx'.1 hx'.2 hy'.1 hy'.2
  simpa [orderedNaryRelational, NaryConcreteOp.transport,
    BinaryConcreteOp.asNary, BinaryOperand.left, BinaryOperand.right]
    using hresult

/-- An interior result outside the signed hull of all four corner results
disproves binary backward completeness at i8. -/
theorem binaryBackwardIncompleteOfCorner_i8 {m : Nat}
    (f : BinaryConcreteOp (BitVec 8) (BitVec 8) (BitVec m))
    (leftLower leftUpper rightLower rightUpper : BitVec 8)
    (insideLeft insideRight : BitVec 8)
    (result cornerLower cornerUpper : BitVec m)
    (hleft : leftLower.toInt ≤ leftUpper.toInt)
    (hright : rightLower.toInt ≤ rightUpper.toInt)
    (hinside : leftLower.toInt ≤ insideLeft.toInt ∧
      insideLeft.toInt ≤ leftUpper.toInt ∧
      rightLower.toInt ≤ insideRight.toInt ∧
      insideRight.toInt ≤ rightUpper.toInt)
    (hresult : result ∈ f insideLeft insideRight)
    (hcornerOrder : cornerLower.toInt ≤ cornerUpper.toInt)
    (hresultOutside : result.toInt < cornerLower.toInt ∨
      cornerUpper.toInt < result.toInt)
    (hcorners : ∀ x y z,
      (x = leftLower ∨ x = leftUpper) →
      (y = rightLower ∨ y = rightUpper) → z ∈ f x y →
      cornerLower.toInt ≤ z.toInt ∧ z.toInt ≤ cornerUpper.toInt) :
    ¬ BinaryBackwardComplete (domain 8) (domain 8) (domain m) f := by
  rw [SynthXfer.binaryBackwardComplete_iff_nary]
  rw [naryBackwardComplete_iff_boundedByCornerResults]
  intro hcomplete
  let lower : BinaryOperand → SignedBitVec 8 := fun k ↦
    if k = BinaryOperand.left then ⟨leftLower⟩ else ⟨rightLower⟩
  let upper : BinaryOperand → SignedBitVec 8 := fun k ↦
    if k = BinaryOperand.left then ⟨leftUpper⟩ else ⟨rightUpper⟩
  have hlowerUpper : ∀ k, lower k ≤ upper k := by
    intro k
    rcases BinaryOperand.eq_left_or_right k with rfl | rfl <;>
      simp [lower, upper, BinaryOperand.left, BinaryOperand.right, hleft,
        hright]
  have hinterior : SignedBitVec.equiv m result ∈
      NaryConcreteOp.lift (orderedNaryRelational f.asNary)
        (fun k ↦ Set.Icc (lower k) (upper k)) := by
    let inputs : BinaryOperand → SignedBitVec 8 := fun k ↦
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
  let bounds : SIntRange m := ofBounds cornerLower cornerUpper hcornerOrder
  have hcornerSubset : NaryConcreteOp.lift
      (orderedNaryRelational f.asNary)
      (fun k ↦ ({lower k, upper k} : Set (SignedBitVec 8))) ⊆
      (bounds : Set (SignedBitVec m)) := by
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
      (hxOrdered.imp (congrArg SignedBitVec.bitvec)
        (congrArg SignedBitVec.bitvec))
      (hyOrdered.imp (congrArg SignedBitVec.bitvec)
        (congrArg SignedBitVec.bitvec)) hz'
  have hinBounds := IntervalDomain.hull_minimal hcornerSubset hinHull
  change cornerLower.toInt ≤ result.toInt ∧
    result.toInt ≤ cornerUpper.toInt at hinBounds
  rcases hresultOutside with hout | hout
  · exact (not_le_of_gt hout) hinBounds.1
  · exact (not_le_of_gt hout) hinBounds.2

end SynthXfer.SIntRange
