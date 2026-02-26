import type { Module } from '../types';
import { detectCasks, detectFormulas, installCasks, installFormulas } from './helpers';

const formulas = ['docker-compose', 'terraform', 'ansible', 'awscli', 'kubernetes-cli'];
const casks = ['docker'];

export const cloudModule: Module = {
  name: 'cloud',
  label: 'Cloud Tools',
  description: 'docker, terraform, ansible, awscli, kubernetes-cli',
  dependencies: ['core'],
  async detect(opts) {
    const config = (opts.profile.config.cloud as { formulas?: string[] } | undefined)?.formulas ?? formulas;
    return detectFormulas(config);
  },
  async install(opts) {
    const config = opts.profile.config.cloud as { formulas?: string[]; casks?: string[] } | undefined;
    await installFormulas(config?.formulas ?? formulas, opts);
    await installCasks(config?.casks ?? casks, opts);
  },
};

export async function detectCloudCasks(opts: Parameters<Module['detect']>[0]) {
  const config = opts.profile.config.cloud as { casks?: string[] } | undefined;
  return detectCasks(config?.casks ?? casks);
}
