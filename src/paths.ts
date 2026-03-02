import path from 'node:path';
import { realHome } from './utils/shell';

/** Single directory for all dotfiles-managed files */
const DOTFILES_HOME = path.join(realHome(), '.dotfiles');

/** Staging copies of dotfiles (symlinked from ~/) */
export const DOTFILES_DIR = path.join(DOTFILES_HOME, 'files');

/** dotfiles config/state directory */
export const CONFIG_DIR = path.join(DOTFILES_HOME, 'config');

/** State file tracking last install */
export const STATE_PATH = path.join(CONFIG_DIR, 'state.json');

/** Previous state (before last install) */
export const PREVIOUS_STATE_PATH = path.join(CONFIG_DIR, 'state.previous.json');

/** Defaults backup file */
export const BACKUP_PATH = path.join(CONFIG_DIR, 'defaults-backup.json');

/** Root ~/.dotfiles directory */
export const DOTFILES_ROOT = DOTFILES_HOME;

/** Git clone of the dotfiles repo */
export const REPO_DIR = path.join(DOTFILES_HOME, 'repo');

/** ~/Workspace directory */
export const WORKSPACE_DIR = path.join(realHome(), 'Workspace');
