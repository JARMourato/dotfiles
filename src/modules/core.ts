import type { Module } from '../types';
import { detectFormulas, installFormulas } from './helpers';
import { runCommand } from '../utils/shell';

const defaultFormulas = [
  'git',
  'gh',
  'curl',
  'wget',
  'jq',
  'tree',
  'bat',
  'fd',
  'ripgrep',
  'htop',
  'mas',
];

async function ensureHomebrew(dryRun: boolean): Promise<void> {
  const exists = (await runCommand('brew', ['--version'], { continueOnError: true })).ok;
  if (exists) {
    await runCommand('brew', ['update'], { dryRun, continueOnError: true });
    return;
  }

  await runCommand(
    '/bin/bash',
    ['-c', '$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)'],
    { dryRun, continueOnError: true },
  );
  await runCommand('brew', ['update'], { dryRun, continueOnError: true });
}

export const coreModule: Module = {
  name: 'core',
  label: 'Core Tools',
  description: 'git, gh, curl, wget, jq, tree, bat, fd, ripgrep, htop, mas',
  async detect(opts) {
    const formulas = (opts.profile.config.core?.formulas as string[] | undefined) ?? defaultFormulas;
    return detectFormulas(formulas);
  },
  async install(opts) {
    const formulas = (opts.profile.config.core?.formulas as string[] | undefined) ?? defaultFormulas;
    await ensureHomebrew(opts.dryRun);
    await installFormulas(formulas, opts);
  },
};
