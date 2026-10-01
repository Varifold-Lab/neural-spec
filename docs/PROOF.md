# What is proved

The proofs concern the frozen XOR network trained with seed `7` for `1000` Adam steps. Its 22 parameters are defined once in [Parameters.lean](../NeuralSpec/Network/Xor/Parameters.lean), together with their binary32 words, original checkpoint words, and SHA-256 identity. Changing any weight requires a new proof.

## Domain and claim

The exact specification is [Spec.lean](../NeuralSpec/Verification/Xor/Robustness/Spec.lean). Let `L = [0, 1/5]` and `H = [4/5, 1]`:

| Input region | Correct class |
| --- | --- |
| L × L | 0 |
| L × H | 1 |
| H × L | 1 |
| H × H | 0 |

For every input in each closed region, including its endpoints:

```text
correct_score(x) - other_score(x) ≥ 1/4
```

The outputs are raw scores. There is no claim about inputs outside these regions.

## Theorems

All names below are in `NeuralSpec.Xor` and are included in `lake build`.

| Theorem | Arithmetic and guarantee |
| --- | --- |
| `trainedNetwork_satisfies_spec` | Exact-real evaluation satisfies `XorSpec`. |
| `trainedNetwork_margin_half` | The exact-real margin is at least `1/2`, leaving room for rounding error. |
| `floatLibNetwork_satisfies_spec` | All finite binary32 inputs whose decoded values lie in the regions have finite FloatLib outputs and margin at least `1/4`. |
| `floatLibNetwork_margin_real` | All original real inputs, rounded once to binary32, have finite FloatLib outputs and margin at least `1/4`. |
| `floatLibNetwork_sub_margin_real` | The same real-input guarantee also covers rounding the final score subtraction to binary32. |

The real-input floating-point theorems assume only membership in the region. Input conversion, intermediate finiteness, and error bounds are proved. The endpoint `1/5` is covered even though its nearest binary32 value lies slightly above `1/5`.

## How the proof works

[Correctness.lean](../NeuralSpec/Verification/Xor/Robustness/Correctness.lean) substitutes the exact rational weights into the real-valued network, splits the four regions and ReLU activation cases, and proves the resulting linear inequalities.

[FloatingError.lean](../NeuralSpec/Verification/Shared/Arithmetic/FloatingError.lean) connects the actual FloatLib operations to nearest-even binary32 arithmetic with gradual underflow. It proves finiteness and conservative rounding bounds, including signed zero and subnormals. ReLU does not increase error. These lemmas live in `NeuralSpec.FloatingError` and can be imported without XOR. Their current premises use operation magnitude at most `128`, rounding error at most `1/1024`, and exact coefficients of magnitude at most `2` for parameter multiplication; another example must establish those premises or extend the lemmas.

[FloatingPoint.lean](../NeuralSpec/Verification/Xor/Robustness/FloatingPoint.lean) composes those bounds through the shared [forward program](../NeuralSpec/Network/Xor/Forward.lean). Multiplications and additions are separate; sums associate to the left and biases are added last. Each output differs from the ideal real output by at most `9/128`, including input conversion. Another `1/1024` covers the final subtraction:

```text
rounded_margin ≥ 1/2 - 2 × (9/128) - 1/1024 = 367/1024 > 1/4
```

These are proved bounds, not measured errors. The proof does not use the IBP/CROWN reports or sampled predictions. Parameter-decoding proofs identify the coefficients; the export script separately checks their extraction from the checkpoint file.

## Remaining boundary

The floating-point theorem applies to **FloatLib's software binary32 implementation**. Whole-network equivalence with native Float32/TorchLean execution is still open, as are the connection to the CLI decimal parser and deployment compiler/hardware. The real-input adapter specifies direct nearest-even conversion mathematically. The theorem does not prove the training algorithm or automatically apply to another checkpoint or an ablated network.

## Reproduce and audit

```sh
lake build
lake env lean scripts/Audit.lean
lake env lean scripts/CheckImports.lean
lake env lean scripts/CheckShared.lean
python3 scripts/export_checkpoint.py --check
```

Only the last command requires Python and the original local `artifacts/xor.state`. The pinned Lean, TorchLean, and FloatLib versions are recorded in the repository's toolchain and dependency files.

Validation on 2026-09-30: the build, import checks, and checkpoint export check passed. All 16 audited theorems depend only on `propext`, `Classical.choice`, and `Quot.sound`, with no `sorryAx`, native-evaluation axiom, or assumed network safety property.

Separate numerical observations: the saved checkpoint passed all four region checks (minimum reported margin `0.501937`); the one-step checkpoint failed three regions. Native/FloatLib regression testing found zero output-word mismatches on 447 input pairs. These observations do not establish universal native-runtime correctness.
