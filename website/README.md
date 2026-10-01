# Website source

The XOR page is authored in [xor.mdx](xor.mdx) with React components. Requires Node.js 22 or later and Python 3. Run from the repository root:

```sh
npm --prefix website ci
npm --prefix website run build
npm --prefix website test
python3 -m http.server 4175 --bind 127.0.0.1 --directory artifacts/site
```

Preview at http://127.0.0.1:4175/. The build extracts the frozen parameters, checks their encodings and local links, and renders static HTML before hydration.

Use `$...$` for inline mathematics and `$$...$$` for display mathematics. Shared macros are `\R`, `\ReLU`, `\XorSpec`, and `\RN`.

Statement blocks use `\begin{definition}[Title]`, `\begin{theorem}[Title]`, or `\begin{proof}`, with matching `\end{...}` markers. Put each marker on its own line with blank lines around it. The build rejects unmatched environments and invalid LaTeX; math fonts are served locally.
