/** Convert standalone LaTeX statement markers to MDX components.
 * Markers need blank lines around them; prose and $/$$ math remain Markdown.
 * Each environment has its own numbering, reset for each document.
 */
export default function remarkStatements() {
  return (tree, file) => {
    const source = String(file);
    const counts = { definition: 0, theorem: 0, proof: 0 };
    const marker = node => {
      if (node.type !== 'paragraph') return null;
      const raw = source.slice(node.position.start.offset, node.position.end.offset);
      if (!/^\\(?:begin|end)\{/.test(raw)) return null;
      const match = raw.match(/^\\(begin|end)\{([a-z]+)\}(?:\[([^\]\r\n]+)\])?$/);
      if (!match) file.fail('Statement markers must stand alone, with blank lines around them', node);
      const [, action, kind, title] = match;
      if (!Object.hasOwn(counts, kind)) file.fail(`Unsupported statement environment: ${kind}`, node);
      if (action === 'end' && title) file.fail('An end marker cannot have a title', node);
      return { action, kind, title };
    };

    function transform(parent) {
      const output = [], stack = [];
      const append = node => (stack.length ? stack.at(-1).children : output).push(node);
      for (const node of parent.children) {
        const found = marker(node);
        if (found?.action === 'begin') {
          stack.push({ ...found, number: ++counts[found.kind], children: [], position: node.position });
        } else if (found?.action === 'end') {
          const open = stack.pop();
          if (!open || open.kind !== found.kind) file.fail(`Unmatched \\end{${found.kind}}`, node);
          append({
            type: 'mdxJsxFlowElement', name: 'MathStatement',
            attributes: Object.entries({ kind: open.kind, number: String(open.number), title: open.title || '' })
              .map(([name, value]) => ({ type: 'mdxJsxAttribute', name, value })),
            children: open.children,
            position: { start: open.position.start, end: node.position.end },
          });
        } else {
          if (node.children && node.type !== 'paragraph') transform(node);
          append(node);
        }
      }
      if (stack.length) file.fail(`Unclosed \\begin{${stack.at(-1).kind}}`, stack.at(-1).position);
      parent.children = output;
    }
    transform(tree);
  };
}
