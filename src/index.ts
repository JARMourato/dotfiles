import path from 'node:path';
import {
  cancel,
  confirm,
  intro,
  isCancel,
  log,
  multiselect,
  outro,
  password,
  select,
  text,
} from '@clack/prompts';
import chalk from 'chalk';
import { Command } from 'commander';
import { loadProfile, loadUserConfig, saveUserConfig } from './config';
import { modules } from './modules';
import { runModules } from './runner';
import { JsonStateManager } from './state';
import type { InstallOptions, ProfileConfig } from './types';
import { detectMachine } from './utils/detect';
import { getKeychainPassword, setKeychainPassword } from './utils/keychain';

const program = new Command();

program
  .name('macsetup')
  .description('Interactive macOS setup CLI for dotfiles and machine provisioning')
  .option('--profile <name>', 'profile to use (dev/server/minimal)')
  .option('--dry-run', 'preview commands without executing')
  .option('--module <name>', 'run a single module')
  .option('--diff', 'show diff since last run')
  .option('--export', 'export current state as profile YAML')
  .option('--verbose', 'verbose output')
  .parse(process.argv);

const options = program.opts<{
  profile?: string;
  dryRun?: boolean;
  module?: string;
  diff?: boolean;
  export?: boolean;
  verbose?: boolean;
}>();

function handleCancelled<T>(value: T): T {
  if (isCancel(value)) {
    cancel('Operation cancelled.');
    process.exit(0);
  }
  return value;
}

function profileFromPreset(name: string): string[] {
  switch (name) {
    case 'dev':
      return ['core', 'terminal', 'shell', 'macos', 'macos-complex', 'node', 'python', 'ruby', 'ios', 'cloud', 'apps', 'comms', 'productivity', 'ai', 'ssh', 'git', 'xcode', 'encryption', 'cleanup', 'mas'];
    case 'server':
      return ['core', 'terminal', 'shell', 'macos', 'cloud', 'apps', 'comms', 'git', 'ssh', 'cleanup'];
    case 'minimal':
      return ['core', 'terminal', 'shell', 'macos', 'node'];
    default:
      return [];
  }
}

async function resolveProfile(rootDir: string): Promise<ProfileConfig> {
  if (options.profile) {
    return loadProfile(rootDir, options.profile);
  }

  const lastConfig = await loadUserConfig();
  const machine = await detectMachine();

  intro(chalk.cyan('macsetup'));
  log.info(`Machine: ${machine.chip} • ${machine.ram} • ${machine.os}`);

  const setupKind = handleCancelled(
    await select({
      message: 'What kind of setup?',
      options: [
        { value: 'dev', label: 'Full Dev' },
        { value: 'server', label: 'Server' },
        { value: 'minimal', label: 'Minimal' },
        { value: 'custom', label: 'Custom' },
        ...(lastConfig ? [{ value: 'last', label: `Use last config (${lastConfig.name})` }] : []),
      ],
    }),
  );

  if (setupKind === 'last' && lastConfig) return lastConfig;

  if (setupKind === 'custom') {
    const tempProfile: ProfileConfig = {
      name: 'custom',
      description: 'Custom setup',
      modules: [],
      config: {},
    };

    const detectOpts: InstallOptions = {
      dryRun: Boolean(options.dryRun),
      verbose: Boolean(options.verbose),
      nonInteractive: false,
      profile: tempProfile,
      state: new JsonStateManager(),
      rootDir,
    };

    const detected = await Promise.all(modules.map(async (mod) => ({ mod, result: await mod.detect(detectOpts) })));

    const selected = handleCancelled(
      await multiselect({
        message: 'Select modules',
        options: detected.map(({ mod, result }) => ({
          value: mod.name,
          label: mod.label,
          hint: mod.description,
          selected: result.missing.length > 0,
        })),
        required: true,
      }),
    ) as string[];

    return {
      name: 'custom',
      description: 'Custom setup',
      modules: selected,
      config: lastConfig?.config ?? {},
    };
  }

  const profileName = String(setupKind);
  return loadProfile(rootDir, profileName);
}

async function maybePromptGit(profile: ProfileConfig): Promise<void> {
  if (!profile.modules.includes('git')) return;

  if (!profile.config.git?.user_name) {
    const userName = handleCancelled(await text({ message: 'Git user.name' }));
    profile.config.git = { ...profile.config.git, user_name: String(userName) };
  }

  if (!profile.config.git?.user_email) {
    const userEmail = handleCancelled(await text({ message: 'Git user.email' }));
    profile.config.git = { ...profile.config.git, user_email: String(userEmail) };
  }
}

async function maybeResolveEncryptionPassword(profile: ProfileConfig): Promise<string | undefined> {
  if (!profile.modules.includes('encryption')) return undefined;

  let secret = await getKeychainPassword();
  if (secret) return secret;

  const create = handleCancelled(
    await confirm({
      message: 'No keychain encryption password found. Set one now?',
      initialValue: true,
    }),
  );

  if (!create) {
    throw new Error('Encryption module selected but no keychain password available.');
  }

  const entered = handleCancelled(
    await password({
      message: 'Encryption password',
      validate(value) {
        if (!value || value.length < 4) return 'Password must be at least 4 characters.';
      },
    }),
  );

  secret = String(entered);
  await setKeychainPassword(secret);
  return secret;
}

async function run(): Promise<void> {
  const rootDir = process.cwd();
  const state = new JsonStateManager();

  if (options.diff) {
    const current = await state.load();
    if (!current) {
      console.log('No state file found.');
      return;
    }
    const lines = await state.diff(current);
    console.log(lines.join('\n'));
    return;
  }

  if (options.export) {
    const current = await state.load();
    if (!current) {
      console.log('No state to export.');
      return;
    }

    const yaml = await import('yaml');
    const exported: ProfileConfig = {
      name: `${current.profile}-exported`,
      description: `Exported profile from ${current.lastRun}`,
      modules: Object.keys(current.modules),
      config: {},
    };
    console.log(yaml.stringify(exported));
    return;
  }

  const profile = await resolveProfile(rootDir);

  if (options.module) {
    profile.modules = [options.module];
  }

  await maybePromptGit(profile);
  const encryptionPassword = await maybeResolveEncryptionPassword(profile);

  const machine = await detectMachine();
  log.info(
    `Profile: ${profile.name}\nModules: ${profile.modules.join(', ')}\nDry run: ${Boolean(options.dryRun) ? 'yes' : 'no'}`,
  );

  const shouldRun = options.profile || options.module
    ? true
    : handleCancelled(
        await confirm({
          message: 'Proceed with installation?',
          initialValue: true,
        }),
      );

  if (!shouldRun) {
    outro('Cancelled.');
    return;
  }

  const installOpts: InstallOptions = {
    dryRun: Boolean(options.dryRun),
    verbose: Boolean(options.verbose),
    profile,
    state,
    rootDir,
    encryptionPassword,
  };

  const result = await runModules(modules, profile.modules, installOpts);
  result.state.machine = machine;

  await state.save(result.state);
  await saveUserConfig(profile);

  if (result.failures.length > 0) {
    for (const failure of result.failures) {
      log.error(failure);
    }
    outro(`Finished with ${result.failures.length} failure(s).`);
    process.exitCode = 1;
    return;
  }

  outro('Setup complete.');
}

run().catch((error) => {
  const message = error instanceof Error ? error.message : String(error);
  console.error(chalk.red(`Error: ${message}`));
  process.exit(1);
});
