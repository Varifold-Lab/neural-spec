import NeuralSpec.Verification.Xor.Robustness.Correctness
import NeuralSpec.Verification.Shared.Arithmetic.FloatingError
import NeuralSpec.Network.Xor.FloatLib
import NeuralSpec.Network.Xor.Real
import FloatLib.Floats.Formats.IEEE754.Native.AddSub
import FloatLib.Floats.ExecFloat.Proof.Arithmetic
import Mathlib.Tactic.NormNum

/-!
# Binary32 semantics and the full-domain XOR margin

The first part identifies parameters and operation semantics. The second part
proves the margin throughout the original input regions, including input rounding
and the final score subtraction. Whole-network native arithmetic agreement
remains a separate obligation.
-/

namespace NeuralSpec.Xor

open FloatLib.Floats

/-- Reference operations specified by FloatLib's floating-point format. -/
def floatLibOperationSpecOps : MLP.ScalarOps Binary32 :=
  ⟨ExecFloat.Spec.add, ExecFloat.Spec.mul, floatLibRelu⟩

def floatLibOperationSpecNetwork (x : Binary32 × Binary32) : Fin 2 → Binary32 :=
  forward floatLibOperationSpecOps floatLibParameter x

set_option maxRecDepth 4096 in
set_option maxHeartbeats 2000000 in
/-- All frozen words denote the original exact rational parameters, including zero. -/
theorem floatLib_parameters_exact :
    Checkpoint.sourceBits32.map (fun bits => ExecFloat.Binary.toRat?
      (ExecFloat.Binary.ofBits32 bits)) = Checkpoint.parameters.map some := by
  decide +kernel

set_option maxRecDepth 4096 in
/-- Native construction and FloatLib construction use identical finite parameter words. -/
theorem native_parameters_import_exact :
    ∀ i : Fin 22, ExecFloat.Binary.ofFloat32 (nativeParameter i) = floatLibParameter i := by
  decide +kernel

/-- Conversion from a native value into FloatLib and back loses no native value. -/
theorem native_roundtrip (x : Float32) :
    ExecFloat.Binary.toFloat32 (ExecFloat.Binary.ofFloat32 x) = x :=
  ExecFloat.Binary.toFloat32_ofFloat32 x

/-- The FloatLib forward program uses its specified IEEE addition and multiplication. -/
theorem floatLib_network_eq_operationSpec (x : Binary32 × Binary32) :
    floatLibNetwork x = floatLibOperationSpecNetwork x := by
  have hadd : ((· + ·) : Binary32 → Binary32 → Binary32) = ExecFloat.Spec.add :=
    funext fun x => funext fun y => ExecFloat.Proof.add_eq_spec x y
  have hmul : ((· * ·) : Binary32 → Binary32 → Binary32) = ExecFloat.Spec.mul :=
    funext fun x => funext fun y => ExecFloat.Proof.mul_eq_spec x y
  simp only [floatLibNetwork, floatLibOperationSpecNetwork, floatLibOps, floatLibOperationSpecOps, hadd, hmul]

/-- Available native addition bridge, with its explicit finite-input premises. -/
theorem native_add_import (x y : Float32) (hx : x.isFinite = true) (hy : y.isFinite = true) :
    ExecFloat.Binary.ofFloat32 (x + y) =
      ExecFloat.Binary.ofFloat32 x + ExecFloat.Binary.ofFloat32 y :=
  ExecFloat.Binary.ofFloat32_add_of_isFinite x y hx hy

/-- The shared program, interpreted over the reals, is the already-proved network. -/
theorem forward_real_eq_trainedNetwork (x : Point) (label : Fin 2) :
    forward (⟨(· + ·), (· * ·), max 0⟩ : MLP.ScalarOps ℝ)
      (fun i => ((Checkpoint.parameters[i]?).getD 0 : ℝ)) x label =
      trainedNetwork x label := by
  simp [forward, trainedNetwork, pre0, pre1, pre2, pre3, Checkpoint.parameters]

end NeuralSpec.Xor

/-! ## Uniform margin, including rounding -/

namespace NeuralSpec.Xor

open FloatLib.Floats
open FloatLib.Floats.Formats.BinaryInterchange
open NeuralSpec.FloatingError

namespace FloatingError

private theorem hidden_approx {p q bias x y : Binary32} {a b c r s : ℝ}
    (hp : Approx p a 2 0) (hq : Approx q b 2 0) (hb : Approx bias c 2 0)
    (hx : Approx x r 1 (1 / 1024)) (hy : Approx y s 1 (1 / 1024)) :
    Approx (floatLibRelu ((p * x + q * y) + bias))
      (max 0 ((a * r + b * s) + c)) 6 (1 / 128) := by
  have hpx := hp.mul_parameter hx (by norm_num)
  have hqy := hq.mul_parameter hy (by norm_num)
  have hs := hpx.add hqy (by norm_num)
  have ht := hs.add hb (by norm_num)
  convert ht.relu using 1 <;> norm_num

