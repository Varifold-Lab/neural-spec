import NeuralSpec.Model.Binary32
import FloatLib.Floats.ExecFloat.Proof.Arithmetic
import Mathlib.Tactic.NormNum
import Mathlib.Tactic.Linarith
import Mathlib.Tactic.Ring
import FloatLib.Floats.Formats.BinaryInterchange.Analysis.Error
import FloatLib.Floats.Formats.Flocq.Theory.Analysis.Ulp
import FloatLib.Floats.Formats.BinaryInterchange.Configured.Value.CoreProof
import Mathlib.Tactic.Positivity

/-!
Reusable bounds for FloatLib binary32 operations, independent of any network.
The local bounds use magnitude at most 128 and rounding error at most 1/1024;
`Approx.mul_parameter` assumes an exact coefficient of magnitude at most 2.
These are explicit premises, not guarantees for arbitrary network sizes or weights.
-/

namespace NeuralSpec

open FloatLib.Floats
open FloatLib.Floats.Formats.BinaryInterchange

noncomputable def binary32Value (x : Binary32) : ℝ :=
  Model.toReal (ExecFloat.Binary.toModel x)

namespace FloatingError

open FloatLib.Floats.Formats.Flocq

theorem round_error (x : ℝ) (hx : |x| ≤ 128) :
    |Model.roundAt FloatFormat.binary32 x - x| ≤ 1 / 1024 := by
  by_cases hzero : x = 0
  · subst x
    rw [Model.roundAt_zero]
    norm_num
  have hu := ulp_mono_pos (β := FloatLib.Numerics.binaryRadix)
    (fexp := Model.fexpOf FloatFormat.binary32) (abs_pos.mpr hzero) hx
  rw [ulp_abs] at hu
  have hp : (128 : ℝ) = bpow FloatLib.Numerics.binaryRadix 7 := by
    norm_num [bpow, FloatLib.Numerics.binaryRadix, FloatLib.Numerics.Radix.toReal]
  rw [hp, ulp_bpow] at hu
  have he := Model.abs_roundAt_sub_le FloatFormat.binary32 x
  unfold Model.epsilonAt Model.ulpAt at he
  norm_num [Model.fexpOf, fltExp, FloatFormat.binary32,
    FloatFormat.minSubnormalExponent, FloatFormat.minNormalExponent,
    FloatFormat.bias, FloatFormat.ieeeMinNormalExponent,
    bpow, FloatLib.Numerics.binaryRadix, FloatLib.Numerics.Radix.toReal] at hu
  change ulp FloatLib.Numerics.binaryRadix (Model.fexpOf FloatFormat.binary32) x ≤
    1 / 65536 at hu
  linarith

theorem toModel_add (x y : Binary32) :
    ExecFloat.Binary.toModel (x + y) =
      Model.add (ExecFloat.Binary.toModel x) (ExecFloat.Binary.toModel y) := by
  change ExecFloat.Binary.toModel (ExecFloat.add x y) = _
  rw [ExecFloat.Proof.add_eq_spec]
  change ExecFloat.Binary.toModel (ExecFloat.Binary.ofModel
    (Model.Spec.add (ExecFloat.Binary.toModel x) (ExecFloat.Binary.toModel y))) = _
  rw [ExecFloat.Binary.toModel_ofModel, Model.Proof.add_eq_spec]

theorem toModel_mul (x y : Binary32) :
    ExecFloat.Binary.toModel (x * y) =
      Model.mul (ExecFloat.Binary.toModel x) (ExecFloat.Binary.toModel y) := by
  change ExecFloat.Binary.toModel (ExecFloat.mul x y) = _
  rw [ExecFloat.Proof.mul_eq_spec]
  change ExecFloat.Binary.toModel (ExecFloat.Binary.ofModel
    (Model.Spec.mul (ExecFloat.Binary.toModel x) (ExecFloat.Binary.toModel y))) = _
  rw [ExecFloat.Binary.toModel_ofModel, Model.Proof.mul_eq_spec]

theorem toModel_sub (x y : Binary32) :
    ExecFloat.Binary.toModel (x - y) =
      Model.sub (ExecFloat.Binary.toModel x) (ExecFloat.Binary.toModel y) := by
  change ExecFloat.Binary.toModel (ExecFloat.sub x y) = _
  rw [ExecFloat.Proof.sub_eq_spec]
  change ExecFloat.Binary.toModel (ExecFloat.Binary.ofModel
    (Model.Spec.sub (ExecFloat.Binary.toModel x) (ExecFloat.Binary.toModel y))) = _
  rw [ExecFloat.Binary.toModel_ofModel, Model.Proof.sub_eq_spec]

