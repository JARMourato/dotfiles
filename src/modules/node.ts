import type { Module } from '../types';
import { detectCommands } from './helpers';
import { installFormulas } from './helpers';
import { runCommand } from '../utils/shell';

export const nodeModule: Module = {
  name: 'node',
  label: 'Node.js',
  description: 'Install Node.js using fnm',
  dependencies: ['core'],
  async detect() {
    return detectCommands(['node', 'npm']);
  },
  async install(opts) {
    await installFormulas(['fnm'], opts);
    const version = (opts.profile.config.node as { version?: string } | undefined)?.version ?? 'lts';
    await runCommand('fnm', ['install', version], { dryRun: opts.dryRun, continueOnError: true });
    await runCommand('fnm', ['default', version], { dryRun: opts.dryRun, continueOnError: true });
  },
};
