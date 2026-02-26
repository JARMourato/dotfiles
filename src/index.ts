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
import { masAppsForItems, masItemsFromApps } from './modules/mas';
import { runRequiredPhase } from './required';
import { runModules } from './runner';
import { JsonStateManager } from './state';
import type { InstallOptions, ModuleV2, ProfileConfig } from './types';
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
  .option('--uninstall', 'uninstall everything from last state')
  .parse(process.argv);

const options = program.opts<{
  profile?: string;
  dryRun?: boolean;
  module?: string;
  diff?: boolean;
  export?: boolean;
  verbose?: boolean;
  uninstall?: boolean;
}>();

function handleCancelled<T>(value: T): T {
  if (isCancel(value)) {
    cancel('Operation cancelled.');
    process.exit(0);
  }
  return value;
}

function itemLabel(module: ModuleV2, id: string): string {
  return module.items.find((item) => item.id === id)?.label ?? id;
}

function sanitizeItems(module: ModuleV2, items: string[]): string[] {
  const available = new Set(module.items.map((item) => item.id));
  return items.filter((item) => available.has(item));
}

function legacyIncludes(profile: ProfileConfig, name: string): boolean {
  return Array.isArray(profile.modules) && profile.modules.includes(name);
}

function selectionsFromProfile(profile: ProfileConfig): Record<string, string[]> {
  const selected: Record<string, string[]> = {};
  const profileAny = profile as unknown as Record<string, unknown>;

  for (const module of modules) {
    let items: string[] = [];

    if (module.name === 'encryption') {
      if (profile.encryption || legacyIncludes(profile, 'encryption')) {
        items = [...module.defaultItems];
      }
    } else if (module.name === 'xcode') {
      if (profile.xcode || legacyIncludes(profile, 'xcode')) {
        items = [...module.defaultItems];
      }
    } else if (module.name === 'mas') {
      if (Array.isArray(profile.mas)) {
        items = masItemsFromApps(profile.mas);
      } else if (legacyIncludes(profile, 'mas')) {
        items = [...module.defaultItems];
      } else {
        const legacyApps = profile.config.mas?.apps ?? [];
        items = masItemsFromApps(legacyApps);
      }
    } else if (module.name === 'macos_complex') {
      const direct = profile.macos_complex;
      if (Array.isArray(direct)) {
        items = direct;
      } else if (legacyIncludes(profile, 'macos-complex')) {
        items = [...module.defaultItems];
      }
    } else if (module.name === 'languages') {
      if (Array.isArray(profile.languages)) {
        items = profile.languages;
      } else {
        if (legacyIncludes(profile, 'languages') || legacyIncludes(profile, 'python')) items.push('python');
        if (legacyIncludes(profile, 'languages') || legacyIncludes(profile, 'ruby')) items.push('ruby');
        if (items.length === 0 && (profile.config.python || profile.config.ruby)) {
          if (profile.config.python) items.push('python');
          if (profile.config.ruby) items.push('ruby');
        }
      }
    } else {
      const direct = profileAny[module.name];
      if (Array.isArray(direct)) {
        items = direct.map(String);
      } else if (legacyIncludes(profile, module.name)) {
        items = [...module.defaultItems];
      }
    }

    selected[module.name] = sanitizeItems(module, items);
  }

  return selected;
}

function applySelectionsToProfile(profile: ProfileConfig, selected: Record<string, string[]>): void {
  delete profile.modules;
  const profileAny = profile as unknown as Record<string, unknown>;

  for (const module of modules) {
    const items = selected[module.name] ?? [];

    if (module.name === 'encryption') {
      profile.encryption = items.length > 0;
      continue;
    }

    if (module.name === 'xcode') {
      profile.xcode = items.length > 0;
      continue;
    }

    if (module.name === 'mas') {
      profile.mas = masAppsForItems(items);
      continue;
    }

    if (module.name === 'macos_complex') {
      profile.macos_complex = items;
      continue;
    }

    profileAny[module.name] = items;
  }
}

function defaultCustomProfile(config: ProfileConfig['config']): ProfileConfig {
  return {
    name: 'custom',
    description: 'Custom setup',
    config,
  };
}

