import NeuralSpec.Xor.Model
import NeuralSpec.Xor.Data
import NN.API.Trainer.Train.Loop
import NN.API.Verification

namespace NeuralSpec.Xor

open TorchLean

private def candidateMargin (trained : Trainer.Result [2] [2])
    (center : Tensor Float [2]) (radius : Float) (label : Nat)
    (algorithm : Verification.Algorithm) : IO Float := do
  let report ← trained.verify center (radius := radius)
    (norm := .inf) (property := .topLabel label) (algorithm := algorithm)
  match report.result with
  | .topLabel _ lowerMargin _ => return lowerMargin
  | .bounds => throw <| IO.userError "expected a top-label report"

private def checkWith (trained : Trainer.Result [2] [2]) (region : Region)
    (algorithm : Verification.Algorithm) : IO Bool := do
  -- Padding avoids interpreting rounded endpoints as exact rational endpoints.
  -- Establishing a semantic bridge to Spec.lean remains a proof obligation.
  let lowerMargin ← candidateMargin trained region.center 0.100001 region.label algorithm
  let met := lowerMargin.isFinite && lowerMargin >= 0.25
  IO.println s!"  {algorithm}: candidate lower margin={lowerMargin}; meets 1/4={met}"
  return met

/-- Check every cell of a fixed 8×8 cover; no input region is discarded. -/
private def checkSubregions (trained : Trainer.Result [2] [2]) (region : Region) : IO Bool := do
  let mut smallest : Option Float := none
  let mut allFinite := true
  for i in [0:8] do
    for j in [0:8] do
      let x := (if region.highX then 0.8 else 0.0) + (i.toFloat + 0.5) * 0.025
      let y := (if region.highY then 0.8 else 0.0) + (j.toFloat + 0.5) * 0.025
      let lowerMargin ← candidateMargin trained [x, y] 0.012501 region.label .ibp
      allFinite := allFinite && lowerMargin.isFinite
      smallest := some (smallest.map (min · lowerMargin) |>.getD lowerMargin)
  let lowerMargin ← match smallest with
    | some value => pure value
    | none => throw <| IO.userError "empty subdivision"
  let met := allFinite && lowerMargin >= 0.25
  IO.println s!"  IBP 8x8 cover: minimum candidate margin={lowerMargin}; meets 1/4={met}"
  return met

/-- Numerical verification only. The exact-real `XorSpec` theorem is a separate milestone. -/
def checkRegions (trained : Trainer.Result [2] [2]) : IO Nat := do
  let mut passed := 0
  IO.println "Numerical bound reports (not Lean proofs of XorSpec):"
  for region in regions do
    let prediction ← trained.predict region.center
    IO.println s!"{region.name}: expected={region.label}, center logits={reprStr prediction}"
    let ibpMet ← checkWith trained region .ibp
    let crownMet ← if ibpMet then pure true else checkWith trained region .crown
    let met ← if crownMet then pure true else checkSubregions trained region
    if met then passed := passed + 1
  IO.println s!"Numerical margin checks: {passed}/4. Formal checkpoint proof: not yet implemented."
  return passed

def trainAndCheck (steps : Nat) (seed : Nat) (checkpoint : System.FilePath) : IO Unit := do
  IO.println s!"XOR 2→4→2; seed={seed}; steps={steps}; CPU/native binary32"
  let trained ← (trainer seed).train dataset
    { steps := steps, samplesPerStep := 36, logEvery := max 1 (steps / 10) }
  trained.printSummary
  if let some parent := checkpoint.parent then IO.FS.createDirAll parent
  trained.save checkpoint
  IO.println s!"Saved trained parameters to {checkpoint}"
  let _ ← checkRegions trained

def loadAndCheck (checkpoint : System.FilePath) : IO Nat := do
  let trained ← (trainer 7).load checkpoint dataset
  checkRegions trained

end NeuralSpec.Xor
