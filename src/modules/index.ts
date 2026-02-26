import type { ModuleV2 } from '../types';
import { aiModule } from './ai';
import { appsModule } from './apps';
import { cleanupModule } from './cleanup';
import { cloudModule } from './cloud';
import { commsModule } from './comms';
import { coreModule } from './core';
import { encryptionModule } from './encryption';
import { iosModule } from './ios';
import { languagesModule } from './languages';
import { macosModule } from './macos';
import { macosComplexModule } from './macos-complex';
import { masModule } from './mas';
import { productivityModule } from './productivity';
import { terminalModule } from './terminal';
import { xcodeModule } from './xcode';

export const modules: ModuleV2[] = [
  coreModule,
  terminalModule,
  languagesModule,
  iosModule,
  cloudModule,
  appsModule,
  commsModule,
  productivityModule,
  aiModule,
  masModule,
  macosModule,
  macosComplexModule,
  cleanupModule,
  encryptionModule,
  xcodeModule,
];

export function getModuleByName(name: string): ModuleV2 | undefined {
  return modules.find((mod) => mod.name === name);
}