private theorem output_approx {p q r s bias x y z w : Binary32}
    {a b c d e h i j k : ℝ}
    (hp : Approx p a 2 0) (hq : Approx q b 2 0)
    (hr : Approx r c 2 0) (hs : Approx s d 2 0) (hb : Approx bias e 2 0)
    (hx : Approx x h 6 (1 / 128)) (hy : Approx y i 6 (1 / 128))
    (hz : Approx z j 6 (1 / 128)) (hw : Approx w k 6 (1 / 128)) :
    Approx ((((p * x + q * y) + r * z) + s * w) + bias)
      ((((a * h + b * i) + c * j) + d * k) + e) 50 (9 / 128) := by
  have hpx := hp.mul_parameter hx (by norm_num)
  have hqy := hq.mul_parameter hy (by norm_num)
  have hrz := hr.mul_parameter hz (by norm_num)
  have hsw := hs.mul_parameter hw (by norm_num)
  have hxy := hpx.add hqy (by norm_num)
  have hxyz := hxy.add hrz (by norm_num)
  have hxyzw := hxyz.add hsw (by norm_num)
  have hout := hxyzw.add hb (by norm_num)
  convert hout using 1 <;> norm_num

theorem forward_approx (p : Nat → Binary32) (q : Nat → ℝ)
    (hp : ∀ i, i < 22 → Approx (p i) (q i) 2 0)
    (x : Binary32 × Binary32) (r : Point)
    (hx : Approx x.1 r.1 1 (1 / 1024)) (hy : Approx x.2 r.2 1 (1 / 1024))
    (label : Fin 2) :
    Approx (forward floatLibOps p x label)
      (forward (⟨(· + ·), (· * ·), max 0⟩ : MLP.ScalarOps ℝ) q r label) 50 (9 / 128) := by
  have h0 := hidden_approx (hp 0 (by decide)) (hp 1 (by decide)) (hp 8 (by decide)) hx hy
  have h1 := hidden_approx (hp 2 (by decide)) (hp 3 (by decide)) (hp 9 (by decide)) hx hy
  have h2 := hidden_approx (hp 4 (by decide)) (hp 5 (by decide)) (hp 10 (by decide)) hx hy
  have h3 := hidden_approx (hp 6 (by decide)) (hp 7 (by decide)) (hp 11 (by decide)) hx hy
  unfold forward
  split
  · exact output_approx (hp 12 (by decide)) (hp 13 (by decide))
      (hp 14 (by decide)) (hp 15 (by decide)) (hp 20 (by decide)) h0 h1 h2 h3
  · exact output_approx (hp 16 (by decide)) (hp 17 (by decide))
      (hp 18 (by decide)) (hp 19 (by decide)) (hp 21 (by decide)) h0 h1 h2 h3

set_option maxRecDepth 4096 in
set_option maxHeartbeats 2000000 in
private theorem parameter_facts : ∀ i : Fin 22,
    ExecFloat.Binary.toRat? (floatLibParameter i) = some ((Checkpoint.parameters[i.val]?).getD 0) ∧
      |(Checkpoint.parameters[i.val]?).getD 0| ≤ (2 : ℚ) := by
  decide +kernel

theorem parameter_approx (i : Nat) (hi : i < 22) :
    Approx (floatLibParameter i) ((Checkpoint.parameters[i]?).getD 0 : ℝ) 2 0 := by
  have h := parameter_facts ⟨i, hi⟩
  refine ⟨finite_of_toRat h.1, ?_, ?_⟩
  · exact_mod_cast h.2
  · rw [value_of_toRat h.1, sub_self, abs_zero]

end FloatingError

open FloatingError

/-- Each output is finite and differs from its exact-real counterpart by at most 9/128.
The bound includes an input conversion error of up to 1/1024 in each coordinate. -/
theorem floatLibNetwork_error (x : Binary32 × Binary32) (r : Point)
    (hx : Approx x.1 r.1 1 (1 / 1024)) (hy : Approx x.2 r.2 1 (1 / 1024))
    (label : Fin 2) :
    Approx (floatLibNetwork x label) (trainedNetwork r label) 50 (9 / 128) := by
  have h := forward_approx floatLibParameter
    (fun i => ((Checkpoint.parameters[i]?).getD 0 : ℝ)) parameter_approx x r hx hy label
  rw [forward_real_eq_trainedNetwork] at h
  exact h

