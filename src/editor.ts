import { promises as fs } from 'node:fs';
import path from 'node:path';
import { cancel, confirm, intro, isCancel, log, multiselect, outro, select, text } from '@clack/prompts';
import chalk from 'chalk';
import { stringify } from 'yaml';
import { modules } from './modules';
import { listProfiles, loadProfile } from './config';
import type { ProfileConfig } from './types';
import { DOTFILES_ROOT } from './paths';

/** Modules that are always required — cannot be toggled off */
const REQUIRED_MODULES = new Set(['core']);

/** Modules that are all-or-nothing bundles (yes/no toggle) */
const BUNDLE_MODULES = new Set(['terminal', 'macos', 'macos_complex']);

function handleCancelled<T>(value: T): T {
  if (isCancel(value)) {
    cancel('Profile editing cancelled.');
    process.exit(0);
  }
  return value;
}

async function selectBaseProfile(rootDir: string): Promise<{ profile: ProfileConfig | null; name: string }> {
  const builtIn = await listProfiles(rootDir);
  const userDir = path.join(DOTFILES_ROOT, 'profiles');
  let userProfiles: string[] = [];
  try {
    const entries = await fs.readdir(userDir);
    userProfiles = entries.filter((e) => e.endsWith('.yaml')).map((e) => e.replace(/\.yaml$/, ''));
  } catch { /* no user profiles dir */ }

  const options: Array<{ value: string; label: string; hint?: string }> = [
    { value: '__new__', label: 'Create from scratch', hint: 'empty profile' },
  ];
  for (const name of builtIn) {
    options.push({ value: `builtin:${name}`, label: name, hint: 'built-in' });
  }
  for (const name of userProfiles) {
    if (!builtIn.includes(name)) {
      options.push({ value: `user:${name}`, label: name, hint: 'custom' });
    }
  }

  const choice = handleCancelled(
    await select({
      message: 'Start from an existing profile or create new?',
      options,
    }),
  ) as string;

  if (choice === '__new__') {
    return { profile: null, name: '' };
  }

  const [source, name] = choice.split(':');
  if (source === 'builtin') {
    return { profile: await loadProfile(rootDir, name), name };
  }
  const raw = await fs.readFile(path.join(userDir, `${name}.yaml`), 'utf8');
  const { parse } = await import('yaml');
  return { profile: parse(raw) as ProfileConfig, name };
}

function getProfileItems(profile: ProfileConfig | null, moduleName: string): string[] {
  if (!profile) return [];
  const value = (profile as unknown as Record<string, unknown>)[moduleName];
  if (Array.isArray(value)) return value.map(String);
  return [];
}

async function promptCustomAdditions(): Promise<{ formulas: string[]; casks: string[] }> {
  const formulas: string[] = [];
  const casks: string[] = [];

  const addExtras = handleCancelled(
    await confirm({
      message: 'Add custom brew formulas or casks not in the default modules?',
      initialValue: false,
    }),
  );

  if (!addExtras) return { formulas, casks };

  const formulaInput = handleCancelled(
    await text({
      message: 'Extra brew formulas (comma-separated, or leave empty)',
      placeholder: 'e.g. ffmpeg, imagemagick, gh',
      defaultValue: '',
    }),
  ) as string;

  if (formulaInput.trim()) {
    formulas.push(...formulaInput.split(',').map((s) => s.trim()).filter(Boolean));
  }

  const caskInput = handleCancelled(
    await text({
      message: 'Extra brew casks (comma-separated, or leave empty)',
      placeholder: 'e.g. discord, figma, notion',
      defaultValue: '',
    }),
  ) as string;

  if (caskInput.trim()) {
    casks.push(...caskInput.split(',').map((s) => s.trim()).filter(Boolean));
  }

  return { formulas, casks };
}

