import NeuralSpec.Xor.Run

private def usage : String :=
  "Usage:\n  lake exe xor train [steps=1000] [seed=7] [checkpoint=artifacts/xor.state]\n" ++
  "  lake exe xor check [checkpoint=artifacts/xor.state]\n" ++
  "  lake exe xor smoke\n" ++
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
    | ["smoke"] =>
        NeuralSpec.Xor.trainAndCheck 1 7 "artifacts/smoke.state"
        return 0
    | "train" :: rest =>
        if rest.length > 3 then throw <| IO.userError usage
        let steps ← parsePositive (rest[0]?.getD "1000")
        let seed ← match (rest[1]?.getD "7").toNat? with
          | some n => pure n
          | none => throw <| IO.userError "seed must be a natural number"
        let path := rest[2]?.getD "artifacts/xor.state"
        NeuralSpec.Xor.trainAndCheck steps seed path
        return 0
    | ["check"] | ["check", _] =>
        let path := args[1]?.getD "artifacts/xor.state"
        let passed ← NeuralSpec.Xor.loadAndCheck path
        return if passed == 4 then 0 else 2
    | _ => IO.eprintln usage; return 1
  catch error =>
    IO.eprintln s!"xor: {error}"
    return 1
