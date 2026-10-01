# Working on neural-spec

- Write project content, documentation, and code comments in English. Communicate with the user in Chinese.
- Keep documentation concise, factual, and academic. State each definition, result, and limitation once; omit slogans, reading advice, and generic contribution prose. Match the Varifold community website’s visual style. Explain the example rather than promoting dependency libraries; identify the arithmetic model precisely without repeating library names. Keep the current XOR example on one concise page; do not add landing pages, guides, or per-section pages.
- Reuse the AI Safety documentation header and reading styles: `Varifold / project` at the left, with Varifold linking to the community home, and GitHub at the right. Compare the actual project pages before changing navigation or controls.
- Use the pinned Lean and TorchLean revisions. Keep `lake-manifest.json` committed.
- Keep the four exact input regions and the 1/4 margin aligned with `NeuralSpec/Verification/Xor/Robustness/Spec.lean`.
- Distinguish a numerical report, a checker result, and a kernel-checked theorem.
- Do not use `sorry`, `admit`, or assume the target network property to complete a proof.
- State whether a theorem describes exact real arithmetic or a particular floating-point model.
- Use trained parameters for post-training checks; do not accidentally verify initialization.
- Build with `lake build`; smoke-test training with `lake exe xor smoke` when changing runtime code.
- Generated checkpoints and logs belong in `artifacts/`, which is not committed.

## Module boundaries

- Follow the LeanSort-style separation: `Model/` for shared definitions, `Network/` for architecture and frozen network definitions, `Training/` for training and checkpoint IO, and `Verification/` for specifications, theorems, and numerical checks.
- Put generic network structures in `Network/Architectures/<family>/` and concrete configurations, frozen parameters, and evaluators in `Network/<example>/`. Generic architectures must not import examples.
- Organize example verification by `Verification/<example>/<case>/`. Group shared properties, arithmetic proofs, and family-specific theory under `Verification/Shared/Properties/`, `Arithmetic/`, and `Architectures/` respectively. Planned architecture families may reserve a directory with a concise README; add Lean modules only with implementations.
- Put network-independent lemmas in `Verification/Shared/`; shared proof modules must not import an example. Keep their numerical premises explicit.
- Keep project specifications and proofs out of `Network/`; do not import `Verification/` or `Training/` from the network. Put parameter-decoding proofs in `Verification/`, not generated parameter files.
- Keep training independent of project verification. Compose training and numerical checking in `Main.lean`.
- Define each network and parameter set once; verification must import those definitions.
- After changing module boundaries, run `lake build NeuralSpec.Network`, `lake env lean scripts/CheckImports.lean`, and `lake env lean scripts/CheckShared.lean`, then the full build and theorem audit.
