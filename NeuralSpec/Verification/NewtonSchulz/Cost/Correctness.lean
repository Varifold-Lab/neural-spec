import NeuralSpec.Verification.NewtonSchulz.Cost.Spec
import NeuralSpec.Verification.Shared.Arithmetic.NewtonSchulzCost

namespace NeuralSpec.NewtonSchulz

theorem muonMatmulFlops_eq (m n : ℕ) :
    muonMatmulFlops m n = 5 * (4 * n * m ^ 2 + 2 * m ^ 3) := by
  rw [muonMatmulFlops, muonSteps, factoredStepMatmulFlops_eq]

theorem muonMatmulFlops_saving (m n : ℕ) (h : m ≤ n) :
    muonMatmulFlops m n + 10 * m ^ 2 * (n - m) =
      5 * expandedStepMatmulFlops m n := by
  have hs := factoredStepMatmulFlops_saving m n h
  simp only [muonMatmulFlops, muonSteps]
  nlinarith

theorem muonCost_satisfies_spec : MuonCostSpec := by
  intro m n h
  have hs := muonMatmulFlops_saving m n h
  rw [expandedStepMatmulFlops_eq] at hs
  nlinarith

end NeuralSpec.NewtonSchulz
