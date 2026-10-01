/-! Scalar operations used to interpret ReLU MLP computations. -/

namespace NeuralSpec.MLP

/-- Arithmetic operations only; numerical laws belong in verification. -/
structure ScalarOps (α : Type) where
  add : α → α → α
  mul : α → α → α
  relu : α → α

end NeuralSpec.MLP
