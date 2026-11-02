import NeuralSpec.Model.NewtonSchulz
import Mathlib.Topology.Algebra.Ring.Real
import Mathlib.Tactic.NormNum
import Mathlib.Tactic.Linarith
import Mathlib.Tactic.Ring

/-! Matrix factorization and boundary results for the exact-real quintic iteration.
The factorization hypotheses state orthonormal columns, not an optimizer guarantee.
No theorem here concerns bfloat16, GPU execution, or training loss. -/

namespace NeuralSpec.NewtonSchulz

open Matrix Filter Topology

variable {m n r : Type*} [Fintype m] [Fintype n] [Fintype r]
  [DecidableEq r]

theorem scalarStep_zero (q : Coefficients) : scalarStep q 0 = 0 := by
  simp [scalarStep]

theorem scalarIterate_zero (q : Coefficients) (k : ℕ) : scalarIterate q k 0 = 0 := by
  induction k with
  | zero => rfl
  | succ k ih => simp [scalarIterate, ih, scalarStep_zero]

theorem matrixStep_zero (q : Coefficients) :
    matrixStep q (0 : Matrix m n ℝ) = 0 := by
  simp [matrixStep]

theorem matrixIterate_zero (q : Coefficients) (k : ℕ) :
    matrixIterate q k (0 : Matrix m n ℝ) = 0 := by
  induction k with
  | zero => rfl
  | succ k ih => simp [matrixIterate, ih, matrixStep_zero]

/-- Transposing a tall input and transposing back gives the same exact-real step. -/
theorem matrixStep_transpose (q : Coefficients) (X : Matrix m n ℝ) :
    matrixStep q X.transpose = (matrixStep q X).transpose := by
  simp only [matrixStep, transpose_add, transpose_smul, transpose_mul,
    transpose_transpose, Matrix.add_mul, Matrix.smul_mul, Matrix.mul_assoc]

/-- Both evaluation schemes compute the same matrix polynomial over exact reals. -/
theorem matrixStep_eq_expanded (q : Coefficients) (X : Matrix m n ℝ) :
    matrixStep q X = expandedMatrixStep q X := by
  simp only [matrixStep, expandedMatrixStep, Matrix.add_mul, Matrix.smul_mul,
    Matrix.mul_assoc, add_assoc]

theorem matrixIterate_transpose (q : Coefficients) (k : ℕ) (X : Matrix m n ℝ) :
    matrixIterate q k X.transpose = (matrixIterate q k X).transpose := by
  induction k with
  | zero => rfl
  | succ k ih => simp only [matrixIterate, ih, matrixStep_transpose]

/-- The iteration cannot create an update in a direction annihilated by the input. -/
theorem matrixStep_preserves_kernel (q : Coefficients) (X : Matrix m n ℝ)
    (v : n → ℝ) (hv : X *ᵥ v = 0) : matrixStep q X *ᵥ v = 0 := by
  simp [matrixStep, Matrix.add_mulVec, Matrix.smul_mulVec,
    ← Matrix.mulVec_mulVec, hv]

theorem matrixIterate_preserves_kernel (q : Coefficients) (k : ℕ)
    (X : Matrix m n ℝ) (v : n → ℝ) (hv : X *ᵥ v = 0) :
    matrixIterate q k X *ᵥ v = 0 := by
  induction k with
  | zero => exact hv
  | succ k ih => exact matrixStep_preserves_kernel q _ v ih

omit [Fintype n] in
private theorem framed_mul (U : Matrix m r ℝ) (V : Matrix n r ℝ)
    (D E : Matrix r r ℝ) (hU : U.transpose * U = 1) :
    (U * D * U.transpose) * (U * E * V.transpose) = U * (D * E) * V.transpose := by
  calc
    _ = U * D * (U.transpose * U) * E * V.transpose := by
      simp only [Matrix.mul_assoc]
    _ = _ := by rw [hU]; simp only [Matrix.mul_one, Matrix.mul_assoc]

