import type { Module } from '../types';
import { detectCasks, installCasks } from './helpers';

const defaults = [
  'google-chrome',
  'visual-studio-code',
  'sublime-text',
  'docker',
  'postman',
  'sourcetree',
  'cursor',
  'proxyman',
  'charles',
];

export const appsModule: Module = {
  name: 'apps',
  label: 'Applications',
  description: 'Developer and productivity application casks',
  dependencies: ['core'],
  async detect(opts) {
    const casks = opts.profile.config.apps?.casks ?? defaults;
    return detectCasks(casks);
  },
  async install(opts) {
    const casks = opts.profile.config.apps?.casks ?? defaults;
    await installCasks(casks, opts);
  },
};
