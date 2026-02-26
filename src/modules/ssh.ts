import { promises as fs } from 'node:fs';
import os from 'node:os';
import path from 'node:path';
import type { Module } from '../types';
import { runCommand } from '../utils/shell';

export const sshModule: Module = {
  name: 'ssh',
  label: 'SSH',
  description: 'Generate and configure SSH keys for GitHub',
  async detect() {
    const sshDir = path.join(os.homedir(), '.ssh');
    try {
      const files = await fs.readdir(sshDir);
      const pubs = files.filter((x) => x.endsWith('.pub'));
      return {
        installed: pubs,
        missing: pubs.length === 0 ? ['id_rsa.pub'] : [],
        partial: false,
      };
    } catch {
      return { installed: [], missing: ['id_rsa.pub'], partial: false };
    }
  },
  async install(opts) {
    const email = opts.profile.config.git?.user_email ?? 'user@example.com';
    const sshDir = path.join(os.homedir(), '.ssh');
    if (!opts.dryRun) await fs.mkdir(sshDir, { recursive: true });
    await runCommand('ssh-keygen', ['-t', 'rsa', '-b', '4096', '-C', email, '-f', path.join(sshDir, 'id_rsa'), '-N', ''], {
      dryRun: opts.dryRun,
      continueOnError: true,
    });
    await runCommand('bash', ['-lc', 'eval "$(ssh-agent -s)" && ssh-add -K ~/.ssh/id_rsa'], {
      dryRun: opts.dryRun,
      continueOnError: true,
    });
  },
};
