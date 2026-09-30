/-!
# Shared scalar forward program

Both executable floating-point backends use this exact sequence of operations.
Products are rounded separately, additions associate to the left, and bias is
added last. The program contains no fused multiply-add operation.
Parameter indices follow the frozen checkpoint's row-major tensor order.
-/

namespace NeuralSpec.Xor

/-- Arithmetic choices for the same 2 → 4 ReLU → 2 forward computation. -/
structure ForwardOps (α : Type) where
  add : α → α → α
  mul : α → α → α
  relu : α → α

/-- One forward program, independent of scalar representation and proof obligations. -/
def forward {α : Type} (ops : ForwardOps α) (parameter : Nat → α)
    (x : α × α) (label : Fin 2) : α :=
  let h0 := ops.relu (ops.add (ops.add
    (ops.mul (parameter 0) x.1) (ops.mul (parameter 1) x.2)) (parameter 8))
  let h1 := ops.relu (ops.add (ops.add
    (ops.mul (parameter 2) x.1) (ops.mul (parameter 3) x.2)) (parameter 9))
  let h2 := ops.relu (ops.add (ops.add
    (ops.mul (parameter 4) x.1) (ops.mul (parameter 5) x.2)) (parameter 10))
  let h3 := ops.relu (ops.add (ops.add
    (ops.mul (parameter 6) x.1) (ops.mul (parameter 7) x.2)) (parameter 11))
  if label = 0 then
    ops.add (ops.add (ops.add (ops.add
      (ops.mul (parameter 12) h0) (ops.mul (parameter 13) h1))
      (ops.mul (parameter 14) h2)) (ops.mul (parameter 15) h3)) (parameter 20)
  else
    ops.add (ops.add (ops.add (ops.add
      (ops.mul (parameter 16) h0) (ops.mul (parameter 17) h1))
      (ops.mul (parameter 18) h2)) (ops.mul (parameter 19) h3)) (parameter 21)

end NeuralSpec.Xor
