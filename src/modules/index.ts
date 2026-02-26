import type { Module } from '../types';
import { aiModule } from './ai';
import { appsModule } from './apps';
import { cleanupModule } from './cleanup';
import { cloudModule } from './cloud';
import { commsModule } from './comms';
import { coreModule } from './core';
import { encryptionModule } from './encryption';
import { gitModule } from './git';
import { iosModule } from './ios';
import { macosModule } from './macos';
import { macosComplexModule } from './macos-complex';
import { masModule } from './mas';
import { nodeModule } from './node';
import { productivityModule } from './productivity';
import { pythonModule } from './python';
import { rubyModule } from './ruby';
import { shellModule } from './shell';
import { sshModule } from './ssh';
import { terminalModule } from './terminal';
import { xcodeModule } from './xcode';

export const modules: Module[] = [
  coreModule,
  terminalModule,
  shellModule,
  macosModule,
  nodeModule,
  pythonModule,
  rubyModule,
  iosModule,
  cloudModule,
  appsModule,
  commsModule,
  productivityModule,
  aiModule,
  sshModule,
  gitModule,
  xcodeModule,
  encryptionModule,
  cleanupModule,
  macosComplexModule,
  masModule,
];

export function getModuleByName(name: string): Module | undefined {
  return modules.find((mod) => mod.name === name);
}
