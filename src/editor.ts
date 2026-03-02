import { promises as fs } from 'node:fs';
import path from 'node:path';
import { cancel, confirm, intro, isCancel, log, multiselect, outro, select, text } from '@clack/prompts';
import chalk from 'chalk';
import { stringify } from 'yaml';
import { modules } from './modules';
import { listProfiles, loadProfile } from './config';
import type { ProfileConfig } from './types';
import { DOTFILES_ROOT } from './paths';

const REQUIRED_MODULES = new Set(['core']);
const BUNDLE_MODULES = new Set(['terminal', 'macos', 'macos_complex']);

const BACK = Symbol('back');

function handleCancelled<T>(value: T): T {
  if (isCancel(value)) {
    cancel('Profile editing cancelled.');
    process.exit(0);
  }
  return value;
}

function getProfileItems(profile: ProfileConfig | null, moduleName: string): string[] {
  if (!profile) return [];
  const value = (profile as unknown as Record<string, unknown>)[moduleName];
  if (Array.isArray(value)) return value.map(String);
  return [];
}

/** State collected across steps */
interface EditorState {
  baseProfile: ProfileConfig | null;
  baseName: string;
  profileName: string;
  profileDesc: string;
  gitName: string;
  gitEmail: string;
  selectedModules: Record<string, string[]>;
  enableEncryption: boolean;
  extraFormulas: string[];
  extraCasks: string[];
}

function freshState(): EditorState {
  return {
    baseProfile: null,
    baseName: '',
    profileName: '',
    profileDesc: '',
    gitName: '',
    gitEmail: '',
    selectedModules: {},
    enableEncryption: false,
    extraFormulas: [],
    extraCasks: [],
  };
}

// ── Step functions ──────────────────────────────────────────────
// Each returns true to advance, BACK to go back

async function stepBaseProfile(rootDir: string, state: EditorState): Promise<true | typeof BACK> {
  const builtIn = await listProfiles(rootDir);
  const userDir = path.join(DOTFILES_ROOT, 'profiles');
  let userProfiles: string[] = [];
  try {
    const entries = await fs.readdir(userDir);
    userProfiles = entries.filter((e) => e.endsWith('.yaml')).map((e) => e.replace(/\.yaml$/, ''));
  } catch {}

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
    await select({ message: 'Start from an existing profile or create new?', options }),
  ) as string;

  if (choice === '__new__') {
    state.baseProfile = null;
    state.baseName = '';
    return true;
  }

  const [source, name] = choice.split(':');
  if (source === 'builtin') {
    state.baseProfile = await loadProfile(rootDir, name);
  } else {
    const raw = await fs.readFile(path.join(userDir, `${name}.yaml`), 'utf8');
    const { parse } = await import('yaml');
    state.baseProfile = parse(raw) as ProfileConfig;
  }
  state.baseName = name;
  return true;
}

async function stepNameDesc(state: EditorState): Promise<true | typeof BACK> {
  const name = handleCancelled(
    await text({
      message: 'Profile name' + chalk.dim(' (type "<" to go back)'),
      placeholder: state.baseName || 'my-setup',
      defaultValue: state.profileName || state.baseName || '',
      validate: (val) => {
        if (val.trim() === '<') return undefined; // allow back
        if (!val.trim()) return 'Name is required';
        if (!/^[a-z0-9-]+$/.test(val.trim())) return 'Use lowercase letters, numbers, and hyphens only';
      },
    }),
  ) as string;
  if (name.trim() === '<') return BACK;
  state.profileName = name.trim();

  const desc = handleCancelled(
    await text({
      message: 'Description' + chalk.dim(' (type "<" to go back)'),
      placeholder: 'My machine setup',
      defaultValue: state.profileDesc || state.baseProfile?.description || '',
    }),
  ) as string;
  if (desc.trim() === '<') return BACK;
  state.profileDesc = desc.trim();

  return true;
}

async function stepGit(state: EditorState): Promise<true | typeof BACK> {
  log.step('Git configuration');
  const name = handleCancelled(
    await text({
      message: 'Git user.name' + chalk.dim(' (type "<" to go back)'),
      placeholder: 'Your Name',
      defaultValue: state.gitName || state.baseProfile?.config?.git?.user_name || '',
    }),
  ) as string;
  if (name.trim() === '<') return BACK;
  state.gitName = name.trim();

  const email = handleCancelled(
    await text({
      message: 'Git user.email' + chalk.dim(' (type "<" to go back)'),
      placeholder: 'you@example.com',
      defaultValue: state.gitEmail || state.baseProfile?.config?.git?.user_email || '',
    }),
  ) as string;
  if (email.trim() === '<') return BACK;
  state.gitEmail = email.trim();

  return true;
}

