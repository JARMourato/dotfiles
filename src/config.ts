import { promises as fs } from 'node:fs';
import os from 'node:os';
import path from 'node:path';
import { parse, stringify } from 'yaml';
import type { ProfileConfig } from './types';

const CONFIG_PATH = path.join(os.homedir(), '.macsetup.config.yaml');

export async function loadUserConfig(): Promise<ProfileConfig | null> {
  try {
    const raw = await fs.readFile(CONFIG_PATH, 'utf8');
    return parse(raw) as ProfileConfig;
  } catch {
    return null;
  }
}

export async function saveUserConfig(config: ProfileConfig): Promise<void> {
  await fs.writeFile(CONFIG_PATH, stringify(config), 'utf8');
}

export async function loadProfile(rootDir: string, profileName: string): Promise<ProfileConfig> {
  const profilePath = path.join(rootDir, 'profiles', `${profileName}.yaml`);
  const raw = await fs.readFile(profilePath, 'utf8');
  return parse(raw) as ProfileConfig;
}

export async function listProfiles(rootDir: string): Promise<string[]> {
  const dir = path.join(rootDir, 'profiles');
  const entries = await fs.readdir(dir);
  return entries
    .filter((entry) => entry.endsWith('.yaml'))
    .map((entry) => entry.replace(/\.yaml$/, ''));
}

export { CONFIG_PATH };