/-- A supplied thin SVD frame reduces one matrix step to a scalar polynomial.
Nonnegative diagonal entries are only needed to interpret them as singular values. -/
theorem matrixStep_factorization (q : Coefficients)
    (U : Matrix m r ℝ) (V : Matrix n r ℝ) (s : r → ℝ)
    (hU : U.transpose * U = 1) (hV : V.transpose * V = 1) :
    matrixStep q (U * diagonal s * V.transpose) =
      U * diagonal (fun i => scalarStep q (s i)) * V.transpose := by
  let D := diagonal s
  have gram : (U * D * V.transpose) * (U * D * V.transpose).transpose =
      U * (D * D) * U.transpose := by
    calc
      _ = U * D * (V.transpose * V) * D * U.transpose := by
        simp only [D, transpose_mul, transpose_transpose, diagonal_transpose,
          Matrix.mul_assoc]
      _ = _ := by rw [hV]; simp only [Matrix.mul_one, Matrix.mul_assoc]
  have gramSq : (U * (D * D) * U.transpose) * (U * (D * D) * U.transpose) =
      U * ((D * D) * (D * D)) * U.transpose := framed_mul U U _ _ hU
  change q.a • (U * D * V.transpose) +
    (q.b • ((U * D * V.transpose) * (U * D * V.transpose).transpose) +
      q.c • (((U * D * V.transpose) * (U * D * V.transpose).transpose) *
        ((U * D * V.transpose) * (U * D * V.transpose).transpose))) *
          (U * D * V.transpose) = _
  rw [gram, gramSq, Matrix.add_mul, Matrix.smul_mul, Matrix.smul_mul,
    framed_mul U V _ _ hU, framed_mul U V _ _ hU]
  have diagPoly : q.a • D + q.b • ((D * D) * D) +
      q.c • (((D * D) * (D * D)) * D) =
        diagonal (fun i => scalarStep q (s i)) := by
    ext i j
    by_cases hij : i = j
    · subst j
      simp only [D, Matrix.add_apply, Matrix.smul_apply, diagonal_mul_diagonal,
        diagonal_apply_eq, smul_eq_mul, scalarStep]
      ring
    · simp [D, diagonal_mul_diagonal, diagonal_apply_ne _ hij]
  rw [← diagPoly]
  simp only [Matrix.mul_add, Matrix.add_mul, Matrix.mul_smul, Matrix.smul_mul,
    add_assoc]

/-- The same orthonormal frame works for any finite number of steps. -/
theorem matrixIterate_factorization (q : Coefficients) (k : ℕ)
    (U : Matrix m r ℝ) (V : Matrix n r ℝ) (s : r → ℝ)
    (hU : U.transpose * U = 1) (hV : V.transpose * V = 1) :
    matrixIterate q k (U * diagonal s * V.transpose) =
      U * diagonal (fun i => scalarIterate q k (s i)) * V.transpose := by
  induction k with
  | zero => rfl
  | succ k ih =>
    rw [matrixIterate, ih, matrixStep_factorization q U V _ hU hV]
    rfl

theorem continuous_scalarStep (q : Coefficients) : Continuous (scalarStep q) := by
  exact ((continuous_const.mul continuous_id).add
    (continuous_const.mul (continuous_id.pow 3))).add
      (continuous_const.mul (continuous_id.pow 5))

theorem continuous_scalarIterate (q : Coefficients) (k : ℕ) :
    Continuous (scalarIterate q k) := by
  induction k with
  | zero => exact continuous_id
  | succ k ih => exact (continuous_scalarStep q).comp ih

/-- No finite step count gives a uniform positive output bound on all of (0, 1]. -/
theorem exists_small_positive_input (q : Coefficients) (k : ℕ) (ε : ℝ) (hε : 0 < ε) :
    ∃ x : ℝ, 0 < x ∧ x ≤ 1 ∧ |scalarIterate q k x| < ε := by
  obtain ⟨δ, hδ, hnear⟩ := Metric.continuousAt_iff.mp
    (continuous_scalarIterate q k).continuousAt ε hε
  let x := min δ 1 / 2
  have hmin : 0 < min δ 1 := lt_min hδ (by norm_num)
  have hx : 0 < x := by dsimp [x]; linarith
  have hxd : x < δ := by
    have := min_le_left δ (1 : ℝ)
    dsimp [x]
    linarith
  have hx1 : x ≤ 1 := by
    have := min_le_right δ (1 : ℝ)
    dsimp [x]
    linarith
  have hd : dist x 0 < δ := by simpa [Real.dist_eq, abs_of_pos hx] using hxd
  refine ⟨x, hx, hx1, ?_⟩
  simpa [Real.dist_eq, scalarIterate_zero] using hnear hd

/-- Any limit of the scalar iteration must be a fixed point. -/
theorem scalarIterate_limit_fixed (q : Coefficients) (x l : ℝ)
    (h : Tendsto (fun k => scalarIterate q k x) atTop (𝓝 l)) : scalarStep q l = l := by
  have hstep := ((continuous_scalarStep q).tendsto l).comp h
  have hshift := h.comp (tendsto_add_atTop_nat 1)
  change Tendsto (fun k => scalarIterate q (k + 1) x) atTop
    (𝓝 (scalarStep q l)) at hstep
  exact tendsto_nhds_unique hstep hshift

end NeuralSpec.NewtonSchulz
