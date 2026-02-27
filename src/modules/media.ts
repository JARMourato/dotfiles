import type { ModuleV2 } from '../types';
import { detectCasks, installCask, installCasks } from './helpers';

const items = [
  { id: 'spotify', label: 'Spotify' },
  { id: 'iina', label: 'IINA' },
];

export const mediaModule: ModuleV2 = {
  name: 'media',
  label: 'Media',
  description: 'Music and video apps',
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
