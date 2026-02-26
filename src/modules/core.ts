import type { ModuleV2 } from '../types';
import { detectFormulas, installFormulas } from './helpers';

const items = [
  { id: 'jq', label: 'jq' },
  { id: 'curl', label: 'curl' },
  { id: 'wget', label: 'wget' },
  { id: 'tree', label: 'tree' },
  { id: 'bat', label: 'bat' },
  { id: 'fd', label: 'fd' },
  { id: 'ripgrep', label: 'ripgrep' },
  { id: 'htop', label: 'htop' },
];

export const coreModule: ModuleV2 = {
  name: 'core',
  label: 'Core Tools',
  description: 'jq, curl, wget, tree, bat, fd, ripgrep, htop',
  items,
  defaultItems: items.map((item) => item.id),
  async detect(selectedItems) {
    return detectFormulas(selectedItems);
  },
  async install(selectedItems, opts) {
    await installFormulas(selectedItems, opts);
  },
};
