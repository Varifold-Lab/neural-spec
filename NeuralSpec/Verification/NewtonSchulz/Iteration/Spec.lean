import NeuralSpec.Model.NewtonSchulz.Muon

namespace NeuralSpec.NewtonSchulz

open Matrix

/-- Five-step factorization, transpose equivalence, and preservation of the input kernel. -/
def MuonIterationSpec : Prop :=
  (∀ (m n r : ℕ) (U : Matrix (Fin m) (Fin r) ℝ)
      (V : Matrix (Fin n) (Fin r) ℝ) (s : Fin r → ℝ),
    U.transpose * U = 1 → V.transpose * V = 1 →
      muonIteration (U * Matrix.diagonal s * V.transpose) =
        U * Matrix.diagonal (fun i => scalarIterate muonCoefficients muonSteps (s i)) *
          V.transpose) ∧
  (∀ (m n : ℕ) (X : Matrix (Fin m) (Fin n) ℝ),
    muonIteration X.transpose = (muonIteration X).transpose) ∧
  (∀ (m n : ℕ) (X : Matrix (Fin m) (Fin n) ℝ) (v : Fin n → ℝ),
    X *ᵥ v = 0 → muonIteration X *ᵥ v = 0)

end NeuralSpec.NewtonSchulz
