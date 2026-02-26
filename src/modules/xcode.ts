import { promises as fs } from 'node:fs';
import os from 'node:os';
import path from 'node:path';
import type { Module } from '../types';
import { detectCommands, installFormulas } from './helpers';
import { runCommand } from '../utils/shell';

export const xcodeModule: Module = {
  name: 'xcode',
  label: 'Xcode',
  description: 'Install Xcode tools and copy Xcode templates/macros',
  dependencies: ['core'],
  async detect() {
    return detectCommands(['xcode-select']);
  },
  async install(opts) {
    await runCommand('xcode-select', ['--install'], { dryRun: opts.dryRun, continueOnError: true });
    await installFormulas(['aria2', 'robotsandpencils/made/xcodes'], opts);
    await runCommand('xcodes', ['install', '--latest', '--experimental-unxip'], {
      dryRun: opts.dryRun,
      continueOnError: true,
    });

    const source = path.join(opts.rootDir, 'Xcode', 'IDETemplateMacros.plist');
    const targetDir = path.join(os.homedir(), 'Library', 'Developer', 'Xcode', 'UserData');
    const target = path.join(targetDir, 'IDETemplateMacros.plist');

    if (!opts.dryRun) {
      await fs.mkdir(targetDir, { recursive: true });
      await fs.copyFile(source, target);
    }
  },
};
