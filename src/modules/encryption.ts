import path from 'node:path';
import { promises as fs } from 'node:fs';
import type { ModuleV2 } from '../types';
import { getKeychainPassword } from '../utils/keychain';
import { runCommand } from '../utils/shell';

const itemId = 'decrypt-dotfiles';

export const encryptionModule: ModuleV2 = {
  name: 'encryption',
  label: 'Encryption',
  description: 'Decrypt encrypted dotfiles using keychain password',
  items: [{ id: itemId, label: 'Decrypt encrypted dotfiles' }],
  defaultItems: [itemId],
  async detect() {
    const password = await getKeychainPassword();
    return {
      installed: password ? [itemId] : [],
      missing: password ? [] : [itemId],
      partial: false,
    };
  },
  async install(_selectedItems, opts) {
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
