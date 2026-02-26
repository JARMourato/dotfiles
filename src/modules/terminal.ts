import { promises as fs } from 'node:fs';
import os from 'node:os';
import path from 'node:path';
import type { ModuleV2 } from '../types';
import { commandExists, runCommand } from '../utils/shell';

const terminalItems = [
  { id: 'oh-my-zsh', label: 'oh-my-zsh' },
  { id: 'powerline', label: 'powerline-shell' },
  { id: 'theme', label: 'Highway theme' },
  { id: 'fonts', label: 'Meslo LG fonts' },
];

async function hasMesloFonts(): Promise<boolean> {
  const check = await runCommand('bash', ['-lc', 'ls ~/Library/Fonts/Meslo* >/dev/null 2>&1'], { continueOnError: true });
  return check.ok;
}

async function hasHighwayTheme(): Promise<boolean> {
  const read = await runCommand('defaults', ['read', 'com.apple.Terminal', 'Default Window Settings'], { continueOnError: true });
  return read.ok && read.stdout.includes('Highway');
}

export const terminalModule: ModuleV2 = {
  name: 'terminal',
  label: 'Terminal',
  description: 'oh-my-zsh, powerline, Highway theme, Meslo fonts',
  items: terminalItems,
  defaultItems: terminalItems.map((item) => item.id),
  dependencies: ['core'],
  async detect(selectedItems) {
    const installed: string[] = [];
    const missing: string[] = [];

    for (const item of selectedItems) {
      if (item === 'oh-my-zsh') {
        const check = await runCommand('test', ['-d', path.join(os.homedir(), '.oh-my-zsh')], { continueOnError: true });
        if (check.ok) installed.push(item);
        else missing.push(item);
      }

      if (item === 'powerline') {
        if (await commandExists('powerline-shell')) installed.push(item);
        else missing.push(item);
      }

      if (item === 'theme') {
        if (await hasHighwayTheme()) installed.push(item);
        else missing.push(item);
      }

      if (item === 'fonts') {
        if (await hasMesloFonts()) installed.push(item);
        else missing.push(item);
      }
    }

    return { installed, missing, partial: installed.length > 0 && missing.length > 0 };
  },
  async install(selectedItems, opts) {
    if (selectedItems.includes('oh-my-zsh')) {
      await runCommand(
        'bash',
        ['-lc', 'if [ ! -d "$HOME/.oh-my-zsh" ]; then sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended; fi'],
        { dryRun: opts.dryRun, continueOnError: true },
      );
    }

    if (selectedItems.includes('fonts')) {
      await runCommand(
        'bash',
        ['-lc', 'if ! ls ~/Library/Fonts/Meslo* >/dev/null 2>&1; then git clone https://github.com/powerline/fonts.git --depth=1 && cd fonts && ./install.sh "Meslo LG" && cd .. && rm -rf fonts; fi'],
        { dryRun: opts.dryRun, continueOnError: true },
      );
    }

    if (selectedItems.includes('powerline')) {
      await runCommand(
        'bash',
        ['-lc', 'if ! command -v powerline-shell >/dev/null 2>&1; then git clone https://github.com/b-ryan/powerline-shell.git --depth=1 && cd powerline-shell && python3 setup.py install && cd .. && rm -rf powerline-shell; fi'],
        { dryRun: opts.dryRun, continueOnError: true },
      );

      const configDir = path.join(os.homedir(), '.config', 'powerline-shell');
      const configSrc = path.join(opts.rootDir, 'Terminal', 'powerline-shell-config.json');
      const configDst = path.join(configDir, 'config.json');
      if (!opts.dryRun) {
        await fs.mkdir(configDir, { recursive: true });
        await fs.copyFile(configSrc, configDst);
      }
    }

    if (selectedItems.includes('theme')) {
      const terminalDir = path.join(opts.rootDir, 'Terminal');
      await runCommand('open', [path.join(terminalDir, 'Highway.terminal')], {
        dryRun: opts.dryRun,
        continueOnError: true,
      });
      await runCommand('defaults', ['write', 'com.apple.Terminal', 'Default Window Settings', '-string', 'Highway'], {
        dryRun: opts.dryRun,
        continueOnError: true,
      });
      await runCommand('defaults', ['write', 'com.apple.Terminal', 'Startup Window Settings', '-string', 'Highway'], {
        dryRun: opts.dryRun,
        continueOnError: true,
      });
    }
  },
};
