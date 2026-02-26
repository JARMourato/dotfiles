import { execa } from 'execa';

export interface CommandOptions {
  dryRun?: boolean;
  cwd?: string;
  continueOnError?: boolean;
  env?: NodeJS.ProcessEnv;
}

export async function runCommand(
  cmd: string,
  args: string[] = [],
  opts: CommandOptions = {},
): Promise<{ ok: boolean; stdout: string; stderr: string }> {
  if (opts.dryRun) {
    return { ok: true, stdout: `[dry-run] ${cmd} ${args.join(' ')}`.trim(), stderr: '' };
  }

  try {
    const result = await execa(cmd, args, {
      cwd: opts.cwd,
      env: opts.env,
      shell: false,
    });
    return { ok: true, stdout: result.stdout, stderr: result.stderr };
  } catch (error) {
    if (opts.continueOnError) {
      const msg = error instanceof Error ? error.message : String(error);
      return { ok: false, stdout: '', stderr: msg };
    }
    throw error;
  }
}

export async function runCapture(cmd: string, args: string[] = [], cwd?: string): Promise<string> {
  const result = await execa(cmd, args, { cwd, shell: false });
  return result.stdout;
}

export async function commandExists(name: string): Promise<boolean> {
  const result = await runCommand('which', [name], { continueOnError: true });
  return result.ok;
}

export async function brewFormulaInstalled(name: string): Promise<boolean> {
  const result = await runCommand('brew', ['list', name], { continueOnError: true });
  return result.ok;
}

export async function brewCaskInstalled(name: string): Promise<boolean> {
  const result = await runCommand('brew', ['list', '--cask', name], { continueOnError: true });
  return result.ok;
}

export async function masAppInstalled(id: number): Promise<boolean> {
  const result = await runCommand('mas', ['list'], { continueOnError: true });
  if (!result.ok) return false;
  return result.stdout
    .split('\n')
    .some((line) => line.trim().startsWith(String(id)));
}
