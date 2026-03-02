import path from 'node:path';
import type { ModuleV2 } from '../types';
import { commandExists, realHome, runCommand } from '../utils/shell';
import { installFormulas } from './helpers';

const languageItems = [
  { id: 'python', label: 'Python (pyenv)' },
  { id: 'ruby', label: 'Ruby (rbenv + bundler)' },
];

function pythonVersionsFromProfile(config: Record<string, unknown>): string[] {
  const direct = config.python_versions;
  if (Array.isArray(direct) && direct.length > 0) {
    return direct.map(String);
  }

  const legacy = config.python as { versions?: string[] } | undefined;
  if (Array.isArray(legacy?.versions) && legacy.versions.length > 0) {
    return legacy.versions;
  }

  return ['3.12'];
}

function rubyVersionFromProfile(config: Record<string, unknown>): string {
  const direct = config.ruby_version;
  if (typeof direct === 'string' && direct.trim().length > 0) {
    return direct.trim();
  }

  const legacy = config.ruby as { version?: string } | undefined;
  if (typeof legacy?.version === 'string' && legacy.version.trim().length > 0) {
    return legacy.version.trim();
  }

  return '3.4.8';
}

export const languagesModule: ModuleV2 = {
  name: 'languages',
  label: 'Languages',
  description: 'Python and Ruby runtimes',
  items: languageItems,
  defaultItems: languageItems.map((item) => item.id),
  dependencies: ['core'],
  async detect(selectedItems) {
    const installed: string[] = [];
    const missing: string[] = [];

    for (const item of selectedItems) {
      if (item === 'python') {
        const hasPython = await commandExists('python3');
        const hasPip = await commandExists('pip3');
        if (hasPython && hasPip) installed.push(item);
        else missing.push(item);
      }

      if (item === 'ruby') {
        const hasRuby = await commandExists('ruby');
        const hasRbenv = await commandExists('rbenv');
        if (hasRuby && hasRbenv) installed.push(item);
        else missing.push(item);
      }
    }

    return { installed, missing, partial: installed.length > 0 && missing.length > 0 };
  },
  async install(selectedItems, opts) {
    for (const item of selectedItems) {
      await languagesModule.installItem!(item, opts);
    }
  },
  async installItem(item, opts) {
    if (item === 'python') {
      await installFormulas(['pyenv', 'python'], opts);
      const versions = pythonVersionsFromProfile(opts.profile.config);
      for (const version of versions) {
        await runCommand('pyenv', ['install', '-s', version], { dryRun: opts.dryRun, continueOnError: true });
        await runCommand('pyenv', ['global', version], { dryRun: opts.dryRun, continueOnError: true });
      }
      await runCommand('pip3', ['install', '--upgrade', '--break-system-packages', 'pip', 'setuptools', 'wheel'], {
        dryRun: opts.dryRun,
        continueOnError: true,
      });
      await runCommand('pip3', ['install', '--break-system-packages', 'pyusb'], {
        dryRun: opts.dryRun,
        continueOnError: true,
      });
    }

    if (item === 'ruby') {
      await installFormulas(['rbenv', 'ruby-build'], opts);
      const versionFile = path.join(realHome(), '.ruby-version');
      let version = rubyVersionFromProfile(opts.profile.config);
      const read = await runCommand('cat', [versionFile], { continueOnError: true });
      if (read.ok && read.stdout.trim()) {
        version = read.stdout.trim();
      }

      await runCommand('rbenv', ['install', '-s', version], { dryRun: opts.dryRun, continueOnError: true });
      await runCommand('rbenv', ['global', version], { dryRun: opts.dryRun, continueOnError: true });
      await runCommand('gem', ['install', 'bundler'], { dryRun: opts.dryRun, continueOnError: true });
    }
  },
};
