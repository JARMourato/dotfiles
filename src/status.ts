import { promises as fs } from 'node:fs';

import path from 'node:path';
import { log } from '@clack/prompts';
import chalk from 'chalk';
import { JsonStateManager } from './state';
import { realHome, runCommand } from './utils/shell';

type BaselineCheck = { domain: string; key: string; factory: string | number | boolean };

const DOTFILES = ['.aliases', '.exports', '.paths', '.gemrc', '.ruby-version', '.zshrc'];
const MANAGED_FORMULAS = new Set([
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
]);
const MANAGED_CASKS = new Set([
  'docker',
  'android-studio',
  'google-chrome',
  'visual-studio-code',
  'sublime-text',
  'sourcetree',
  'proxyman',
  'charles',
  'postman',
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
]);
const NPM_GLOBALS: { label: string; packageName: string }[] = [];
const NATIVE_CLI_TOOLS = [
  { label: 'claude-code', bin: 'claude' },
];
const MACOS_BASELINE: Record<string, BaselineCheck[]> = {
  dock: [
    { domain: 'com.apple.dock', key: 'autohide', factory: false },
    { domain: 'com.apple.dock', key: 'tilesize', factory: 64 },
    { domain: 'com.apple.dock', key: 'magnification', factory: false },
  ],
  finder: [
    { domain: 'com.apple.finder', key: 'ShowStatusBar', factory: false },
    { domain: 'com.apple.finder', key: 'ShowPathbar', factory: false },
    { domain: 'com.apple.finder', key: 'AppleShowAllFiles', factory: false },
  ],
  keyboard: [
    { domain: '-g', key: 'KeyRepeat', factory: 6 },
    { domain: '-g', key: 'InitialKeyRepeat', factory: 68 },
    { domain: '-g', key: 'NSAutomaticSpellingCorrectionEnabled', factory: true },
  ],
  trackpad: [{ domain: 'com.apple.AppleMultitouchTrackpad', key: 'Clicking', factory: false }],
  mouse: [{ domain: '-g', key: 'com.apple.mouse.scaling', factory: 1 }],
  power: [{ domain: 'com.apple.screensaver', key: 'askForPasswordDelay', factory: 5 }],
  screenshots: [{ domain: 'com.apple.screencapture', key: 'type', factory: 'png' }],
  'menu-bar': [{ domain: 'com.apple.menuextra.clock', key: 'ShowSeconds', factory: false }],
  'hot-corners': [{ domain: 'com.apple.dock', key: 'wvous-tl-corner', factory: 1 }],
  'language-region': [{ domain: '-g', key: 'AppleTemperatureUnit', factory: 'Fahrenheit' }],
  'activity-monitor': [{ domain: 'com.apple.ActivityMonitor', key: 'OpenMainWindow', factory: false }],
  'app-store': [{ domain: 'com.apple.SoftwareUpdate', key: 'ScheduleFrequency', factory: 7 }],
  terminal: [{ domain: 'com.apple.terminal', key: 'SecureKeyboardEntry', factory: false }],
  'time-machine': [{ domain: 'com.apple.TimeMachine', key: 'DoNotOfferNewDisksForBackup', factory: false }],
  xcode: [{ domain: 'com.apple.dt.Xcode', key: 'DVTTextShowMinimap', factory: true }],
};

function parseValue(value: string): string | number | boolean {
  const trimmed = value.trim();
  if (trimmed === 'true') return true;
  if (trimmed === 'false') return false;
  if (/^-?\d+$/.test(trimmed)) return Number.parseInt(trimmed, 10);
  if (/^-?\d+\.\d+$/.test(trimmed)) return Number.parseFloat(trimmed);
  return trimmed;
}

function line(symbol: string, label: string, details?: string): void {
  const base = `${symbol} ${label}`;
  log.info(details ? `${base} ${chalk.dim(details)}` : base);
}

async function readDefault(domain: string, key: string): Promise<string | number | boolean | '__NOT_SET__'> {
  const read = await runCommand('defaults', ['read', domain, key], { continueOnError: true });
  if (!read.ok) return '__NOT_SET__';
  return parseValue(read.stdout);
}

async function npmGlobalInstalled(packageName: string): Promise<boolean> {
  const result = await runCommand('npm', ['ls', '-g', packageName, '--depth=0'], { continueOnError: true });
  return result.ok;
}

