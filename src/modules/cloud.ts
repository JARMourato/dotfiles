import type { ModuleV2 } from '../types';
import { detectCasks, detectFormulas, installCasks, installFormulas } from './helpers';

const items = [
  { id: 'docker-desktop', label: 'Docker', critical: true },
  { id: 'docker-compose', label: 'docker-compose' },
  { id: 'terraform', label: 'terraform' },
  { id: 'ansible', label: 'ansible' },
  { id: 'awscli', label: 'awscli' },
  { id: 'kubernetes-cli', label: 'kubernetes-cli' },
];

const caskItems = new Set(['docker-desktop']);

export const cloudModule: ModuleV2 = {
  name: 'cloud',
  label: 'Cloud',
  description: 'Docker and cloud tooling',
  items,
  defaultItems: items.map((item) => item.id),
  dependencies: ['core'],
  async detect(selectedItems) {
    const formulas = selectedItems.filter((item) => !caskItems.has(item));
    const casks = selectedItems.filter((item) => caskItems.has(item));
    const formulaDetect = formulas.length > 0
      ? await detectFormulas(formulas)
      : { installed: [], missing: [], partial: false };
    const caskDetect = casks.length > 0
      ? await detectCasks(casks)
      : { installed: [], missing: [], partial: false };

    return {
      installed: [...formulaDetect.installed, ...caskDetect.installed],
      missing: [...formulaDetect.missing, ...caskDetect.missing],
      partial: formulaDetect.partial || caskDetect.partial,
    };
  },
  async install(selectedItems, opts) {
    const formulas = selectedItems.filter((item) => !caskItems.has(item));
    const casks = selectedItems.filter((item) => caskItems.has(item));
    if (formulas.length > 0) {
      await installFormulas(formulas, opts);
    }
    if (casks.length > 0) {
      await installCasks(casks, opts);
    }
  },
};
