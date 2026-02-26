import os from 'node:os';
import path from 'node:path';
import type { Module } from '../types';
import { detectCommands, installFormulas } from './helpers';
import { runCommand } from '../utils/shell';

export const rubyModule: Module = {
  name: 'ruby',
  label: 'Ruby',
  description: 'Install Ruby via rbenv and bundler',
  dependencies: ['core'],
  async detect() {
    return detectCommands(['ruby', 'gem', 'rbenv']);
  },
  async install(opts) {
    await installFormulas(['rbenv', 'ruby-build'], opts);
    const configured = (opts.profile.config.ruby as { version?: string } | undefined)?.version;
    const defaultFile = path.join(os.homedir(), '.ruby-version');
    let version = configured ?? '3.4.1';
    const read = await runCommand('cat', [defaultFile], { continueOnError: true });
    if (read.ok && read.stdout.trim()) version = read.stdout.trim();

    await runCommand('rbenv', ['install', '-s', version], { dryRun: opts.dryRun, continueOnError: true });
    await runCommand('rbenv', ['global', version], { dryRun: opts.dryRun, continueOnError: true });
    await runCommand('gem', ['install', 'bundler'], { dryRun: opts.dryRun, continueOnError: true });
  },
};
