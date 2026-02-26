import type { Module } from '../types';
import { runCommand } from '../utils/shell';

const defaults = ['GarageBand.app', 'iMovie.app', 'Keynote.app', 'Numbers.app', 'Pages.app'];

export const cleanupModule: Module = {
  name: 'cleanup',
  label: 'Cleanup',
  description: 'Remove optional bundled macOS applications',
  async detect(opts) {
    const apps = opts.profile.config.cleanup?.remove ?? defaults;
    const installed: string[] = [];
    const missing: string[] = [];
    for (const app of apps) {
      const check = await runCommand('test', ['-d', `/Applications/${app}`], { continueOnError: true });
      if (check.ok) installed.push(app);
      else missing.push(app);
    }
    return { installed, missing, partial: installed.length > 0 && missing.length > 0 };
  },
  async install(opts) {
    const apps = opts.profile.config.cleanup?.remove ?? defaults;
    for (const app of apps) {
      await runCommand('sudo', ['rm', '-rf', `/Applications/${app}`], { dryRun: opts.dryRun, continueOnError: true });
    }
  },
};
