import { promises as fs } from 'node:fs';
import { realHome } from './utils/shell';
import path from 'node:path';
import { parse, stringify } from 'yaml';
import type { ProfileConfig } from './types';

const CONFIG_PATH = path.join(realHome(), '.macsetup.config.yaml');

function normalizeProfile(raw: Partial<ProfileConfig>): ProfileConfig {
  return {
    name: raw.name ?? 'custom',
    description: raw.description ?? 'Custom setup',
    ...raw,
    config: raw.config ?? {},
  } as ProfileConfig;
}

export async function loadUserConfig(): Promise<ProfileConfig | null> {
  try {
    const raw = await fs.readFile(CONFIG_PATH, 'utf8');
    return normalizeProfile(parse(raw) as Partial<ProfileConfig>);
  } catch {
    return null;
  }
}

export async function saveUserConfig(config: ProfileConfig): Promise<void> {
  await fs.writeFile(CONFIG_PATH, stringify(config), 'utf8');
}

export async function loadProfile(rootDir: string, profileName: string): Promise<ProfileConfig> {
  // Check user profiles first (~/.dotfiles/profiles/), then built-in
  const { DOTFILES_ROOT } = await import('./paths');
  const userPath = path.join(DOTFILES_ROOT, 'profiles', `${profileName}.yaml`);
  const builtInPath = path.join(rootDir, 'profiles', `${profileName}.yaml`);

  let raw: string;
  try {
    raw = await fs.readFile(userPath, 'utf8');
  } catch {
    raw = await fs.readFile(builtInPath, 'utf8');
  }
  return normalizeProfile(parse(raw) as Partial<ProfileConfig>);
}

export async function listProfiles(rootDir: string): Promise<string[]> {
  const dir = path.join(rootDir, 'profiles');
  const entries = await fs.readdir(dir);
  return entries
    .filter((entry) => entry.endsWith('.yaml'))
    .map((entry) => entry.replace(/\.yaml$/, ''));
}

export { CONFIG_PATH };
