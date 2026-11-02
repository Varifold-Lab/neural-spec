import { hydrateRoot } from 'react-dom/client';
import Page from './Page.jsx';

hydrateRoot(document.getElementById('main'), <Page name={document.body.dataset.case} />);
