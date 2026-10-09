import SynthXfer.ConcreteOps
import Mathlib.Data.BitVec
import Mathlib.Data.Finset.Max
import Mathlib.Data.FinEnum
import Mathlib.Order.Interval.Basic
import Mathlib.Order.Interval.Set.OrdConnected

/-!
# Closed-interval and integer-range abstract domains

Mathlib's `Interval α` consists of bottom or a nonempty closed interval. This
file equips it with the abstraction operation that sends a concrete set to the
least interval containing it. It then instantiates that construction as
unsigned and signed non-wrapping ranges over bitvectors.
-/

open Set

namespace SynthXfer

universe u v

namespace IntervalDomain

variable {α : Type u} [Fintype α] [LinearOrder α]

/-- The elements of a concrete set, collected into a finset. -/
private noncomputable def elements (s : Set α) : Finset α := by
  classical
  exact Finset.univ.filter (· ∈ s)

omit [LinearOrder α] in
@[simp]
private theorem mem_elements {s : Set α} {x : α} : x ∈ elements s ↔ x ∈ s := by
  classical
  simp [elements]

omit [LinearOrder α] in
private theorem elements_nonempty {s : Set α} (hs : s.Nonempty) :
    (elements s).Nonempty := by
  obtain ⟨x, hxs⟩ := hs
  exact ⟨x, mem_elements.mpr hxs⟩

/-- The least closed interval containing `s`. -/
noncomputable def hull (s : Set α) : Interval α := by
  classical
  exact if hs : s.Nonempty then
    let es := elements s
    let hes := elements_nonempty hs
    ((⟨(es.min' hes, es.max' hes), es.min'_le_max' hes⟩ : NonemptyInterval α) :
      Interval α)
  else
    ⊥

theorem subset_hull (s : Set α) : s ⊆ (hull s : Set α) := by
  intro x hxs
  have hs : s.Nonempty := ⟨x, hxs⟩
  rw [hull, dif_pos hs]
  exact ⟨(elements s).min'_le x (mem_elements.mpr hxs),
    (elements s).le_max' x (mem_elements.mpr hxs)⟩

theorem hull_minimal {s : Set α} {i : Interval α} (h : s ⊆ (i : Set α)) :
    (hull s : Set α) ⊆ (i : Set α) := by
  by_cases hs : s.Nonempty
  · rw [hull, dif_pos hs]
    let es := elements s
    let hes := elements_nonempty hs
    have hmin_mem : es.min' hes ∈ s :=
      mem_elements.mp (es.min'_mem hes)
    have hmax_mem : es.max' hes ∈ s :=
      mem_elements.mp (es.max'_mem hes)
    cases i with
    | bot => simpa using h hmin_mem
    | coe i =>
        rintro x hx
        exact ⟨(h hmin_mem).1.trans hx.1, hx.2.trans (h hmax_mem).2⟩
  · rw [hull, dif_neg hs]
    exact Set.empty_subset _

theorem hull_gc : GaloisConnection (hull : Set α → Interval α)
    ((↑) : Interval α → Set α) := by
  intro s i
  constructor
  · intro h
    exact (subset_hull s).trans (Interval.coe_subset_coe.mpr h)
  · intro h
    exact Interval.coe_subset_coe.mp (hull_minimal h)

@[simp]
theorem hull_coe (i : Interval α) : hull (i : Set α) = i := by
  apply le_antisymm
  · exact (hull_gc (i : Set α) i).2 Subset.rfl
  · exact Interval.coe_subset_coe.mp (hull_gc.le_u_l (i : Set α))

/-- Closed intervals, ordered by inclusion, form an abstract domain for sets of
elements of `α`. -/
noncomputable def domain : AbstractDomain α (Interval α) where
  abstract := hull
  concretize := (↑)
  gc := hull_gc
  insertion := hull_coe

@[simp]
theorem domain_abstract (s : Set α) : domain.abstract s = hull s :=
  rfl

@[simp]
theorem domain_concretize (i : Interval α) : domain.concretize i = (i : Set α) :=
  rfl

@[simp]
theorem hull_empty : hull (∅ : Set α) = ⊥ :=
  domain.abstract_empty

theorem hull_mono : Monotone (hull : Set α → Interval α) :=
  hull_gc.monotone_l

theorem hull_eq_bot_iff {s : Set α} : hull s = ⊥ ↔ s = ∅ := by
  constructor
  · intro h
    apply not_nonempty_iff_eq_empty.mp
    rintro ⟨x, hxs⟩
    have := subset_hull s hxs
    simp [h] at this
  · rintro rfl
    exact hull_empty

/-- Every nonempty finite-set hull has endpoints drawn from the original set. -/
theorem exists_endpoints_hull {s : Set α} (hs : s.Nonempty) :
    ∃ lower ∈ s, ∃ upper ∈ s,
      lower ≤ upper ∧ (hull s : Set α) = Icc lower upper := by
  let es := elements s
  let hes := elements_nonempty hs
  refine ⟨es.min' hes, mem_elements.mp (es.min'_mem hes),
    es.max' hes, mem_elements.mp (es.max'_mem hes),
    es.min'_le_max' hes, ?_⟩
  rw [hull, dif_pos hs]
  rfl

/-- A concrete set is exactly representable when it is the concretization of
some closed interval. -/
def ExactlyRepresentable (s : Set α) : Prop :=
  ∃ i : Interval α, (i : Set α) = s

theorem exactlyRepresentable_iff_hull (s : Set α) :
    ExactlyRepresentable s ↔ (hull s : Set α) = s := by
  constructor
  · rintro ⟨i, rfl⟩
    simp
  · intro h
    exact ⟨hull s, h⟩

omit [Fintype α] in
/-- In a finite linear order, the exactly representable sets are precisely
the order-connected sets: sets with no gaps. -/
theorem exactlyRepresentable_iff_ordConnected [Finite α] (s : Set α) :
    ExactlyRepresentable s ↔ s.OrdConnected := by
  letI := Fintype.ofFinite α
  constructor
  · rintro ⟨i, rfl⟩
    cases i with
    | bot => exact Set.ordConnected_empty
    | coe i =>
        simpa [NonemptyInterval.coe_def] using
          (Set.ordConnected_Icc : (Icc i.fst i.snd).OrdConnected)
  · intro hs
    by_cases hempty : s.Nonempty
    · obtain ⟨lower, hlower, upper, hupper, _, hhull⟩ :=
        exists_endpoints_hull hempty
      apply (exactlyRepresentable_iff_hull s).mpr
      apply Set.Subset.antisymm
      · rw [hhull]
        exact hs.out hlower hupper
      · exact subset_hull s
    · have : s = ∅ := Set.not_nonempty_iff_eq_empty.mp hempty
      subst s
      exact ⟨⊥, by simp⟩

theorem forwardComplete_iff_exactlyRepresentable
    {β : Type*} [Fintype β] [LinearOrder β]
    (f : ConcreteOp α β) :
    ForwardComplete (domain : AbstractDomain α (Interval α))
        (domain : AbstractDomain β (Interval β)) f ↔
      ∀ i : Interval α,
        ExactlyRepresentable (ConcreteOp.lift f (i : Set α)) := by
  constructor
  · intro h i
    refine ⟨bestTransformer domain domain f i, ?_⟩
    exact h i
  · rintro h i
    obtain ⟨j, hj⟩ := h i
    change ((hull (ConcreteOp.lift f (i : Set α)) : Interval β) : Set β) =
      ConcreteOp.lift f (i : Set α)
    rw [← hj, hull_coe]

/-- A relational operation is interval-forward-complete exactly when the
result set of every input interval has no gaps. -/
theorem forwardComplete_iff_ordConnected
    {β : Type*} [Fintype β] [LinearOrder β]
    (f : ConcreteOp α β) :
    ForwardComplete (domain : AbstractDomain α (Interval α))
        (domain : AbstractDomain β (Interval β)) f ↔
      ∀ i : Interval α,
        (ConcreteOp.lift f (i : Set α)).OrdConnected := by
  rw [forwardComplete_iff_exactlyRepresentable]
  exact forall_congr' fun i ↦ exactlyRepresentable_iff_ordConnected _