export async function showStatus(rootDir: string): Promise<void> {
  log.info(chalk.bold(chalk.cyan('Status: Brew')));
  const formulasRes = await runCommand('brew', ['list', '--formula'], { continueOnError: true });
  if (!formulasRes.ok) {
    line('☐', 'Homebrew formulas unavailable', '(brew not installed)');
  } else {
    const formulas = formulasRes.stdout.split('\n').map((x) => x.trim()).filter(Boolean);
    for (const formula of formulas) {
      if (MANAGED_FORMULAS.has(formula)) line(chalk.green('✅'), formula, '(managed)');
      else line(chalk.yellow('⚠️'), formula, '(unmanaged)');
    }
    if (formulas.length === 0) line('☐', 'No formulas installed');
  }

  const casksRes = await runCommand('brew', ['list', '--cask'], { continueOnError: true });
  if (!casksRes.ok) {
    line('☐', 'Homebrew casks unavailable', '(brew not installed)');
  } else {
    const casks = casksRes.stdout.split('\n').map((x) => x.trim()).filter(Boolean);
    for (const cask of casks) {
      if (MANAGED_CASKS.has(cask)) line(chalk.green('✅'), cask, '(managed)');
      else line(chalk.yellow('⚠️'), cask, '(unmanaged)');
    }
    if (casks.length === 0) line('☐', 'No casks installed');
  }

  log.info(chalk.bold(chalk.cyan('Status: CLI Tools')));
  for (const tool of NATIVE_CLI_TOOLS) {
    const check = await runCommand('which', [tool.bin], { continueOnError: true });
    if (check.ok) line(chalk.green('✅'), tool.label, '(installed)');
    else line('☐', tool.label, '(not installed)');
  }
  for (const pkg of NPM_GLOBALS) {
    if (await npmGlobalInstalled(pkg.packageName)) line(chalk.green('✅'), pkg.label, '(installed)');
    else line('☐', pkg.label, '(not installed)');
  }

  log.info(chalk.bold(chalk.cyan('Status: Dotfile Symlinks')));
  for (const dotfile of DOTFILES) {
    const filePath = path.join(realHome(), dotfile);
    try {
      const target = await fs.readlink(filePath);
      const candidateTargets = [
        path.join(rootDir, 'dotfiles', dotfile),
        path.join(realHome(), '.macsetup', 'dotfiles', dotfile),
        path.join(realHome(), '.dotfiles', dotfile),
        path.join(realHome(), '.dotfiles', 'files', dotfile),
      ];
      const resolvedTarget = path.resolve(path.dirname(filePath), target);
      const managed = candidateTargets.some((expected) => path.resolve(expected) === resolvedTarget);
      if (managed) line(chalk.green('✅'), dotfile, `(-> ${target})`);
      else line(chalk.yellow('⚠️'), dotfile, `(symlink -> ${target})`);
    } catch {
      line('☐', dotfile, '(missing or not symlink)');
    }
  }

  log.info(chalk.bold(chalk.cyan('Status: Shell Tools')));
  const hasOhMyZsh = await runCommand('test', ['-d', path.join(realHome(), '.oh-my-zsh')], { continueOnError: true });
  const hasPowerline = await runCommand('which', ['powerline-shell'], { continueOnError: true });
  const hasFonts = await runCommand('bash', ['-lc', 'ls ~/Library/Fonts/Meslo* >/dev/null 2>&1'], { continueOnError: true });
  if (hasOhMyZsh.ok) line(chalk.green('✅'), 'oh-my-zsh');
  else line('☐', 'oh-my-zsh');
  if (hasPowerline.ok) line(chalk.green('✅'), 'powerline-shell');
  else line('☐', 'powerline-shell');
  if (hasFonts.ok) line(chalk.green('✅'), 'Meslo fonts');
  else line('☐', 'Meslo fonts');

  log.info(chalk.bold(chalk.cyan('Status: macOS Defaults')));
  for (const [section, checks] of Object.entries(MACOS_BASELINE)) {
    let drift = 0;
    for (const check of checks) {
      const current = await readDefault(check.domain, check.key);
      if (current !== '__NOT_SET__' && current !== check.factory) {
        drift += 1;
      }
    }
    if (drift > 0) line(chalk.yellow('⚠️'), section, `(${drift} key(s) differ from factory baseline)`);
    else line(chalk.green('✅'), section, '(matches factory baseline)');
  }

  log.info(chalk.bold(chalk.cyan('Status: Environment')));
  const hasAndroidHomeEnv = Boolean(process.env.ANDROID_HOME?.trim());
  const exportsPath = path.join(realHome(), '.exports');
  const exportsContents = await fs.readFile(exportsPath, 'utf8').catch(() => '');
  const hasAndroidHomeFile = exportsContents.includes('ANDROID_HOME');
  const hasSshKey = (await runCommand('test', ['-f', path.join(realHome(), '.ssh', 'id_rsa.pub')], { continueOnError: true })).ok
    || (await runCommand('test', ['-f', path.join(realHome(), '.ssh', 'id_ed25519.pub')], { continueOnError: true })).ok;
  if (hasAndroidHomeEnv || hasAndroidHomeFile) line(chalk.green('✅'), 'ANDROID_HOME', '(present)');
  else line('☐', 'ANDROID_HOME', '(not set)');
  if (hasSshKey) line(chalk.green('✅'), 'SSH public key');
  else line('☐', 'SSH public key');

  log.info(chalk.bold(chalk.cyan('Status: State File')));
  const state = new JsonStateManager();
  const current = await state.load();
  if (!current) {
    line('☐', '~/.dotfiles/config/state.json', '(not found)');
    return;
  }

  line(chalk.green('✅'), '~/.dotfiles/config/state.json', `(lastRun ${current.lastRun}, profile ${current.profile})`);
}
