import type { ModuleV2 } from '../types';
import { detectCasks, detectCommands, installCasks } from './helpers';
import { runCommand } from '../utils/shell';

const items = [
  { id: 'claude', label: 'Claude app' },
  { id: 'chatgpt', label: 'ChatGPT app' },
  { id: 'claude-code', label: 'Claude Code CLI' },
  { id: 'openclaw', label: 'OpenClaw CLI' },
];

export const aiModule: ModuleV2 = {
  name: 'ai',
  label: 'AI Tools',
  description: 'Claude, ChatGPT, Claude Code, OpenClaw',
  items,
  defaultItems: items.map((item) => item.id),
  dependencies: ['core'],
  async detect(selectedItems) {
    const casks = selectedItems.filter((item) => item === 'claude' || item === 'chatgpt');
    const commands = selectedItems
      .filter((item) => item === 'claude-code' || item === 'openclaw')
      .map((item) => (item === 'claude-code' ? 'claude' : 'openclaw'));

    const caskDetect = casks.length > 0
      ? await detectCasks(casks)
      : { installed: [], missing: [], partial: false };
    const commandDetect = commands.length > 0
      ? await detectCommands(commands)
      : { installed: [], missing: [], partial: false };

    const installedCliItems = commandDetect.installed.map((cmd) => (cmd === 'claude' ? 'claude-code' : cmd));
    const missingCliItems = commandDetect.missing.map((cmd) => (cmd === 'claude' ? 'claude-code' : cmd));

    return {
      installed: [...caskDetect.installed, ...installedCliItems],
      missing: [...caskDetect.missing, ...missingCliItems],
      partial: caskDetect.partial || commandDetect.partial,
    };
  },
  async install(selectedItems, opts) {
    const casks = selectedItems.filter((item) => item === 'claude' || item === 'chatgpt');
    if (casks.length > 0) {
      await installCasks(casks, opts);
    }

    if (selectedItems.includes('claude-code')) {
      await runCommand('npm', ['install', '-g', '@anthropic-ai/claude-code'], {
        dryRun: opts.dryRun,
        continueOnError: true,
      });
    }

    if (selectedItems.includes('openclaw')) {
      await runCommand('npm', ['install', '-g', 'openclaw'], {
        dryRun: opts.dryRun,
        continueOnError: true,
      });
    }
  },
};
