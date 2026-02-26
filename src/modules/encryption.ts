import path from 'node:path';
import { promises as fs } from 'node:fs';
import type { Module } from '../types';
import { getKeychainPassword } from '../utils/keychain';
import { runCommand } from '../utils/shell';

export const encryptionModule: Module = {
  name: 'encryption',
  label: 'Encryption',
  description: 'Decrypt encrypted dotfiles using keychain password',
  async detect() {
    const password = await getKeychainPassword();
    return {
      installed: password ? ['keychain-password'] : [],
      missing: password ? [] : ['keychain-password'],
      partial: false,
    };
  },
  async install(opts) {
    const password = opts.encryptionPassword ?? (await getKeychainPassword());
    if (!password) {
      throw new Error('Encryption password not found in keychain and not provided.');
    }
    let decryptScript = path.join(opts.rootDir, 'scripts', 'decrypt_files.sh');
    try {
      await fs.access(decryptScript);
    } catch {
      decryptScript = path.join(opts.rootDir, 'Scripts', 'decrypt_files.sh');
    }
    await runCommand('bash', [decryptScript, password], {
      dryRun: opts.dryRun,
      continueOnError: true,
      cwd: opts.rootDir,
      env: {
        ...process.env,
        DOTFILES_DIR: opts.rootDir,
      },
    });
  },
};
