import { promises as fs } from 'node:fs';
import os from 'node:os';
import path from 'node:path';
import type { ModuleV2 } from '../types';
import { detectFormulas, installFormulas } from './helpers';
import { runCommand } from '../utils/shell';

const items = [
  { id: 'xcode', label: 'Xcode (via xcodes)', description: 'Full Xcode installation' },
  { id: 'swiftlint', label: 'swiftlint' },
  { id: 'swiftformat', label: 'swiftformat' },
  { id: 'xcbeautify', label: 'xcbeautify' },
  { id: 'asc', label: 'App Store Connect CLI', description: 'Fast CLI for App Store Connect API' },
];

export const iosModule: ModuleV2 = {
  name: 'ios',
  label: 'iOS Dev',
  description: 'Xcode, swiftlint, swiftformat, xcbeautify, App Store Connect CLI',
  items,
  defaultItems: items.map((item) => item.id),
  dependencies: ['core'],
  async detect(selectedItems) {
    const installed: string[] = [];
    const missing: string[] = [];

    // Xcode detection
    if (selectedItems.includes('xcode')) {
      const exists = await runCommand('test', ['-d', '/Applications/Xcode.app'], { continueOnError: true });
      if (exists.ok) installed.push('xcode');
      else missing.push('xcode');
    }

    // Brew formulas
    const formulas = selectedItems.filter((item) => item !== 'xcode');
    if (formulas.length > 0) {
      const result = await detectFormulas(formulas);
      installed.push(...result.installed);
      missing.push(...result.missing);
    }

    return { installed, missing, partial: installed.length > 0 && missing.length > 0 };
  },
  async install(selectedItems, opts) {
    // Install Xcode via xcodes
    if (selectedItems.includes('xcode')) {
      await installFormulas(['aria2', 'robotsandpencils/made/xcodes'], opts);
      await runCommand('xcodes', ['install', '--latest', '--experimental-unxip'], {
        dryRun: opts.dryRun,
        continueOnError: true,
      });

      // Copy Xcode template macros if available
      const source = path.join(opts.rootDir, 'Xcode', 'IDETemplateMacros.plist');
      const targetDir = path.join(os.homedir(), 'Library', 'Developer', 'Xcode', 'UserData');
      const target = path.join(targetDir, 'IDETemplateMacros.plist');
      const sourceExists = await runCommand('test', ['-f', source], { continueOnError: true });
      if (sourceExists.ok && !opts.dryRun) {
        await fs.mkdir(targetDir, { recursive: true });
        await fs.copyFile(source, target);
      }
    }

    // Install brew formulas (swiftlint, swiftformat, xcbeautify, asc)
    const formulas = selectedItems.filter((item) => item !== 'xcode');
    if (formulas.length > 0) {
      await installFormulas(formulas, opts);
    }
  },
};
