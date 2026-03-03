import { promises as fs } from 'node:fs';

import path from 'node:path';
import { confirm, isCancel, log } from '@clack/prompts';
import chalk from 'chalk';
import type { InstallOptions } from './types';
import { clearDefaultsBackup, restoreAllDefaults } from './defaults-backup';
import { DOTFILES_ROOT, PREVIOUS_STATE_PATH, STATE_PATH } from './paths';
import { commandExists, realHome, runAsUser, runCommand } from './utils/shell';
import { uninstallCasks, uninstallFormulas } from './modules/helpers';

async function acquireSudo(dryRun: boolean): Promise<void> {
  if (dryRun) return;
  if (process.getuid?.() === 0) return; // already root
  log.info(chalk.yellow('Some operations need admin privileges.'));
  const check = await runCommand('sudo', ['-v'], { continueOnError: true });
  if (!check.ok) {
    log.warn('Could not acquire sudo. Some operations may be skipped.');
  }
}

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
const NPM_GLOBALS = ['@openai/codex'];
const NATIVE_UNINSTALLERS: { id: string; bin: string; args: string[] }[] = [
  { id: 'claude-code', bin: 'claude', args: ['uninstall'] },
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

  // Remove the entire ~/.dotfiles/ directory (files, config, everything)
  const dotfilesDir = DOTFILES_ROOT;
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
  if (!(await commandExists('powerline-shell'))) return;

  const sudo = (args: string[]) =>
    process.getuid?.() === 0
      ? runCommand(args[0], args.slice(1), { dryRun, continueOnError: true })
      : runCommand('sudo', args, { dryRun, continueOnError: true });

  // Try pip3 uninstall first (works if installed via pip)
  await sudo(['pip3', 'uninstall', '-y', 'powerline-shell']);
  await runAsUser('pip3', ['uninstall', '-y', 'powerline-shell'], { dryRun, continueOnError: true });

  // If still present, it was installed via setup.py (egg-based) — remove files directly
  if (await commandExists('powerline-shell')) {
    log.info(chalk.dim('  pip3 could not remove it — removing files directly'));
    await sudo(['rm', '-f', '/usr/local/bin/powerline-shell']);
    // Remove egg from all Python site-packages
    await sudo(['bash', '-c', 'rm -rf /Library/Python/*/site-packages/powerline_shell* /Library/Python/*/site-packages/powerline-shell*']);
    await runAsUser('bash', ['-c', 'rm -rf ~/Library/Python/*/lib/python/site-packages/powerline_shell* ~/Library/Python/*/lib/python/site-packages/powerline-shell*'], { dryRun, continueOnError: true });
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
  log.info(chalk.bold(chalk.red('Reset mode (aggressive): this will remove most dotfiles-managed changes.')));
  log.info(chalk.yellow('Safety: SSH keys, git config, and machine name are intentionally skipped.'));
  log.step(chalk.bold('Preview'));
  log.info('1) Restore macOS defaults from ~/.dotfiles/config/defaults-backup.json');
  log.info(`2) Uninstall formulas: ${MANAGED_FORMULAS.join(', ')}`);
  log.info(`3) Uninstall casks: ${MANAGED_CASKS.join(', ')}`);
  log.info(`4) Uninstall Mac App Store apps: ${MANAGED_MAS_APPS.map((a) => a.name).join(', ')}`);
  log.info(`5) Uninstall CLI tools: ${NATIVE_UNINSTALLERS.map((n) => n.id).join(', ')}, ${NPM_GLOBALS.join(', ')}`);
  log.info(`6) Remove dotfile symlinks + ~/.dotfiles/ directory: ${DOTFILES.join(', ')}`);
  log.info('7) Remove ~/.oh-my-zsh and ~/.config/powerline-shell');
  log.info('8) Uninstall powerline-shell (pip3)');
  log.info('9) Remove Meslo LG fonts from ~/Library/Fonts');
  log.info('10) Remove ANDROID_HOME lines from ~/.exports');
  log.info('11) Remove homeserver artifacts (Plex symlink, workspace symlink)');
  log.info('12) Remove tool data dirs (~/.pyenv, ~/.rbenv, ~/.claude, ~/.gem, ~/.claude.json)');
  log.info('13) Skip SSH keys (safety)');
  log.info('14) Skip git config (safety)');
  log.info('15) Skip machine name (safety)');
  log.info('16) Clear state files (inside ~/.dotfiles/config/)');
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

  await acquireSudo(false);

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

  const total = 12;
  let step = 0;
  const progress = (label: string) => {
    step++;
    log.step(chalk.cyan(`[${step}/${total}]`) + ` ${label}`);
  };

  // 1) Restore macOS defaults
  progress('Restoring macOS defaults');
  await restoreAllDefaults(false);

  // 2) Uninstall brew formulas
  progress('Uninstalling brew formulas');
  await uninstallFormulas(MANAGED_FORMULAS, installOpts);

  // 3) Uninstall brew casks
  progress('Uninstalling brew casks');
  await uninstallCasks(MANAGED_CASKS, installOpts);

  // 4) Uninstall Mac App Store apps
  progress('Uninstalling Mac App Store apps');
  await uninstallMasApps(false);

  // 5) Uninstall CLI tools (native + npm)
  progress('Uninstalling CLI tools');
  for (const native of NATIVE_UNINSTALLERS) {
    log.info(chalk.dim(`  → ${native.id} (native uninstaller)`));
    if (await commandExists(native.bin)) {
      await runAsUser(native.bin, native.args, { continueOnError: true });
    }
  }
  for (const pkg of NPM_GLOBALS) {
    log.info(chalk.dim(`  → ${pkg}`));
    // Try as user first (normal case), then with sudo if it fails (e.g. global prefix owned by root)
    const r1 = await runAsUser('npm', ['uninstall', '-g', pkg], { continueOnError: true });
    if (!r1.ok) {
      const isRoot = process.getuid?.() === 0;
      if (isRoot) {
        await runCommand('npm', ['uninstall', '-g', pkg], { continueOnError: true });
      } else {
        await runCommand('sudo', ['npm', 'uninstall', '-g', pkg], { continueOnError: true });
      }
    }
  }

  // 6) Remove dotfile symlinks + ~/.dotfiles/
  progress('Removing dotfile symlinks');
  await removeDotfileSymlinks(false);

  // 7-8) Remove oh-my-zsh, powerline-shell
  progress('Removing oh-my-zsh & powerline-shell');
  await runCommand('rm', ['-rf', path.join(realHome(), '.oh-my-zsh')], { continueOnError: true });
  await runCommand('rm', ['-rf', path.join(realHome(), '.config', 'powerline-shell')], { continueOnError: true });
  await uninstallPowerlineShell(false);

  // 9) Remove Meslo LG fonts
  progress('Removing Meslo LG fonts');
  await removeMesloFonts(false);

  // 10) Remove ANDROID_HOME lines + homeserver artifacts
  progress('Cleaning up environment & homeserver artifacts');
  await removeAndroidExportsLines(false);
  await removeHomeserverArtifacts(false);

  // 11) Remove tool data directories left behind by uninstalled packages
  progress('Removing tool data directories');
  const toolDataDirs = [
    { dir: '.pyenv', label: 'pyenv' },
    { dir: '.rbenv', label: 'rbenv' },
    { dir: '.claude', label: 'Claude Code' },
    { dir: '.gem', label: 'Ruby gems' },
  ];
  const toolDataFiles = [
    { file: '.claude.json', label: 'Claude Code config' },
  ];
  const home = realHome();
  for (const { dir, label } of toolDataDirs) {
    const fullPath = path.join(home, dir);
    try {
      await fs.access(fullPath);
      log.info(chalk.dim(`  → removing ~/${dir} (${label})`));
      await fs.rm(fullPath, { recursive: true, force: true });
    } catch { /* not present */ }
  }
  for (const { file, label } of toolDataFiles) {
    const fullPath = path.join(home, file);
    try {
      await fs.access(fullPath);
      log.info(chalk.dim(`  → removing ~/${file} (${label})`));
      await fs.rm(fullPath, { force: true });
    } catch { /* not present */ }
  }

  // 12) Clear state files (new + legacy locations)
  progress('Clearing state files');
  await fs.rm(STATE_PATH, { force: true });
  await fs.rm(PREVIOUS_STATE_PATH, { force: true });
  await clearDefaultsBackup(false);
  // Clean legacy locations from before ~/.dotfiles consolidation
  for (const legacy of ['.macsetup-state.json', '.macsetup-state.previous.json', '.macsetup-defaults-backup.json']) {
    await fs.rm(path.join(home, legacy), { force: true });
  }

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
