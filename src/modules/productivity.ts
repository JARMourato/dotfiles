import type { ModuleV2 } from '../types';
import { detectCasks, installCask, installCasks } from './helpers';

const items = [
  { id: 'bitwarden', label: 'Bitwarden' },
  { id: 'betterzip', label: 'BetterZip' },
  { id: 'setapp', label: 'Setapp' },
  { id: 'dockdoor', label: 'DockDoor' },
  { id: 'openaudible', label: 'OpenAudible' },
];

export const productivityModule: ModuleV2 = {
  name: 'productivity',
  label: 'Productivity',
  description: 'Personal productivity and media apps',
  items,
  defaultItems: items.map((item) => item.id),
  dependencies: ['core'],
  async detect(selectedItems) {
    return detectCasks(selectedItems);
  },
  async install(selectedItems, opts) {
    await installCasks(selectedItems, opts);
  },
  async installItem(item, opts) {
    await installCask(item, opts);
  },
};