private theorem region_magnitudes (highX highY : Bool) (r : Point)
    (hr : InRegion highX highY r) : |r.1| ≤ 1 ∧ |r.2| ≤ 1 := by
  cases highX <;> cases highY <;>
    simp only [InRegion, InBand, Bool.false_eq_true, ↓reduceIte] at hr <;>
    constructor <;> apply abs_le.mpr <;> constructor <;> linarith [hr.1.1, hr.1.2, hr.2.1, hr.2.2]

/-- Finiteness and a margin for the exact values of the two computed binary32 outputs. -/
def FloatingMargin (output : Fin 2 → Binary32) (label : Bool) : Prop :=
  (∀ i, ExecFloat.Binary.isFinite (output i) = true) ∧
    (1 / 4 : ℝ) ≤ binary32Value (output (if label then 1 else 0)) -
      binary32Value (output (if !label then 1 else 0))

/-- Robustness to input conversion, followed by the actual rounded forward computation. -/
theorem floatLibNetwork_margin_of_input_error
    (highX highY : Bool) (r : Point) (hr : InRegion highX highY r)
    (x : Binary32 × Binary32)
    (hxfin : ExecFloat.Binary.isFinite x.1 = true)
    (hyfin : ExecFloat.Binary.isFinite x.2 = true)
    (hxerr : |binary32Value x.1 - r.1| ≤ 1 / 1024)
    (hyerr : |binary32Value x.2 - r.2| ≤ 1 / 1024) :
    FloatingMargin (floatLibNetwork x) (expectedLabel highX highY) := by
  have hm := region_magnitudes highX highY r hr
  have h := floatLibNetwork_error x r ⟨hxfin, hm.1, hxerr⟩ ⟨hyfin, hm.2, hyerr⟩
  refine ⟨fun i => (h i).finite, ?_⟩
  have hreal := trainedNetwork_margin_half highX highY r hr
  unfold margin score at hreal
  have hcorrect := (abs_le.mp (h (if expectedLabel highX highY then 1 else 0)).accuracy).1
  have hother := (abs_le.mp (h (if !(expectedLabel highX highY) then 1 else 0)).accuracy).2
  linarith

/-- Universal binary32 specification: the decoded inputs lie in the exact original boxes. -/
def FloatingXorSpec (network : Binary32 × Binary32 → Fin 2 → Binary32) : Prop :=
  ∀ highX highY x,
    ExecFloat.Binary.isFinite x.1 = true → ExecFloat.Binary.isFinite x.2 = true →
    InRegion highX highY (binary32Value x.1, binary32Value x.2) →
    FloatingMargin (network x) (expectedLabel highX highY)

/-- Every finite binary32 input in the specified boxes has margin at least 1/4. -/
theorem floatLibNetwork_satisfies_spec : FloatingXorSpec floatLibNetwork := by
  intro highX highY x hx hy hr
  exact floatLibNetwork_margin_of_input_error highX highY _ hr x hx hy
    (by simp) (by simp)

/-- Input conversion means nearest-even binary32 rounding of the original real coordinates. -/
def RoundedInput (r : Point) (x : Binary32 × Binary32) : Prop :=
  ExecFloat.Binary.isFinite x.1 = true ∧ ExecFloat.Binary.isFinite x.2 = true ∧
    binary32Value x.1 = Model.roundAt FloatFormat.binary32 r.1 ∧
    binary32Value x.2 = Model.roundAt FloatFormat.binary32 r.2

/-- All original real inputs, including exact rational endpoints, are covered after rounding. -/
theorem floatLibNetwork_margin_rounded
    (highX highY : Bool) (r : Point) (hr : InRegion highX highY r)
    (x : Binary32 × Binary32) (hx : RoundedInput r x) :
    FloatingMargin (floatLibNetwork x) (expectedLabel highX highY) := by
  have hm := region_magnitudes highX highY r hr
  apply floatLibNetwork_margin_of_input_error highX highY r hr x hx.1 hx.2.1
  · rw [hx.2.2.1]
    exact round_error r.1 (hm.1.trans (by norm_num))
  · rw [hx.2.2.2]
    exact round_error r.2 (hm.2.trans (by norm_num))

/-- Nearest-even binary32 conversion exists for every input in the original real regions. -/
theorem roundBinary32_input (highX highY : Bool) (r : Point)
    (hr : InRegion highX highY r) :
    RoundedInput r (roundBinary32 r.1, roundBinary32 r.2) := by
  have hm := region_magnitudes highX highY r hr
  have hx := roundBinary32_spec r.1 hm.1
  have hy := roundBinary32_spec r.2 hm.2
  exact ⟨hx.1, hy.1, hx.2, hy.2⟩

