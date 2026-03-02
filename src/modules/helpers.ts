import type { DetectResult, InstallOptions } from '../types';
import {
  brewCaskInstalled,
  brewFormulaInstalled,
  commandExists,
  masAppInstalled,
  runAsUser,
  runCommand,
  runStreamedCommand,
} from '../utils/shell';

export async function detectFormulas(formulas: string[]): Promise<DetectResult> {
  const installed: string[] = [];
  const missing: string[] = [];
  for (const formula of formulas) {
    if (await brewFormulaInstalled(formula)) installed.push(formula);
    else missing.push(formula);
  }
  return { installed, missing, partial: installed.length > 0 && missing.length > 0 };
}

export async function installFormulas(formulas: string[], opts: InstallOptions): Promise<void> {
  for (const formula of formulas) {
    if (!(await brewFormulaInstalled(formula))) {
      await runAsUser('brew', ['install', formula], { dryRun: opts.dryRun });
    }
  }
}

export async function installFormula(formula: string, opts: InstallOptions & { onProgress?: (line: string) => void }): Promise<void> {
  if (!(await brewFormulaInstalled(formula))) {
    if (opts.onProgress) {
      await runStreamedCommand('brew', ['install', formula], {
        dryRun: opts.dryRun,
        continueOnError: true,
        onProgress: opts.onProgress,
      });
    } else {
      await runAsUser('brew', ['install', formula], { dryRun: opts.dryRun });
    }
  }
}

export async function detectCasks(casks: string[]): Promise<DetectResult> {
  const installed: string[] = [];
  const missing: string[] = [];
  for (const cask of casks) {
    if (await brewCaskInstalled(cask)) installed.push(cask);
    else missing.push(cask);
  }
  return { installed, missing, partial: installed.length > 0 && missing.length > 0 };
}

export async function installCasks(casks: string[], opts: InstallOptions): Promise<void> {
  for (const cask of casks) {
    if (!(await brewCaskInstalled(cask))) {
      await runAsUser('brew', ['install', '--cask', cask], { dryRun: opts.dryRun });
    }
  }
}

export async function installCask(cask: string, opts: InstallOptions & { onProgress?: (line: string) => void }): Promise<void> {
  if (!(await brewCaskInstalled(cask))) {
    if (opts.onProgress) {
      // Use streamed command to pipe download progress to the spinner
      await runStreamedCommand('brew', ['install', '--cask', cask], {
        dryRun: opts.dryRun,
        continueOnError: true,
        onProgress: opts.onProgress,
      });
    } else {
      await runAsUser('brew', ['install', '--cask', cask], { dryRun: opts.dryRun });
    }
  }
}

export async function detectCommands(commands: string[]): Promise<DetectResult> {
  const installed: string[] = [];
  const missing: string[] = [];
  for (const cmd of commands) {
    if (await commandExists(cmd)) installed.push(cmd);
    else missing.push(cmd);
  }
  return { installed, missing, partial: installed.length > 0 && missing.length > 0 };
}

export async function detectMasApps(ids: number[]): Promise<DetectResult> {
  const installed: string[] = [];
  const missing: string[] = [];
  for (const id of ids) {
    if (await masAppInstalled(id)) installed.push(String(id));
    else missing.push(String(id));
  }
  return { installed, missing, partial: installed.length > 0 && missing.length > 0 };
}

export async function installMasApps(ids: number[], opts: InstallOptions): Promise<void> {
  for (const id of ids) {
    if (!(await masAppInstalled(id))) {
      await runAsUser('mas', ['install', String(id)], { dryRun: opts.dryRun });
    }
  }
}

export async function installMasApp(id: number, opts: InstallOptions & { onProgress?: (line: string) => void }): Promise<void> {
  if (!(await masAppInstalled(id))) {
    await runAsUser('mas', ['install', String(id)], { dryRun: opts.dryRun });
  }
}

export async function uninstallFormulas(formulas: string[], opts: InstallOptions): Promise<void> {
  for (const formula of formulas) {
    if (await brewFormulaInstalled(formula)) {
      console.log(`    ✕ ${formula}`);
      const result = await runAsUser('brew', ['uninstall', '--ignore-dependencies', formula], { dryRun: opts.dryRun, continueOnError: true });
      if (!result.ok && !opts.dryRun) {
        console.log(`      ⚠ failed: ${result.stderr.trim()}`);
      }
    } else {
      console.log(`    · ${formula} (not installed)`);
    }
  }
}

export async function uninstallCasks(casks: string[], opts: InstallOptions): Promise<void> {
  for (const cask of casks) {
    if (await brewCaskInstalled(cask)) {
      console.log(`    ✕ ${cask}`);
      const result = await runAsUser('brew', ['uninstall', '--cask', cask], { dryRun: opts.dryRun, continueOnError: true });
      if (!result.ok && !opts.dryRun) {
        console.log(`      ⚠ failed: ${result.stderr.trim()}`);
      }
    } else {
      console.log(`    · ${cask} (not installed)`);
    }
  }
}