async function stepModules(state: EditorState): Promise<true | typeof BACK> {
  log.step('Select what to install');

  // Filter to selectable modules (skip required + no-item modules)
  const selectableModules = modules.filter(
    (mod) => !REQUIRED_MODULES.has(mod.name) && mod.items.length > 0,
  );

  // Always include required modules
  for (const mod of modules) {
    if (REQUIRED_MODULES.has(mod.name)) {
      log.info(chalk.green('✔ ' + mod.label) + chalk.dim(' (required — always installed)'));
      state.selectedModules[mod.name] = mod.defaultItems;
    }
  }

  let i = 0;
  while (i < selectableModules.length) {
    const mod = selectableModules[i];
    const currentItems = getProfileItems(state.baseProfile, mod.name);
    // Also check previously selected (for when going back)
    const prevSelected = state.selectedModules[mod.name];

    if (BUNDLE_MODULES.has(mod.name)) {
      const wasEnabled = prevSelected ? prevSelected.length > 0 : currentItems.length > 0;
      const itemList = mod.items.map((it) => it.label).join(', ');

      const options: Array<{ value: string; label: string }> = [
        { value: 'yes', label: `Yes — include ${mod.label}` },
        { value: 'no', label: `No — skip ${mod.label}` },
      ];
      if (i > 0) options.push({ value: '__back__', label: chalk.dim('← Go back') });

      const choice = handleCancelled(
        await select({
          message: `${mod.label}? ${chalk.dim(`(${itemList})`)}`,
          options,
          initialValue: wasEnabled ? 'yes' : 'no',
        }),
      ) as string;

      if (choice === '__back__') { i--; continue; }
      if (choice === 'yes') {
        state.selectedModules[mod.name] = mod.defaultItems;
      } else {
        delete state.selectedModules[mod.name];
      }
    } else {
      const moduleOptions = mod.items.map((item) => ({
        value: item.id,
        label: item.label,
        hint: item.description,
      }));

      const preSelected = prevSelected
        ? prevSelected
        : currentItems.filter((id) => mod.items.some((it) => it.id === id));

      const selected = handleCancelled(
        await multiselect({
          message: `${mod.label} — ${mod.description}`,
          options: moduleOptions,
          initialValues: preSelected,
          required: false,
        }),
      ) as string[];

      if (selected.length > 0) {
        state.selectedModules[mod.name] = selected;
      } else {
        delete state.selectedModules[mod.name];
      }

      // After each module, offer navigation
      if (i > 0) {
        const nav = handleCancelled(
          await select({
            message: chalk.dim('Next?'),
            options: [
              { value: 'next', label: 'Continue' },
              { value: 'redo', label: `Redo ${mod.label}` },
              { value: 'back', label: '← Previous module' },
            ],
            initialValue: 'next',
          }),
        ) as string;
        if (nav === 'redo') continue;
        if (nav === 'back') { i--; continue; }
      }
    }

    i++;
  }

  // First module back = go back to previous step
  if (i < 0) return BACK;

  return true;
}

async function stepEncryptionAndExtras(state: EditorState): Promise<true | typeof BACK> {
  const encOptions: Array<{ value: string; label: string }> = [
    { value: 'yes', label: 'Yes' },
    { value: 'no', label: 'No' },
    { value: '__back__', label: chalk.dim('← Go back') },
  ];
  const encChoice = handleCancelled(
    await select({
      message: 'Enable encrypted dotfiles?',
      options: encOptions,
      initialValue: state.enableEncryption ? 'yes' : 'no',
    }),
  ) as string;
  if (encChoice === '__back__') return BACK;
  state.enableEncryption = encChoice === 'yes';

  // Custom additions
  log.step('Custom additions');
  const addExtras = handleCancelled(
    await confirm({
      message: 'Add custom brew formulas or casks not in the default modules?',
      initialValue: state.extraFormulas.length > 0 || state.extraCasks.length > 0,
    }),
  );

  if (addExtras) {
    const formulaInput = handleCancelled(
      await text({
        message: 'Extra brew formulas (comma-separated, or leave empty)',
        placeholder: 'e.g. ffmpeg, imagemagick, gh',
        defaultValue: state.extraFormulas.join(', '),
      }),
    ) as string;
    state.extraFormulas = formulaInput.trim() ? formulaInput.split(',').map((s) => s.trim()).filter(Boolean) : [];

    const caskInput = handleCancelled(
      await text({
        message: 'Extra brew casks (comma-separated, or leave empty)',
        placeholder: 'e.g. discord, figma, notion',
        defaultValue: state.extraCasks.join(', '),
      }),
    ) as string;
    state.extraCasks = caskInput.trim() ? caskInput.split(',').map((s) => s.trim()).filter(Boolean) : [];
  } else {
    state.extraFormulas = [];
    state.extraCasks = [];
  }

  return true;
}

