import { log, spinner } from '@clack/prompts';
import type { InstallOptions, ModuleV2, StateFile } from './types';

function resolveExecutionOrder(modules: ModuleV2[], selected: string[]): ModuleV2[] {
  const byName = new Map(modules.map((m) => [m.name, m]));
  const visiting = new Set<string>();
  const visited = new Set<string>();
  const output: ModuleV2[] = [];

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
  modules: ModuleV2[],
  selected: Record<string, string[]>,
  opts: InstallOptions,
): Promise<{ failures: string[]; state: StateFile }> {
  const selectedModules = Object.keys(selected).filter((name) => (selected[name] ?? []).length > 0);
  const order = resolveExecutionOrder(modules, selectedModules);
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
    const selectedItems = selected[module.name] ?? [];
    if (selectedItems.length === 0) continue;

    const s = spinner();
    s.start(`Running module: ${module.label}`);
    try {
      const detect = await module.detect(selectedItems, opts);
      if (detect.missing.length === 0 && detect.installed.length > 0) {
        s.stop(`${module.label}: already installed`);
      } else {
        await module.install(selectedItems, opts);
        s.stop(`${module.label}: complete`);
      }
      nextState.modules[module.name] = {
        installed: selectedItems,
        version: '2.0.0',
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
