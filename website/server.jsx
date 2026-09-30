import { renderToString } from 'react-dom/server';
import Page from './Page.jsx';

export function renderPage() {
  return renderToString(<Page />);
}