async function stepPreviewAndSave(rootDir: string, state: EditorState): Promise<true | typeof BACK> {
  // Build profile
  const profile: Record<string, unknown> = {
    name: state.profileName,
    description: state.profileDesc,
  };

  for (const mod of modules) {
    if (mod.items.length === 0) continue;
    profile[mod.name] = state.selectedModules[mod.name] || [];
  }

  profile.encryption = state.enableEncryption;

  const config: Record<string, unknown> = {
    git: { user_name: state.gitName, user_email: state.gitEmail },
  };
  if (state.baseProfile?.config) {
    for (const [key, value] of Object.entries(state.baseProfile.config)) {
      if (key !== 'git') config[key] = value;
    }
  }
  if (state.extraFormulas.length > 0) config.extra_formulas = state.extraFormulas;
  if (state.extraCasks.length > 0) config.extra_casks = state.extraCasks;
  profile.config = config;

  // Preview
  log.step('Preview');
  const yaml = stringify(profile);
  console.log(chalk.dim(yaml));

  const action = handleCancelled(
    await select({
      message: 'What would you like to do?',
      options: [
        { value: 'save', label: 'Save this profile' },
        { value: '__back__', label: chalk.dim('← Go back and edit') },
        { value: 'cancel', label: 'Discard' },
      ],
    }),
  ) as string;

  if (action === '__back__') return BACK;
  if (action === 'cancel') {
    cancel('Profile not saved.');
    return true;
  }

  // Save location
  const saveLocation = handleCancelled(
    await select({
      message: 'Where to save?',
      options: [
        { value: 'user', label: 'Save locally', hint: `~/.dotfiles/profiles/${state.profileName}.yaml — use immediately` },
        { value: 'share', label: 'Share with the team', hint: 'outputs YAML + instructions to submit a PR' },
      ],
    }),
  ) as string;

  if (saveLocation === 'user') {
    const userProfileDir = path.join(DOTFILES_ROOT, 'profiles');
    await fs.mkdir(userProfileDir, { recursive: true });
    const savePath = path.join(userProfileDir, `${state.profileName}.yaml`);
    await fs.writeFile(savePath, yaml, 'utf8');
    outro(chalk.green(`Profile saved to ${savePath}`));
    log.info(`\nRun it with: ${chalk.cyan(`npx dotfiles --profile ${state.profileName}`)}`);
  } else {
    // Share mode — print YAML and PR instructions
    outro(chalk.green('Profile ready to share!'));
    console.log('');
    console.log(chalk.bold(`── ${state.profileName}.yaml ──`));
    console.log(yaml);
    console.log(chalk.bold('── How to submit ──'));
    console.log('');
    console.log(`1. Fork the repo:      ${chalk.cyan('gh repo fork ultronservant/dotfiles --clone')}`);
    console.log(`2. Save the profile:   ${chalk.cyan(`cat > profiles/${state.profileName}.yaml << 'EOF'\n${yaml}EOF`)}`);
    console.log(`3. Commit & push:      ${chalk.cyan(`git add profiles/${state.profileName}.yaml && git commit -m "Add ${state.profileName} profile" && git push`)}`);
    console.log(`4. Open a PR:          ${chalk.cyan('gh pr create --title "Add ' + state.profileName + ' profile"')}`);
    console.log('');

    // Also offer to save locally as backup
    const alsoSaveLocal = handleCancelled(
      await confirm({ message: 'Also save locally so you can use it now?', initialValue: true }),
    );
    if (alsoSaveLocal) {
      const userProfileDir = path.join(DOTFILES_ROOT, 'profiles');
      await fs.mkdir(userProfileDir, { recursive: true });
      const savePath = path.join(userProfileDir, `${state.profileName}.yaml`);
      await fs.writeFile(savePath, yaml, 'utf8');
      log.success(`Also saved to ${savePath}`);
      log.info(`Run it with: ${chalk.cyan(`npx dotfiles --profile ${state.profileName}`)}`);
    }
  }

  return true;
}

// ── Main editor loop ────────────────────────────────────────────

export async function runEditor(rootDir: string): Promise<void> {
  intro(chalk.bold('dotfiles — Profile Editor'));

  const state = freshState();

  type StepFn = () => Promise<true | typeof BACK>;
  const steps: StepFn[] = [
    () => stepBaseProfile(rootDir, state),
    () => stepNameDesc(state),
    () => stepGit(state),
    () => stepModules(state),
    () => stepEncryptionAndExtras(state),
    () => stepPreviewAndSave(rootDir, state),
  ];

  let step = 0;
  while (step < steps.length) {
    const result = await steps[step]();
    if (result === BACK) {
      step = Math.max(0, step - 1);
    } else {
      step++;
    }
  }
}
