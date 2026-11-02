import { renderToString } from 'react-dom/server';
import Page from './Page.jsx';

export function renderPage(name) {
  return renderToString(<Page name={name} />);
}
