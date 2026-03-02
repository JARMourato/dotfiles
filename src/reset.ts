import { promises as fs } from 'node:fs';

import path from 'node:path';
import { confirm, isCancel, log } from '@clack/prompts';
import chalk from 'chalk';
import type { InstallOptions } from './types';
import { clearDefaultsBackup, restoreAllDefaults } from './defaults-backup';
import { PREVIOUS_STATE_PATH, STATE_PATH } from './state';
import { commandExists, realHome, runAsUser, runCommand } from './utils/shell';
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
  'dockutil',
];
const MANAGED_CASKS = [
  'docker-desktop',
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
  // 'telegram', — skipped: control channel for OpenClaw, same install path as other casks
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
const MANAGED_MAS_APPS = [
  { id: 472226235, name: 'LanScan' },
  { id: 904280696, name: 'Things 3' },
  { id: 441258766, name: 'Magnet' },
];
const NPM_GLOBALS = ['@anthropic-ai/claude-code', '@openai/codex'];
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

async function removeDotfileSymlinks(dryRun: boolean): Promise<void> {
  // Remove symlinks in ~/
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

  // Remove the ~/.dotfiles/ staging directory
  const dotfilesDir = path.join(realHome(), '.dotfiles');
  try {
    await fs.access(dotfilesDir);
    if (!dryRun) {
      await fs.rm(dotfilesDir, { recursive: true, force: true });
    }
  } catch {
    // Not present
  }
}

async function removeMesloFonts(dryRun: boolean): Promise<void> {
  const fontsDir = path.join(realHome(), 'Library', 'Fonts');
  try {
    const files = await fs.readdir(fontsDir);
    const mesloFiles = files.filter((f) => f.startsWith('Meslo'));
    for (const font of mesloFiles) {
      if (!dryRun) {
        await fs.rm(path.join(fontsDir, font), { force: true });
      }
    }
    if (mesloFiles.length > 0) {
      log.info(`Removed ${mesloFiles.length} Meslo font(s)`);
    }
  } catch {
    // Fonts dir doesn't exist or no access
  }
}

async function uninstallPowerlineShell(dryRun: boolean): Promise<void> {
  if (await commandExists('powerline-shell')) {
    await runAsUser('pip3', ['uninstall', '-y', 'powerline-shell'], { dryRun, continueOnError: true });
  }
}

async function uninstallMasApps(dryRun: boolean): Promise<void> {
  if (!(await commandExists('mas'))) return;
  for (const app of MANAGED_MAS_APPS) {
    const check = await runCommand('mas', ['list'], { continueOnError: true });
    if (check.ok && check.stdout.includes(String(app.id))) {
      log.info(`Uninstalling ${app.name} (${app.id})`);
      await runAsUser('mas', ['uninstall', String(app.id)], { dryRun, continueOnError: true });
    }
  }
}

async function removeHomeserverArtifacts(dryRun: boolean): Promise<void> {
  const home = realHome();

  // Remove Plex data symlink
  const plexLocal = path.join(home, 'Library', 'Application Support', 'Plex Media Server');
  try {
    await fs.readlink(plexLocal);
    if (!dryRun) {
      await fs.rm(plexLocal, { force: true });
      log.info('Removed Plex data symlink');
    }
  } catch {
    // Not a symlink or not present
  }

  // Remove homeserver workspace symlink
  const homeserverDir = path.join(home, 'Workspace', 'Git', 'homeserver');
  try {
    await fs.readlink(homeserverDir);
    if (!dryRun) {
      await fs.rm(homeserverDir, { force: true });
      log.info('Removed homeserver workspace symlink');
    }
  } catch {
    // Not a symlink or not present
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
  log.info(chalk.yellow('Safety: SSH keys, git config, and machine name are intentionally skipped.'));
  log.step(chalk.bold('Preview'));
  log.info('1) Restore macOS defaults from ~/.macsetup-defaults-backup.json');
  log.info(`2) Uninstall formulas: ${MANAGED_FORMULAS.join(', ')}`);
  log.info(`3) Uninstall casks: ${MANAGED_CASKS.join(', ')}`);
  log.info(`4) Uninstall Mac App Store apps: ${MANAGED_MAS_APPS.map((a) => a.name).join(', ')}`);
  log.info(`5) Uninstall npm globals: ${NPM_GLOBALS.join(', ')}`);
  log.info(`6) Remove dotfile symlinks + ~/.dotfiles/: ${DOTFILES.join(', ')}`);
  log.info('7) Remove ~/.oh-my-zsh and ~/.config/powerline-shell');
  log.info('8) Uninstall powerline-shell (pip3)');
  log.info('9) Remove Meslo LG fonts from ~/Library/Fonts');
  log.info('10) Remove ANDROID_HOME lines from ~/.exports');
  log.info('11) Remove homeserver artifacts (Plex symlink, workspace symlink)');
  log.info('12) Skip SSH keys (safety)');
  log.info('13) Skip git config (safety)');
  log.info('14) Skip machine name (safety)');
  log.info('15) Clear ~/.macsetup-state.json and ~/.macsetup-state.previous.json');
  log.info('16) Clear ~/.macsetup-defaults-backup.json');
  log.info('17) Optionally remove Homebrew (extra prompt)');

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

  // 1) Restore macOS defaults
  await restoreAllDefaults(false);

  // 2-3) Uninstall brew formulas and casks (uses runAsUser internally)
  await uninstallFormulas(MANAGED_FORMULAS, installOpts);
  await uninstallCasks(MANAGED_CASKS, installOpts);

  // 4) Uninstall Mac App Store apps
  await uninstallMasApps(false);

  // 5) Uninstall npm globals (via runAsUser to match install behavior)
  for (const pkg of NPM_GLOBALS) {
    await runAsUser('npm', ['uninstall', '-g', pkg], { continueOnError: true });
  }

  // 6) Remove dotfile symlinks + ~/.dotfiles/
  await removeDotfileSymlinks(false);

  // 7) Remove oh-my-zsh and powerline-shell config
  await runCommand('rm', ['-rf', path.join(realHome(), '.oh-my-zsh')], { continueOnError: true });
  await runCommand('rm', ['-rf', path.join(realHome(), '.config', 'powerline-shell')], { continueOnError: true });

  // 8) Uninstall powerline-shell binary
  await uninstallPowerlineShell(false);

  // 9) Remove Meslo LG fonts
  await removeMesloFonts(false);

  // 10) Remove ANDROID_HOME lines
  await removeAndroidExportsLines(false);

  // 11) Remove homeserver artifacts
  await removeHomeserverArtifacts(false);

  // 15-16) Clear state files
  await fs.rm(STATE_PATH, { force: true });
  await fs.rm(PREVIOUS_STATE_PATH, { force: true });
  await clearDefaultsBackup(false);

  log.success(chalk.green('Reset complete.'));

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
