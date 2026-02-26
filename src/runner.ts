import { log, spinner } from '@clack/prompts';
import type { InstallOptions, Module, StateFile } from './types';

function resolveExecutionOrder(modules: Module[], selected: string[]): Module[] {
  const byName = new Map(modules.map((m) => [m.name, m]));
  const visiting = new Set<string>();
  const visited = new Set<string>();
  const output: Module[] = [];

  const visit = (name: string): void => {
    if (visited.has(name)) return;
    if (visiting.has(name)) throw new Error(`Dependency cycle detected at module: ${name}`);
    const mod = byName.get(name);
    if (!mod) throw new Error(`Unknown module: ${name}`);
    visiting.add(name);
    for (const dep of mod.dependencies ?? []) visit(dep);
    visiting.delete(name);
    visited.add(name);
    output.push(mod);
  };

  for (const name of selected) visit(name);
  return output;
}

export async function runModules(
  modules: Module[],
  selected: string[],
  opts: InstallOptions,
): Promise<{ failures: string[]; state: StateFile }> {
  const order = resolveExecutionOrder(modules, selected);
  const failures: string[] = [];

  const machine = (await opts.state.load())?.machine ?? {
    chip: 'unknown',
    ram: 'unknown',
    os: 'unknown',
  };

  const nextState: StateFile = {
    lastRun: new Date().toISOString(),
    profile: opts.profile.name,
    machine,
    modules: {},
  };

  for (const module of order) {
    const s = spinner();
    s.start(`Running module: ${module.label}`);
    try {
      const detect = await module.detect(opts);
      if (detect.missing.length === 0 && detect.installed.length > 0) {
        s.stop(`${module.label}: already installed`);
      } else {
        await module.install(opts);
        s.stop(`${module.label}: complete`);
      }
      nextState.modules[module.name] = {
        installed: [...detect.installed, ...detect.missing],
        version: '1.0.0',
      };
    } catch (error) {
      const message = error instanceof Error ? error.message : String(error);
      failures.push(`${module.name}: ${message}`);
      s.stop(`${module.label}: failed`);
      log.error(`${module.name} failed: ${message}`);
    }
  }

  return { failures, state: nextState };
}
