import { promises as fs } from 'node:fs';
import path from 'node:path';
import { log, spinner } from '@clack/prompts';
import chalk from 'chalk';
import { REPO_DIR, DOTFILES_DIR } from './paths';
import { runCommand, realHome } from './utils/shell';

const REPO_URL = 'https://github.com/JARMourato/dotfiles.git';
const SSH_URL = 'git@github.com:JARMourato/dotfiles.git';

/** Check if the repo clone exists */
export async function hasRepoClone(): Promise<boolean> {
  try {
    await fs.access(path.join(REPO_DIR, '.git'));
    return true;
  } catch {
    return false;
  }
}

/** Clone the dotfiles repo to ~/.dotfiles/repo/ */
export async function cloneRepo(dryRun = false): Promise<void> {
  if (await hasRepoClone()) return;

  if (dryRun) {
    log.info(`[dry-run] git clone ${REPO_URL} ${REPO_DIR}`);
    return;
  }

  const s = spinner();
  s.start('Cloning dotfiles repo...');

  // Try SSH first (for push access), fall back to HTTPS
  let result = await runCommand('git', ['clone', SSH_URL, REPO_DIR], { continueOnError: true });
  if (!result.ok) {
    result = await runCommand('git', ['clone', REPO_URL, REPO_DIR], { continueOnError: true });
  }

  if (result.ok) {
    s.stop('Dotfiles repo cloned to ~/.dotfiles/repo/');
  } else {
    s.stop('Could not clone dotfiles repo (continuing without sync support)');
  }
}

/** Get the dotfiles source dir — prefer repo clone, fall back to bundled */
export function getDotfilesSource(rootDir: string): string {
  // We check synchronously via the caller; this just returns the path
  return path.join(REPO_DIR, 'dotfiles');
}

/** Pull latest changes from origin */
export async function pullRepo(): Promise<void> {
  if (!(await hasRepoClone())) {
    log.error('No repo clone found. Run an install first to set up the repo.');
    return;
  }

  const s = spinner();
  s.start('Pulling latest changes...');

  // Stash any local changes
  await runCommand('git', ['-C', REPO_DIR, 'stash'], { continueOnError: true });

  const result = await runCommand('git', ['-C', REPO_DIR, 'pull', '--rebase'], { continueOnError: true });

  // Pop stash
  await runCommand('git', ['-C', REPO_DIR, 'stash', 'pop'], { continueOnError: true });

  if (result.ok) {
    s.stop('Up to date.');

    // Re-copy dotfiles from repo to ~/.dotfiles/files/ and re-symlink
    await syncDotfilesToHome();
  } else {
    s.stop(chalk.yellow('Pull failed. You may need to resolve conflicts manually.'));
    log.info(`  cd ~/.dotfiles/repo && git status`);
  }
}

/** Push local dotfile changes back to repo */
export async function pushRepo(): Promise<void> {
  if (!(await hasRepoClone())) {
    log.error('No repo clone found. Run an install first to set up the repo.');
    return;
  }

  // Check for SSH remote (needed for push)
  const remote = await runCommand('git', ['-C', REPO_DIR, 'remote', 'get-url', 'origin'], { continueOnError: true });
  if (remote.ok && remote.stdout.trim().startsWith('https://')) {
    // Switch to SSH for push
    log.info('Switching remote to SSH for push access...');
    await runCommand('git', ['-C', REPO_DIR, 'remote', 'set-url', 'origin', SSH_URL], { continueOnError: true });
  }

  // Copy managed dotfiles from ~/.dotfiles/files/ back to repo
  const s = spinner();
  s.start('Syncing dotfiles to repo...');

  const dotfilesInRepo = path.join(REPO_DIR, 'dotfiles');
  const managedFiles = ['.aliases', '.exports', '.paths', '.gemrc', '.ruby-version', '.zshrc'];

  for (const file of managedFiles) {
    const src = path.join(DOTFILES_DIR, file);
    const dst = path.join(dotfilesInRepo, file);
    try {
      await fs.access(src);
      await fs.copyFile(src, dst);
    } catch { /* file doesn't exist in managed dir */ }
  }

  s.stop('Dotfiles synced to repo.');

  // Check if there are changes
  const status = await runCommand('git', ['-C', REPO_DIR, 'status', '--porcelain'], { continueOnError: true });
  if (!status.stdout.trim()) {
    log.info('Nothing to push — repo is up to date.');
    return;
  }

  // Show what changed
  log.info(chalk.bold('Changes to push:'));
  const diff = await runCommand('git', ['-C', REPO_DIR, 'diff', '--stat'], { continueOnError: true });
  if (diff.stdout.trim()) console.log(diff.stdout);

  const untracked = await runCommand('git', ['-C', REPO_DIR, 'status', '--porcelain'], { continueOnError: true });
  if (untracked.stdout.trim()) console.log(chalk.dim(untracked.stdout));

  // Stage, commit, push
  await runCommand('git', ['-C', REPO_DIR, 'add', '-A'], { continueOnError: true });
  const commitResult = await runCommand('git', ['-C', REPO_DIR, 'commit', '-m', 'Update dotfiles'], { continueOnError: true });

  if (!commitResult.ok) {
    log.error('Commit failed.');
    return;
  }

  const pushResult = await runCommand('git', ['-C', REPO_DIR, 'push'], { continueOnError: true });

  if (pushResult.ok) {
    log.success('Pushed to origin.');
  } else {
    log.error('Push failed. Check your SSH key and repo permissions.');
    log.info(`  cd ~/.dotfiles/repo && git push`);
  }
}

/** Copy dotfiles from repo clone to ~/.dotfiles/files/ and re-symlink to ~/ */
async function syncDotfilesToHome(): Promise<void> {
  const repoSource = path.join(REPO_DIR, 'dotfiles');
  const home = realHome();
  const managedFiles = ['.aliases', '.exports', '.paths', '.gemrc', '.ruby-version', '.zshrc'];

  await fs.mkdir(DOTFILES_DIR, { recursive: true });

  for (const file of managedFiles) {
    const src = path.join(repoSource, file);
    const managed = path.join(DOTFILES_DIR, file);
    const homeLink = path.join(home, file);

    try {
      await fs.access(src);
    } catch {
      continue; // file doesn't exist in repo
    }

    // Copy to managed dir
    await fs.copyFile(src, managed);

    // Ensure symlink
    try {
      const existing = await fs.readlink(homeLink);
      if (existing === managed) continue;
    } catch { /* not a symlink */ }

    await fs.rm(homeLink, { force: true });
    await fs.symlink(managed, homeLink);
  }
}