async function promptModuleItems(
  selectedModules: string[],
  prefill: Record<string, string[]>,
): Promise<Record<string, string[]>> {
  const selected: Record<string, string[]> = {};

  for (const moduleName of selectedModules) {
    const module = modules.find((candidate) => candidate.name === moduleName);
    if (!module) continue;

    const initial = prefill[module.name]?.length ? prefill[module.name] : module.defaultItems;

    // If only one item (single toggle modules like encryption/xcode), skip drill-down
    if (module.items.length === 1) {
      selected[module.name] = [...module.defaultItems];
      continue;
    }

    const allIds = module.items.map((item) => item.id);

    const items = handleCancelled(
      await multiselect({
        message: `${module.label} - select items (first two options toggle all)`,
        options: [
          { value: '__select_all__', label: '✅ Select All', hint: 'Toggle all items on' },
          { value: '__select_none__', label: '☐  Select None', hint: 'Toggle all items off' },
          ...module.items.map((item) => ({
            value: item.id,
            label: item.label,
            hint: item.description,
            selected: initial.includes(item.id),
          })),
        ],
      }),
    ) as string[];

    let finalItems: string[];
    if (items.includes('__select_all__')) {
      finalItems = allIds;
    } else if (items.includes('__select_none__')) {
      finalItems = [];
    } else {
      finalItems = items.filter((item) => !item.startsWith('__'));
    }

    selected[module.name] = sanitizeItems(module, finalItems);
  }

  return selected;
}

async function promptModuleSelection(
  initialSelections: Record<string, string[]>,
): Promise<Record<string, string[]>> {
  const selectedModules = handleCancelled(
    await multiselect({
      message: 'Select modules to install',
      options: modules.map((module) => ({
        value: module.name,
        label: module.label,
        hint: module.description,
        selected: (initialSelections[module.name] ?? []).length > 0,
      })),
      required: true,
    }),
  ) as string[];

  const itemSelection = await promptModuleItems(selectedModules, initialSelections);
  const output: Record<string, string[]> = {};
  for (const module of modules) {
    const items = itemSelection[module.name] ?? [];
    if (items.length > 0) {
      output[module.name] = items;
    }
  }
  return output;
}

