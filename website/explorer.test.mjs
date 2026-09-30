import test from 'node:test';
import assert from 'node:assert/strict';
import { readFileSync } from 'node:fs';
import { scores, trace, region } from './lib/xor.mjs';

test('all exact region endpoints are included, and the gap is excluded', () => {
  for (const x of [0, 1 / 5, 4 / 5, 1]) {
    for (const y of [0, 1 / 5, 4 / 5, 1]) {
      assert.equal(region(x, y).label, Number(x >= 4 / 5) ^ Number(y >= 4 / 5));
    }
  }
  for (const outside of [-0.01, 0.200001, 0.5, 0.799999, 1.01, NaN, Infinity]) {
    assert.equal(region(outside, 0.1), null);
    assert.equal(region(0.9, outside), null);
  }
});

test('browser scores use the frozen parameter layout', () => {
  // Independent matrix interpretation from the Lean rational definitions.
  const source = readFileSync(new URL('../NeuralSpec/Network/Xor/Parameters.lean', import.meta.url), 'utf8');
  const p = Object.fromEntries([...source.matchAll(/^def (\w+) : ℚ := (-?\d+) \/ (\d+)$/gm)]
    .map(([, name, numerator, denominator]) => [name, Number(numerator) / Number(denominator)]));
  for (const [x, y] of [[0.1, 0.1], [0.1, 0.9], [0.9, 0.1], [0.9, 0.9], [0.5, 0.5], [0, 1]]) {
    const h = [0, 1, 2, 3].map(i => Math.max(0, p[`w1_${i}0`] * x + p[`w1_${i}1`] * y + p[`b1_${i}`]));
    const expected = [0, 1].map(j => h.reduce((v, value, i) => v + p[`w2_${j}${i}`] * value, p[`b2_${j}`]));
    scores(x, y).forEach((value, j) => assert.ok(Math.abs(value - expected[j]) < 1e-14));
    const values = trace(x, y);
    values.hidden.forEach((value, i) => assert.equal(value, h[i]));
    values.pre.forEach((value, i) => assert.equal(value, p[`w1_${i}0`] * x + p[`w1_${i}1`] * y + p[`b1_${i}`]));
  }
});

test('the MDX build includes a readable forward pass without JavaScript', () => {
  const html = readFileSync(new URL('../artifacts/site/index.html', import.meta.url), 'utf8');
  assert.ok(html.includes('A forward pass through the trained network'));
  assert.ok(html.includes('JavaScript binary64 arithmetic'));
  assert.match(html, /id="point-margin">-?\d+\.\d{5}</);
  assert.ok(html.includes('id="specification"'));
  assert.ok(!html.includes('{{'));
});