theorem maxFinite_bound : (128 : ℝ) ≤ Model.toReal (Model.posMaxFinite FloatFormat.binary32) := by
  rw [Model.toReal_posMaxFinite]
  norm_num [Model.bpow, bpow, FloatLib.Numerics.binaryRadix, FloatLib.Numerics.Radix.toReal,
    Model.pow2, FloatFormat.binary32, FloatFormat.maxFiniteFracField,
    FloatFormat.fracMaskNat, FloatFormat.maxNormalExponent, FloatFormat.maxFiniteExpField,
    FloatFormat.Encoding.maxFiniteExponent]

theorem add_error (x y : Binary32)
    (hx : ExecFloat.Binary.isFinite x = true) (hy : ExecFloat.Binary.isFinite y = true)
    (hbound : |binary32Value x + binary32Value y| ≤ 128) :
    ExecFloat.Binary.isFinite (x + y) = true ∧
      |binary32Value (x + y) - (binary32Value x + binary32Value y)| ≤ 1 / 1024 := by
  have hf := Model.isFinite_add_of_abs_toReal_add_le_posMaxFinite
    (ExecFloat.Binary.toModel x) (ExecFloat.Binary.toModel y) (by decide) hx hy
    (hbound.trans maxFinite_bound)
  constructor
  · simpa only [ExecFloat.Binary.isFinite, toModel_add] using hf
  · unfold binary32Value
    rw [toModel_add, Model.toReal_add_eq_roundAt _ _ (by decide) hx hy hf]
    exact round_error _ hbound

theorem mul_error (x y : Binary32)
    (hx : ExecFloat.Binary.isFinite x = true) (hy : ExecFloat.Binary.isFinite y = true)
    (hbound : |binary32Value x * binary32Value y| ≤ 128) :
    ExecFloat.Binary.isFinite (x * y) = true ∧
      |binary32Value (x * y) - binary32Value x * binary32Value y| ≤ 1 / 1024 := by
  have hf := Model.isFinite_mul_of_abs_mul_le_posMaxFinite
    (ExecFloat.Binary.toModel x) (ExecFloat.Binary.toModel y) (by decide) hx hy
    (by
      change |binary32Value x| * |binary32Value y| ≤ _
      rw [← abs_mul]
      exact hbound.trans maxFinite_bound)
  constructor
  · simpa only [ExecFloat.Binary.isFinite, toModel_mul] using hf
  · unfold binary32Value
    rw [toModel_mul, Model.toReal_mul_eq_roundAt _ _ (by decide) hx hy hf]
    exact round_error _ hbound

theorem sub_error (x y : Binary32)
    (hx : ExecFloat.Binary.isFinite x = true) (hy : ExecFloat.Binary.isFinite y = true)
    (hbound : |binary32Value x| + |binary32Value y| ≤ 128) :
    ExecFloat.Binary.isFinite (x - y) = true ∧
      |binary32Value (x - y) - (binary32Value x - binary32Value y)| ≤ 1 / 1024 := by
  have hf := Model.isFinite_sub_of_abs_add_le_posMaxFinite
    (ExecFloat.Binary.toModel x) (ExecFloat.Binary.toModel y) (by decide) hx hy
    (hbound.trans maxFinite_bound)
  constructor
  · simpa only [ExecFloat.Binary.isFinite, toModel_sub] using hf
  · unfold binary32Value
    rw [toModel_sub, Model.toReal_sub_eq_roundAt _ _ (by decide) hx hy hf]
    exact round_error _ ((abs_sub _ _).trans hbound)

theorem value_of_toRat {x : Binary32} {r : ℚ}
    (h : ExecFloat.Binary.toRat? x = some r) : binary32Value x = (r : ℝ) := by
  unfold ExecFloat.Binary.toRat? Model.toRat? at h
  unfold binary32Value
  rw [Model.toReal_eq]
  cases hd : Model.toDyadic? (ExecFloat.Binary.toModel x) with
  | none => simp [hd] at h
  | some d =>
    simp only [hd, Option.map_some, Option.some.injEq] at h
    change d.toReal = (r : ℝ)
    rw [← FloatLib.Numerics.Dyadic.cast_toRat, h]

theorem finite_of_toRat {x : Binary32} {r : ℚ}
    (h : ExecFloat.Binary.toRat? x = some r) : ExecFloat.Binary.isFinite x = true := by
  cases hd : Model.toDyadic? (ExecFloat.Binary.toModel x) with
  | none => simp [ExecFloat.Binary.toRat?, Model.toRat?, hd] at h
  | some d => exact Model.isFinite_eq_true_of_toDyadic?_some hd

