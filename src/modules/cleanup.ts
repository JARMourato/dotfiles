import type { ModuleV2 } from '../types';
import { runCommand } from '../utils/shell';

const items = [
  { id: 'GarageBand.app', label: 'GarageBand.app' },
  { id: 'iMovie.app', label: 'iMovie.app' },
  { id: 'Keynote.app', label: 'Keynote.app' },
  { id: 'Numbers.app', label: 'Numbers.app' },
  { id: 'Pages.app', label: 'Pages.app' },
];

export const cleanupModule: ModuleV2 = {
  name: 'cleanup',
  label: 'Cleanup',
  description: 'Remove optional bundled macOS applications',
  items,
  defaultItems: items.map((item) => item.id),
  async detect(selectedItems) {
    const installed: string[] = [];
    const missing: string[] = [];

    for (const app of selectedItems) {
      const check = await runCommand('test', ['-d', `/Applications/${app}`], { continueOnError: true });
      if (check.ok) installed.push(app);
      else missing.push(app);
    }

    return { installed, missing, partial: installed.length > 0 && missing.length > 0 };
  },
  async install(selectedItems, opts) {
    for (const app of selectedItems) {
      await runCommand('sudo', ['rm', '-rf', `/Applications/${app}`], { dryRun: opts.dryRun, continueOnError: true });
    }
  },
};
