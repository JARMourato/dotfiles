import { promises as fs } from 'node:fs';

import path from 'node:path';
import { confirm, isCancel, log } from '@clack/prompts';
import chalk from 'chalk';
import type { InstallOptions } from './types';
import { clearDefaultsBackup, restoreAllDefaults } from './defaults-backup';
import { PREVIOUS_STATE_PATH, STATE_PATH } from './state';
import { realHome, runCommand } from './utils/shell';
import { uninstallCasks, uninstallFormulas } from './modules/helpers';

const MANAGED_FORMULAS = [
  'jq',
  'curl',
  'wget',
  'tree',
  'bat',
  'fd',
  'ripgrep',
  'htop',
  'swiftlint',
  'swiftformat',
  'cocoapods',
  'fastlane',
  'carthage',
  'xcbeautify',
  'docker-compose',
  'terraform',
  'ansible',
  'awscli',
  'kubernetes-cli',
  'openjdk',
  'bundletool',
  'pyenv',
  'python',
  'rbenv',
  'ruby-build',
  'aria2',
  'robotsandpencils/made/xcodes',
];
const MANAGED_CASKS = [
  'docker',
  'android-studio',
  'google-chrome',
  'visual-studio-code',
  'sublime-text',
  'sourcetree',
  'proxyman',
  'charles',
  'postman',
  'cursor',
  'sf-symbols',
  'slack',
  'zoom',
  'whatsapp',
  'telegram',
  'bitwarden',
  'betterzip',
  'setapp',
  'dockdoor',
  'openaudible',
  'spotify',
  'iina',
  'claude',
  'chatgpt',
];
const DOTFILES = ['.aliases', '.exports', '.paths', '.gemrc', '.ruby-version', '.zshrc'];
const ANDROID_ENV_MARKER = '# macsetup: android env';

function handleCancelled<T>(value: T): T {
  if (isCancel(value)) {
    throw new Error('Operation cancelled.');
  }
  return value;
}

async function removeAndroidExportsLines(dryRun: boolean): Promise<void> {
  const exportsPath = path.join(realHome(), '.exports');
  let contents = '';
  try {
    contents = await fs.readFile(exportsPath, 'utf8');
  } catch {
    return;
  }

  const lines = contents.split('\n');
  const filtered = lines.filter((line) => !line.includes('ANDROID_HOME') && !line.includes(ANDROID_ENV_MARKER));
  if (dryRun) return;
  await fs.writeFile(exportsPath, filtered.join('\n'), 'utf8');
}

async function removeDotfileSymlinks(rootDir: string, dryRun: boolean): Promise<void> {
  void rootDir;
  for (const dotfile of DOTFILES) {
    const filePath = path.join(realHome(), dotfile);
    try {
      await fs.readlink(filePath);
      if (!dryRun) {
        await fs.rm(filePath, { force: true });
      }
    } catch {
      // Not a symlink or not present
    }
  }
}

async function removeHomebrew(dryRun: boolean): Promise<void> {
  await runCommand(
    '/bin/bash',
    ['-c', '$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/uninstall.sh)'],
    { dryRun, continueOnError: true },
  );
}

export async function runReset(rootDir: string, dryRun: boolean): Promise<void> {
  log.info(chalk.bold(chalk.red('Reset mode (aggressive): this will remove most macsetup-managed changes.')));
  log.info(chalk.yellow('Safety: SSH keys and git config are intentionally skipped.'));
  log.step(chalk.bold('Preview'));
  log.info('1) Restore macOS defaults from ~/.macsetup-defaults-backup.json');
  log.info(`2) Uninstall formulas: ${MANAGED_FORMULAS.join(', ')}`);
  log.info(`3) Uninstall casks: ${MANAGED_CASKS.join(', ')}`);
  log.info('4) Uninstall npm globals: @anthropic-ai/claude-code, @openai/codex');
  log.info(`5) Remove dotfile symlinks: ${DOTFILES.join(', ')}`);
  log.info('6) Remove ~/.oh-my-zsh and ~/.config/powerline-shell');
  log.info('7) Remove ANDROID_HOME lines from ~/.exports');
  log.info('8) Skip SSH keys (safety)');
  log.info('9) Skip git config (safety)');
  log.info('10) Clear ~/.macsetup-state.json and ~/.macsetup-state.previous.json');
  log.info('11) Clear ~/.macsetup-defaults-backup.json');
  log.info('12) Optionally remove Homebrew (extra prompt)');

  if (dryRun) {
    log.info(chalk.cyan('Dry run enabled: preview only, no changes were applied.'));
    return;
  }

  const confirmed = handleCancelled(
    await confirm({
      message: 'Proceed with full reset?',
      initialValue: false,
    }),
  );
  if (!confirmed) {
    return;
  }

  const installOpts: InstallOptions = {
    dryRun: false,
    verbose: false,
    profile: { name: 'reset', description: 'reset', config: {} },
    state: {
      async load() { return null; },
      async save() { return; },
      async diff() { return []; },
    },
    rootDir,
  };

  await restoreAllDefaults(false);
  await uninstallFormulas(MANAGED_FORMULAS, installOpts);
  await uninstallCasks(MANAGED_CASKS, installOpts);
  await runCommand('npm', ['uninstall', '-g', '@anthropic-ai/claude-code'], { continueOnError: true });
  await runCommand('npm', ['uninstall', '-g', '@openai/codex'], { continueOnError: true });
  await removeDotfileSymlinks(rootDir, false);
  await runCommand('rm', ['-rf', path.join(realHome(), '.oh-my-zsh')], { continueOnError: true });
  await runCommand('rm', ['-rf', path.join(realHome(), '.config', 'powerline-shell')], { continueOnError: true });
  await removeAndroidExportsLines(false);
  await fs.rm(STATE_PATH, { force: true });
  await fs.rm(PREVIOUS_STATE_PATH, { force: true });
  await clearDefaultsBackup(false);

  const removeBrew = handleCancelled(
    await confirm({
      message: 'Also remove Homebrew? This is rarely needed.',
      initialValue: false,
    }),
  );
  if (removeBrew) {
    await removeHomebrew(false);
  }
}