/-- A heterogeneous operation on independent interval operands is forward
complete exactly when the result set of every input box has no gaps. -/
theorem naryForwardComplete_iff_ordConnected
    {ι : Type*} {C : ι → Type u}
    [∀ k, Fintype (C k)] [∀ k, LinearOrder (C k)]
    {β : Type v} [Fintype β] [LinearOrder β]
    (f : NaryConcreteOp ι C β) :
    NaryForwardComplete
        (fun k ↦ (domain : AbstractDomain (C k) (Interval (C k))))
        (domain : AbstractDomain β (Interval β)) f ↔
      ∀ a : (k : ι) → Interval (C k),
        (NaryConcreteOp.lift f fun k ↦ (a k : Set (C k))).OrdConnected := by
  constructor
  · intro hcomplete a
    apply (exactlyRepresentable_iff_ordConnected _).mp
    refine ⟨bestNaryTransformer
      (fun k ↦ (domain : AbstractDomain (C k) (Interval (C k))))
      (domain : AbstractDomain β (Interval β)) f a, ?_⟩
    exact hcomplete a
  · intro hconnected a
    obtain ⟨result, hresult⟩ :=
      (exactlyRepresentable_iff_ordConnected _).mpr (hconnected a)
    change ((hull (NaryConcreteOp.lift f
      fun k ↦ (a k : Set (C k))) : Interval β) : Set β) =
        NaryConcreteOp.lift f fun k ↦ (a k : Set (C k))
    rw [← hresult, hull_coe]

/-- A linear order has no strict intermediate points when every value between
two ordered endpoints is one of those endpoints. -/
def NoStrictIntermediate (β : Type*) [LinearOrder β] : Prop :=
  ∀ a b z : β, a ≤ z → z ≤ b → z = a ∨ z = b

/-- Any relational operation into a linear order with no strict intermediate
points is forward complete for closed intervals, regardless of arity or
partiality. -/
theorem naryForwardComplete_of_noStrictIntermediate
    {I : Type*} {C : I → Type u}
    [∀ k, Fintype (C k)] [∀ k, LinearOrder (C k)]
    {β : Type v} [Fintype β] [LinearOrder β]
    (hβ : NoStrictIntermediate β) (f : NaryConcreteOp I C β) :
    NaryForwardComplete
      (fun k ↦ (domain : AbstractDomain (C k) (Interval (C k))))
      (domain : AbstractDomain β (Interval β)) f := by
  rw [naryForwardComplete_iff_ordConnected]
  intro intervals
  constructor
  intro a ha b hb z hz
  rcases hβ a b z hz.1 hz.2 with rfl | rfl
  · exact ha
  · exact hb

omit [Fintype α] in
/-- The image of every point of `[lower, upper]` lies between the images of
the two endpoints. Equivalently, the minimum and maximum image values on an
interval are witnessed at its endpoints. -/
def BoundedByEndpointImages {β : Type*} [LinearOrder β] (f : α → β) : Prop :=
  ∀ lower upper, lower ≤ upper → ∀ x ∈ Icc lower upper,
    f x ∈ Icc (min (f lower) (f upper)) (max (f lower) (f upper))

omit [Fintype α] in
/-- Every result produced inside `[lower, upper]` lies in the hull of the
results produced at its endpoints. This is the endpoint condition for a
relational operation, including partial operations whose undefined inputs
produce no results. -/
def BoundedByEndpointResults {β : Type*} [Fintype β] [LinearOrder β]
    (f : ConcreteOp α β) : Prop :=
  ∀ lower upper, lower ≤ upper →
    ConcreteOp.lift f (Icc lower upper) ⊆
      (hull (f lower ∪ f upper) : Set β)

/-- A hull contains every point lying between any two of its original
members. -/
theorem mem_hull_of_between {s : Set α} {a b x : α}
    (ha : a ∈ s) (hb : b ∈ s)
    (hx : x ∈ Icc (min a b) (max a b)) :
    x ∈ (hull s : Set α) := by
  have haHull := subset_hull s ha
  have hbHull := subset_hull s hb
  cases hHull : hull s with
  | bot => simp [hHull] at haHull
  | coe i =>
      have haI : a ∈ (i : Set α) := by simpa [hHull] using haHull
      have hbI : b ∈ (i : Set α) := by simpa [hHull] using hbHull
      change i.fst ≤ x ∧ x ≤ i.snd
      exact ⟨(le_min haI.1 hbI.1).trans hx.1,
        hx.2.trans (max_le haI.2 hbI.2)⟩

omit [Fintype α] in
/-- Every closed interval contains each point between any two of its
members. -/
theorem mem_interval_of_between {i : Interval α} {a b x : α}
    (ha : a ∈ (i : Set α)) (hb : b ∈ (i : Set α))
    (hx : x ∈ Icc (min a b) (max a b)) : x ∈ (i : Set α) := by
  cases i with
  | bot => simp at ha
  | coe bounds =>
      rcases le_total a b with hab | hba
      · rw [min_eq_left hab, max_eq_right hab] at hx
        exact ⟨ha.1.trans hx.1, hx.2.trans hb.2⟩
      · rw [min_eq_right hba, max_eq_left hba] at hx
        exact ⟨hb.1.trans hx.1, hx.2.trans ha.2⟩

/-- Exact unary backward-completeness characterization for relational
operations over finite closed intervals. -/
theorem backwardComplete_iff_boundedByEndpointResults
    {β : Type*} [Fintype β] [LinearOrder β] (f : ConcreteOp α β) :
    BackwardComplete (domain : AbstractDomain α (Interval α))
        (domain : AbstractDomain β (Interval β)) f ↔
      BoundedByEndpointResults f := by
  constructor
  · intro hcomplete lower upper hlowerUpper y hy
    let s : Set α := {lower, upper}
    have hEq := hcomplete s
    change hull (ConcreteOp.lift f (hull s : Set α)) =
      hull (ConcreteOp.lift f s) at hEq
    obtain ⟨x, hx, hyfx⟩ := hy
    have hxHull : x ∈ (hull s : Set α) := by
      apply mem_hull_of_between (s := s) (a := lower) (b := upper)
      · simp [s]
      · simp [s]
      · simpa [min_eq_left hlowerUpper, max_eq_right hlowerUpper] using hx
    have hyHull : y ∈ (hull (ConcreteOp.lift f
        (hull s : Set α)) : Set β) :=
      subset_hull _ ⟨x, hxHull, hyfx⟩
    rw [hEq] at hyHull
    have hendpoints : ConcreteOp.lift f s = f lower ∪ f upper := by
      ext z
      simp [ConcreteOp.lift, s]
    rwa [hendpoints] at hyHull
  · intro hbounded s
    change hull (ConcreteOp.lift f (hull s : Set α)) =
      hull (ConcreteOp.lift f s)
    by_cases hs : s.Nonempty
    · obtain ⟨lower, hlower, upper, hupper, hlowerUpper, hhull⟩ :=
        exists_endpoints_hull hs
      apply le_antisymm
      · apply Interval.coe_subset_coe.mp
        apply hull_minimal
        rintro y ⟨x, hx, hy⟩
        rw [hhull] at hx
        have hyEndpointHull := hbounded lower upper hlowerUpper ⟨x, hx, hy⟩
        have hendpointSubset : f lower ∪ f upper ⊆
            ConcreteOp.lift f s := by
          intro z hz
          rcases hz with hz | hz
          · exact ⟨lower, hlower, hz⟩
          · exact ⟨upper, hupper, hz⟩
        exact (Interval.coe_subset_coe.mpr (hull_mono hendpointSubset))
          hyEndpointHull
      · exact hull_mono (ConcreteOp.lift_mono f (subset_hull s))
    · have hempty : s = ∅ := Set.not_nonempty_iff_eq_empty.mp hs
      subst s
      simp

