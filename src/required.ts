import { promises as fs } from 'node:fs';
import os from 'node:os';
import path from 'node:path';
import { log, spinner } from '@clack/prompts';
import type { InstallOptions } from './types';
import { commandExists, runCommand } from './utils/shell';

// Core dotfiles that are always safe to symlink (no external dependencies)
const alwaysSafeDotfiles = ['.aliases', '.exports', '.paths', '.gemrc', '.ruby-version'];
// Dotfiles that depend on optional modules — only symlink if deps are met or .zshrc is defensive
const conditionalDotfiles = ['.zshrc'];

async function ensureXcodeCliTools(opts: InstallOptions): Promise<void> {
  const selected = await runCommand('xcode-select', ['-p'], { continueOnError: true });
  if (!selected.ok) {
    await runCommand('xcode-select', ['--install'], { dryRun: opts.dryRun, continueOnError: true });
  }
}

async function ensureHomebrew(opts: InstallOptions): Promise<void> {
  const hasBrew = await commandExists('brew');
  if (hasBrew) {
    await runCommand('brew', ['update'], { dryRun: opts.dryRun, continueOnError: true });
    return;
  }

  await runCommand(
    '/bin/bash',
    ['-c', '$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)'],
    { dryRun: opts.dryRun, continueOnError: true },
  );
  await runCommand('brew', ['update'], { dryRun: opts.dryRun, continueOnError: true });
}

async function ensureNode(opts: InstallOptions): Promise<void> {
  const hasNode = await commandExists('node');
  const hasNpm = await commandExists('npm');
  if (hasNode && hasNpm) return;

  await runCommand('brew', ['install', 'node'], { dryRun: opts.dryRun, continueOnError: true });
}

async function ensureSshKey(opts: InstallOptions): Promise<void> {
  const sshDir = path.join(os.homedir(), '.ssh');
  const pubPath = path.join(sshDir, 'id_rsa.pub');
  const pubExists = await runCommand('test', ['-f', pubPath], { continueOnError: true });
  if (pubExists.ok) return;

  if (!opts.dryRun) {
    await fs.mkdir(sshDir, { recursive: true });
  }

  const email = opts.profile.config.git?.user_email ?? 'user@example.com';
  await runCommand('ssh-keygen', ['-t', 'rsa', '-b', '4096', '-C', email, '-f', path.join(sshDir, 'id_rsa'), '-N', ''], {
    dryRun: opts.dryRun,
    continueOnError: true,
  });
  await runCommand('bash', ['-lc', 'eval "$(ssh-agent -s)" && ssh-add -K ~/.ssh/id_rsa'], {
    dryRun: opts.dryRun,
    continueOnError: true,
  });
}

async function ensureGitConfig(opts: InstallOptions): Promise<void> {
  const git = opts.profile.config.git;
  if (!git) return;

  if (git.user_name) {
    await runCommand('git', ['config', '--global', 'user.name', git.user_name], {
      dryRun: opts.dryRun,
      continueOnError: true,
    });
  }
  if (git.user_email) {
    await runCommand('git', ['config', '--global', 'user.email', git.user_email], {
      dryRun: opts.dryRun,
      continueOnError: true,
    });
  }
  if (git.global_gitignore) {
    await runCommand('git', ['config', '--global', 'core.excludesfile', git.global_gitignore], {
      dryRun: opts.dryRun,
      continueOnError: true,
    });
  }
}

async function symlinkDotfile(srcDir: string, file: string, dryRun: boolean): Promise<void> {
  const src = path.join(srcDir, file);
  const dst = path.join(os.homedir(), file);
  const srcExists = await runCommand('test', ['-e', src], { continueOnError: true });
  if (!srcExists.ok) return;

  if (dryRun) return;

  // If destination exists and is already a symlink pointing to our source, skip
  try {
    const existing = await fs.readlink(dst);
    if (existing === src) return;
  } catch {
    // Not a symlink or doesn't exist — proceed
  }

  await fs.rm(dst, { recursive: true, force: true });
  await fs.symlink(src, dst);
}

async function ensureDotfileSymlinks(opts: InstallOptions): Promise<void> {
  const srcDir = path.join(opts.rootDir, 'dotfiles');

  // Always symlink safe dotfiles
  for (const file of alwaysSafeDotfiles) {
    await symlinkDotfile(srcDir, file, opts.dryRun);
  }

  // Symlink .zshrc — it's now defensive (checks for commands before using them)
  for (const file of conditionalDotfiles) {
    await symlinkDotfile(srcDir, file, opts.dryRun);
  }
}

export async function runRequiredPhase(opts: InstallOptions): Promise<void> {
  const s = spinner();
  s.start('Running required setup phase');
  try {
    await ensureXcodeCliTools(opts);
    await ensureHomebrew(opts);
    await ensureNode(opts);
    await ensureSshKey(opts);
    await ensureGitConfig(opts);
    await ensureDotfileSymlinks(opts);
    s.stop('Required phase complete');
  } catch (error) {
    const message = error instanceof Error ? error.message : String(error);
    s.stop('Required phase failed');
    log.error(`required phase failed: ${message}`);
    throw error;
  }
}
