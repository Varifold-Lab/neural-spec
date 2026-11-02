import Xor from './xor.mdx';
import NewtonSchulz from './newton-schulz.mdx';
import { pages } from './lib/pages.mjs';

const articles = { xor: Xor, 'newton-schulz': NewtonSchulz };

export default function Page({ name }) {
  const Article = articles[name];
  if (!Article) throw new Error(`Unknown verification case: ${name}`);
  return <>
    <nav className="case-navigation" aria-label="Verification cases">
      {pages.map(page => <a key={page.id} href={page.file}
        aria-current={page.id === name ? 'page' : undefined}>{page.label}</a>)}
    </nav>
    <Article />
  </>;
}
