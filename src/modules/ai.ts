import type { Module } from '../types';
import { detectCasks, detectCommands, installCasks } from './helpers';
import { runCommand } from '../utils/shell';

const caskDefaults = ['claude', 'chatgpt'];
const npmDefaults = ['@anthropic-ai/claude-code', 'openclaw'];

export const aiModule: Module = {
  name: 'ai',
  label: 'AI Tools',
  description: 'Claude, ChatGPT, OpenClaw and Claude Code CLI',
  dependencies: ['core', 'node'],
  async detect(opts) {
    const casks = opts.profile.config.ai?.casks ?? caskDefaults;
    const caskDetect = await detectCasks(casks);
    const cmdDetect = await detectCommands(['claude']);
    return {
      installed: [...caskDetect.installed, ...cmdDetect.installed],
      missing: [...caskDetect.missing, ...cmdDetect.missing],
      partial: caskDetect.partial || cmdDetect.partial,
    };
  },
  async install(opts) {
    const casks = opts.profile.config.ai?.casks ?? caskDefaults;
    const npmPackages = opts.profile.config.ai?.npm ?? npmDefaults;
    await installCasks(casks, opts);
    for (const pkg of npmPackages) {
      await runCommand('npm', ['install', '-g', pkg], { dryRun: opts.dryRun, continueOnError: true });
    }
  },
};
