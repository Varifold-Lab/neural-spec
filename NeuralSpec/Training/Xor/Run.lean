import NeuralSpec.Training.Xor.Config
import NeuralSpec.Training.Xor.Data
import NN.API.Trainer.Train.Loop

/-! Training and checkpoint IO only; the CLI invokes verification separately. -/

namespace NeuralSpec.Xor

open TorchLean

def trainAndSave (steps : Nat) (seed : Nat) (checkpoint : System.FilePath) : IO (Trainer.Result [2] [2]) := do
  IO.println s!"XOR 2→4→2; seed={seed}; steps={steps}; CPU/native binary32"
  let trained ← (trainer seed).train dataset
    { steps := steps, samplesPerStep := 36, logEvery := max 1 (steps / 10) }
  trained.printSummary
  if let some parent := checkpoint.parent then IO.FS.createDirAll parent
  trained.save checkpoint
  IO.println s!"Saved trained parameters to {checkpoint}"
  return trained

def loadTrained (checkpoint : System.FilePath) : IO (Trainer.Result [2] [2]) :=
  (trainer 7).load checkpoint dataset

end NeuralSpec.Xor
