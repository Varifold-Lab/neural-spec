import { parameters } from '../../artifacts/site/assets/parameters.mjs';

// Reading aid: JavaScript binary64 operations approximate the exact-real network.
// They do not implement the theorem's separately rounded binary32 operations.
export function trace(x, y) {
  const pre = Array.from({ length: 4 }, (_, i) =>
    parameters[2 * i] * x + parameters[2 * i + 1] * y + parameters[8 + i]);
  const hidden = pre.map(value => Math.max(0, value));
  const scores = [0, 1].map(j => hidden.reduce((sum, h, i) =>
    sum + parameters[12 + 4 * j + i] * h, 0) + parameters[20 + j]);
  return { pre, hidden, scores };
}

export function scores(x, y) {
  return trace(x, y).scores;
}

export function region(x, y) {
  const band = value => value >= 0 && value <= 1 / 5 ? 0
    : value >= 4 / 5 && value <= 1 ? 1 : null;
  const a = band(x), b = band(y);
  return a === null || b === null ? null : { label: a ^ b, name: `${a ? 'H' : 'L'} × ${b ? 'H' : 'L'}` };
}
