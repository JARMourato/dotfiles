import type { ModuleV2 } from '../types';
import { detectCasks, installCask, installCasks } from './helpers';
import { brewCaskInstalled, runAsUser } from '../utils/shell';

const items = [
  { id: 'google-chrome', label: 'Google Chrome' },
  { id: 'visual-studio-code', label: 'Visual Studio Code' },
  { id: 'sublime-text', label: 'Sublime Text' },
  { id: 'sourcetree', label: 'SourceTree' },
  { id: 'proxyman', label: 'Proxyman' },
  { id: 'charles', label: 'Charles' },
  { id: 'postman', label: 'Postman' },
  { id: 'sf-symbols', label: 'SF Symbols' },
];

export const appsModule: ModuleV2 = {
  name: 'apps',
  label: 'Apps',
  description: 'Developer and utility applications',
  items,
  defaultItems: items.map((item) => item.id),
  dependencies: ['core'],
  async detect(selectedItems) {
    return detectCasks(selectedItems);
  },
  async install(selectedItems, opts) {
    await installCasks(selectedItems, opts);
  },
  async installItem(item, opts) {
    // Special handling for SF Symbols - Apple's pkg installer often hangs in headless mode
    if (item === 'sf-symbols') {
      if (await brewCaskInstalled('sf-symbols')) {
        return; // Already installed
      }
      
      console.log('Installing SF Symbols (may require GUI interaction)...');
      const result = await runAsUser('brew', ['install', '--cask', 'sf-symbols'], {
        dryRun: opts.dryRun,
        continueOnError: true,
        timeoutMs: 120_000, // 2 minute timeout
      });
      
      if (!result.ok) {
        console.log('⚠️  SF Symbols installation timed out or failed. Please install manually:');
        console.log('   brew install --cask sf-symbols');
        console.log('   (Apple pkg installers sometimes require GUI interaction)');
        return; // Don't fail the entire script
      }
      return;
    }
    
    // Standard installation for other apps
    await installCask(item, opts);
  },
};
