import { promises as fs } from 'node:fs';
import os from 'node:os';
import path from 'node:path';
import { confirm, isCancel, text } from '@clack/prompts';
import type { ModuleV2 } from '../types';
import { installCasks } from './helpers';
import { commandExists, runCommand } from '../utils/shell';
import { getKeychainPassword } from '../utils/keychain';

const items = [
  { id: 'hostname', label: 'Set hostname' },
  { id: 'plex', label: 'Plex Media Server' },
  { id: 'automounter', label: 'AutoMounter (App Store)' },
  { id: 'volumes', label: 'Verify volume mounts (/Volumes/4TB, /Volumes/Media)' },
  { id: 'plex-symlink', label: 'Plex data symlink to external drive' },
  { id: 'decrypt-env', label: 'Decrypt .env from keychain' },
  { id: 'docker-start', label: 'Start Docker containers' },
  { id: 'backup-scripts', label: 'Install backup/restore scripts' },
];

const HOMESERVER_DIR = path.join(os.homedir(), 'Workspace', 'Git', 'homeserver');

function handleCancelled<T>(value: T): T {
  if (isCancel(value)) {
    throw new Error('Operation cancelled.');
  }
  return value;
}

export const homeserverModule: ModuleV2 = {
  name: 'homeserver',
  label: 'Homeserver',
  description: 'Media server stack: Plex, Sonarr, Radarr, qBittorrent, and more',
  items,
  defaultItems: items.map((item) => item.id),
  dependencies: ['core', 'cloud'],
  async detect(selectedItems) {
    const installed: string[] = [];
    const missing: string[] = [];

    if (selectedItems.includes('plex')) {
      const exists = await runCommand('test', ['-d', '/Applications/Plex Media Server.app'], { continueOnError: true });
      if (exists.ok) installed.push('plex');
      else missing.push('plex');
    }

    if (selectedItems.includes('automounter')) {
      const exists = await runCommand('test', ['-d', '/Applications/AutoMounter.app'], { continueOnError: true });
      if (exists.ok) installed.push('automounter');
      else missing.push('automounter');
    }

    if (selectedItems.includes('volumes')) {
      const vol4tb = await runCommand('test', ['-d', '/Volumes/4TB'], { continueOnError: true });
      const volMedia = await runCommand('test', ['-d', '/Volumes/Media'], { continueOnError: true });
      if (vol4tb.ok && volMedia.ok) installed.push('volumes');
      else missing.push('volumes');
    }

    if (selectedItems.includes('plex-symlink')) {
      const plexLocal = path.join(os.homedir(), 'Library', 'Application Support', 'Plex Media Server');
      const isSymlink = await runCommand('test', ['-L', plexLocal], { continueOnError: true });
      if (isSymlink.ok) installed.push('plex-symlink');
      else missing.push('plex-symlink');
    }

    if (selectedItems.includes('decrypt-env')) {
      const servicesDir = path.join(process.cwd(), 'services', 'homeserver');
      const envExists = await runCommand('test', ['-f', path.join(servicesDir, '.env')], { continueOnError: true });
      if (envExists.ok) installed.push('decrypt-env');
      else missing.push('decrypt-env');
    }

    if (selectedItems.includes('docker-start')) {
      const dockerRunning = await runCommand('docker', ['info'], { continueOnError: true });
      if (dockerRunning.ok) {
        const containers = await runCommand('docker', ['compose', '-f', path.join(process.cwd(), 'services', 'homeserver', 'docker-compose.yml'), 'ps', '-q'], { continueOnError: true });
        if (containers.ok && containers.stdout.trim().length > 0) installed.push('docker-start');
        else missing.push('docker-start');
      } else {
        missing.push('docker-start');
      }
    }

    // hostname and backup-scripts are always "actionable"
    if (selectedItems.includes('hostname')) missing.push('hostname');
    if (selectedItems.includes('backup-scripts')) missing.push('backup-scripts');

    return { installed, missing, partial: installed.length > 0 && missing.length > 0 };
  },
  async install(selectedItems, opts) {
    const servicesDir = path.join(opts.rootDir, 'services', 'homeserver');

    // Set hostname
    if (selectedItems.includes('hostname')) {
      const currentName = await runCommand('scutil', ['--get', 'ComputerName'], { continueOnError: true });
      const newHostname = handleCancelled(
        await text({
          message: `Set hostname (current: ${currentName.stdout.trim()})`,
          placeholder: 'Press Enter to keep current',
        }),
      );

      if (newHostname && String(newHostname).trim()) {
        const name = String(newHostname).trim();
        await runCommand('sudo', ['scutil', '--set', 'ComputerName', name], { dryRun: opts.dryRun, continueOnError: true });
        await runCommand('sudo', ['scutil', '--set', 'LocalHostName', name], { dryRun: opts.dryRun, continueOnError: true });
        await runCommand('sudo', ['scutil', '--set', 'HostName', name], { dryRun: opts.dryRun, continueOnError: true });
      }
    }

    // Install Plex Media Server
    if (selectedItems.includes('plex')) {
      await installCasks(['plex-media-server'], opts);
    }

    // Install AutoMounter from App Store
    if (selectedItems.includes('automounter')) {
      const hasMas = await commandExists('mas');
      if (!hasMas) {
        await runCommand('brew', ['install', 'mas'], { dryRun: opts.dryRun, continueOnError: true });
      }
      await runCommand('mas', ['install', '1160435653'], { dryRun: opts.dryRun, continueOnError: true });
    }

    // Verify volumes
    if (selectedItems.includes('volumes')) {
      const vol4tb = await runCommand('test', ['-d', '/Volumes/4TB'], { continueOnError: true });
      const volMedia = await runCommand('test', ['-d', '/Volumes/Media'], { continueOnError: true });
      if (!vol4tb.ok) {
        const { log } = await import('@clack/prompts');
        log.warn('/Volumes/4TB not found — ensure external drive is connected');
      }
      if (!volMedia.ok) {
        const { log } = await import('@clack/prompts');
        log.warn('/Volumes/Media not found — ensure external drive is connected');
      }
    }

    // Plex data symlink
    if (selectedItems.includes('plex-symlink')) {
      const plexLocal = path.join(os.homedir(), 'Library', 'Application Support', 'Plex Media Server');
      const plexExternal = '/Volumes/4TB/Plex Media Server';
      const isSymlink = await runCommand('test', ['-L', plexLocal], { continueOnError: true });

      if (!isSymlink.ok && !opts.dryRun) {
        const vol4tb = await runCommand('test', ['-d', '/Volumes/4TB'], { continueOnError: true });
        if (vol4tb.ok) {
          // Stop Plex if running
          await runCommand('osascript', ['-e', 'quit app "Plex Media Server"'], { continueOnError: true });
          await new Promise((r) => setTimeout(r, 2000));

          // Remove existing and create symlink
          const plexExists = await runCommand('test', ['-d', plexLocal], { continueOnError: true });
          if (plexExists.ok) {
            await runCommand('rm', ['-rf', plexLocal], { continueOnError: true });
          }
          await fs.mkdir(path.dirname(plexLocal), { recursive: true });
          await runCommand('mkdir', ['-p', plexExternal], { continueOnError: true });
          await fs.symlink(plexExternal, plexLocal);
        }
      }
    }

    // Decrypt .env
    if (selectedItems.includes('decrypt-env')) {
      const envPath = path.join(servicesDir, '.env');
      const encPath = path.join(servicesDir, '.env.enc');
      const envExists = await runCommand('test', ['-f', envPath], { continueOnError: true });

      if (!envExists.ok) {
        const encExists = await runCommand('test', ['-f', encPath], { continueOnError: true });
        if (encExists.ok) {
          const password = opts.encryptionPassword ?? await getKeychainPassword();
          if (password) {
            await runCommand('openssl', ['enc', '-aes-256-cbc', '-d', '-salt', '-pbkdf2', '-pass', `pass:${password}`, '-in', encPath, '-out', envPath], {
              dryRun: opts.dryRun,
              continueOnError: true,
            });
          }
        }
      }
    }

    // Start Docker containers
    if (selectedItems.includes('docker-start')) {
      const dockerRunning = await runCommand('docker', ['info'], { continueOnError: true });
      if (dockerRunning.ok) {
        const composePath = path.join(servicesDir, 'docker-compose.yml');
        await runCommand('docker', ['compose', '-f', composePath, 'up', '-d'], {
          dryRun: opts.dryRun,
          continueOnError: true,
        });
      } else {
        const { log } = await import('@clack/prompts');
        log.warn('Docker is not running — please start Docker Desktop first, then run: docker compose -f services/homeserver/docker-compose.yml up -d');
      }
    }

    // Install backup/restore scripts — make them executable
    if (selectedItems.includes('backup-scripts') && !opts.dryRun) {
      for (const script of ['backup-api.sh', 'restore-api.sh', 'backup.sh', 'restore.sh']) {
        const scriptPath = path.join(servicesDir, script);
        const exists = await runCommand('test', ['-f', scriptPath], { continueOnError: true });
        if (exists.ok) {
          await runCommand('chmod', ['+x', scriptPath], { continueOnError: true });
        }
      }

      // Create convenience symlink at ~/Workspace/Git/homeserver
      const symTarget = path.join(servicesDir);
      const symlinkExists = await runCommand('test', ['-e', HOMESERVER_DIR], { continueOnError: true });
      if (!symlinkExists.ok) {
        await fs.mkdir(path.dirname(HOMESERVER_DIR), { recursive: true });
        await fs.symlink(symTarget, HOMESERVER_DIR);
      }
    }
  },
};