export async function runEditor(rootDir: string): Promise<void> {
  intro(chalk.bold('macsetup — Profile Editor'));

  const { profile: baseProfile, name: baseName } = await selectBaseProfile(rootDir);

  // Profile name
  const profileName = handleCancelled(
    await text({
      message: 'Profile name',
      placeholder: baseName || 'my-setup',
      defaultValue: baseName || '',
      validate: (val) => {
        if (!val.trim()) return 'Name is required';
        if (!/^[a-z0-9-]+$/.test(val.trim())) return 'Use lowercase letters, numbers, and hyphens only';
      },
    }),
  ) as string;

  const profileDesc = handleCancelled(
    await text({
      message: 'Description',
      placeholder: 'My machine setup',
      defaultValue: baseProfile?.description || '',
    }),
  ) as string;

  // Git config
  log.step('Git configuration');
  const gitName = handleCancelled(
    await text({
      message: 'Git user.name',
      placeholder: 'Your Name',
      defaultValue: baseProfile?.config?.git?.user_name || '',
    }),
  ) as string;

  const gitEmail = handleCancelled(
    await text({
      message: 'Git user.email',
      placeholder: 'you@example.com',
      defaultValue: baseProfile?.config?.git?.user_email || '',
    }),
  ) as string;

  // Module selection
  log.step('Select what to install');
  const selectedModules: Record<string, string[]> = {};

  for (const mod of modules) {
    const currentItems = getProfileItems(baseProfile, mod.name);
    const hasItems = mod.items.length > 0;

    // Required modules — always included, not toggleable
    if (REQUIRED_MODULES.has(mod.name)) {
      log.info(chalk.green('✔ ' + mod.label) + chalk.dim(' (required — always installed)'));
      selectedModules[mod.name] = mod.defaultItems;
      continue;
    }

    if (!hasItems) continue;

    // Bundle modules — all-or-nothing toggle
    if (BUNDLE_MODULES.has(mod.name)) {
      const wasEnabled = currentItems.length > 0;
      const itemList = mod.items.map((i) => i.label).join(', ');
      const enable = handleCancelled(
        await confirm({
          message: `${mod.label}? ${chalk.dim(`(${itemList})`)}`,
          initialValue: wasEnabled,
        }),
      );
      if (enable) {
        selectedModules[mod.name] = mod.defaultItems;
      }
      continue;
    }

    // Multiselect modules — pick individual items
    const moduleOptions = mod.items.map((item) => ({
      value: item.id,
      label: item.label,
      hint: item.description,
    }));

    const preSelected = currentItems.length > 0
      ? currentItems.filter((id) => mod.items.some((it) => it.id === id))
      : [];

    const selected = handleCancelled(
      await multiselect({
        message: `${mod.label} — ${mod.description}`,
        options: moduleOptions,
        initialValues: preSelected,
        required: false,
      }),
    ) as string[];

    if (selected.length > 0) {
      selectedModules[mod.name] = selected;
    }
  }

  // Encryption toggle
  const enableEncryption = handleCancelled(
    await confirm({
      message: 'Enable encrypted dotfiles?',
      initialValue: baseProfile?.encryption === true,
    }),
  );

  // Custom additions
  log.step('Custom additions');
  const { formulas: extraFormulas, casks: extraCasks } = await promptCustomAdditions();

  // Build profile YAML
  const profile: Record<string, unknown> = {
    name: profileName.trim(),
    description: profileDesc.trim(),
  };

  for (const mod of modules) {
    if (mod.items.length === 0) continue;
    profile[mod.name] = selectedModules[mod.name] || [];
  }

  profile.encryption = enableEncryption;

  const config: Record<string, unknown> = {
    git: {
      user_name: gitName.trim(),
      user_email: gitEmail.trim(),
    },
  };

  // Carry over non-git config from base profile (macos defaults, python versions, etc.)
  if (baseProfile?.config) {
    for (const [key, value] of Object.entries(baseProfile.config)) {
      if (key !== 'git') {
        config[key] = value;
      }
    }
  }

  // Add custom formulas/casks
  if (extraFormulas.length > 0) {
    config.extra_formulas = extraFormulas;
  }
  if (extraCasks.length > 0) {
    config.extra_casks = extraCasks;
  }

  profile.config = config;

  // Preview
  log.step('Preview');
  const yaml = stringify(profile);
  console.log(chalk.dim(yaml));

  const saveConfirmed = handleCancelled(
    await confirm({
      message: 'Save this profile?',
      initialValue: true,
    }),
  );

  if (!saveConfirmed) {
    cancel('Profile not saved.');
    return;
  }

  // Save location
  const saveLocation = handleCancelled(
    await select({
      message: 'Where to save?',
      options: [
        { value: 'user', label: `~/.dotfiles/profiles/${profileName}.yaml`, hint: 'personal, persists across runs' },
        { value: 'repo', label: `profiles/${profileName}.yaml`, hint: 'in the repo, shareable' },
      ],
    }),
  ) as string;

  let savePath: string;
  if (saveLocation === 'user') {
    const userProfileDir = path.join(DOTFILES_ROOT, 'profiles');
    await fs.mkdir(userProfileDir, { recursive: true });
    savePath = path.join(userProfileDir, `${profileName}.yaml`);
  } else {
    savePath = path.join(rootDir, 'profiles', `${profileName}.yaml`);
  }

  await fs.writeFile(savePath, yaml, 'utf8');
  outro(chalk.green(`Profile saved to ${savePath}`));

  log.info(`\nRun it with: ${chalk.cyan(`npx macsetup --profile ${profileName}`)}`);
}
