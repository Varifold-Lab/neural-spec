# neural-spec

A [Varifold](https://varifold-lab.github.io/) project for concrete neural-network specifications and Lean proofs, built on pinned TorchLean and FloatLib definitions.

[Documentation](https://varifold-lab.github.io/neural-spec/) · [Proof scope](docs/PROOF.md)

The implemented XOR case proves a margin of at least 1/4 on four closed input regions for a frozen trained network. The theorems are kernel-checked over exact reals and a nearest-even binary32 model; whole-network correspondence with native execution remains open.

## Run

Requires [elan / Lean](https://lean-lang.org/install/) and a C compiler. Dependencies are pinned.

```sh
lake exe cache get
lake build
lake env lean scripts/Audit.lean
lake exe xor --help
```

## Organization

Architecture modules adapt upstream structures when needed; examples select concrete networks and parameters. Verification cases state properties such as robustness or quantization; shared theory composes existing results and supplies missing lemmas required by cases.

Directory layout; reserved entries are planned:

```text
NeuralSpec/
├── Model/                                 # Mathematical objects and arithmetic models
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
    │   ├── Arithmetic/                     # Rounding and error propagation
    │   └── Architectures/                  # Family-specific verification theory
    │       └── Transformer/                # Reserved
    ├── Xor/Robustness/                      # Implemented specifications and proofs
    └── TinyTransformer/                    # Reserved Causality, CacheEquivalence, Quantization
```

XOR instantiates the generic MLP builder. [Transformer components](NeuralSpec/Network/Architectures/Transformer/README.md), [shared theory](NeuralSpec/Verification/Shared/Architectures/Transformer/README.md), and [TinyTransformer cases](NeuralSpec/Verification/TinyTransformer/README.md) have reserved directories and module plans; implementations and proofs remain pending. MNIST remains planned. Training and verification import networks; shared proofs do not import examples, and each instance must discharge their hypotheses.

Each website example occupies one MDX page. Frozen proof inputs and certificates are committed; datasets, checkpoints, and logs go in the uncommitted `artifacts/` directory.

[Module rules](AGENTS.md) · [Website source and build](website/README.md)
