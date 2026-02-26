import type { Module } from '../types';
import { detectCommands } from './helpers';
import { runCommand } from '../utils/shell';

export const gitModule: Module = {
  name: 'git',
  label: 'Git Config',
  description: 'Apply global git user and ignore configuration',
  dependencies: ['core'],
  async detect() {
    return detectCommands(['git']);
  },
  async install(opts) {
    const gitConfig = opts.profile.config.git;
    if (gitConfig?.user_name) {
      await runCommand('git', ['config', '--global', 'user.name', gitConfig.user_name], {
        dryRun: opts.dryRun,
        continueOnError: true,
      });
    }
    if (gitConfig?.user_email) {
      await runCommand('git', ['config', '--global', 'user.email', gitConfig.user_email], {
        dryRun: opts.dryRun,
        continueOnError: true,
      });
    }
    if (gitConfig?.global_gitignore) {
      await runCommand('git', ['config', '--global', 'core.excludesfile', gitConfig.global_gitignore], {
        dryRun: opts.dryRun,
        continueOnError: true,
      });
    }
  },
};
