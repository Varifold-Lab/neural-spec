# neural-spec

A [Varifold](https://varifold-lab.github.io/) project for neural-network specifications and Lean proofs.

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

Architecture families define reusable structures; examples select concrete networks and parameters. Verification cases state properties such as robustness or quantization; shared theory supplies general definitions and soundness lemmas.

Target layout; planned families are marked below:

```text
NeuralSpec/
├── Model/                                 # Mathematical objects and arithmetic models
├── Network/
│   ├── Architectures/
│   │   ├── MLP/                            # Implemented builders and scalar operations
│   │   ├── CNN/                            # Reserved; planned
│   │   └── Transformer/                    # Reserved; planned
│   └── <example>/                          # Concrete networks and frozen parameters
├── Training/<example>/                    # Training and checkpoint IO
└── Verification/
    ├── Shared/
    │   ├── Properties/<property>/          # Generic specifications and lemmas
    │   ├── Arithmetic/                     # Rounding and error propagation
    │   └── Architectures/<family>/         # Family-specific verification theory
    └── <example>/<case>/                   # Instance specifications and proofs
```

XOR instantiates the generic MLP builder; its regional case is in `Verification/Xor/Robustness/`. MNIST remains planned. Training and verification import networks; shared proofs do not import examples, and each instance must discharge their hypotheses.

Each website example occupies one MDX page. Frozen proof inputs and certificates are committed; datasets, checkpoints, and logs go in the uncommitted `artifacts/` directory.

[Module rules](AGENTS.md) · [Website source and build](website/README.md)
