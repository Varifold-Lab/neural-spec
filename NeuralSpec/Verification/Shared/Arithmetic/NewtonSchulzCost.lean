import NeuralSpec.Model.NewtonSchulz.Cost
import Mathlib.Tactic.Ring
import Mathlib.Tactic.Linarith

/-! Cost comparisons for the two dense matrix evaluation schemes.
These are natural-number theorems in the stipulated FLOPs model, not GPU timings. -/

namespace NeuralSpec.NewtonSchulz

theorem factoredStepMatmulFlops_eq (m n : ℕ) :
    factoredStepMatmulFlops m n = 4 * n * m ^ 2 + 2 * m ^ 3 := by
  simp only [factoredStepMatmulFlops, matmulFlops]
  ring

theorem expandedStepMatmulFlops_eq (m n : ℕ) :
    expandedStepMatmulFlops m n = 6 * n * m ^ 2 := by
  simp only [expandedStepMatmulFlops, matmulFlops]
  ring

theorem factoredStepMatmulFlops_saving (m n : ℕ) (h : m ≤ n) :
    factoredStepMatmulFlops m n + 2 * m ^ 2 * (n - m) =
      expandedStepMatmulFlops m n := by
  obtain ⟨d, rfl⟩ := Nat.exists_eq_add_of_le h
  rw [factoredStepMatmulFlops_eq, expandedStepMatmulFlops_eq, Nat.add_sub_cancel_left]
  ring

theorem factoredStepMatmulFlops_le (m n : ℕ) (h : m ≤ n) :
    factoredStepMatmulFlops m n ≤ expandedStepMatmulFlops m n := by
  have hs := factoredStepMatmulFlops_saving m n h
  omega

end NeuralSpec.NewtonSchulz
