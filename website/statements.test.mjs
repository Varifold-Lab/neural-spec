import test from 'node:test';
import assert from 'node:assert/strict';
import { readFileSync, existsSync } from 'node:fs';
import { compile } from '@mdx-js/mdx';
import remarkMath from 'remark-math';
import rehypeKatex from 'rehype-katex';
import remarkStatements from './lib/remark-statements.mjs';
import { mathMacros, rejectMathErrors } from './lib/math.mjs';

const options = {
  remarkPlugins: [remarkMath, remarkStatements],
  rehypePlugins: [[rehypeKatex, { macros: mathMacros, strict: 'error' }], rejectMathErrors],
};

test('statement environments number independently and preserve LaTeX bodies', async () => {
  let statements;
  const capture = () => tree => { statements = tree.children.filter(node => node.name === 'MathStatement'); };
  const source = String.raw`\begin{definition}[Domain]

Let $D\subseteq\R^2$.

\end{definition}

\begin{theorem}[Margin]

$$
\forall x\in D,\quad m(x)\ge\frac14.
$$

\end{theorem}

\begin{proof}

Use the bound.

\end{proof}

\begin{definition}[Scores]

Let $z:D\to\R^2$.

\end{definition}`;
  await compile(source, { ...options, remarkPlugins: [...options.remarkPlugins, capture] });
  assert.deepEqual(statements.map(node => Object.fromEntries(node.attributes.map(attr => [attr.name, attr.value]))), [
    { kind: 'definition', number: '1', title: 'Domain' },
    { kind: 'theorem', number: '1', title: 'Margin' },
    { kind: 'proof', number: '1', title: '' },
    { kind: 'definition', number: '2', title: 'Scores' },
  ]);
  assert.equal(statements[1].children[0].type, 'math');
  assert.ok(statements[1].children[0].value.includes('\\frac14'));
});

test('unmatched and unclosed statement environments fail compilation', async () => {
  for (const source of [
    String.raw`\end{theorem}`,
    String.raw`\begin{theorem}`,
    String.raw`\begin{theorem}` + '\n\nClaim.\n\n' + String.raw`\end{definition}`,
  ]) await assert.rejects(compile(source, options), /Unmatched|Unclosed/);
});

test('invalid LaTeX fails compilation', async () => {
  await assert.rejects(compile(String.raw`$$
\thisCommandDoesNotExist
$$`, options), /Undefined control sequence/);
});

test('the published page includes numbered statements, accessible math, and local fonts', () => {
  const html = readFileSync(new URL('../artifacts/site/index.html', import.meta.url), 'utf8');
  assert.equal((html.match(/class="math-statement statement-definition"/g) || []).length, 4);
  assert.equal((html.match(/class="math-statement statement-theorem"/g) || []).length, 2);
  assert.ok(html.includes('id="theorem-1-title"'));
  assert.ok(html.includes('id="theorem-2-title"'));
  assert.ok(html.includes('class="katex-mathml"'));
  assert.ok(html.includes('encoding="application/x-tex"'));
  assert.ok(!html.includes('katex-error'));
  assert.ok(!html.includes('\\begin{theorem}'));
  assert.ok(existsSync(new URL('../artifacts/site/assets/katex/fonts/KaTeX_Main-Regular.woff2', import.meta.url)));
});
