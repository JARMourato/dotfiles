import type { Module } from '../types';
import { detectCasks, installCasks } from './helpers';

const defaults = ['bitwarden', 'spotify', 'things', 'iina', 'betterzip', 'setapp'];

export const productivityModule: Module = {
  name: 'productivity',
  label: 'Productivity',
  description: 'Bitwarden, Spotify, Things and related tools',
  dependencies: ['core'],
  async detect(opts) {
    const casks = opts.profile.config.productivity?.casks ?? defaults;
    return detectCasks(casks);
  },
  async install(opts) {
    const casks = opts.profile.config.productivity?.casks ?? defaults;
    await installCasks(casks, opts);
  },
};