omit [Fintype α] in
private theorem boundedByEndpointResults_ofTotal_iff
    {β : Type*} [Fintype β] [LinearOrder β] (f : α → β) :
    BoundedByEndpointResults (ConcreteOp.ofTotal f) ↔
      BoundedByEndpointImages f := by
  constructor
  · intro h lower upper hlowerUpper x hx
    have hfx := h lower upper hlowerUpper
      ⟨x, hx, Set.mem_singleton (f x)⟩
    apply (hull_minimal (s := ({f lower} ∪ {f upper} : Set β)) (i :=
      ((⟨(min (f lower) (f upper), max (f lower) (f upper)), min_le_max⟩ :
        NonemptyInterval β) : Interval β)) ?_) hfx
    intro y hy
    rcases hy with hy | hy
    · have : y = f lower := Set.mem_singleton_iff.mp hy
      subst y
      exact ⟨min_le_left _ _, le_max_left _ _⟩
    · have : y = f upper := Set.mem_singleton_iff.mp hy
      subst y
      exact ⟨min_le_right _ _, le_max_right _ _⟩
  · intro h lower upper hlowerUpper y hy
    obtain ⟨x, hx, hyfx⟩ := hy
    have hyEq : y = f x := Set.mem_singleton_iff.mp hyfx
    subst y
    apply mem_hull_of_between (s := ({f lower} ∪ {f upper} : Set β))
      (a := f lower) (b := f upper) (x := f x)
    · simp
    · simp
    · exact h lower upper hlowerUpper x hx

/-- Exact unary backward-completeness characterization for total operations
over finite closed intervals. -/
theorem backwardComplete_iff_boundedByEndpointImages
    {β : Type*} [Fintype β] [LinearOrder β] (f : α → β) :
    BackwardComplete (domain : AbstractDomain α (Interval α))
        (domain : AbstractDomain β (Interval β)) (ConcreteOp.ofTotal f) ↔
      BoundedByEndpointImages f := by
  rw [backwardComplete_iff_boundedByEndpointResults]
  exact boundedByEndpointResults_ofTotal_iff f

/-- A monotone total operation is backward complete for closed intervals:
every interior result lies between the two endpoint results. -/
theorem backwardComplete_of_monotone
    {β : Type*} [Fintype β] [LinearOrder β] (f : α → β)
    (hf : Monotone f) :
    BackwardComplete (domain : AbstractDomain α (Interval α))
      (domain : AbstractDomain β (Interval β)) (ConcreteOp.ofTotal f) := by
  rw [backwardComplete_iff_boundedByEndpointImages]
  intro lower upper hlowerUpper x hx
  rw [min_eq_left (hf hlowerUpper), max_eq_right (hf hlowerUpper)]
  exact ⟨hf hx.1, hf hx.2⟩

/-- An antitone total operation is backward complete for closed intervals. -/
theorem backwardComplete_of_antitone
    {β : Type*} [Fintype β] [LinearOrder β] (f : α → β)
    (hf : Antitone f) :
    BackwardComplete (domain : AbstractDomain α (Interval α))
      (domain : AbstractDomain β (Interval β)) (ConcreteOp.ofTotal f) := by
  rw [backwardComplete_iff_boundedByEndpointImages]
  intro lower upper hlowerUpper x hx
  rw [min_eq_right (hf hlowerUpper), max_eq_left (hf hlowerUpper)]
  exact ⟨hf hx.2, hf hx.1⟩

/-- A monotone function has interval-connected images when every value between
two ordered results is attained between their inputs. -/
theorem forwardComplete_of_monotone_intermediate
    {β : Type*} [Fintype β] [LinearOrder β] (f : α → β)
    (hf : Monotone f)
    (hintermediate : ∀ a b z, a ≤ b → f a ≤ z → z ≤ f b →
      ∃ x ∈ Icc a b, f x = z) :
    ForwardComplete (domain : AbstractDomain α (Interval α))
      (domain : AbstractDomain β (Interval β)) (ConcreteOp.ofTotal f) := by
  rw [forwardComplete_iff_ordConnected]
  intro i
  constructor
  rintro _ ⟨a, ha, rfl⟩ _ ⟨b, hb, rfl⟩ z hz
  by_cases hab : a ≤ b
  · obtain ⟨x, hx, rfl⟩ := hintermediate a b z hab hz.1 hz.2
    refine ⟨x, ?_, rfl⟩
    cases i with
    | bot => simp at ha
    | coe iv => exact ⟨ha.1.trans hx.1, hx.2.trans hb.2⟩
  · have hba : b ≤ a := le_of_not_ge hab
    have heq : f a = f b := le_antisymm (hz.1.trans hz.2) (hf hba)
    have hzEq : z = f a := le_antisymm (hz.2.trans heq.symm.le) hz.1
    exact ⟨a, ha, by simp [hzEq]⟩

/-- Antitone counterpart of `forwardComplete_of_monotone_intermediate`. -/
theorem forwardComplete_of_antitone_intermediate
    {β : Type*} [Fintype β] [LinearOrder β] (f : α → β)
    (hf : Antitone f)
    (hintermediate : ∀ a b z, a ≤ b → f b ≤ z → z ≤ f a →
      ∃ x ∈ Icc a b, f x = z) :
    ForwardComplete (domain : AbstractDomain α (Interval α))
      (domain : AbstractDomain β (Interval β)) (ConcreteOp.ofTotal f) := by
  rw [forwardComplete_iff_ordConnected]
  intro i
  constructor
  rintro _ ⟨a, ha, rfl⟩ _ ⟨b, hb, rfl⟩ z hz
  by_cases hba : b ≤ a
  · obtain ⟨x, hx, rfl⟩ := hintermediate b a z hba hz.1 hz.2
    refine ⟨x, ?_, rfl⟩
    cases i with
    | bot => simp at ha
    | coe iv => exact ⟨hb.1.trans hx.1, hx.2.trans ha.2⟩
  · have hab : a ≤ b := le_of_not_ge hba
    have heq : f a = f b := le_antisymm (hz.1.trans hz.2) (hf hab)
    have hzEq : z = f a := le_antisymm (hz.2.trans heq.symm.le) hz.1
    exact ⟨a, ha, by simp [hzEq]⟩

/-- The corners determined by independently choosing the lower or upper
endpoint of every operand. -/
def Corners {ι : Type*} {C : ι → Type u}
    (lower upper : (k : ι) → C k) : Set ((k : ι) → C k) :=
  {x | ∀ k, x k = lower k ∨ x k = upper k}

/-- Every result produced inside an input box lies in the hull of the results
produced at its corners. Unlike `BoundedByCornerImages`, this applies directly
to relational and partial operations. -/
def BoundedByCornerResults {ι : Type*} {C : ι → Type u}
    [∀ k, LinearOrder (C k)]
    {β : Type v} [Fintype β] [LinearOrder β]
    (f : NaryConcreteOp ι C β) : Prop :=
  ∀ (lower upper : (k : ι) → C k), (∀ k, lower k ≤ upper k) →
    NaryConcreteOp.lift f (fun k ↦ Icc (lower k) (upper k)) ⊆
      (hull (NaryConcreteOp.lift f
        (fun k ↦ ({lower k, upper k} : Set (C k)))) : Set β)

/-- Every point in an input box maps between the least and greatest corner
images. Membership in the corner-image hull expresses this without choosing
explicit extrema. -/
def BoundedByCornerImages {ι : Type*} {C : ι → Type u}
    [∀ k, LinearOrder (C k)]
    {β : Type v} [Fintype β] [LinearOrder β]
    (f : ((k : ι) → C k) → β) : Prop :=
  ∀ lower upper, (∀ k, lower k ≤ upper k) →
    ∀ x, (∀ k, x k ∈ Icc (lower k) (upper k)) →
      f x ∈ (hull (f '' Corners lower upper) : Set β)

/-- Whether an operand is ordered in the ordinary or reversed direction for
a monotonicity argument. -/
inductive OrderVariance where
  | increasing
  | decreasing
deriving DecidableEq

/-- The product order obtained by choosing an ordering direction for every
operand. -/
def VarianceLE {I : Type*} {C : I → Type u} [∀ k, LE (C k)]
    (variance : I → OrderVariance)
    (x y : (k : I) → C k) : Prop :=
  ∀ k, match variance k with
    | .increasing => x k ≤ y k
    | .decreasing => y k ≤ x k

/-- A heterogeneous function monotone in a separately specified direction
for every operand. -/
def MonotoneWithVariances {I : Type*} {C : I → Type u}
    [∀ k, LE (C k)] {β : Type v} [LE β]
    (variance : I → OrderVariance)
    (f : ((k : I) → C k) → β) : Prop :=
  ∀ x y, VarianceLE variance x y → f x ≤ f y

