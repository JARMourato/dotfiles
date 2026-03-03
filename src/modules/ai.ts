import type { ModuleV2 } from '../types';
import { detectCasks, installCask, installCasks } from './helpers';
import { runAsUser, runCommand } from '../utils/shell';

const items = [
  { id: 'claude', label: 'Claude app' },
  { id: 'chatgpt', label: 'ChatGPT app' },
  { id: 'claude-code', label: 'Claude Code CLI' },
  { id: 'codex', label: 'Codex CLI (OpenAI)' },
];

const CASK_IDS = new Set(['claude', 'chatgpt']);
const NPM_PACKAGES: Record<string, string> = {
  'codex': '@openai/codex',
};
// claude-code uses its native installer (auto-updates)
const NATIVE_INSTALLERS: Record<string, { install: string[]; bin: string }> = {
  'claude-code': { install: ['bash', '-c', 'curl -fsSL https://claude.ai/install.sh | bash'], bin: 'claude' },
};

export const aiModule: ModuleV2 = {
  name: 'ai',
  label: 'AI Tools',
  description: 'Claude, ChatGPT, Claude Code, OpenClaw',
  items,
  defaultItems: items.map((item) => item.id),
  dependencies: ['core'],
  async detect(selectedItems) {
    const casks = selectedItems.filter((item) => CASK_IDS.has(item));
    const cliItems = selectedItems.filter((item) => item in NPM_PACKAGES || item in NATIVE_INSTALLERS);

    const caskDetect = casks.length > 0
      ? await detectCasks(casks)
      : { installed: [], missing: [], partial: false };

    const commandInstalled: string[] = [];
    const commandMissing: string[] = [];
    for (const item of cliItems) {
      const bin = NATIVE_INSTALLERS[item]?.bin ?? item;
      const check = await runAsUser('which', [bin], { continueOnError: true });
      if (check.ok) commandInstalled.push(item);
      else commandMissing.push(item);
    }

    return {
      installed: [...caskDetect.installed, ...commandInstalled],
      missing: [...caskDetect.missing, ...commandMissing],
      partial: (caskDetect.installed.length + commandInstalled.length) > 0 &&
               (caskDetect.missing.length + commandMissing.length) > 0,
    };
  },
  async install(selectedItems, opts) {
    for (const item of selectedItems) {
      await aiModule.installItem!(item, opts);
    }
  },
  async installItem(item, opts) {
    if (CASK_IDS.has(item)) {
      await installCask(item, opts);
      return;
    }

    const native = NATIVE_INSTALLERS[item];
    if (native) {
      const result = await runAsUser(native.install[0], native.install.slice(1), {
        dryRun: opts.dryRun,
        continueOnError: true,
        timeoutMs: 180_000,
      });
      if (!result.ok) {
        const err = (result.stderr || result.stdout).trim().slice(0, 300);
        throw new Error(`Native install of ${item} failed: ${err || 'timed out after 3 minutes'}`);
      }
      return;
    }

    const pkg = NPM_PACKAGES[item];
    if (pkg) {
      const result = await runAsUser('npm', ['install', '-g', pkg], {
        dryRun: opts.dryRun,
        continueOnError: true,
        timeoutMs: 180_000,
      });
      if (!result.ok) {
        const err = (result.stderr || result.stdout).trim().slice(0, 300);
        throw new Error(`npm install -g ${pkg} failed: ${err || 'timed out after 3 minutes'}`);
      }
    }
  },
};
