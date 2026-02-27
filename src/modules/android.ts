import { promises as fs } from 'node:fs';
import os from 'node:os';
import path from 'node:path';
import type { ModuleV2 } from '../types';
import { detectCasks, installCasks, detectFormulas, installFormulas } from './helpers';
import { commandExists, runCommand } from '../utils/shell';

const items = [
  { id: 'android-studio', label: 'Android Studio', critical: true },
  { id: 'openjdk', label: 'OpenJDK (Gradle)', critical: true },
  { id: 'bundletool', label: 'bundletool' },
  { id: 'env-vars', label: 'ANDROID_HOME + PATH setup' },
  { id: 'sdk-license', label: 'Accept SDK licenses' },
];

const ANDROID_ENV_MARKER = '# macsetup: android env';
const ANDROID_ENV_BLOCK = `
${ANDROID_ENV_MARKER}
export ANDROID_HOME="$HOME/Library/Android/sdk"
export PATH="$ANDROID_HOME/emulator:$ANDROID_HOME/tools:$ANDROID_HOME/tools/bin:$ANDROID_HOME/platform-tools:$PATH"
`;

export const androidModule: ModuleV2 = {
  name: 'android',
  label: 'Android Dev',
  description: 'Android Studio, OpenJDK, bundletool, ANDROID_HOME setup',
  items,
  defaultItems: items.map((item) => item.id),
  dependencies: ['core'],
  async detect(selectedItems) {
    const installed: string[] = [];
    const missing: string[] = [];

    if (selectedItems.includes('android-studio')) {
      const caskDetect = await detectCasks(['android-studio']);
      // Also check /Applications in case installed outside brew (JetBrains Toolbox, .dmg, etc)
      const appExists = await runCommand('test', ['-d', '/Applications/Android Studio.app'], { continueOnError: true });
      if (caskDetect.installed.length > 0 || appExists.ok) installed.push('android-studio');
      else missing.push('android-studio');
    }

    if (selectedItems.includes('openjdk')) {
      const formulaDetect = await detectFormulas(['openjdk']);
      // Also check if java is available on PATH (installed outside brew)
      const javaExists = await commandExists('java');
      if (formulaDetect.installed.length > 0 || javaExists) installed.push('openjdk');
      else missing.push('openjdk');
    }

    if (selectedItems.includes('bundletool')) {
      const formulaDetect = await detectFormulas(['bundletool']);
      if (formulaDetect.installed.length > 0) installed.push('bundletool');
      else missing.push('bundletool');
    }

    if (selectedItems.includes('env-vars')) {
      const exportsFile = path.join(os.homedir(), '.exports');
      try {
        const contents = await fs.readFile(exportsFile, 'utf8');
        if (contents.includes(ANDROID_ENV_MARKER)) installed.push('env-vars');
        else missing.push('env-vars');
      } catch {
        missing.push('env-vars');
      }
    }

    if (selectedItems.includes('sdk-license')) {
      const licensePath = path.join(os.homedir(), 'Library', 'Android', 'sdk', 'licenses', 'android-sdk-license');
      const exists = await runCommand('test', ['-f', licensePath], { continueOnError: true });
      if (exists.ok) installed.push('sdk-license');
      else missing.push('sdk-license');
    }

    return { installed, missing, partial: installed.length > 0 && missing.length > 0 };
  },
  async install(selectedItems, opts) {
    if (selectedItems.includes('android-studio')) {
      await installCasks(['android-studio'], opts);
    }

    if (selectedItems.includes('openjdk')) {
      await installFormulas(['openjdk'], opts);
      // Symlink so system java wrappers find it
      await runCommand('sudo', ['ln', '-sfn', '/opt/homebrew/opt/openjdk/libexec/openjdk.jdk', '/Library/Java/JavaVirtualMachines/openjdk.jdk'], {
        dryRun: opts.dryRun,
        continueOnError: true,
      });
    }

    if (selectedItems.includes('bundletool')) {
      await installFormulas(['bundletool'], opts);
    }

    if (selectedItems.includes('env-vars')) {
      // Append ANDROID_HOME to .exports if not already there
      const exportsPath = path.join(os.homedir(), '.exports');
      if (!opts.dryRun) {
        try {
          const contents = await fs.readFile(exportsPath, 'utf8');
          if (!contents.includes(ANDROID_ENV_MARKER)) {
            await fs.appendFile(exportsPath, ANDROID_ENV_BLOCK);
          }
        } catch {
          // .exports doesn't exist, create it
          await fs.writeFile(exportsPath, ANDROID_ENV_BLOCK);
        }
      }
    }

    if (selectedItems.includes('sdk-license')) {
      // Accept licenses — needs SDK to be installed first (usually after first Android Studio launch)
      const sdkManager = path.join(os.homedir(), 'Library', 'Android', 'sdk', 'cmdline-tools', 'latest', 'bin', 'sdkmanager');
      const exists = await runCommand('test', ['-f', sdkManager], { continueOnError: true });
      if (exists.ok) {
        await runCommand('bash', ['-c', `yes | ${sdkManager} --licenses`], {
          dryRun: opts.dryRun,
          continueOnError: true,
        });
      } else if (!opts.dryRun) {
        // SDK not installed yet — skip, user needs to open Android Studio first
      }
    }
  },
};