theorem relu_exact (x : Binary32) (hx : ExecFloat.Binary.isFinite x = true) :
    ExecFloat.Binary.isFinite (floatLibRelu x) = true ∧
      binary32Value (floatLibRelu x) = max 0 (binary32Value x) := by
  have hn : ExecFloat.Binary.isNaN x = false :=
    Model.isNaN_eq_false_of_isFinite_eq_true _ hx
  have hz : ExecFloat.Binary.isFinite (ExecFloat.Binary.ofBits32 0) = true := by decide
  have hv : binary32Value (ExecFloat.Binary.ofBits32 0) = 0 :=
    by simpa only [Rat.cast_zero] using
      value_of_toRat (x := ExecFloat.Binary.ofBits32 0) (r := 0) (by decide +kernel)
  have hc : ExecFloat.compareLess (ExecFloat.Binary.ofBits32 0) x = true ↔
      0 < binary32Value x := by
    change (ExecFloat.Binary.ofBits32 0 : Binary32) < x ↔ _
    rw [ExecFloat.Binary.lt_iff_compare_eq_lt,
      Model.compare_eq_some_lt_iff_toReal_lt_of_isFinite _ _ hz hx]
    change binary32Value (ExecFloat.Binary.ofBits32 0) < binary32Value x ↔ _
    rw [hv]
  unfold floatLibRelu
  simp only [hn, Bool.false_eq_true, ↓reduceIte]
  split
  · rename_i hp
    exact ⟨hx, (max_eq_right (le_of_lt (hc.mp hp))).symm⟩
  · rename_i hp
    exact ⟨hz, hv.trans (max_eq_left (le_of_not_gt (fun h => hp (hc.mpr h)))).symm⟩

/-- A finite computed value, an ideal real value, and proved magnitude/error bounds. -/
structure Approx (x : Binary32) (r bound error : ℝ) : Prop where
  finite : ExecFloat.Binary.isFinite x = true
  magnitude : |r| ≤ bound
  accuracy : |binary32Value x - r| ≤ error

theorem Approx.value_bound {x : Binary32} {r b e : ℝ} (h : Approx x r b e) :
    |binary32Value x| ≤ b + e := by
  calc
    |binary32Value x| = |r + (binary32Value x - r)| := by congr 1; ring
    _ ≤ |r| + |binary32Value x - r| := abs_add_le _ _
    _ ≤ b + e := add_le_add h.magnitude h.accuracy

theorem Approx.add {x y : Binary32} {r s b c e f : ℝ}
    (hx : Approx x r b e) (hy : Approx y s c f)
    (hrange : b + c + e + f ≤ 128) :
    Approx (x + y) (r + s) (b + c) (e + f + 1 / 1024) := by
  have hb : |binary32Value x + binary32Value y| ≤ 128 :=
    (abs_add_le _ _).trans (by linarith [hx.value_bound, hy.value_bound])
  obtain ⟨hfin, herr⟩ := add_error x y hx.finite hy.finite hb
  refine ⟨hfin, (abs_add_le _ _).trans (add_le_add hx.magnitude hy.magnitude), ?_⟩
  calc
    |binary32Value (x + y) - (r + s)| =
        |(binary32Value (x + y) - (binary32Value x + binary32Value y)) +
          ((binary32Value x - r) + (binary32Value y - s))| := by congr 1; ring
    _ ≤ |binary32Value (x + y) - (binary32Value x + binary32Value y)| +
          (|binary32Value x - r| + |binary32Value y - s|) :=
      (abs_add_le _ _).trans (add_le_add_right (abs_add_le _ _) _)
    _ ≤ e + f + 1 / 1024 := by linarith [hx.accuracy, hy.accuracy]

theorem Approx.mul_parameter {p x : Binary32} {a r b e : ℝ}
    (hp : Approx p a 2 0) (hx : Approx x r b e)
    (hrange : 2 * (b + e) ≤ 128) :
    Approx (p * x) (a * r) (2 * b) (2 * e + 1 / 1024) := by
  have hpval : binary32Value p = a := sub_eq_zero.mp (abs_nonpos_iff.mp hp.accuracy)
  have he : 0 ≤ e := (abs_nonneg _).trans hx.accuracy
  have hb : |binary32Value p * binary32Value x| ≤ 128 := by
    rw [abs_mul, hpval]
    exact (mul_le_mul hp.magnitude hx.value_bound (abs_nonneg _) (by norm_num)).trans hrange
  obtain ⟨hfin, herr⟩ := mul_error p x hp.finite hx.finite hb
  refine ⟨hfin, ?_, ?_⟩
  · rw [abs_mul]
    exact mul_le_mul hp.magnitude hx.magnitude (abs_nonneg _) (by norm_num)
  · calc
      |binary32Value (p * x) - a * r| =
          |(binary32Value (p * x) - binary32Value p * binary32Value x) +
            a * (binary32Value x - r)| := by rw [hpval]; congr 1; ring
      _ ≤ |binary32Value (p * x) - binary32Value p * binary32Value x| +
            |a * (binary32Value x - r)| := abs_add_le _ _
      _ ≤ 1 / 1024 + 2 * e := by
        rw [abs_mul]
        exact add_le_add herr (mul_le_mul hp.magnitude hx.accuracy (abs_nonneg _) (by norm_num))
      _ = 2 * e + 1 / 1024 := by ring

