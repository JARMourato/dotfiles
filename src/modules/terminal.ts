import path from 'node:path';
import type { Module } from '../types';
import { detectCommands } from './helpers';
import { runCommand } from '../utils/shell';

export const terminalModule: Module = {
  name: 'terminal',
  label: 'Terminal Setup',
  description: 'oh-my-zsh, powerline, custom theme and terminal assets',
  dependencies: ['core'],
  async detect() {
    return detectCommands(['zsh']);
  },
  async install(opts) {
    const script = path.join(opts.rootDir, 'Terminal', 'set_up_terminal.sh');
    await runCommand('bash', [script], {
      dryRun: opts.dryRun,
      continueOnError: true,
      env: {
        ...process.env,
        DOTFILES_DIR: opts.rootDir,
      },
    });
  },
};
