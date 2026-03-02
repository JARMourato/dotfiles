import { promises as fs } from 'node:fs';
import { runCommand } from './utils/shell';
import { BACKUP_PATH, CONFIG_DIR } from './paths';

const NOT_SET = '__NOT_SET__';

type Primitive = string | number | boolean;
type RawValue = { kind: 'raw'; value: string };
export type DefaultValue = Primitive | RawValue | typeof NOT_SET;

export interface DefaultsBackup {
  created: string;
  defaults: Record<string, Record<string, DefaultValue>>;
}

let backupCache: DefaultsBackup | null | undefined;
let backupEnabled: boolean | undefined;

function parseDefaultsValue(stdout: string): DefaultValue {
  const value = stdout.trim();
  if (value === 'true') return true;
  if (value === 'false') return false;
  if (/^-?\d+$/.test(value)) return Number.parseInt(value, 10);
  if (/^-?\d+\.\d+$/.test(value)) return Number.parseFloat(value);
  if (value.startsWith('{') || value.startsWith('(')) {
    return { kind: 'raw', value };
  }
  return value;
}

function valueToWriteArgs(value: DefaultValue): string[] {
  if (typeof value === 'boolean') {
    return ['-bool', String(value)];
  }
  if (typeof value === 'number') {
    return [Number.isInteger(value) ? '-int' : '-float', String(value)];
  }
  if (typeof value === 'string') {
    return ['-string', value];
  }
  return [value.value];
}

async function backupFileExists(): Promise<boolean> {
  try {
    await fs.access(BACKUP_PATH);
    return true;
  } catch {
    return false;
  }
}

async function ensureBackupState(): Promise<void> {
  if (backupEnabled !== undefined) return;
  const exists = await backupFileExists();
  backupEnabled = !exists;
  if (!exists) {
    backupCache = {
      created: new Date().toISOString(),
      defaults: {},
    };
  }
}

export async function loadDefaultsBackup(): Promise<DefaultsBackup | null> {
  try {
    const raw = await fs.readFile(BACKUP_PATH, 'utf8');
    return JSON.parse(raw) as DefaultsBackup;
  } catch {
    return null;
  }
}

export async function saveDefaultsBackup(backup: DefaultsBackup): Promise<void> {
  await fs.mkdir(CONFIG_DIR, { recursive: true });
  await fs.writeFile(BACKUP_PATH, JSON.stringify(backup, null, 2), 'utf8');
}

export async function backupDefault(domain: string, key: string): Promise<void> {
  await ensureBackupState();
  if (!backupEnabled || !backupCache) return;

  const domainDefaults = backupCache.defaults[domain] ?? {};
  if (Object.hasOwn(domainDefaults, key)) return;

  const read = await runCommand('defaults', ['read', domain, key], { continueOnError: true });
  domainDefaults[key] = read.ok ? parseDefaultsValue(read.stdout) : NOT_SET;
  backupCache.defaults[domain] = domainDefaults;
  await saveDefaultsBackup(backupCache);
}

export async function restoreAllDefaults(dryRun: boolean): Promise<void> {
  const backup = await loadDefaultsBackup();
  if (!backup) return;

  for (const [domain, values] of Object.entries(backup.defaults)) {
    for (const [key, value] of Object.entries(values)) {
      if (value === NOT_SET) {
        await runCommand('defaults', ['delete', domain, key], { dryRun, continueOnError: true });
        continue;
      }
      await runCommand('defaults', ['write', domain, key, ...valueToWriteArgs(value)], {
        dryRun,
        continueOnError: true,
      });
    }
  }
}

export async function clearDefaultsBackup(dryRun: boolean): Promise<void> {
  if (dryRun) return;
  await fs.rm(BACKUP_PATH, { force: true });
}

export { BACKUP_PATH, NOT_SET };
