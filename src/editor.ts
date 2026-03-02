import { promises as fs } from 'node:fs';
import path from 'node:path';
import { cancel, confirm, intro, isCancel, log, multiselect, outro, select, text } from '@clack/prompts';
import chalk from 'chalk';
import { stringify } from 'yaml';
import { modules } from './modules';
import { listProfiles, loadProfile } from './config';
import type { ProfileConfig } from './types';
import { CONFIG_DIR, DOTFILES_ROOT } from './paths';

/** Modules that are always required and cannot be deselected */
const REQUIRED_MODULES = new Set(['core']);

/** Items within modules that are always required */
const REQUIRED_ITEMS: Record<string, Set<string>> = {};

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
  // user profile
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
  log.step('Select modules and items');
  const selectedModules: Record<string, string[]> = {};

  for (const mod of modules) {
    const isRequired = REQUIRED_MODULES.has(mod.name);
    const currentItems = getProfileItems(baseProfile, mod.name);

    if (isRequired) {
      // Required module — show as locked, use all default items
      log.info(chalk.green(`✔ ${mod.label}`) + chalk.dim(' (required — always installed)'));
      selectedModules[mod.name] = mod.defaultItems;
      continue;
    }

    // Skip modules with no selectable items (like encryption which is boolean)
    if (mod.items.length === 0) continue;

    const moduleOptions = mod.items.map((item) => {
      const isRequiredItem = REQUIRED_ITEMS[mod.name]?.has(item.id);
      return {
        value: item.id,
        label: isRequiredItem ? `${item.label} ${chalk.dim('(required)')}` : item.label,
        hint: item.description,
      };
    });

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

    // Ensure required items are always included
    const requiredForModule = REQUIRED_ITEMS[mod.name];
    if (requiredForModule) {
      for (const req of requiredForModule) {
        if (!selected.includes(req)) selected.push(req);
      }
    }

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
  profile.config = {
    git: {
      user_name: gitName.trim(),
      user_email: gitEmail.trim(),
    },
    ...(baseProfile?.config ? Object.fromEntries(
      Object.entries(baseProfile.config).filter(([key]) => key !== 'git')
    ) : {}),
  };

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

  // Save location choice
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

  log.info(`\nRun it with: ${chalk.cyan(`macsetup --profile ${profileName}`)}`);
}
