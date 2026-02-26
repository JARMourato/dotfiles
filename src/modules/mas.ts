import type { Module } from '../types';
import { detectMasApps, installMasApps } from './helpers';

const defaults = [472226235, 904280696, 1477385213, 441258766];

export const masModule: Module = {
  name: 'mas',
  label: 'Mac App Store',
  description: 'Install Mac App Store applications by id',
  dependencies: ['core'],
  async detect(opts) {
    const ids = (opts.profile.config.mas?.apps ?? []).map((app) => app.id);
    return detectMasApps(ids.length > 0 ? ids : defaults);
  },
  async install(opts) {
    const ids = (opts.profile.config.mas?.apps ?? []).map((app) => app.id);
    await installMasApps(ids.length > 0 ? ids : defaults, opts);
  },
};
