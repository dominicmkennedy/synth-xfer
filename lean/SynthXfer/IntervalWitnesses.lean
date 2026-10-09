import SynthXfer.Interval

/-!
# Witnesses for interval incompleteness

Small, order-generic lemmas for turning a missing intermediate result or an
interior result outside the endpoint/corner hull into an incompleteness proof.
-/

namespace SynthXfer.IntervalDomain

theorem forwardIncomplete_of_gap
    {α : Type*} [Fintype α] [LinearOrder α]
    {β : Type*} [Fintype β] [LinearOrder β]
    (f : ConcreteOp α β) (input : Interval α)
    (below gap above : β)
    (hbelow : below ∈ ConcreteOp.lift f (input : Set α))
    (habove : above ∈ ConcreteOp.lift f (input : Set α))
    (hbetween : gap ∈ Set.Icc below above)
    (hgap : gap ∉ ConcreteOp.lift f (input : Set α)) :
    ¬ ForwardComplete
      (domain : AbstractDomain α (Interval α))
      (domain : AbstractDomain β (Interval β)) f := by
  rw [forwardComplete_iff_ordConnected]
  intro hcomplete
  exact hgap ((hcomplete input).out hbelow habove hbetween)

theorem naryForwardIncomplete_of_gap
    {I : Type*} {C : I → Type*}
    [∀ k, Fintype (C k)] [∀ k, LinearOrder (C k)]
    {β : Type*} [Fintype β] [LinearOrder β]
    (f : NaryConcreteOp I C β)
    (inputs : (k : I) → Interval (C k))
    (below gap above : β)
    (hbelow : below ∈ NaryConcreteOp.lift f
      (fun k ↦ (inputs k : Set (C k))))
    (habove : above ∈ NaryConcreteOp.lift f
      (fun k ↦ (inputs k : Set (C k))))
    (hbetween : gap ∈ Set.Icc below above)
    (hgap : gap ∉ NaryConcreteOp.lift f
      (fun k ↦ (inputs k : Set (C k)))) :
    ¬ NaryForwardComplete
      (fun k ↦ (domain : AbstractDomain (C k) (Interval (C k))))
      (domain : AbstractDomain β (Interval β)) f := by
  rw [naryForwardComplete_iff_ordConnected]
  intro hcomplete
  exact hgap ((hcomplete inputs).out hbelow habove hbetween)

theorem backwardIncomplete_of_endpointWitness
    {α : Type*} [Fintype α] [LinearOrder α]
    {β : Type*} [Fintype β] [LinearOrder β]
    (f : ConcreteOp α β)
    (lower upper inside : α) (result boundLower boundUpper : β)
    (hlowerUpper : lower ≤ upper)
    (hinside : inside ∈ Set.Icc lower upper)
    (hresult : result ∈ f inside)
    (hboundOrder : boundLower ≤ boundUpper)
    (hresultOutside : result < boundLower ∨ boundUpper < result)
    (hendpoints : f lower ∪ f upper ⊆ Set.Icc boundLower boundUpper) :
    ¬ BackwardComplete
      (domain : AbstractDomain α (Interval α))
      (domain : AbstractDomain β (Interval β)) f := by
  rw [backwardComplete_iff_boundedByEndpointResults]
  intro hcomplete
  have hinHull := hcomplete lower upper hlowerUpper
    ⟨inside, hinside, hresult⟩
  have hinBounds : result ∈ Set.Icc boundLower boundUpper := by
    let bounds : Interval β :=
      ((⟨(boundLower, boundUpper), hboundOrder⟩ : NonemptyInterval β) :
        Interval β)
    exact hull_minimal (i := bounds) hendpoints hinHull
  rcases hresultOutside with hout | hout
  · exact (not_le_of_gt hout) hinBounds.1
  · exact (not_le_of_gt hout) hinBounds.2

theorem naryBackwardIncomplete_of_cornerWitness
    {I : Type*} {C : I → Type*}
    [∀ k, Fintype (C k)] [∀ k, LinearOrder (C k)]
    {β : Type*} [Fintype β] [LinearOrder β]
    (f : NaryConcreteOp I C β)
    (lower upper : (k : I) → C k)
    (result boundLower boundUpper : β)
    (hlowerUpper : ∀ k, lower k ≤ upper k)
    (hresult : result ∈ NaryConcreteOp.lift f
      (fun k ↦ Set.Icc (lower k) (upper k)))
    (hboundOrder : boundLower ≤ boundUpper)
    (hresultOutside : result < boundLower ∨ boundUpper < result)
    (hcorners : NaryConcreteOp.lift f
      (fun k ↦ ({lower k, upper k} : Set (C k))) ⊆
        Set.Icc boundLower boundUpper) :
    ¬ NaryBackwardComplete
      (fun k ↦ (domain : AbstractDomain (C k) (Interval (C k))))
      (domain : AbstractDomain β (Interval β)) f := by
  rw [naryBackwardComplete_iff_boundedByCornerResults]
  intro hcomplete
  have hinHull := hcomplete lower upper hlowerUpper hresult
  have hinBounds : result ∈ Set.Icc boundLower boundUpper := by
    let bounds : Interval β :=
      ((⟨(boundLower, boundUpper), hboundOrder⟩ : NonemptyInterval β) :
        Interval β)
    exact hull_minimal (i := bounds) hcorners hinHull
  rcases hresultOutside with hout | hout
  · exact (not_le_of_gt hout) hinBounds.1
  · exact (not_le_of_gt hout) hinBounds.2

end SynthXfer.IntervalDomain
