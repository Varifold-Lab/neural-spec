import { useEffect, useState } from 'react';
import { trace, region } from '../lib/xor.mjs';

const steps = ['Inputs', 'Weighted sums', 'ReLU', 'Scores'];
const explanations = [
  'The two coordinates enter the network. The four shaded boxes are the specified input regions.',
  'Each hidden unit multiplies the inputs by its weights and adds a bias: aᵢ = wᵢ₁x₁ + wᵢ₂x₂ + bᵢ.',
  'ReLU sets negative weighted sums to zero: hᵢ = max(0, aᵢ). Grey units contribute zero to both scores.',
  'The output layer combines the hidden values with another set of weights and biases. The larger score selects the class.',
];
const presets = [[0.1, 0.1, 'L × L'], [0.1, 0.9, 'L × H'], [0.9, 0.1, 'H × L'], [0.9, 0.9, 'H × H']];
const format = value => value.toFixed(3);

function Regions({ x, y }) {
  return <svg className="region-plot" viewBox="0 0 344 330" role="img"
    aria-label={`Four closed XOR regions with the selected input at (${x.toFixed(2)}, ${y.toFixed(2)}). Class 0 in the lower-left and upper-right; class 1 in the other two boxes.`}>
    <rect className="plot-ground" x="48" y="26" width="260" height="260" />
    <path className="tick-line" d="M100 26V286 M256 26V286 M48 78H308 M48 234H308" />
    <rect className="region-same" x="48" y="234" width="52" height="52" />
    <rect className="region-different" x="48" y="26" width="52" height="52" />
    <rect className="region-different" x="256" y="234" width="52" height="52" />
    <rect className="region-same" x="256" y="26" width="52" height="52" />
    <text className="region-label" x="74" y="265">0</text><text className="region-label" x="74" y="57">1</text>
    <text className="region-label" x="282" y="265">1</text><text className="region-label" x="282" y="57">0</text>
    <text className="empty-label" x="178" y="150">Outside the</text><text className="empty-label" x="178" y="167">specified domain</text>
    <text x="48" y="306">0</text><text x="100" y="306">⅕</text><text x="256" y="306">⅘</text><text x="308" y="306">1</text>
    <text x="29" y="290">0</text><text x="29" y="238">⅕</text><text x="29" y="82">⅘</text><text x="29" y="30">1</text>
    <text className="axis-label" x="331" y="290">x₁</text><text className="axis-label" x="47" y="14">x₂</text>
    <circle className="point" cx={48 + 260 * x} cy={286 - 260 * y} r="5" />
  </svg>;
}

