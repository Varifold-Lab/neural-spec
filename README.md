# neural-spec

A [Varifold](https://varifold-lab.github.io/) project for specifications and Lean proofs of neural networks and training algorithms.

[Documentation](https://varifold-lab.github.io/neural-spec/)

## Verification cases

| Case | Algorithm or model | Verified properties | Arithmetic or cost model |
| --- | --- | --- | --- |
| [XOR](docs/PROOF.md) | A frozen trained two-layer classifier | Correct-class margin at least `1/4` on four closed input regions | Exact reals and nearest-even binary32 |
| [Newton–Schulz](docs/NEWTON_SCHULZ.md) | The five-step quintic matrix iteration used by Muon | Factorization, transpose equivalence, kernel preservation, scalar limitations, and matrix multiplication cost savings | Exact reals and a stipulated dense-multiplication FLOPs model |

The algorithm layer defines the objects and computation. The verification layer states a specification and proves it from explicit premises. XOR concerns one frozen parameter set; Newton–Schulz concerns matrices of arbitrary finite dimensions with a fixed coefficient configuration. A training log, numerical report, or checker result is separate evidence from a kernel-checked universal theorem.

Whole-network native execution correspondence remains open for XOR. Normalization, floating-point execution, quantitative approximation errors, and complete optimizer training or wall-clock guarantees remain open for Newton–Schulz.

## Run

Requires [elan / Lean](https://lean-lang.org/install/) and a C compiler. Dependencies are pinned.

```sh
lake exe cache get
lake build
lake env lean scripts/Audit.lean
lake exe xor --help
```

## Organization

Architecture modules define network structures; examples select concrete networks and parameters. Matrix algorithms and arithmetic models live in `Model/`. Verification cases state properties and instantiate shared theorems.

Directory layout; reserved entries are planned:

```text
NeuralSpec/
├── Model/                                 # Mathematical objects and arithmetic models
│   ├── NewtonSchulz.lean                   # Generic quintic iteration
│   └── NewtonSchulz/                       # Cost model and Muon configuration
├── Network/
│   ├── Architectures/
│   │   ├── MLP/                            # Implemented builders and scalar operations
│   │   ├── CNN/                            # Reserved; planned
│   │   └── Transformer/                    # Reserved; planned
│   ├── Xor/                                # Concrete network and frozen trained parameters
│   └── TinyTransformer/                    # Reserved instance
├── Training/<example>/                    # Training and checkpoint IO
└── Verification/
    ├── Shared/
    │   ├── Properties/<property>/          # Generic specifications and lemmas
    │   ├── Arithmetic/                     # Rounding, error propagation, matrix iteration
    │   └── Architectures/                  # Family-specific verification theory
    │       └── Transformer/                # Reserved
    ├── Xor/Robustness/                      # Implemented specifications and proofs
    ├── NewtonSchulz/                        # Implemented Iteration and Cost cases
    └── TinyTransformer/                    # Reserved Causality, CacheEquivalence, Quantization
```

XOR instantiates the generic MLP builder. Newton–Schulz has no network or checkpoint: its two cases import the Muon configuration and generic iteration or cost proofs. Training does not import verification; shared proofs do not import concrete cases, and each instance must discharge their hypotheses.

[Transformer components](NeuralSpec/Network/Architectures/Transformer/README.md), [shared theory](NeuralSpec/Verification/Shared/Architectures/Transformer/README.md), and [TinyTransformer cases](NeuralSpec/Verification/TinyTransformer/README.md) have reserved directories and module plans; implementations and proofs remain pending. MNIST remains planned.

Each website example occupies one MDX page. Frozen proof inputs and certificates are committed; datasets, checkpoints, and logs go in the uncommitted `artifacts/` directory.

[Module rules](AGENTS.md) · [Website source and build](website/README.md)
