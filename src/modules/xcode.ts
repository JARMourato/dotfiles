import { promises as fs } from 'node:fs';
import os from 'node:os';
import path from 'node:path';
import type { ModuleV2 } from '../types';
import { installFormulas } from './helpers';
import { runCommand } from '../utils/shell';

const itemId = 'full-install';

export const xcodeModule: ModuleV2 = {
  name: 'xcode',
  label: 'Xcode',
  description: 'Install full Xcode via xcodes and set IDE template macros',
  items: [{ id: itemId, label: 'Install full Xcode' }],
  defaultItems: [itemId],
  dependencies: ['core'],
  async detect() {
    const app = await runCommand('test', ['-d', '/Applications/Xcode.app'], { continueOnError: true });
    return {
      installed: app.ok ? [itemId] : [],
      missing: app.ok ? [] : [itemId],
      partial: false,
    };
  },
  async install(_selectedItems, opts) {
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
