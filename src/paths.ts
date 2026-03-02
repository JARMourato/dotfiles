import path from 'node:path';
import { realHome } from './utils/shell';

/** Single directory for all macsetup-managed files */
const DOTFILES_HOME = path.join(realHome(), '.dotfiles');

/** Staging copies of dotfiles (symlinked from ~/) */
export const DOTFILES_DIR = path.join(DOTFILES_HOME, 'files');

/** macsetup config/state directory */
export const CONFIG_DIR = path.join(DOTFILES_HOME, 'config');

/** State file tracking last install */
export const STATE_PATH = path.join(CONFIG_DIR, 'state.json');

/** Previous state (before last install) */
export const PREVIOUS_STATE_PATH = path.join(CONFIG_DIR, 'state.previous.json');

/** Defaults backup file */
export const BACKUP_PATH = path.join(CONFIG_DIR, 'defaults-backup.json');

/** Root ~/.dotfiles directory */
export const DOTFILES_ROOT = DOTFILES_HOME;
