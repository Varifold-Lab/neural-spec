import Mathlib.Data.Matrix.Basic
import Mathlib.Basic.Real.Basic

/-! Generic exact-real quintic matrix iteration. Normalization and floating-point
execution are outside this model. Concrete coefficients are defined separately. -/

namespace NeuralSpec.NewtonSchulz

structure Coefficients where
  a : ℝ
  b : ℝ
  c : ℝ

def scalarStep (q : Coefficients) (x : ℝ) : ℝ :=
  q.a * x + q.b * x ^ 3 + q.c * x ^ 5

def scalarIterate (q : Coefficients) : ℕ → ℝ → ℝ
  | 0, x => x
  | k + 1, x => scalarStep q (scalarIterate q k x)

def matrixStep {m n : Type*} [Fintype m] [Fintype n]
    (q : Coefficients) (X : Matrix m n ℝ) : Matrix m n ℝ :=
  let A := X * X.transpose
  q.a • X + (q.b • A + q.c • (A * A)) * X

/-- Alternative evaluation using a shared cubic term instead of squaring the Gram matrix. -/
def expandedMatrixStep {m n : Type*} [Fintype m] [Fintype n]
    (q : Coefficients) (X : Matrix m n ℝ) : Matrix m n ℝ :=
  let A := X * X.transpose
  let Y := A * X
  q.a • X + q.b • Y + q.c • (A * Y)

def matrixIterate {m n : Type*} [Fintype m] [Fintype n]
    (q : Coefficients) : ℕ → Matrix m n ℝ → Matrix m n ℝ
  | 0, X => X
  | k + 1, X => matrixStep q (matrixIterate q k X)

end NeuralSpec.NewtonSchulz
