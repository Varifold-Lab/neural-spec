const names = { definition: 'Definition', theorem: 'Theorem', proof: 'Proof' };

export function MathStatement({ kind, number, title, children }) {
  const id = `${kind}-${number}`;
  return <section id={id} className={`math-statement statement-${kind}`} aria-labelledby={`${id}-title`}>
    <p className="statement-title" id={`${id}-title`}>
      <strong>{names[kind]}{kind === 'proof' ? '' : ` ${number}`}.</strong>{title && <span> {title}.</span>}
    </p>
    <div className="statement-body">{children}</div>
  </section>;
}
