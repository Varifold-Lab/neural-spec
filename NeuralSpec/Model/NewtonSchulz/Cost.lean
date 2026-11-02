import Mathlib.Algebra.Order.Ring.Nat

/-! Dense matrix multiplication cost with two FLOPs per inner-product term.
This model counts only matrix multiplications, not elapsed time, scalar operations,
normalization, storage, data movement, or communication. -/

namespace NeuralSpec.NewtonSchulz

/-- Multiplying a `p × q` matrix by a `q × r` matrix in the stipulated FLOPs model. -/
def matmulFlops (p q r : ℕ) : ℕ := 2 * p * q * r

/-- Input shape is `m × n`; the Gram matrix has shape `m × m`. -/
def factoredStepMatmulFlops (m n : ℕ) : ℕ :=
  matmulFlops m n m + matmulFlops m m m + matmulFlops m m n

def expandedStepMatmulFlops (m n : ℕ) : ℕ :=
  matmulFlops m n m + matmulFlops m m n + matmulFlops m m n

end NeuralSpec.NewtonSchulz
