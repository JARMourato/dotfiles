import type { DetectResult, InstallOptions } from '../types';
import {
  brewCaskInstalled,
  brewFormulaInstalled,
  commandExists,
  masAppInstalled,
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
      await runCommand('brew', ['install', formula], { dryRun: opts.dryRun, continueOnError: true });
    }
  }
}

export async function installFormula(formula: string, opts: InstallOptions & { onProgress?: (line: string) => void }): Promise<void> {
  if (!(await brewFormulaInstalled(formula))) {
    const run = opts.onProgress ? runStreamedCommand : runCommand;
    await run('brew', ['install', formula], { dryRun: opts.dryRun, continueOnError: true, onProgress: opts.onProgress });
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
      await runCommand('brew', ['install', '--cask', cask], { dryRun: opts.dryRun, continueOnError: true });
    }
  }
}

export async function installCask(cask: string, opts: InstallOptions & { onProgress?: (line: string) => void }): Promise<void> {
  if (!(await brewCaskInstalled(cask))) {
    const run = opts.onProgress ? runStreamedCommand : runCommand;
    await run('brew', ['install', '--cask', cask], { dryRun: opts.dryRun, continueOnError: true, onProgress: opts.onProgress });
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
      await runCommand('mas', ['install', String(id)], { dryRun: opts.dryRun, continueOnError: true });
    }
  }
}

export async function installMasApp(id: number, opts: InstallOptions & { onProgress?: (line: string) => void }): Promise<void> {
  if (!(await masAppInstalled(id))) {
    const run = opts.onProgress ? runStreamedCommand : runCommand;
    await run('mas', ['install', String(id)], { dryRun: opts.dryRun, continueOnError: true, onProgress: opts.onProgress });
  }
}

export async function uninstallFormulas(formulas: string[], opts: InstallOptions): Promise<void> {
  for (const formula of formulas) {
    if (await brewFormulaInstalled(formula)) {
      await runCommand('brew', ['uninstall', formula], { dryRun: opts.dryRun, continueOnError: true });
    }
  }
}

export async function uninstallCasks(casks: string[], opts: InstallOptions): Promise<void> {
  for (const cask of casks) {
    if (await brewCaskInstalled(cask)) {
      await runCommand('brew', ['uninstall', '--cask', cask], { dryRun: opts.dryRun, continueOnError: true });
    }
  }
}
