import { promises as fs } from 'node:fs';
import os from 'node:os';
import path from 'node:path';
import type { Module } from '../types';

const dotfiles = ['.aliases', '.exports', '.zshrc', '.paths', '.gemrc', '.ruby-version', '.gitconfig'];

export const shellModule: Module = {
  name: 'shell',
  label: 'Shell Dotfiles',
  description: 'Create symlinks for shell and git dotfiles',
  async detect(opts) {
    const installed: string[] = [];
    const missing: string[] = [];
    for (const file of dotfiles) {
      const target = path.join(os.homedir(), file);
      try {
        const stat = await fs.lstat(target);
        if (stat.isSymbolicLink()) installed.push(file);
        else missing.push(file);
      } catch {
        missing.push(file);
      }
    }
    return { installed, missing, partial: installed.length > 0 && missing.length > 0 };
  },
  async install(opts) {
    const srcDir = path.join(opts.rootDir, 'dotfiles');
    for (const file of dotfiles) {
      const src = path.join(srcDir, file);
      const dest = path.join(os.homedir(), file);
      try {
        await fs.access(src);
      } catch {
        continue;
      }
      if (opts.dryRun) continue;
      await fs.rm(dest, { recursive: true, force: true });
      await fs.symlink(src, dest);
    }
  },
};