/-- Every real input in all four original boxes, rounded once to binary32 and then
evaluated by FloatLib, has finite scores with a margin of at least 1/4. -/
theorem floatLibNetwork_margin_real (highX highY : Bool) (r : Point)
    (hr : InRegion highX highY r) :
    FloatingMargin (floatLibNetwork (roundBinary32 r.1, roundBinary32 r.2))
      (expectedLabel highX highY) :=
  floatLibNetwork_margin_rounded highX highY r hr _ (roundBinary32_input highX highY r hr)

/-- The separately rounded binary32 subtraction of the two scores. -/
def computedMargin (output : Fin 2 → Binary32) (label : Bool) : Binary32 :=
  output (if label then 1 else 0) - output (if !label then 1 else 0)

/-- The margin remains at least 1/4 even when the final subtraction is rounded. -/
theorem floatLibNetwork_sub_margin_of_input_error
    (highX highY : Bool) (r : Point) (hr : InRegion highX highY r)
    (x : Binary32 × Binary32)
    (hxfin : ExecFloat.Binary.isFinite x.1 = true)
    (hyfin : ExecFloat.Binary.isFinite x.2 = true)
    (hxerr : |binary32Value x.1 - r.1| ≤ 1 / 1024)
    (hyerr : |binary32Value x.2 - r.2| ≤ 1 / 1024) :
    ExecFloat.Binary.isFinite (computedMargin (floatLibNetwork x) (expectedLabel highX highY)) = true ∧
      (1 / 4 : ℝ) ≤ binary32Value (computedMargin (floatLibNetwork x) (expectedLabel highX highY)) := by
  have hm := region_magnitudes highX highY r hr
  have h := floatLibNetwork_error x r ⟨hxfin, hm.1, hxerr⟩ ⟨hyfin, hm.2, hyerr⟩
  let correct : Fin 2 := if expectedLabel highX highY then 1 else 0
  let other : Fin 2 := if !(expectedLabel highX highY) then 1 else 0
  have hc := h correct
  have ho := h other
  have hs := sub_error (floatLibNetwork x correct) (floatLibNetwork x other) hc.finite ho.finite
    (by linarith [hc.value_bound, ho.value_bound])
  refine ⟨hs.1, ?_⟩
  have hreal := trainedNetwork_margin_half highX highY r hr
  change (1 / 2 : ℝ) ≤ trainedNetwork r correct - trainedNetwork r other at hreal
  change (1 / 4 : ℝ) ≤ binary32Value (floatLibNetwork x correct - floatLibNetwork x other)
  linarith [(abs_le.mp hc.accuracy).1, (abs_le.mp ho.accuracy).2, (abs_le.mp hs.2).1]

/-- Universal margin for a binary32 input, including the rounded score subtraction. -/
theorem floatLibNetwork_sub_margin (highX highY : Bool) (x : Binary32 × Binary32)
    (hx : ExecFloat.Binary.isFinite x.1 = true) (hy : ExecFloat.Binary.isFinite x.2 = true)
    (hr : InRegion highX highY (binary32Value x.1, binary32Value x.2)) :
    ExecFloat.Binary.isFinite (computedMargin (floatLibNetwork x) (expectedLabel highX highY)) = true ∧
      (1 / 4 : ℝ) ≤ binary32Value (computedMargin (floatLibNetwork x) (expectedLabel highX highY)) :=
  floatLibNetwork_sub_margin_of_input_error highX highY _ hr x hx hy (by simp) (by simp)

/-- Universal real-input guarantee, including input rounding, inference, and score subtraction. -/
theorem floatLibNetwork_sub_margin_real (highX highY : Bool) (r : Point)
    (hr : InRegion highX highY r) :
    let output := floatLibNetwork (roundBinary32 r.1, roundBinary32 r.2)
    ExecFloat.Binary.isFinite (computedMargin output (expectedLabel highX highY)) = true ∧
      (1 / 4 : ℝ) ≤ binary32Value (computedMargin output (expectedLabel highX highY)) := by
  have hm := region_magnitudes highX highY r hr
  have hx := roundBinary32_spec r.1 hm.1
  have hy := roundBinary32_spec r.2 hm.2
  apply floatLibNetwork_sub_margin_of_input_error highX highY r hr
    (roundBinary32 r.1, roundBinary32 r.2) hx.1 hy.1
  · rw [hx.2]
    exact round_error _ (hm.1.trans (by norm_num))
  · rw [hy.2]
    exact round_error _ (hm.2.trans (by norm_num))

end NeuralSpec.Xor
