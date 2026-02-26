import os from 'node:os';
import type { MachineInfo } from '../types';
import { runCapture } from './shell';

export async function detectMachine(): Promise<MachineInfo> {
  const chip = (await runCapture('sysctl', ['-n', 'machdep.cpu.brand_string']).catch(() => os.arch())).trim();
  const ram = `${Math.round(os.totalmem() / 1024 / 1024 / 1024)}GB`;
  const osVersion = (await runCapture('sw_vers', ['-productVersion']).catch(() => os.release())).trim();
  return {
    chip,
    ram,
    os: `macOS ${osVersion}`,
  };
}
