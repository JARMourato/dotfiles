import type { ModuleV2 } from '../types';
import { detectCasks, detectCommands, installCasks } from './helpers';
import { runAsUser, runCommand } from '../utils/shell';

const items = [
  { id: 'claude', label: 'Claude app' },
  { id: 'chatgpt', label: 'ChatGPT app' },
  { id: 'claude-code', label: 'Claude Code CLI' },
  { id: 'codex', label: 'Codex CLI (OpenAI)' },

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
      .filter((item) => item === 'claude-code' || item === 'codex')
      .map((item) => (item === 'claude-code' ? 'claude' : 'codex'));

    const caskDetect = casks.length > 0
      ? await detectCasks(casks)
      : { installed: [], missing: [], partial: false };
    // Detect CLI commands as real user (root PATH doesn't have user's npm globals)
    const commandInstalled: string[] = [];
    const commandMissing: string[] = [];
    for (const cmd of commands) {
      const check = await runAsUser('which', [cmd], { continueOnError: true });
      if (check.ok) commandInstalled.push(cmd);
      else commandMissing.push(cmd);
    }
    const commandDetect = { installed: commandInstalled, missing: commandMissing, partial: commandInstalled.length > 0 && commandMissing.length > 0 };

    const cliMap = (cmd: string) => cmd === 'claude' ? 'claude-code' : cmd;
    const installedCliItems = commandDetect.installed.map(cliMap);
    const missingCliItems = commandDetect.missing.map(cliMap);

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
      await runAsUser('npm', ['install', '-g', '@anthropic-ai/claude-code'], { dryRun: opts.dryRun });
    }

    if (selectedItems.includes('codex')) {
      await runAsUser('npm', ['install', '-g', '@openai/codex'], { dryRun: opts.dryRun });
    }

  },
};
