import NeuralSpec.Training.Xor.Run
import NeuralSpec.Verification.Xor.Numerical
import NN.API.CLI.Parser

-- The executable composes independent training and numerical-checking workflows.
private def trainAndCheck (steps seed : Nat) (checkpoint : System.FilePath) : IO Unit := do
  let trained ← NeuralSpec.Xor.trainAndSave steps seed checkpoint
  let _ ← NeuralSpec.Xor.checkRegions trained

private def loadAndCheck (checkpoint : System.FilePath) : IO Nat := do
  let trained ← NeuralSpec.Xor.loadTrained checkpoint
  NeuralSpec.Xor.checkRegions trained

private def parseInput (text : String) : IO Float32 := do
  let value ← match TorchLean.CLI.parseFloatLit? text with
    | some value => pure value.toFloat32
    | none => throw <| IO.userError s!"invalid numeric input: {text}"
  unless value.isFinite do
    throw <| IO.userError s!"input must be finite in binary32: {text}"
  return value

private def inferFrozen (backend xText yText : String) : IO Unit := do
  let x ← parseInput xText
  let y ← parseInput yText
  let scores ← match backend with
    | "native" => pure (NeuralSpec.Xor.nativeNetwork (x, y))
    | "ieee" =>
        let reference := NeuralSpec.Xor.floatLibNetwork
          (FloatLib.Floats.ExecFloat.Binary.ofFloat32 x,
           FloatLib.Floats.ExecFloat.Binary.ofFloat32 y)
        pure (fun label => FloatLib.Floats.ExecFloat.Binary.toFloat32 (reference label))
    | _ => throw <| IO.userError "inference backend must be native or ieee"
  let same := scores 0
  let different := scores 1
  unless same.isFinite && different.isFinite do
    throw <| IO.userError "inference produced nonfinite scores"
  IO.println s!"Frozen seed-7 checkpoint; backend={backend}; input=[{x}, {y}]"
  IO.println s!"same-band score={same}; different-band score={different}"
  IO.println s!"output bits=[{same.toBits}, {different.toBits}]"

private def usage : String :=
  "Usage:\n  lake exe xor train [steps=1000] [seed=7] [checkpoint=artifacts/xor.state]\n" ++
  "  lake exe xor check [checkpoint=artifacts/xor.state]\n" ++
  "  lake exe xor smoke\n" ++
  "  lake exe xor infer native|ieee x1 x2\n" ++
  "  lake exe xor parity\n" ++
  "check returns 2 when the numerical margin test is inconclusive; it does not prove XorSpec."

private def parsePositive (s : String) : IO Nat := do
  match s.toNat? with
  | some n =>
      if n > 0 then return n
      throw <| IO.userError "steps must be positive"
  | none => throw <| IO.userError s!"invalid step count: {s}"

def main (args : List String) : IO UInt32 := do
  try
    match args with
    | [] | ["--help"] | ["help"] => IO.println usage; return 0
    | ["infer", backend, x, y] => inferFrozen backend x y; return 0
    | ["parity"] =>
        let mismatches ← NeuralSpec.Xor.checkFloatingParity
        return if mismatches == 0 then 0 else 2
    | ["smoke"] =>
        trainAndCheck 1 7 "artifacts/smoke.state"
        return 0
    | "train" :: rest =>
        if rest.length > 3 then throw <| IO.userError usage
        let steps ← parsePositive (rest[0]?.getD "1000")
        let seed ← match (rest[1]?.getD "7").toNat? with
          | some n => pure n
          | none => throw <| IO.userError "seed must be a natural number"
        let path := rest[2]?.getD "artifacts/xor.state"
        trainAndCheck steps seed path
        return 0
    | ["check"] | ["check", _] =>
        let path := args[1]?.getD "artifacts/xor.state"
        let passed ← loadAndCheck path
        return if passed == 4 then 0 else 2
    | _ => IO.eprintln usage; return 1
  catch error =>
    IO.eprintln s!"xor: {error}"
    return 1
