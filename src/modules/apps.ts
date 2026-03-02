import type { ModuleV2 } from '../types';
import { detectCasks, installCask, installCasks } from './helpers';

const items = [
  { id: 'google-chrome', label: 'Google Chrome' },
  { id: 'visual-studio-code', label: 'Visual Studio Code' },
  { id: 'sublime-text', label: 'Sublime Text' },
  { id: 'sourcetree', label: 'SourceTree' },
  { id: 'proxyman', label: 'Proxyman' },
  { id: 'charles', label: 'Charles' },
  { id: 'postman', label: 'Postman' },
  { id: 'cursor', label: 'Cursor' },
  { id: 'sf-symbols', label: 'SF Symbols' },
];

export const appsModule: ModuleV2 = {
  name: 'apps',
  label: 'Apps',
  description: 'Developer and utility applications',
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
