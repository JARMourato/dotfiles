import type { Module } from '../types';
import { detectCasks, installCasks } from './helpers';

const defaults = ['slack', 'zoom', 'whatsapp', 'telegram'];

export const commsModule: Module = {
  name: 'comms',
  label: 'Communication',
  description: 'Slack, Zoom, WhatsApp, Telegram',
  dependencies: ['core'],
  async detect(opts) {
    const casks = opts.profile.config.comms?.casks ?? defaults;
    return detectCasks(casks);
  },
  async install(opts) {
    const casks = opts.profile.config.comms?.casks ?? defaults;
    await installCasks(casks, opts);
  },
};