async function resolveProfile(rootDir: string): Promise<{ profile: ProfileConfig; selected: Record<string, string[]> }> {
  if (options.profile) {
    const profile = await loadProfile(rootDir, options.profile);
    const selected = selectionsFromProfile(profile);
    return { profile, selected };
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

  if (setupKind === 'custom') {
    const profile = defaultCustomProfile(lastConfig?.config ?? {});
    const selected = await promptModuleSelection({});
    applySelectionsToProfile(profile, selected);
    return { profile, selected };
  }

  if (setupKind === 'last' && lastConfig) {
    const selected = selectionsFromProfile(lastConfig);
    return { profile: lastConfig, selected };
  }

  const profile = await loadProfile(rootDir, String(setupKind));
  let selected = selectionsFromProfile(profile);

  const customize = handleCancelled(
    await confirm({
      message: `${profile.name} profile selected. Customize items?`,
      initialValue: false,
    }),
  );

  if (customize) {
    selected = await promptModuleSelection(selected);
  }

  applySelectionsToProfile(profile, selected);
  return { profile, selected };
}

async function maybePromptGit(profile: ProfileConfig): Promise<void> {
  if (!profile.config.git?.user_name) {
    const userName = handleCancelled(await text({ message: 'Git user.name' }));
    profile.config.git = { ...profile.config.git, user_name: String(userName) };
  }

  if (!profile.config.git?.user_email) {
    const userEmail = handleCancelled(await text({ message: 'Git user.email' }));
    profile.config.git = { ...profile.config.git, user_email: String(userEmail) };
  }
}

async function maybeResolveEncryptionPassword(selected: Record<string, string[]>): Promise<string | undefined> {
  if ((selected.encryption ?? []).length === 0) return undefined;

  let secret = await getKeychainPassword();
  if (secret) return secret;

  const create = handleCancelled(
    await confirm({
      message: 'No keychain encryption password found. Set one now?',
      initialValue: true,
    }),
  );

  if (!create) {
    throw new Error('Encryption selected but no keychain password available.');
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

function summaryLines(selected: Record<string, string[]>): string[] {
  const lines: string[] = [];

  for (const module of modules) {
    const items = selected[module.name] ?? [];
    if (items.length === 0) continue;
    const labels = items.map((item) => itemLabel(module, item));
    lines.push(`${module.label}: ${labels.join(', ')}`);
  }

  return lines;
}

async function run(): Promise<void> {
  const rootDir = process.cwd();
  const state = new JsonStateManager();

  if (options.uninstall) {
    const current = await state.load();
    if (!current) {
      console.log('No state file found — nothing to uninstall.');
      return;
    }

    intro(chalk.cyan('macsetup — uninstall'));
    log.info(`Last run: ${current.lastRun}\nProfile: ${current.profile}`);

    const installedModules = Object.entries(current.modules)
      .filter(([, record]) => record.installed.length > 0)
      .map(([name, record]) => {
        const module = modules.find((m) => m.name === name);
        return { name, label: module?.label ?? name, items: record.installed };
      });

    if (installedModules.length === 0) {
      outro('Nothing installed to remove.');
      return;
    }

    for (const mod of installedModules) {
      log.info(`${mod.label}: ${mod.items.join(', ')}`);
    }

    const shouldUninstall = handleCancelled(
      await confirm({
        message: `Uninstall all ${installedModules.length} modules? This will brew uninstall formulas/casks.`,
        initialValue: false,
      }),
    );

    if (!shouldUninstall) {
      outro('Cancelled.');
      return;
    }

    const { uninstallFormulas, uninstallCasks } = await import('./modules/helpers');
    const { runCommand } = await import('./utils/shell');

    for (const mod of installedModules) {
      const module = modules.find((m) => m.name === mod.name);
      if (!module) continue;

      log.step(`Uninstalling ${mod.label}...`);

      // Determine if items are casks or formulas based on module type
      const caskModules = new Set(['apps', 'comms', 'productivity']);
      const formulaModules = new Set(['core', 'ios', 'cloud', 'languages']);

      if (caskModules.has(mod.name)) {
        await uninstallCasks(mod.items, { dryRun: Boolean(options.dryRun), verbose: Boolean(options.verbose), profile: { name: '', description: '', config: {} }, state, rootDir });
      } else if (formulaModules.has(mod.name)) {
        await uninstallFormulas(mod.items, { dryRun: Boolean(options.dryRun), verbose: Boolean(options.verbose), profile: { name: '', description: '', config: {} }, state, rootDir });
      } else if (mod.name === 'ai') {
        const casks = mod.items.filter((i) => i === 'claude' || i === 'chatgpt');
        const npms = mod.items.filter((i) => i === 'claude-code' || i === 'openclaw');
        if (casks.length > 0) await uninstallCasks(casks, { dryRun: Boolean(options.dryRun), verbose: Boolean(options.verbose), profile: { name: '', description: '', config: {} }, state, rootDir });
        for (const pkg of npms) {
          const npmName = pkg === 'claude-code' ? '@anthropic-ai/claude-code' : pkg;
          await runCommand('npm', ['uninstall', '-g', npmName], { dryRun: Boolean(options.dryRun), continueOnError: true });
        }
      } else if (mod.name === 'terminal') {
        log.info('Terminal settings (oh-my-zsh, theme, fonts) — skipped (manual removal recommended)');
      } else if (mod.name === 'macos' || mod.name === 'macos_complex') {
        log.info(`${mod.label} — defaults cannot be automatically reverted`);
      } else if (mod.name === 'encryption' || mod.name === 'xcode' || mod.name === 'cleanup' || mod.name === 'mas') {
        log.info(`${mod.label} — skipped (not safely reversible)`);
      }
    }

    // Clear state
    const emptyState = {
      lastRun: new Date().toISOString(),
      profile: 'uninstalled',
      modules: {},
      machine: current.machine,
    };
    await state.save(emptyState);

    outro('Uninstall complete.');
    return;
  }

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
      config: {},
    };
    const exportedAny = exported as unknown as Record<string, unknown>;

    for (const module of modules) {
      const installed = current.modules[module.name]?.installed ?? [];
      if (module.name === 'encryption') exported.encryption = installed.length > 0;
      else if (module.name === 'xcode') exported.xcode = installed.length > 0;
      else if (module.name === 'mas') exported.mas = masAppsForItems(installed);
      else if (module.name === 'macos_complex') exported.macos_complex = installed;
      else exportedAny[module.name] = installed;
    }

    console.log(yaml.stringify(exported));
    return;
  }

  const resolved = await resolveProfile(rootDir);
  const profile = resolved.profile;
  let selected = resolved.selected;

  if (options.module) {
    const module = modules.find((candidate) => candidate.name === options.module);
    if (!module) {
      throw new Error(`Unknown module: ${options.module}`);
    }
    const current = selected[module.name] ?? [];
    selected = {
      [module.name]: current.length > 0 ? current : module.defaultItems,
    };
    applySelectionsToProfile(profile, selected);
  }

  await maybePromptGit(profile);
  const encryptionPassword = await maybeResolveEncryptionPassword(selected);

  const machine = await detectMachine();
  const summary = summaryLines(selected);
  log.info(
    `Profile: ${profile.name}\nRequired: xcode-select, homebrew, node, ssh, git, shell dotfiles\nOptional:\n${summary.length > 0 ? summary.join('\n') : 'none'}\nDry run: ${Boolean(options.dryRun) ? 'yes' : 'no'}`,
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

  await runRequiredPhase(installOpts);

  const result = await runModules(modules, selected, installOpts);
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