function NetworkDiagram({ x, y, values, step, playing, vertical = false }) {
  const inputs = vertical ? [[90, 48], [270, 48]] : [[72, 112], [72, 232]];
  const hidden = vertical ? [42, 134, 226, 318].map(cx => [cx, 168]) : [64, 136, 208, 280].map(cy => [360, cy]);
  const outputs = vertical ? [[90, 288], [270, 288]] : [[648, 112], [648, 232]];
  const inputWidth = vertical ? 90 : 116, hiddenWidth = vertical ? 76 : 140;
  const predicted = values.scores[1] > values.scores[0] ? 1 : values.scores[0] > values.scores[1] ? 0 : null;
  const edge = (from, to, fromWidth, toWidth) => {
    if (vertical) {
      const middle = (from[1] + to[1]) / 2;
      return `M${from[0]} ${from[1] + 26} C${from[0]} ${middle} ${to[0]} ${middle} ${to[0]} ${to[1] - 26}`;
    }
    return `M${from[0] + fromWidth / 2} ${from[1]} C${from[0] + fromWidth / 2 + 80} ${from[1]} ${to[0] - toWidth / 2 - 70} ${to[1]} ${to[0] - toWidth / 2} ${to[1]}`;
  };
  const labels = vertical ? [[180, 12, 'Inputs'], [180, 110, step === 1 ? 'Weighted sums' : 'Hidden layer · ReLU'], [180, 230, 'Class scores']]
    : [[72, 18, 'Inputs'], [360, 18, step === 1 ? 'Weighted sums' : 'Hidden layer · ReLU'], [648, 18, 'Class scores']];
  const hiddenDescription = step === 0 ? '' : `${step === 1 ? 'Weighted sums' : 'Hidden ReLU values'}: ${(step === 1 ? values.pre : values.hidden).map(format).join(', ')}.`;
  return <svg className={`network-plot ${vertical ? 'network-vertical' : 'network-horizontal'}`}
    viewBox={vertical ? '0 0 360 320' : '0 0 720 324'} role="img"
    aria-label={`Step: ${steps[step]}. Inputs: ${x.toFixed(2)}, ${y.toFixed(2)}. ${hiddenDescription} ${step === 3 ? `Class scores: ${values.scores.map(format).join(', ')}.` : ''}`}>
    {inputs.flatMap((from, j) => hidden.map((to, i) => {
      const path = edge(from, to, inputWidth, hiddenWidth);
      return <g key={`in-${j}-${i}`} className={`connection ${step >= 1 ? 'computed' : ''}`}>
        <path d={path} />{playing && step === 1 && <path className="signal" d={path} />}
      </g>;
    }))}
    {hidden.flatMap((from, i) => outputs.map((to, j) => {
      const path = edge(from, to, hiddenWidth, inputWidth);
      return <g key={`out-${i}-${j}`} className={`connection ${step >= 3 && values.hidden[i] > 0 ? 'computed' : ''}`}>
        <path d={path} />{playing && step === 3 && values.hidden[i] > 0 && <path className="signal" d={path} />}
      </g>;
    }))}
    {labels.map(([cx, cy, label]) => <g key={label}>
      {vertical && <rect className="label-ground" x={cx - 80} y={cy - 13} width="160" height="18" />}
      <text className="layer-label" x={cx} y={cy}>{label}</text>
    </g>)}
    {[x, y].map((value, i) => <g key={i} className="network-node input-node">
      <rect x={inputs[i][0] - inputWidth / 2} y={inputs[i][1] - 26} width={inputWidth} height="52" rx="5" />
      <text x={inputs[i][0]} y={inputs[i][1] - 7}>{i === 0 ? 'x₁' : 'x₂'}</text>
      <text className="node-value" x={inputs[i][0]} y={inputs[i][1] + 14}>{value.toFixed(2)}</text>
    </g>)}
    {hidden.map(([cx, cy], i) => <g key={i} className={`network-node hidden-node ${step < 1 ? 'pending' : ''} ${step >= 2 && values.hidden[i] === 0 ? 'inactive' : ''}`}>
      <rect x={cx - hiddenWidth / 2} y={cy - 26} width={hiddenWidth} height="52" rx="5" />
      <text x={cx} y={cy - 7}>{step === 1 ? `a${'₀₁₂₃'[i]}` : `h${'₀₁₂₃'[i]}`}</text>
      <text className="node-value" x={cx} y={cy + 14}>{step === 0 ? '—' : format(step === 1 ? values.pre[i] : values.hidden[i])}</text>
    </g>)}
    {values.scores.map((value, i) => <g key={i} className={`network-node output-node ${step < 3 ? 'pending' : i === predicted ? 'selected' : ''}`}>
      <rect x={outputs[i][0] - inputWidth / 2} y={outputs[i][1] - 26} width={inputWidth} height="52" rx="5" />
      <text x={outputs[i][0]} y={outputs[i][1] - 7}>{i === 0 ? 'z₀' : 'z₁'}</text>
      <text className="node-value" x={outputs[i][0]} y={outputs[i][1] + 14}>{step < 3 ? '—' : format(value)}</text>
    </g>)}
  </svg>;
}

function Network(props) {
  return <><NetworkDiagram {...props} /><NetworkDiagram {...props} vertical /></>;
}

