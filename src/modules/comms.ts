import type { ModuleV2 } from '../types';
import { detectCasks, installCasks } from './helpers';

const items = [
  { id: 'slack', label: 'Slack' },
  { id: 'zoom', label: 'Zoom' },
  { id: 'whatsapp', label: 'WhatsApp' },
  { id: 'telegram', label: 'Telegram' },
];

export const commsModule: ModuleV2 = {
  name: 'comms',
  label: 'Communication',
  description: 'Messaging and meeting apps',
  items,
  defaultItems: items.map((item) => item.id),
  dependencies: ['core'],
  async detect(selectedItems) {
    return detectCasks(selectedItems);
  },
  async install(selectedItems, opts) {
    await installCasks(selectedItems, opts);
  },
};
