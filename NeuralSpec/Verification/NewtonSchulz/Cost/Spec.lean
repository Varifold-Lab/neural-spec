import NeuralSpec.Model.NewtonSchulz.Muon

namespace NeuralSpec.NewtonSchulz

/-- Matrix multiplication cost after orienting the input with at most as many rows as columns. -/
def MuonCostSpec : Prop :=
  ∀ m n : ℕ, m ≤ n → muonMatmulFlops m n ≤ 30 * n * m ^ 2

end NeuralSpec.NewtonSchulz
