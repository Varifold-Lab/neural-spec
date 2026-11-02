# Website source

The two verification cases are authored in [xor.mdx](xor.mdx) and [newton-schulz.mdx](newton-schulz.mdx). Each occupies one page; there is no separate landing page. [lib/pages.mjs](lib/pages.mjs) defines metadata and case navigation. Requires Node.js 22 or later and Python 3. Run from the repository root:

```sh
npm --prefix website ci
npm --prefix website run build
npm --prefix website test
python3 -m http.server 4175 --bind 127.0.0.1 --directory artifacts/site
```

Preview XOR at http://127.0.0.1:4175/ and Newton–Schulz at http://127.0.0.1:4175/newton-schulz.html. The build extracts the frozen XOR parameters, checks their encodings and both pages' local links, and renders static HTML before hydration. The client hydrates the case identified by the page's `data-case` attribute.

Use `$...$` for inline mathematics and `$$...$$` for display mathematics. Shared macros are `\R`, `\ReLU`, `\XorSpec`, and `\RN`.

Statement blocks use `\begin{definition}[Title]`, `\begin{theorem}[Title]`, or `\begin{proof}`, with matching `\end{...}` markers. Put each marker on its own line with blank lines around it. The build rejects unmatched environments and invalid LaTeX; math fonts are served locally.