private theorem lift_pair_eq_image_corners {ι : Type*} {C : ι → Type u}
    {β : Type v} (f : ((k : ι) → C k) → β)
    (lower upper : (k : ι) → C k) :
    NaryConcreteOp.lift (NaryConcreteOp.ofTotal f)
        (fun k ↦ ({lower k, upper k} : Set (C k))) =
      f '' Corners lower upper := by
  ext y
  constructor
  · rintro ⟨x, hx, hy⟩
    have hyEq : y = f x := Set.mem_singleton_iff.mp hy
    refine ⟨x, ?_, hyEq.symm⟩
    intro k
    simpa only [Set.mem_insert_iff, Set.mem_singleton_iff] using hx k
  · rintro ⟨x, hx, rfl⟩
    refine ⟨x, ?_, Set.mem_singleton (f x)⟩
    intro k
    simpa only [Set.mem_insert_iff, Set.mem_singleton_iff] using hx k

/-- Exact n-ary backward-completeness characterization for relational
operations over independent finite closed-interval operands. -/
theorem naryBackwardComplete_iff_boundedByCornerResults
    {ι : Type*} {C : ι → Type u}
    [∀ k, Fintype (C k)] [∀ k, LinearOrder (C k)]
    {β : Type v} [Fintype β] [LinearOrder β]
    (f : NaryConcreteOp ι C β) :
    NaryBackwardComplete
        (fun k ↦ (domain : AbstractDomain (C k) (Interval (C k))))
        (domain : AbstractDomain β (Interval β)) f ↔
      BoundedByCornerResults f := by
  classical
  constructor
  · intro hcomplete lower upper hlowerUpper y hy
    let xs : (k : ι) → Set (C k) := fun k ↦ {lower k, upper k}
    have hEq := hcomplete xs
    change hull (NaryConcreteOp.lift f
        (fun k ↦ (hull (xs k) : Set (C k)))) =
      hull (NaryConcreteOp.lift f xs) at hEq
    obtain ⟨x, hx, hyfx⟩ := hy
    have hxClosed : ∀ k, x k ∈ (hull (xs k) : Set (C k)) := by
      intro k
      apply mem_hull_of_between (s := xs k)
        (a := lower k) (b := upper k)
      · simp [xs]
      · simp [xs]
      · simpa [min_eq_left (hlowerUpper k), max_eq_right (hlowerUpper k)]
          using hx k
    have hyHull : y ∈ (hull (NaryConcreteOp.lift f
        (fun k ↦ (hull (xs k) : Set (C k)))) : Set β) :=
      subset_hull _ ⟨x, hxClosed, hyfx⟩
    rw [hEq] at hyHull
    simpa [xs] using hyHull
  · intro hbounded xs
    change hull (NaryConcreteOp.lift f
        (fun k ↦ (hull (xs k) : Set (C k)))) =
      hull (NaryConcreteOp.lift f xs)
    by_cases hall : ∀ k, (xs k).Nonempty
    · choose lower hlower upper hupper hlowerUpper hhull using
        fun k ↦ exists_endpoints_hull (hall k)
      apply le_antisymm
      · apply Interval.coe_subset_coe.mp
        apply hull_minimal
        rintro y ⟨x, hx, hyfx⟩
        have hxBox : ∀ k, x k ∈ Icc (lower k) (upper k) := by
          intro k
          rw [← hhull k]
          exact hx k
        have hyCornerHull := hbounded lower upper hlowerUpper
          ⟨x, hxBox, hyfx⟩
        have hcornerSubset : NaryConcreteOp.lift f
            (fun k ↦ ({lower k, upper k} : Set (C k))) ⊆
            NaryConcreteOp.lift f xs := by
          rintro z ⟨corner, hcorner, hz⟩
          refine ⟨corner, ?_, hz⟩
          intro k
          rcases hcorner k with hk | hk
          · rw [hk]
            exact hlower k
          · rw [hk]
            exact hupper k
        exact (Interval.coe_subset_coe.mpr (hull_mono hcornerSubset))
          hyCornerHull
      · exact hull_mono (NaryConcreteOp.lift_mono _
          (fun k ↦ subset_hull (xs k)))
    · simp only [not_forall] at hall
      obtain ⟨k, hk⟩ := hall
      have hxsempty : xs k = ∅ := Set.not_nonempty_iff_eq_empty.mp hk
      have hclosedEmpty : (hull (xs k) : Set (C k)) = ∅ := by
        rw [hxsempty]
        simp
      have hright : NaryConcreteOp.lift f xs = ∅ :=
        NaryConcreteOp.lift_empty_of_empty_operand f xs k hxsempty
      have hleft : NaryConcreteOp.lift f
          (fun k ↦ (hull (xs k) : Set (C k))) = ∅ :=
        NaryConcreteOp.lift_empty_of_empty_operand f _ k hclosedEmpty
      rw [hright, hleft]

private theorem boundedByCornerResults_ofTotal_iff
    {ι : Type*} {C : ι → Type u} [∀ k, LinearOrder (C k)]
    {β : Type v} [Fintype β] [LinearOrder β]
    (f : ((k : ι) → C k) → β) :
    BoundedByCornerResults (NaryConcreteOp.ofTotal f) ↔
      BoundedByCornerImages f := by
  constructor
  · intro h lower upper hlowerUpper x hx
    have hresult := h lower upper hlowerUpper
      ⟨x, hx, Set.mem_singleton (f x)⟩
    rw [lift_pair_eq_image_corners] at hresult
    exact hresult
  · intro h lower upper hlowerUpper y hy
    obtain ⟨x, hx, hyfx⟩ := hy
    have hyEq : y = f x := Set.mem_singleton_iff.mp hyfx
    subst y
    rw [lift_pair_eq_image_corners]
    exact h lower upper hlowerUpper x hx

/-- Exact n-ary backward-completeness characterization for independent finite
closed-interval operands: all extrema over a box are witnessed at corners. -/
theorem naryBackwardComplete_iff_boundedByCornerImages
    {ι : Type*} {C : ι → Type u}
    [∀ k, Fintype (C k)] [∀ k, LinearOrder (C k)]
    {β : Type v} [Fintype β] [LinearOrder β]
    (f : ((k : ι) → C k) → β) :
    NaryBackwardComplete
        (fun k ↦ (domain : AbstractDomain (C k) (Interval (C k))))
        (domain : AbstractDomain β (Interval β)) (NaryConcreteOp.ofTotal f) ↔
      BoundedByCornerImages f := by
  rw [naryBackwardComplete_iff_boundedByCornerResults]
  exact boundedByCornerResults_ofTotal_iff f

/-- Coordinatewise monotonicity, with independently chosen direction for
each operand, implies n-ary backward completeness for closed intervals. -/
theorem naryBackwardComplete_of_monotoneWithVariances
    {I : Type*} {C : I → Type u}
    [∀ k, Fintype (C k)] [∀ k, LinearOrder (C k)]
    {β : Type v} [Fintype β] [LinearOrder β]
    (variance : I → OrderVariance)
    (f : ((k : I) → C k) → β)
    (hf : MonotoneWithVariances variance f) :
    NaryBackwardComplete
      (fun k ↦ (domain : AbstractDomain (C k) (Interval (C k))))
      (domain : AbstractDomain β (Interval β))
      (NaryConcreteOp.ofTotal f) := by
  rw [naryBackwardComplete_iff_boundedByCornerImages]
  intro lower upper hlowerUpper x hx
  let low : (k : I) → C k := fun k ↦
    match variance k with
    | .increasing => lower k
    | .decreasing => upper k
  let high : (k : I) → C k := fun k ↦
    match variance k with
    | .increasing => upper k
    | .decreasing => lower k
  apply mem_hull_of_between
    (s := f '' Corners lower upper) (a := f low) (b := f high)
  · refine ⟨low, ?_, rfl⟩
    intro k
    cases hvariance : variance k <;>
      simp [low, hvariance]
  · refine ⟨high, ?_, rfl⟩
    intro k
    cases hvariance : variance k <;>
      simp [high, hvariance]
  · have hlow : f low ≤ f x := hf low x (by
      intro k
      cases hvariance : variance k <;>
        simp [low, hvariance, (hx k).1, (hx k).2])
    have hhigh : f x ≤ f high := hf x high (by
      intro k
      cases hvariance : variance k <;>
        simp [high, hvariance, (hx k).1, (hx k).2])
    have horder := hlow.trans hhigh
    rw [min_eq_left horder, max_eq_right horder]
    exact ⟨hlow, hhigh⟩