theorem Approx.relu {x : Binary32} {r b e : ℝ} (hx : Approx x r b e) :
    Approx (floatLibRelu x) (max 0 r) b e := by
  obtain ⟨hfin, hval⟩ := relu_exact x hx.finite
  refine ⟨hfin, ?_, ?_⟩
  · rw [abs_of_nonneg (le_max_left _ _)]
    exact max_le ((abs_nonneg _).trans hx.magnitude) ((le_abs_self _).trans hx.magnitude)
  · rw [hval, max_comm 0, max_comm 0]
    exact (abs_max_sub_max_le_abs _ _ _).trans hx.accuracy

/-- Exact dyadic representation of nearest-even rounding, used only for real-input semantics. -/
noncomputable def roundedDyadic (r : ℝ) : FloatLib.Numerics.Dyadic :=
  FloatLib.Numerics.Dyadic.ofScaledInt
    (nearestEven (scaledMantissa FloatLib.Numerics.binaryRadix
      (Model.fexpOf FloatFormat.binary32) r))
    (cexp FloatLib.Numerics.binaryRadix (Model.fexpOf FloatFormat.binary32) r)

theorem roundedDyadic_value (r : ℝ) :
    (roundedDyadic r).toReal = Model.roundAt FloatFormat.binary32 r := by
  have hs (m e : Int) : (FloatLib.Numerics.Dyadic.ofScaledInt m e).signedSignificand = m := by
    cases m with
    | ofNat n => simp [FloatLib.Numerics.Dyadic.ofScaledInt, FloatLib.Numerics.Dyadic.signedSignificand]
    | negSucc n =>
      simp [FloatLib.Numerics.Dyadic.ofScaledInt, FloatLib.Numerics.Dyadic.signedSignificand]
      omega
  simp only [roundedDyadic, FloatLib.Numerics.Dyadic.toReal, hs]
  rfl

end FloatingError

/-- Mathematical nearest-even conversion of a real input to binary32.
This noncomputable adapter specifies real-input semantics; inference itself remains executable. -/
noncomputable def roundBinary32 (r : ℝ) : Binary32 :=
  ExecFloat.Binary.ofModel (Model.roundDyadic (ExecFloat.Binary.format 8 23) (FloatingError.roundedDyadic r))

namespace FloatingError

open FloatLib.Floats.Formats.Flocq

theorem roundBinary32_spec (r : ℝ) (hr : |r| ≤ 1) :
    ExecFloat.Binary.isFinite (roundBinary32 r) = true ∧
      binary32Value (roundBinary32 r) = Model.roundAt FloatFormat.binary32 r := by
  have herr := round_error r (hr.trans (by norm_num))
  have hb : |(roundedDyadic r).toReal| ≤ Model.toReal (Model.posMaxFinite FloatFormat.binary32) := by
    rw [roundedDyadic_value]
    apply le_trans _ maxFinite_bound
    calc
      |Model.roundAt FloatFormat.binary32 r| =
          |(Model.roundAt FloatFormat.binary32 r - r) + r| := by congr 1; ring
      _ ≤ |Model.roundAt FloatFormat.binary32 r - r| + |r| := abs_add_le _ _
      _ ≤ 128 := by linarith
  have hf := Model.isFinite_roundDyadic_of_isIEEE_of_abs_toReal_le_posMaxFinite
    FloatFormat.binary32 (by decide) (roundedDyadic r) hb
  constructor
  · unfold roundBinary32 ExecFloat.Binary.isFinite
    rw [ExecFloat.Binary.toModel_ofModel, ExecFloat.Binary.format_binary32]
    exact hf
  · unfold binary32Value roundBinary32
    rw [ExecFloat.Binary.toModel_ofModel, ExecFloat.Binary.format_binary32,
      Model.toReal_roundDyadic_eq_roundAt _ (by decide) _ hf, roundedDyadic_value]
    exact round_preserves_generic nearestEven _ (generic_format_round nearestEven r)

end FloatingError
end NeuralSpec
