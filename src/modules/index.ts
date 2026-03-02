import type { ModuleV2 } from '../types';
import { aiModule } from './ai';
import { androidModule } from './android';
import { appsModule } from './apps';
import { cleanupModule } from './cleanup';
import { cloudModule } from './cloud';
import { commsModule } from './comms';
import { coreModule } from './core';
import { encryptionModule } from './encryption';
import { homeserverModule } from './homeserver';
import { iosModule } from './ios';
import { languagesModule } from './languages';
import { macosModule } from './macos';
import { macosComplexModule } from './macos-complex';
import { masModule } from './mas';
import { mediaModule } from './media';
import { productivityModule } from './productivity';
import { terminalModule } from './terminal';


export const modules: ModuleV2[] = [
  coreModule,
  terminalModule,
  languagesModule,
  iosModule,
  androidModule,
  cloudModule,
  appsModule,
  commsModule,
  productivityModule,
  mediaModule,
  aiModule,
  masModule,
  macosModule,
  macosComplexModule,
  homeserverModule,
  cleanupModule,
  encryptionModule,
];

export function getModuleByName(name: string): ModuleV2 | undefined {
  return modules.find((mod) => mod.name === name);
}
