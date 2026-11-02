import test from 'node:test';
import assert from 'node:assert/strict';
import { readFileSync } from 'node:fs';
import { pages } from './lib/pages.mjs';

test('each static route identifies its case and selects only its own navigation link', () => {
  for (const page of pages) {
    const html = readFileSync(new URL(`../artifacts/site/${page.file}`, import.meta.url), 'utf8');
    assert.ok(html.includes(`<body data-case="${page.id}">`));
    assert.ok(html.includes(`<title>${page.title}</title>`));
    const navigation = html.match(/<nav class="case-navigation"[^>]*>(.*?)<\/nav>/s)?.[1];
    assert.ok(navigation);
    assert.equal((navigation.match(/aria-current="page"/g) || []).length, 1);
    assert.ok(navigation.includes(`href="${page.file}" aria-current="page"`));
    for (const sibling of pages) assert.ok(navigation.includes(`href="${sibling.file}"`));
    assert.ok(html.includes('class="katex-mathml"'));
    assert.ok(!html.includes('katex-error'));
    assert.ok(!html.includes('{{'));
  }
});

test('the Newton–Schulz route renders its complete proof content without the XOR explorer', () => {
  const html = readFileSync(new URL('../artifacts/site/newton-schulz.html', import.meta.url), 'utf8');
  for (const id of ['algorithm', 'verification', 'cost', 'scope', 'reproduce']) {
    assert.ok(html.includes(`id="${id}"`));
  }
  assert.ok(html.includes('muonIteration_satisfies_spec'));
  assert.ok(html.includes('muonCost_satisfies_spec'));
  assert.ok(!html.includes('id="point-margin"'));
  assert.equal((html.match(/class="math-statement statement-theorem"/g) || []).length, 3);
});
