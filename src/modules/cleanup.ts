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
    // Ensure dockutil is available for Dock icon removal
    const hasDockutil = await runCommand('command', ['-v', 'dockutil'], { continueOnError: true });
    if (!hasDockutil.ok) {
      await runCommand('brew', ['install', 'dockutil'], { dryRun: opts.dryRun, continueOnError: true });
    }

    for (const app of selectedItems) {
      // Remove from Dock first
      const appName = app.replace('.app', '');
      await runCommand('dockutil', ['--remove', appName, '--no-restart'], { dryRun: opts.dryRun, continueOnError: true });

      // Check if sudo is available without password to avoid hanging
      const sudoCheck = await runCommand('sudo', ['-n', 'true'], { continueOnError: true });
      if (!sudoCheck.ok) {
        console.warn(`⚠️  Skipping ${app} — needs sudo. Run: sudo rm -rf /Applications/${app}`);
        continue;
      }
      await runCommand('sudo', ['rm', '-rf', `/Applications/${app}`], { dryRun: opts.dryRun, continueOnError: true });
    }

    // Restart Dock once after all removals
    await runCommand('killall', ['Dock'], { dryRun: opts.dryRun, continueOnError: true });
  },
};
