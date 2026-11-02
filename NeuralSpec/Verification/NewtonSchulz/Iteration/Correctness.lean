import NeuralSpec.Verification.NewtonSchulz.Iteration.Spec
import NeuralSpec.Verification.Shared.Arithmetic.NewtonSchulz

/-! The five-step Muon instance satisfies its exact-real iteration specification.
The scalar boundary theorems delimit claims of exact orthogonalization. -/

namespace NeuralSpec.NewtonSchulz

open Filter Topology

theorem muonIteration_satisfies_spec : MuonIterationSpec := by
  refine ⟨?_, ?_, ?_⟩
  · intro m n r U V s hU hV
    exact matrixIterate_factorization muonCoefficients muonSteps U V s hU hV
  · intro m n X
    exact matrixIterate_transpose muonCoefficients muonSteps X
  · intro m n X v hv
    exact matrixIterate_preserves_kernel muonCoefficients muonSteps X v hv

theorem muon_one : scalarStep muonCoefficients 1 = 701 / 1000 := by
  norm_num [scalarStep, muonCoefficients]

/-- The tuned coefficients cannot have exact-unit limit, for any initial scalar. -/
theorem muon_not_tendsto_one (x : ℝ) :
    ¬ Tendsto (fun k => scalarIterate muonCoefficients k x) atTop (𝓝 1) := by
  intro h
  have hf := scalarIterate_limit_fixed muonCoefficients x 1 h
  rw [muon_one] at hf
  norm_num at hf

end NeuralSpec.NewtonSchulz
