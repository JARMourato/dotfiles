import { runCapture, runCommand } from './shell';

export async function getKeychainPassword(service = 'dotfiles-encryption', account = 'default'): Promise<string | null> {
  try {
    const password = await runCapture('security', [
      'find-generic-password',
      '-s',
      service,
      '-a',
      account,
      '-w',
    ]);
    return password.trim() || null;
  } catch {
    return null;
  }
}

export async function setKeychainPassword(
  password: string,
  service = 'dotfiles-encryption',
  account = 'default',
): Promise<void> {
  await runCommand('security', ['delete-generic-password', '-s', service, '-a', account], { continueOnError: true });
  await runCommand('security', ['add-generic-password', '-s', service, '-a', account, '-w', password]);
}
