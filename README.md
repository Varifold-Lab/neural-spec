# neural-spec

A learning collection of practical neural-network verification cases from the Varifold community. Each case connects a precise mathematical question to executable code and Lean proofs, using TorchLean and FloatLib.

[XOR specification and proofs](https://varifold-lab.github.io/neural-spec/).

**Example 01 is XOR. Case 01 is regional robustness:** a trained **2 → 4 ReLU → 2** classifier with 22 parameters has a correct-class score margin of at least **1/4** throughout four continuous input regions.

| Arithmetic | Status for the frozen trained network |
| --- | --- |
| Exact reals | Kernel-checked margin theorem. |
| FloatLib binary32 | Kernel-checked margin theorem, including input rounding and rounded score subtraction. |
| Native Float32 / TorchLean | Selected correspondence proofs and regression checks; whole-network correspondence remains open. |

See [the specification, proof, and scope](docs/PROOF.md). Neuron ablation and other interpretability experiments are still planned.

## Run

Install [elan / Lean](https://lean-lang.org/install/) and a native C compiler. The default CPU path requires no Python, PyTorch, or CUDA. Versions are pinned in [lean-toolchain](lean-toolchain), [lakefile.toml](lakefile.toml), and [lake-manifest.json](lake-manifest.json).

```sh
git clone https://github.com/Varifold-Lab/neural-spec.git
cd neural-spec
lake exe cache get
lake build
```

Train and check a saved checkpoint:

```sh
lake exe xor smoke
lake exe xor train 1000 7 artifacts/xor.state
lake exe xor check artifacts/xor.state
```

The optional training arguments are `steps seed checkpoint`, with defaults shown above. Training uses 36 fixed samples, mean squared error, and Adam at learning rate `0.03`. Checkpoints and logs belong in the Git-ignored `artifacts/` directory. `check` reloads the trained weights.

`train` and `smoke` return 0 when the workflow completes. `check` returns 0 when all four numerical margin checks pass, 2 when a check fails or is inconclusive, and 1 on errors. **A numerical check does not prove a new checkpoint correct.**

Evaluate the frozen parameters embedded in the source, or compare the two backends on a regression set:

```sh
lake exe xor infer native 0.1 0.9
lake exe xor infer ieee 0.1 0.9
lake exe xor parity
```

These inference commands use the frozen network rather than loading `artifacts/xor.state`. `parity` reports sample agreement; it is not a universal equivalence theorem. Use `lake exe xor --help` for command syntax.

## Check the proofs

```sh
lake build NeuralSpec
lake env lean scripts/Audit.lean
```

The proofs build from the included parameters without Python or a checkpoint file. With the original local checkpoint available, `python3 scripts/export_checkpoint.py --check` verifies its identity and parameter export. Retraining creates a new proof obligation.

## Read the code

Start with the [real network](NeuralSpec/Network/Xor/Real.lean), then its [specification](NeuralSpec/Verification/Xor/Spec.lean) and [proof](NeuralSpec/Verification/Xor/Correctness.lean). The floating-point proof is a separate, deeper reading path.

XOR verification has four files: `Spec.lean` states the claim, `Correctness.lean` proves it over the reals, `FloatingPoint.lean` proves the binary32 guarantee, and `Numerical.lean` runs numerical checks. General rounding lemmas live in `Verification/Shared/FloatingError.lean`.

| Location | Purpose |
| --- | --- |
| [Model](NeuralSpec/Model/) | Shared binary32 definitions and XOR input types/regions. |
| [Network/Xor](NeuralSpec/Network/Xor/) | Architecture, frozen parameters, and real/native/FloatLib forward definitions. |
| [Training/Xor](NeuralSpec/Training/Xor/) | Training data, optimizer, and checkpoint IO. |
| [Verification/Xor](NeuralSpec/Verification/Xor/) | Specifications and proofs; `Numerical.lean` contains executable checks. |
| [Verification/Shared](NeuralSpec/Verification/Shared/) | Reusable binary32 error lemmas, independent of XOR. |
| [Main.lean](Main.lean) | Command-line entry point. |

Within the project, the network imports shared definitions; training and verification import the network. The network does not import either training or verification. Check this boundary with `lake build NeuralSpec.Network` and `lake env lean scripts/CheckImports.lean`. Contributor rules are in [AGENTS.md](AGENTS.md).

New examples follow the same Model / Network / Training / Verification separation,
using XOR as the reference. Keep example-specific claims together and reuse
`Verification/Shared` lemmas when their explicit premises apply. Only implemented
examples belong in the source tree; planned work needs no placeholder modules.
Check that shared proofs remain independent with `lake env lean scripts/CheckShared.lean`.

## Learning website

The [MDX page](website/xor.mdx) covers XOR, its proofs, and reproduction commands. It embeds a [JSX forward-pass animation](website/components/XorAnimation.jsx) using the frozen trained parameters. Requires Node.js 22 or later and Python 3:

```sh
npm --prefix website ci
npm --prefix website run build
npm --prefix website test
python3 -m http.server 4175 --bind 127.0.0.1 --directory artifacts/site
```

Open `http://127.0.0.1:4175/`. The builder extracts parameter values, checks their encodings and local links, and renders the page as static HTML before adding interaction. Browser calculations approximate the exact-real network using JavaScript binary64 arithmetic. The [Pages workflow](.github/workflows/pages.yml) publishes the generated site from `main` when GitHub Pages is configured to use GitHub Actions.

Write inline and display mathematics as `$...$` and `$$...$$`. The shared macros are `\R`, `\ReLU`, `\XorSpec`, and `\RN`. Numbered statements use `\begin{definition}[Title]` or `\begin{theorem}[Title]`, with matching `\end{...}` markers; `\begin{proof}` adds a proof block. Put each marker on its own line with blank lines around it. The builder rejects unmatched environments and invalid LaTeX. Math fonts are served locally.
