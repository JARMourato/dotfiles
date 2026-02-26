import { promises as fs } from 'node:fs';
import os from 'node:os';
import path from 'node:path';
import type { StateFile, StateManager } from './types';

const STATE_PATH = path.join(os.homedir(), '.macsetup-state.json');
const PREVIOUS_STATE_PATH = path.join(os.homedir(), '.macsetup-state.previous.json');

export class JsonStateManager implements StateManager {
  async load(): Promise<StateFile | null> {
    try {
      const raw = await fs.readFile(STATE_PATH, 'utf8');
      return JSON.parse(raw) as StateFile;
    } catch {
      return null;
    }
  }

  async save(state: StateFile): Promise<void> {
    const current = await this.load();
    if (current) {
      await fs.writeFile(PREVIOUS_STATE_PATH, JSON.stringify(current, null, 2), 'utf8');
    }
    await fs.writeFile(STATE_PATH, JSON.stringify(state, null, 2), 'utf8');
  }

  async diff(next: StateFile): Promise<string[]> {
    const previous = await this.loadPrevious();
    if (!previous) {
      return ['No previous state found.'];
    }

    const lines: string[] = [];
    const prevModules = new Set(Object.keys(previous.modules));
    const nextModules = new Set(Object.keys(next.modules));

    for (const name of prevModules) {
      if (!nextModules.has(name)) {
        lines.push(`- module removed: ${name}`);
      }
    }

    for (const name of nextModules) {
      if (!prevModules.has(name)) {
        lines.push(`+ module added: ${name}`);
        continue;
      }
      const prev = previous.modules[name]?.installed ?? [];
      const curr = next.modules[name]?.installed ?? [];
      const added = curr.filter((x) => !prev.includes(x));
      const removed = prev.filter((x) => !curr.includes(x));
      if (added.length || removed.length) {
        lines.push(`~ module changed: ${name}`);
        for (const item of added) lines.push(`  + ${item}`);
        for (const item of removed) lines.push(`  - ${item}`);
      }
    }

    return lines.length > 0 ? lines : ['No differences detected.'];
  }

  private async loadPrevious(): Promise<StateFile | null> {
    try {
      const raw = await fs.readFile(PREVIOUS_STATE_PATH, 'utf8');
      return JSON.parse(raw) as StateFile;
    } catch {
      return null;
    }
  }
}

export { PREVIOUS_STATE_PATH, STATE_PATH };
