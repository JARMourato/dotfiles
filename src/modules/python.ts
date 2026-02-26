import type { Module } from '../types';
import { detectCommands, installFormulas } from './helpers';
import { runCommand } from '../utils/shell';

export const pythonModule: Module = {
  name: 'python',
  label: 'Python',
  description: 'Install Python via pyenv and pip baseline tools',
  dependencies: ['core'],
  async detect() {
    return detectCommands(['python3', 'pip3']);
  },
  async install(opts) {
    await installFormulas(['pyenv', 'python'], opts);
    const versions = (opts.profile.config.python as { versions?: string[] } | undefined)?.versions ?? ['3.12'];
    for (const version of versions) {
      await runCommand('pyenv', ['install', '-s', version], { dryRun: opts.dryRun, continueOnError: true });
      await runCommand('pyenv', ['global', version], { dryRun: opts.dryRun, continueOnError: true });
    }
    await runCommand('pip3', ['install', '--upgrade', '--break-system-packages', 'pip', 'setuptools', 'wheel'], {
      dryRun: opts.dryRun,
      continueOnError: true,
    });
    await runCommand('pip3', ['install', '--break-system-packages', 'pyusb'], {
      dryRun: opts.dryRun,
      continueOnError: true,
    });
  },
};
