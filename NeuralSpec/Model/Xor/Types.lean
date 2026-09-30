import Mathlib.Basic.Real.Basic

/-! Shared input and output types for the XOR network and its specification. -/

namespace NeuralSpec.Xor

abbrev Point := ℝ × ℝ
abbrev Network := Point → Fin 2 → ℝ

end NeuralSpec.Xor