export function XorAnimation() {
  const [x, setX] = useState(0.1), [y, setY] = useState(0.9);
  const [step, setStep] = useState(3), [playing, setPlaying] = useState(false);
  const [ready, setReady] = useState(false);
  const values = trace(x, y), domain = region(x, y);
  const predicted = values.scores[1] > values.scores[0] ? 1 : values.scores[0] > values.scores[1] ? 0 : 'Tie';
  useEffect(() => { setReady(true); }, []);
  useEffect(() => {
    if (!playing) return;
    const timer = setTimeout(() => {
      if (step === 3) setPlaying(false);
      else setStep(current => current + 1);
    }, 1400);
    return () => clearTimeout(timer);
  }, [playing, step]);

  const changePoint = (nextX, nextY) => {
    setPlaying(false);
    setStep(3);
    setX(nextX);
    setY(nextY);
  };
  const selectStep = next => { setPlaying(false); setStep(next); };
  const play = () => {
    if (playing) setPlaying(false);
    else { if (step === 3) setStep(0); setPlaying(true); }
  };

  return <figure className="xor-animation" id="xor-animation" aria-labelledby="animation-title">
    <div className="figure-label"><span id="animation-title">A forward pass through the trained network</span><span>Browser illustration</span></div>
    <div className="explorer-grid">
      <Regions x={x} y={y} />
      <div className="explorer-controls">
        <label htmlFor="input-x">x₁ <output id="value-x" htmlFor="input-x">{x.toFixed(2)}</output></label>
        <input id="input-x" type="range" min="0" max="1" step="0.01" value={x} disabled={!ready}
          onChange={event => changePoint(Number(event.target.value), y)} />
        <label htmlFor="input-y">x₂ <output id="value-y" htmlFor="input-y">{y.toFixed(2)}</output></label>
        <input id="input-y" type="range" min="0" max="1" step="0.01" value={y} disabled={!ready}
          onChange={event => changePoint(x, Number(event.target.value))} />
        <div className="presets" role="group" aria-label="Select a region center">
          {presets.map(([px, py, label]) => <button key={label} type="button" disabled={!ready}
            aria-pressed={px === x && py === y} onClick={() => changePoint(px, py)}>{label}</button>)}
        </div>
        <div className="explorer-result" data-outside={domain ? undefined : true}>
          <strong id="domain-status">{domain ? `Inside ${domain.name} · expected class ${domain.label}` : 'Outside the specified domain · no theorem claim'}</strong>
          <dl><div><dt>Predicted class</dt><dd id="predicted-label">{step === 3 ? predicted : '—'}</dd></div>
            <div><dt>Correct-class margin</dt><dd id="point-margin">{!domain ? 'No claim' : step === 3 ? (values.scores[domain.label] - values.scores[1 - domain.label]).toFixed(5) : '—'}</dd></div>
            <div><dt>Required bound in the theorem</dt><dd>¼</dd></div></dl>
        </div>
      </div>
    </div>
    <div className="animation-toolbar">
      <button className="play-button" type="button" onClick={play} disabled={!ready}
        aria-label={playing ? 'Pause the forward pass' : step === 3 ? 'Play the forward pass' : 'Continue the forward pass'}>
        {playing ? 'Pause' : step === 3 ? 'Play' : 'Continue'}
      </button>
      <div className="animation-steps" role="group" aria-label="Forward pass steps">
        {steps.map((label, i) => <button key={label} type="button" disabled={!ready} aria-pressed={step === i}
          onClick={() => selectStep(i)}><span aria-hidden="true">{i + 1}. </span>{label}</button>)}
      </div>
    </div>
    <Network x={x} y={y} values={values} step={step} playing={playing} />
    <p className="step-explanation" role="status" aria-live="polite" aria-atomic="true">{explanations[step]}</p>
    <noscript><p>Enable JavaScript to change inputs or play the forward pass.</p></noscript>
    <figcaption>Values use JavaScript binary64 arithmetic with the frozen trained parameters and are rounded for display. This illustration approximates the exact-real network; it is not a checker result or a proof of the binary32 guarantee.</figcaption>
  </figure>;
}
