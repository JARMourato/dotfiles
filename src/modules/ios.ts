import { promises as fs } from 'node:fs';
import path from 'node:path';
import type { ModuleV2 } from '../types';
import { detectFormulas, installFormula, installFormulas } from './helpers';
import { brewFormulaInstalled, commandExists, realHome, runCommand, runStreamedCommand } from '../utils/shell';

const items = [
  { id: 'xcode', label: 'Xcode (via xcodes)', description: 'Full Xcode installation', critical: true },
  { id: 'swiftlint', label: 'swiftlint' },
  { id: 'swiftformat', label: 'swiftformat' },
  { id: 'xcbeautify', label: 'xcbeautify' },
  { id: 'asc', label: 'App Store Connect CLI', description: 'Fast CLI for App Store Connect API' },
];

/**
 * Ensure the `xcodes` CLI is available.
 * Try brew first; if it fails (stale bottle tags on xcodesorg/made tap won't
 * match newer macOS versions, and building from source needs full Xcode),
 * download the pre-built release binary from GitHub.
 */
async function ensureXcodes(opts: { dryRun?: boolean }): Promise<void> {
  if (await commandExists('xcodes')) return;
  if (opts.dryRun) return;

  // Install aria2 for faster Xcode downloads later
  if (!(await brewFormulaInstalled('aria2'))) {
    await runCommand('brew', ['install', 'aria2'], { continueOnError: true });
  }

  // Try brew first
  const brewResult = await runCommand('brew', ['install', 'xcodesorg/made/xcodes'], { continueOnError: true });
  if (brewResult.ok && await commandExists('xcodes')) return;

  // Brew failed — download pre-built binary from GitHub releases
  // The release zip contains a universal (x86_64 + arm64) signed binary
  console.log('⚠️  brew install failed (likely stale bottle tags), downloading xcodes binary from GitHub releases...');
  const zipPath = '/tmp/xcodes.zip';
  const dlResult = await runCommand('curl', ['-fsSL', 'https://github.com/XcodesOrg/xcodes/releases/latest/download/xcodes.zip', '-o', zipPath], { continueOnError: true });
  if (!dlResult.ok) throw new Error('Failed to download xcodes binary from GitHub');

  await runCommand('unzip', ['-o', zipPath, '-d', '/tmp'], { continueOnError: true });

  // Place in homebrew bin (no sudo needed)
  const brewBin = '/opt/homebrew/bin';
  await runCommand('mv', ['/tmp/xcodes', `${brewBin}/xcodes`]);
  await runCommand('chmod', ['+x', `${brewBin}/xcodes`]);
  await runCommand('rm', ['-f', zipPath], { continueOnError: true });

  if (!(await commandExists('xcodes'))) {
    throw new Error('Failed to install xcodes CLI');
  }
}

async function copyXcodeTemplateMacros(opts: { dryRun?: boolean; rootDir: string }): Promise<void> {
  const source = path.join(opts.rootDir, 'Xcode', 'IDETemplateMacros.plist');
  const targetDir = path.join(realHome(), 'Library', 'Developer', 'Xcode', 'UserData');
  const target = path.join(targetDir, 'IDETemplateMacros.plist');
  const sourceExists = await runCommand('test', ['-f', source], { continueOnError: true });
  if (sourceExists.ok && !opts.dryRun) {
    await fs.mkdir(targetDir, { recursive: true });
    await fs.copyFile(source, target);
  }
}

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
    if (selectedItems.includes('xcode')) {
      await ensureXcodes(opts);
      const result = await runCommand('xcodes', ['install', '--latest', '--experimental-unxip'], {
        dryRun: opts.dryRun,
        continueOnError: true,
      });
      if (!result.ok) {
        const output = (result.stderr || result.stdout).trim();
        console.error(`  ⚠ xcodes install failed: ${output || 'unknown error'}`);
      }
      await copyXcodeTemplateMacros(opts);
    }

    const formulas = selectedItems.filter((item) => item !== 'xcode');
    if (formulas.length > 0) {
      await installFormulas(formulas, opts);
    }
  },
  async installItem(item, opts) {
    if (item === 'xcode') {
      const run = opts.onProgress ? runStreamedCommand : runCommand;
      await ensureXcodes(opts);
      const result = await run('xcodes', ['install', '--latest', '--experimental-unxip'], {
        dryRun: opts.dryRun,
        continueOnError: true,
        onProgress: opts.onProgress,
      });
      if (!result.ok) {
        const output = (result.stderr || result.stdout).trim();
        console.error(`  ⚠ xcodes install failed: ${output || 'unknown error'}`);
      }
      await copyXcodeTemplateMacros(opts);
    } else {
      await installFormula(item, opts);
    }
  },
};
