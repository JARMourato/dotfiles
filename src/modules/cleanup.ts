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
      if (check.ok) missing.push(app);   // app exists → still needs removal
      else installed.push(app);            // app gone → cleanup already done
    }

    return { installed, missing, partial: installed.length > 0 && missing.length > 0 };
  },
  async install(selectedItems, opts) {
    for (const app of selectedItems) {
      // Check if sudo is available without password to avoid hanging
      const sudoCheck = await runCommand('sudo', ['-n', 'true'], { continueOnError: true });
      if (!sudoCheck.ok) {
        console.warn(`⚠️  Skipping ${app} — needs sudo. Run: sudo rm -rf /Applications/${app}`);
        continue;
      }
      await runCommand('sudo', ['rm', '-rf', `/Applications/${app}`], { dryRun: opts.dryRun, continueOnError: true });
    }
  },
};
