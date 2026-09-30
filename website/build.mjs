import { build } from 'esbuild';
import mdx from '@mdx-js/esbuild';
import remarkMath from 'remark-math';
import rehypeKatex from 'rehype-katex';
import remarkStatements from './lib/remark-statements.mjs';
import { mathMacros, rejectMathErrors } from './lib/math.mjs';
import { createHash } from 'node:crypto';
import { cp, mkdir, readFile, writeFile } from 'node:fs/promises';
import { execFileSync } from 'node:child_process';
import { fileURLToPath } from 'node:url';

const root = fileURLToPath(new URL('../', import.meta.url));
const out = new URL('../artifacts/site/', import.meta.url);
const python = (...args) => execFileSync('python3', ['scripts/build_site.py', ...args], { cwd: root, stdio: 'inherit' });
python('--prepare');
// Serve the math stylesheet and fonts locally, including under a GitHub Pages subpath.
const katexAssets = new URL('./node_modules/katex/dist/', import.meta.url);
await mkdir(new URL('assets/katex/', out), { recursive: true });
await cp(new URL('katex.min.css', katexAssets), new URL('assets/katex/katex.min.css', out));
await cp(new URL('fonts/', katexAssets), new URL('assets/katex/fonts/', out), { recursive: true });
const notices = await Promise.all(['react', 'react-dom', 'katex'].map(async name =>
  `${name}\n\n${await readFile(new URL(`./node_modules/${name}/LICENSE`, import.meta.url), 'utf8')}`));
await writeFile(new URL('assets/THIRD_PARTY_NOTICES.txt', out), notices.join('\n\n'));
const common = {
  absWorkingDir: fileURLToPath(new URL('./', import.meta.url)),
  bundle: true,
  jsx: 'automatic',
  plugins: [mdx({
    remarkPlugins: [remarkMath, remarkStatements],
    rehypePlugins: [[rehypeKatex, { macros: mathMacros, strict: 'error' }], rejectMathErrors],
  })],
  logLevel: 'info',
};

// Keep the server renderer outside the public output. The article is readable without JavaScript.
const serverModule = new URL('../artifacts/site-render.cjs', import.meta.url);
await build({ ...common, entryPoints: ['server.jsx'], outfile: fileURLToPath(serverModule),
  platform: 'node', format: 'cjs', define: { 'process.env.NODE_ENV': '"production"' } });
const { default: renderer } = await import(serverModule.href);
const article = renderer.renderPage();
const client = await build({ ...common, entryPoints: ['client.jsx'],
  outfile: fileURLToPath(new URL('assets/page.js', out)),
  platform: 'browser', format: 'esm', minify: true,
  define: { 'process.env.NODE_ENV': '"production"' }, metafile: true });
for (const [file, metadata] of Object.entries(client.metafile.outputs)) {
  if (file.endsWith('page.js')) console.log(`Browser bundle: ${(metadata.bytes / 1024).toFixed(1)} KiB`);
}
const version = createHash('sha256').update(await readFile(new URL('assets/style.css', out))).digest('hex').slice(0, 12);
const template = await readFile(new URL('./index.html', import.meta.url), 'utf8');
await writeFile(new URL('index.html', out), template.replace('{{style_version}}', version).replace('{{article}}', article));
python('--check');
