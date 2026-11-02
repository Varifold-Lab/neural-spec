import NeuralSpec.Model.NewtonSchulz
import NeuralSpec.Model.NewtonSchulz.Cost

/-! The five-step Muon instance, with exact rational decimal coefficients.
Only the iteration core is modeled, starting from a supplied real matrix. -/

namespace NeuralSpec.NewtonSchulz

/-- Coefficients in Keller Jordan's Muon article (December 2024). -/
noncomputable def muonCoefficients : Coefficients :=
  ⟨34445 / 10000, -47750 / 10000, 20315 / 10000⟩

def muonSteps : ℕ := 5

noncomputable def muonIteration {m n : Type*} [Fintype m] [Fintype n]
    (X : Matrix m n ℝ) : Matrix m n ℝ :=
  matrixIterate muonCoefficients muonSteps X

def muonMatmulFlops (m n : ℕ) : ℕ :=
  muonSteps * factoredStepMatmulFlops m n

end NeuralSpec.NewtonSchulz
