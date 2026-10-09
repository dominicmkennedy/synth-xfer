import SynthXfer.Interval

/-!
# Arithmetic inside integer boxes
-/

namespace SynthXfer.IntBox

theorem exists_add
    {x₁ x₂ y₁ y₂ z : Int}
    (hlower : x₁ + y₁ ≤ z) (hupper : z ≤ x₂ + y₂) :
    ∃ x y,
      min x₁ x₂ ≤ x ∧ x ≤ max x₁ x₂ ∧
      min y₁ y₂ ≤ y ∧ y ≤ max y₁ y₂ ∧ x + y = z := by
  have hlo : min x₁ x₂ + min y₁ y₂ ≤ z := by
    omega
  have hhi : z ≤ max x₁ x₂ + max y₁ y₂ := by
    omega
  by_cases hfirst : z ≤ max x₁ x₂ + min y₁ y₂
  · refine ⟨z - min y₁ y₂, min y₁ y₂, ?_⟩
    omega
  · refine ⟨max x₁ x₂, z - max x₁ x₂, ?_⟩
    omega

theorem exists_sub
    {x₁ x₂ y₁ y₂ z : Int}
    (hlower : x₁ - y₁ ≤ z) (hupper : z ≤ x₂ - y₂) :
    ∃ x y,
      min x₁ x₂ ≤ x ∧ x ≤ max x₁ x₂ ∧
      min y₁ y₂ ≤ y ∧ y ≤ max y₁ y₂ ∧ x - y = z := by
  obtain ⟨x, negY, hx₁, hx₂, hnegY₁, hnegY₂, hsum⟩ :=
    exists_add (x₁ := x₁) (x₂ := x₂) (y₁ := -y₁) (y₂ := -y₂)
      hlower hupper
  exact ⟨x, -negY, hx₁, hx₂, by omega, by omega, by omega⟩

end SynthXfer.IntBox