/-! ### Transported interval characterizations

These lemmas contain the representation-transport argument shared by the
unsigned and signed bitvector interval adapters below. -/

theorem forwardComplete_comapEquiv_ofTotal_iff_ordConnected
    {C C' D D' : Type*} [Fintype C'] [LinearOrder C']
    [Fintype D'] [LinearOrder D']
    (srcEquiv : C ≃ C') (dstEquiv : D ≃ D') (f : C → D) :
    ForwardComplete
        ((domain : AbstractDomain C' (Interval C')).comapEquiv srcEquiv)
        ((domain : AbstractDomain D' (Interval D')).comapEquiv dstEquiv)
        (ConcreteOp.ofTotal f) ↔
      ∀ i : Interval C',
        (AbstractDomain.transportUnary srcEquiv dstEquiv f ''
          (i : Set C')).OrdConnected := by
  rw [forwardComplete_transportTotal_iff]
  simpa only [ConcreteOp.lift_ofTotal] using
    forwardComplete_iff_ordConnected
      (ConcreteOp.ofTotal
        (AbstractDomain.transportUnary srcEquiv dstEquiv f))

theorem backwardComplete_comapEquiv_ofTotal_iff_boundedByEndpointImages
    {C C' D D' : Type*} [Fintype C'] [LinearOrder C']
    [Fintype D'] [LinearOrder D']
    (srcEquiv : C ≃ C') (dstEquiv : D ≃ D') (f : C → D) :
    BackwardComplete
        ((domain : AbstractDomain C' (Interval C')).comapEquiv srcEquiv)
        ((domain : AbstractDomain D' (Interval D')).comapEquiv dstEquiv)
        (ConcreteOp.ofTotal f) ↔
      BoundedByEndpointImages
        (AbstractDomain.transportUnary srcEquiv dstEquiv f) := by
  rw [backwardComplete_transportTotal_iff]
  exact backwardComplete_iff_boundedByEndpointImages _

theorem forwardComplete_comapEquiv_iff_ordConnected
    {C C' D D' : Type*} [Fintype C'] [LinearOrder C']
    [Fintype D'] [LinearOrder D']
    (srcEquiv : C ≃ C') (dstEquiv : D ≃ D') (f : ConcreteOp C D) :
    ForwardComplete
        ((domain : AbstractDomain C' (Interval C')).comapEquiv srcEquiv)
        ((domain : AbstractDomain D' (Interval D')).comapEquiv dstEquiv) f ↔
      ∀ i : Interval C',
        (ConcreteOp.lift (ConcreteOp.transport srcEquiv dstEquiv f)
          (i : Set C')).OrdConnected := by
  rw [forwardComplete_transport_iff]
  exact forwardComplete_iff_ordConnected _

theorem backwardComplete_comapEquiv_iff_boundedByEndpointResults
    {C C' D D' : Type*} [Fintype C'] [LinearOrder C']
    [Fintype D'] [LinearOrder D']
    (srcEquiv : C ≃ C') (dstEquiv : D ≃ D') (f : ConcreteOp C D) :
    BackwardComplete
        ((domain : AbstractDomain C' (Interval C')).comapEquiv srcEquiv)
        ((domain : AbstractDomain D' (Interval D')).comapEquiv dstEquiv) f ↔
      BoundedByEndpointResults (ConcreteOp.transport srcEquiv dstEquiv f) := by
  rw [backwardComplete_transport_iff]
  exact backwardComplete_iff_boundedByEndpointResults _

theorem naryForwardComplete_comapEquiv_ofTotal_iff_ordConnected
    {ι : Type*} {C C' : ι → Type u} {D D' : Type v}
    [∀ k, Fintype (C' k)] [∀ k, LinearOrder (C' k)]
    [Fintype D'] [LinearOrder D']
    (equiv : ∀ k, C k ≃ C' k) (dstEquiv : D ≃ D')
    (f : ((k : ι) → C k) → D) :
    NaryForwardComplete
        (fun k ↦ (domain : AbstractDomain (C' k) (Interval (C' k))).comapEquiv
          (equiv k))
        ((domain : AbstractDomain D' (Interval D')).comapEquiv dstEquiv)
        (NaryConcreteOp.ofTotal f) ↔
      ∀ a : (k : ι) → Interval (C' k),
        (NaryConcreteOp.lift
          (NaryConcreteOp.ofTotal
            (NaryConcreteOp.transportTotal equiv dstEquiv f))
          fun k ↦ (a k : Set (C' k))).OrdConnected := by
  rw [naryForwardComplete_transportTotal_iff]
  exact naryForwardComplete_iff_ordConnected _

theorem naryBackwardComplete_comapEquiv_ofTotal_iff_boundedByCornerImages
    {ι : Type*} {C C' : ι → Type u} {D D' : Type v}
    [∀ k, Fintype (C' k)] [∀ k, LinearOrder (C' k)]
    [Fintype D'] [LinearOrder D']
    (equiv : ∀ k, C k ≃ C' k) (dstEquiv : D ≃ D')
    (f : ((k : ι) → C k) → D) :
    NaryBackwardComplete
        (fun k ↦ (domain : AbstractDomain (C' k) (Interval (C' k))).comapEquiv
          (equiv k))
        ((domain : AbstractDomain D' (Interval D')).comapEquiv dstEquiv)
        (NaryConcreteOp.ofTotal f) ↔
      BoundedByCornerImages
        (NaryConcreteOp.transportTotal equiv dstEquiv f) := by
  rw [naryBackwardComplete_transportTotal_iff]
  exact naryBackwardComplete_iff_boundedByCornerImages _

theorem naryForwardComplete_comapEquiv_iff_ordConnected
    {ι : Type*} {C C' : ι → Type u} {D D' : Type v}
    [∀ k, Fintype (C' k)] [∀ k, LinearOrder (C' k)]
    [Fintype D'] [LinearOrder D']
    (equiv : ∀ k, C k ≃ C' k) (dstEquiv : D ≃ D')
    (f : NaryConcreteOp ι C D) :
    NaryForwardComplete
        (fun k ↦ (domain : AbstractDomain (C' k) (Interval (C' k))).comapEquiv
          (equiv k))
        ((domain : AbstractDomain D' (Interval D')).comapEquiv dstEquiv) f ↔
      ∀ a : (k : ι) → Interval (C' k),
        (NaryConcreteOp.lift (NaryConcreteOp.transport equiv dstEquiv f)
          fun k ↦ (a k : Set (C' k))).OrdConnected := by
  rw [naryForwardComplete_transport_iff]
  exact naryForwardComplete_iff_ordConnected _

theorem naryBackwardComplete_comapEquiv_iff_boundedByCornerResults
    {ι : Type*} {C C' : ι → Type u} {D D' : Type v}
    [∀ k, Fintype (C' k)] [∀ k, LinearOrder (C' k)]
    [Fintype D'] [LinearOrder D']
    (equiv : ∀ k, C k ≃ C' k) (dstEquiv : D ≃ D')
    (f : NaryConcreteOp ι C D) :
    NaryBackwardComplete
        (fun k ↦ (domain : AbstractDomain (C' k) (Interval (C' k))).comapEquiv
          (equiv k))
        ((domain : AbstractDomain D' (Interval D')).comapEquiv dstEquiv) f ↔
      BoundedByCornerResults (NaryConcreteOp.transport equiv dstEquiv f) := by
  rw [naryBackwardComplete_transport_iff]
  exact naryBackwardComplete_iff_boundedByCornerResults _

end IntervalDomain

/-- A bitvector equipped with its unsigned order. This wrapper keeps the order
local to `UIntRange` instead of installing a global order on `BitVec`. -/
@[ext]
structure UnsignedBitVec (n : Nat) where
  bitvec : BitVec n
deriving DecidableEq

namespace UnsignedBitVec

instance (n : Nat) : LinearOrder (UnsignedBitVec n) :=
  LinearOrder.lift' (fun x ↦ x.bitvec.toNat) fun x y h ↦ by
    have hb : x.bitvec = y.bitvec := BitVec.eq_of_toNat_eq h
    cases x
    cases y
    cases hb
    rfl

@[simp]
theorem le_iff {n : Nat} {x y : UnsignedBitVec n} :
    x ≤ y ↔ x.bitvec.toNat ≤ y.bitvec.toNat :=
  Iff.rfl

/-- Equivalence between ordinary bitvectors and unsigned-ordered values. -/
def equiv (n : Nat) : BitVec n ≃ UnsignedBitVec n where
  toFun := fun x ↦ ⟨x⟩
  invFun := fun x ↦ x.bitvec
  left_inv _ := rfl
  right_inv _ := rfl

instance (n : Nat) : Fintype (UnsignedBitVec n) :=
  Fintype.ofEquiv (BitVec n) (equiv n)

@[simp]
theorem equiv_apply (x : BitVec n) : (equiv n x).bitvec = x :=
  rfl

@[simp]
theorem equiv_symm_apply (x : UnsignedBitVec n) : (equiv n).symm x = x.bitvec :=
  rfl

end UnsignedBitVec

/-- A bitvector equipped with its signed order. -/
@[ext]
structure SignedBitVec (n : Nat) where
  bitvec : BitVec n
deriving DecidableEq

namespace SignedBitVec

instance (n : Nat) : LinearOrder (SignedBitVec n) :=
  LinearOrder.lift' (fun x ↦ x.bitvec.toInt) fun x y h ↦ by
    have hb : x.bitvec = y.bitvec := BitVec.eq_of_toInt_eq h
    cases x
    cases y
    cases hb
    rfl

@[simp]
theorem le_iff {n : Nat} {x y : SignedBitVec n} :
    x ≤ y ↔ x.bitvec.toInt ≤ y.bitvec.toInt :=
  Iff.rfl

/-- Equivalence between ordinary bitvectors and signed-ordered values. -/
def equiv (n : Nat) : BitVec n ≃ SignedBitVec n where
  toFun := fun x ↦ ⟨x⟩
  invFun := fun x ↦ x.bitvec
  left_inv _ := rfl
  right_inv _ := rfl

instance (n : Nat) : Fintype (SignedBitVec n) :=
  Fintype.ofEquiv (BitVec n) (equiv n)

@[simp]
theorem equiv_apply (x : BitVec n) : (equiv n x).bitvec = x :=
  rfl

@[simp]
theorem equiv_symm_apply (x : SignedBitVec n) : (equiv n).symm x = x.bitvec :=
  rfl

end SignedBitVec

/-- Non-wrapping intervals in unsigned bitvector order. -/
abbrev UIntRange (n : Nat) := Interval (UnsignedBitVec n)

/-- Non-wrapping intervals in signed bitvector order. -/
abbrev SIntRange (n : Nat) := Interval (SignedBitVec n)

namespace UIntRange

/-- The unsigned integer-range abstract domain over concrete bitvectors. -/
noncomputable def domain (n : Nat) :
    AbstractDomain (BitVec n) (UIntRange n) :=
  (IntervalDomain.domain : AbstractDomain (UnsignedBitVec n) (UIntRange n)).comapEquiv
    (UnsignedBitVec.equiv n)

/-- Express a bitvector operation over values carrying unsigned order. -/
def orderedUnary {n m : Nat} (f : BitVec n → BitVec m) :
    UnsignedBitVec n → UnsignedBitVec m :=
  fun x ↦ ⟨f x.bitvec⟩

/-- Express a heterogeneous bitvector operation over values carrying unsigned
order. -/
def orderedNary {ι : Type*} {width : ι → Nat} {m : Nat}
    (f : ((k : ι) → BitVec (width k)) → BitVec m) :
    ((k : ι) → UnsignedBitVec (width k)) → UnsignedBitVec m :=
  fun x ↦ ⟨f fun k ↦ (x k).bitvec⟩

/-- Express a relational bitvector operation over unsigned-ordered values. -/
def orderedRelational {n m : Nat} (f : ConcreteOp (BitVec n) (BitVec m)) :
    ConcreteOp (UnsignedBitVec n) (UnsignedBitVec m) :=
  ConcreteOp.transport (UnsignedBitVec.equiv n) (UnsignedBitVec.equiv m) f

/-- Express a relational heterogeneous operation over unsigned-ordered
values. -/
def orderedNaryRelational {ι : Type*} {width : ι → Nat} {m : Nat}
    (f : NaryConcreteOp ι (fun k ↦ BitVec (width k)) (BitVec m)) :
    NaryConcreteOp ι (fun k ↦ UnsignedBitVec (width k))
      (UnsignedBitVec m) :=
  NaryConcreteOp.transport (fun k ↦ UnsignedBitVec.equiv (width k))
    (UnsignedBitVec.equiv m) f

@[simp]
private theorem transportUnary_eq_orderedUnary {n m : Nat}
    (f : BitVec n → BitVec m) :
    AbstractDomain.transportUnary (UnsignedBitVec.equiv n)
      (UnsignedBitVec.equiv m) f = orderedUnary f := by
  rfl

@[simp]
theorem transportTotal_eq_orderedNary {ι : Type*}
    {width : ι → Nat} {m : Nat}
    (f : ((k : ι) → BitVec (width k)) → BitVec m) :
    NaryConcreteOp.transportTotal
        (fun k ↦ UnsignedBitVec.equiv (width k))
        (UnsignedBitVec.equiv m) f = orderedNary f := by
  rfl

/-- Construct the nonempty unsigned interval `[lower, upper]`. -/
def ofBounds {n : Nat} (lower upper : BitVec n) (h : lower.toNat ≤ upper.toNat) :
    UIntRange n :=
  ((⟨(⟨lower⟩, ⟨upper⟩), h⟩ : NonemptyInterval (UnsignedBitVec n)) :
    UIntRange n)

@[simp]
theorem mem_concretize_ofBounds {n : Nat} {lower upper x : BitVec n}
    {h : lower.toNat ≤ upper.toNat} :
    x ∈ (domain n).concretize (ofBounds lower upper h) ↔
      lower.toNat ≤ x.toNat ∧ x.toNat ≤ upper.toNat :=
  Iff.rfl



/-- Direct characterization of forward completeness for ordinary bitvector
operations in `UIntRange`. -/
theorem forwardComplete_ofTotal_iff_ordConnected {n m : Nat}
    (f : BitVec n → BitVec m) :
    ForwardComplete (domain n) (domain m)
        (ConcreteOp.ofTotal f) ↔
      ∀ i : UIntRange n,
        (orderedUnary f '' (i : Set (UnsignedBitVec n))).OrdConnected := by
  simpa only [domain, transportUnary_eq_orderedUnary] using
    (IntervalDomain.forwardComplete_comapEquiv_ofTotal_iff_ordConnected
      (UnsignedBitVec.equiv n) (UnsignedBitVec.equiv m) f)

/-- Direct characterization of backward completeness for ordinary bitvector
operations in `UIntRange`. -/
theorem backwardComplete_ofTotal_iff_boundedByEndpointImages {n m : Nat}
    (f : BitVec n → BitVec m) :
    BackwardComplete (domain n) (domain m)
        (ConcreteOp.ofTotal f) ↔
      IntervalDomain.BoundedByEndpointImages (orderedUnary f) := by
  simpa only [domain, transportUnary_eq_orderedUnary] using
    (IntervalDomain.backwardComplete_comapEquiv_ofTotal_iff_boundedByEndpointImages
      (UnsignedBitVec.equiv n) (UnsignedBitVec.equiv m) f)

/-- An unsigned-monotone total bitvector operation is backward complete in
`UIntRange`. -/
theorem backwardComplete_of_monotone {n m : Nat}
    (f : BitVec n → BitVec m) (hf : Monotone (orderedUnary f)) :
    BackwardComplete (domain n) (domain m) (ConcreteOp.ofTotal f) := by
  simp only [domain]
  rw [backwardComplete_transportTotal_iff]
  simpa only [transportUnary_eq_orderedUnary] using
    (IntervalDomain.backwardComplete_of_monotone (orderedUnary f) hf)

/-- Direct no-gap characterization for unary relational and partial
bitvector operations in `UIntRange`. -/
theorem forwardComplete_iff_ordConnected {n m : Nat}
    (f : ConcreteOp (BitVec n) (BitVec m)) :
    ForwardComplete (domain n) (domain m) f ↔
      ∀ i : UIntRange n,
        (ConcreteOp.lift (orderedRelational f)
          (i : Set (UnsignedBitVec n))).OrdConnected := by
  simpa [domain, orderedRelational] using
    (IntervalDomain.forwardComplete_comapEquiv_iff_ordConnected
      (UnsignedBitVec.equiv n) (UnsignedBitVec.equiv m) f)

/-- Direct endpoint-result characterization for unary relational and partial
bitvector operations in `UIntRange`. -/
theorem backwardComplete_iff_boundedByEndpointResults {n m : Nat}
    (f : ConcreteOp (BitVec n) (BitVec m)) :
    BackwardComplete (domain n) (domain m) f ↔
      IntervalDomain.BoundedByEndpointResults (orderedRelational f) := by
  simpa [domain, orderedRelational] using
    (IntervalDomain.backwardComplete_comapEquiv_iff_boundedByEndpointResults
      (UnsignedBitVec.equiv n) (UnsignedBitVec.equiv m) f)

/-- Direct no-gap characterization for independent unsigned-range operands. -/
theorem naryForwardComplete_ofTotal_iff_ordConnected
    {ι : Type*} {width : ι → Nat} {m : Nat}
    (f : ((k : ι) → BitVec (width k)) → BitVec m) :
    NaryForwardComplete (fun k ↦ domain (width k)) (domain m)
        (NaryConcreteOp.ofTotal f) ↔
      ∀ a : (k : ι) → UIntRange (width k),
        (NaryConcreteOp.lift (NaryConcreteOp.ofTotal (orderedNary f))
          fun k ↦ (a k : Set (UnsignedBitVec (width k)))).OrdConnected := by
  simpa only [domain, transportTotal_eq_orderedNary] using
    (IntervalDomain.naryForwardComplete_comapEquiv_ofTotal_iff_ordConnected
      (fun k ↦ UnsignedBitVec.equiv (width k))
      (UnsignedBitVec.equiv m) f)

/-- Direct corner characterization for independent unsigned-range operands. -/
theorem naryBackwardComplete_ofTotal_iff_boundedByCornerImages
    {ι : Type*} {width : ι → Nat} {m : Nat}
    (f : ((k : ι) → BitVec (width k)) → BitVec m) :
    NaryBackwardComplete (fun k ↦ domain (width k)) (domain m)
        (NaryConcreteOp.ofTotal f) ↔
      IntervalDomain.BoundedByCornerImages (orderedNary f) := by
  simpa only [domain, transportTotal_eq_orderedNary] using
    (IntervalDomain.naryBackwardComplete_comapEquiv_ofTotal_iff_boundedByCornerImages
      (fun k ↦ UnsignedBitVec.equiv (width k))
      (UnsignedBitVec.equiv m) f)

/-- Coordinatewise unsigned monotonicity, with one direction per operand,
implies backward completeness in `UIntRange`. -/
theorem naryBackwardComplete_of_monotoneWithVariances
    {I : Type*} {width : I → Nat} {m : Nat}
    (variance : I → IntervalDomain.OrderVariance)
    (f : ((k : I) → BitVec (width k)) → BitVec m)
    (hf : IntervalDomain.MonotoneWithVariances variance (orderedNary f)) :
    NaryBackwardComplete (fun k ↦ domain (width k)) (domain m)
      (NaryConcreteOp.ofTotal f) := by
  simp only [domain]
  rw [naryBackwardComplete_transportTotal_iff]
  simpa only [transportTotal_eq_orderedNary] using
    (IntervalDomain.naryBackwardComplete_of_monotoneWithVariances
      variance (orderedNary f) hf)

/-- Direct no-gap characterization for relational and partial operations on
independent unsigned-range operands. -/
theorem naryForwardComplete_iff_ordConnected
    {ι : Type*} {width : ι → Nat} {m : Nat}
    (f : NaryConcreteOp ι (fun k ↦ BitVec (width k)) (BitVec m)) :
    NaryForwardComplete (fun k ↦ domain (width k)) (domain m) f ↔
      ∀ a : (k : ι) → UIntRange (width k),
        (NaryConcreteOp.lift (orderedNaryRelational f)
          fun k ↦ (a k : Set (UnsignedBitVec (width k)))).OrdConnected := by
  simpa [domain, orderedNaryRelational] using
    (IntervalDomain.naryForwardComplete_comapEquiv_iff_ordConnected
      (fun k ↦ UnsignedBitVec.equiv (width k))
      (UnsignedBitVec.equiv m) f)

/-- Direct corner-result characterization for relational and partial
operations on independent unsigned-range operands. -/
theorem naryBackwardComplete_iff_boundedByCornerResults
    {ι : Type*} {width : ι → Nat} {m : Nat}
    (f : NaryConcreteOp ι (fun k ↦ BitVec (width k)) (BitVec m)) :
    NaryBackwardComplete (fun k ↦ domain (width k)) (domain m) f ↔
      IntervalDomain.BoundedByCornerResults (orderedNaryRelational f) := by
  simpa [domain, orderedNaryRelational] using
    (IntervalDomain.naryBackwardComplete_comapEquiv_iff_boundedByCornerResults
      (fun k ↦ UnsignedBitVec.equiv (width k))
      (UnsignedBitVec.equiv m) f)

end UIntRange

namespace SIntRange

/-- The signed integer-range abstract domain over concrete bitvectors. -/
noncomputable def domain (n : Nat) :
    AbstractDomain (BitVec n) (SIntRange n) :=
  (IntervalDomain.domain : AbstractDomain (SignedBitVec n) (SIntRange n)).comapEquiv
    (SignedBitVec.equiv n)

/-- Express a bitvector operation over values carrying signed order. -/
def orderedUnary {n m : Nat} (f : BitVec n → BitVec m) :
    SignedBitVec n → SignedBitVec m :=
  fun x ↦ ⟨f x.bitvec⟩

/-- Express a heterogeneous bitvector operation over values carrying signed
order. -/
def orderedNary {ι : Type*} {width : ι → Nat} {m : Nat}
    (f : ((k : ι) → BitVec (width k)) → BitVec m) :
    ((k : ι) → SignedBitVec (width k)) → SignedBitVec m :=
  fun x ↦ ⟨f fun k ↦ (x k).bitvec⟩

/-- Express a relational bitvector operation over signed-ordered values. -/
def orderedRelational {n m : Nat} (f : ConcreteOp (BitVec n) (BitVec m)) :
    ConcreteOp (SignedBitVec n) (SignedBitVec m) :=
  ConcreteOp.transport (SignedBitVec.equiv n) (SignedBitVec.equiv m) f

/-- Express a relational heterogeneous operation over signed-ordered values. -/
def orderedNaryRelational {ι : Type*} {width : ι → Nat} {m : Nat}
    (f : NaryConcreteOp ι (fun k ↦ BitVec (width k)) (BitVec m)) :
    NaryConcreteOp ι (fun k ↦ SignedBitVec (width k)) (SignedBitVec m) :=
  NaryConcreteOp.transport (fun k ↦ SignedBitVec.equiv (width k))
    (SignedBitVec.equiv m) f

@[simp]
private theorem transportUnary_eq_orderedUnary {n m : Nat}
    (f : BitVec n → BitVec m) :
    AbstractDomain.transportUnary (SignedBitVec.equiv n)
      (SignedBitVec.equiv m) f = orderedUnary f := by
  rfl

@[simp]
theorem transportTotal_eq_orderedNary {ι : Type*}
    {width : ι → Nat} {m : Nat}
    (f : ((k : ι) → BitVec (width k)) → BitVec m) :
    NaryConcreteOp.transportTotal
        (fun k ↦ SignedBitVec.equiv (width k))
        (SignedBitVec.equiv m) f = orderedNary f := by
  rfl

/-- Construct the nonempty signed interval `[lower, upper]`. -/
def ofBounds {n : Nat} (lower upper : BitVec n) (h : lower.toInt ≤ upper.toInt) :
    SIntRange n :=
  ((⟨(⟨lower⟩, ⟨upper⟩), h⟩ : NonemptyInterval (SignedBitVec n)) :
    SIntRange n)

@[simp]
theorem mem_concretize_ofBounds {n : Nat} {lower upper x : BitVec n}
    {h : lower.toInt ≤ upper.toInt} :
    x ∈ (domain n).concretize (ofBounds lower upper h) ↔
      lower.toInt ≤ x.toInt ∧ x.toInt ≤ upper.toInt :=
  Iff.rfl



/-- Direct characterization of forward completeness for ordinary bitvector
operations in `SIntRange`. -/
theorem forwardComplete_ofTotal_iff_ordConnected {n m : Nat}
    (f : BitVec n → BitVec m) :
    ForwardComplete (domain n) (domain m)
        (ConcreteOp.ofTotal f) ↔
      ∀ i : SIntRange n,
        (orderedUnary f '' (i : Set (SignedBitVec n))).OrdConnected := by
  simpa only [domain, transportUnary_eq_orderedUnary] using
    (IntervalDomain.forwardComplete_comapEquiv_ofTotal_iff_ordConnected
      (SignedBitVec.equiv n) (SignedBitVec.equiv m) f)

/-- Direct characterization of backward completeness for ordinary bitvector
operations in `SIntRange`. -/
theorem backwardComplete_ofTotal_iff_boundedByEndpointImages {n m : Nat}
    (f : BitVec n → BitVec m) :
    BackwardComplete (domain n) (domain m)
        (ConcreteOp.ofTotal f) ↔
      IntervalDomain.BoundedByEndpointImages (orderedUnary f) := by
  simpa only [domain, transportUnary_eq_orderedUnary] using
    (IntervalDomain.backwardComplete_comapEquiv_ofTotal_iff_boundedByEndpointImages
      (SignedBitVec.equiv n) (SignedBitVec.equiv m) f)

/-- A signed-monotone total bitvector operation is backward complete in
`SIntRange`. -/
theorem backwardComplete_of_monotone {n m : Nat}
    (f : BitVec n → BitVec m) (hf : Monotone (orderedUnary f)) :
    BackwardComplete (domain n) (domain m) (ConcreteOp.ofTotal f) := by
  simp only [domain]
  rw [backwardComplete_transportTotal_iff]
  simpa only [transportUnary_eq_orderedUnary] using
    (IntervalDomain.backwardComplete_of_monotone (orderedUnary f) hf)

/-- A signed-antitone total bitvector operation is backward complete in
`SIntRange`. -/
theorem backwardComplete_of_antitone {n m : Nat}
    (f : BitVec n → BitVec m) (hf : Antitone (orderedUnary f)) :
    BackwardComplete (domain n) (domain m) (ConcreteOp.ofTotal f) := by
  simp only [domain]
  rw [backwardComplete_transportTotal_iff]
  simpa only [transportUnary_eq_orderedUnary] using
    (IntervalDomain.backwardComplete_of_antitone (orderedUnary f) hf)

/-- Direct no-gap characterization for unary relational and partial
bitvector operations in `SIntRange`. -/
theorem forwardComplete_iff_ordConnected {n m : Nat}
    (f : ConcreteOp (BitVec n) (BitVec m)) :
    ForwardComplete (domain n) (domain m) f ↔
      ∀ i : SIntRange n,
        (ConcreteOp.lift (orderedRelational f)
          (i : Set (SignedBitVec n))).OrdConnected := by
  simpa [domain, orderedRelational] using
    (IntervalDomain.forwardComplete_comapEquiv_iff_ordConnected
      (SignedBitVec.equiv n) (SignedBitVec.equiv m) f)

/-- Direct endpoint-result characterization for unary relational and partial
bitvector operations in `SIntRange`. -/
theorem backwardComplete_iff_boundedByEndpointResults {n m : Nat}
    (f : ConcreteOp (BitVec n) (BitVec m)) :
    BackwardComplete (domain n) (domain m) f ↔
      IntervalDomain.BoundedByEndpointResults (orderedRelational f) := by
  simpa [domain, orderedRelational] using
    (IntervalDomain.backwardComplete_comapEquiv_iff_boundedByEndpointResults
      (SignedBitVec.equiv n) (SignedBitVec.equiv m) f)

/-- Direct no-gap characterization for independent signed-range operands. -/
theorem naryForwardComplete_ofTotal_iff_ordConnected
    {ι : Type*} {width : ι → Nat} {m : Nat}
    (f : ((k : ι) → BitVec (width k)) → BitVec m) :
    NaryForwardComplete (fun k ↦ domain (width k)) (domain m)
        (NaryConcreteOp.ofTotal f) ↔
      ∀ a : (k : ι) → SIntRange (width k),
        (NaryConcreteOp.lift (NaryConcreteOp.ofTotal (orderedNary f))
          fun k ↦ (a k : Set (SignedBitVec (width k)))).OrdConnected := by
  simpa only [domain, transportTotal_eq_orderedNary] using
    (IntervalDomain.naryForwardComplete_comapEquiv_ofTotal_iff_ordConnected
      (fun k ↦ SignedBitVec.equiv (width k))
      (SignedBitVec.equiv m) f)

/-- Coordinatewise signed monotonicity, with one direction per operand,
implies backward completeness in `SIntRange`. -/
theorem naryBackwardComplete_of_monotoneWithVariances
    {I : Type*} {width : I → Nat} {m : Nat}
    (variance : I → IntervalDomain.OrderVariance)
    (f : ((k : I) → BitVec (width k)) → BitVec m)
    (hf : IntervalDomain.MonotoneWithVariances variance (orderedNary f)) :
    NaryBackwardComplete (fun k ↦ domain (width k)) (domain m)
      (NaryConcreteOp.ofTotal f) := by
  simp only [domain]
  rw [naryBackwardComplete_transportTotal_iff]
  simpa only [transportTotal_eq_orderedNary] using
    (IntervalDomain.naryBackwardComplete_of_monotoneWithVariances
      variance (orderedNary f) hf)

/-- Direct corner characterization for independent signed-range operands. -/
theorem naryBackwardComplete_ofTotal_iff_boundedByCornerImages
    {ι : Type*} {width : ι → Nat} {m : Nat}
    (f : ((k : ι) → BitVec (width k)) → BitVec m) :
    NaryBackwardComplete (fun k ↦ domain (width k)) (domain m)
        (NaryConcreteOp.ofTotal f) ↔
      IntervalDomain.BoundedByCornerImages (orderedNary f) := by
  simpa only [domain, transportTotal_eq_orderedNary] using
    (IntervalDomain.naryBackwardComplete_comapEquiv_ofTotal_iff_boundedByCornerImages
      (fun k ↦ SignedBitVec.equiv (width k))
      (SignedBitVec.equiv m) f)

/-- Direct no-gap characterization for relational and partial operations on
independent signed-range operands. -/
theorem naryForwardComplete_iff_ordConnected
    {ι : Type*} {width : ι → Nat} {m : Nat}
    (f : NaryConcreteOp ι (fun k ↦ BitVec (width k)) (BitVec m)) :
    NaryForwardComplete (fun k ↦ domain (width k)) (domain m) f ↔
      ∀ a : (k : ι) → SIntRange (width k),
        (NaryConcreteOp.lift (orderedNaryRelational f)
          fun k ↦ (a k : Set (SignedBitVec (width k)))).OrdConnected := by
  simpa [domain, orderedNaryRelational] using
    (IntervalDomain.naryForwardComplete_comapEquiv_iff_ordConnected
      (fun k ↦ SignedBitVec.equiv (width k))
      (SignedBitVec.equiv m) f)

/-- Direct corner-result characterization for relational and partial
operations on independent signed-range operands. -/
theorem naryBackwardComplete_iff_boundedByCornerResults
    {ι : Type*} {width : ι → Nat} {m : Nat}
    (f : NaryConcreteOp ι (fun k ↦ BitVec (width k)) (BitVec m)) :
    NaryBackwardComplete (fun k ↦ domain (width k)) (domain m) f ↔
      IntervalDomain.BoundedByCornerResults (orderedNaryRelational f) := by
  simpa [domain, orderedNaryRelational] using
    (IntervalDomain.naryBackwardComplete_comapEquiv_iff_boundedByCornerResults
      (fun k ↦ SignedBitVec.equiv (width k))
      (SignedBitVec.equiv m) f)

end SIntRange

end SynthXfer
