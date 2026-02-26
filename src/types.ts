export interface DetectResult {
  installed: string[];
  missing: string[];
  partial: boolean;
}

export interface StateModuleRecord {
  installed: string[];
  version: string;
}

export interface MachineInfo {
  chip: string;
  ram: string;
  os: string;
}

export interface StateFile {
  lastRun: string;
  profile: string;
  modules: Record<string, StateModuleRecord>;
  machine: MachineInfo;
}

export interface ProfileConfig {
  name: string;
  description: string;
  modules: string[];
  config: {
    git?: {
      user_name?: string;
      user_email?: string;
      global_gitignore?: string;
    };
    apps?: { casks?: string[] };
    comms?: { casks?: string[] };
    productivity?: { casks?: string[] };
    ai?: { casks?: string[]; npm?: string[] };
    core?: { formulas?: string[] };
    ios?: { formulas?: string[] };
    cloud?: { formulas?: string[]; casks?: string[] };
    cleanup?: { remove?: string[] };
    mas?: { apps?: Array<{ id: number; name: string }> };
    terminal?: { enable_powerline?: boolean; theme?: string };
    encryption?: { keychain_service?: string; keychain_account?: string };
    node?: { version?: string };
    python?: { versions?: string[] };
    ruby?: { version?: string };
    macos?: Record<string, unknown>;
    [key: string]: unknown;
  };
}

export interface RunContext {
  dryRun: boolean;
  verbose: boolean;
  nonInteractive?: boolean;
}

export interface InstallOptions extends RunContext {
  profile: ProfileConfig;
  state: StateManager;
  rootDir: string;
  encryptionPassword?: string;
}

export interface StateManager {
  load(): Promise<StateFile | null>;
  save(state: StateFile): Promise<void>;
  diff(next: StateFile): Promise<string[]>;
}

export interface Module {
  name: string;
  label: string;
  description: string;
  dependencies?: string[];
  detect(opts: InstallOptions): Promise<DetectResult>;
  install(opts: InstallOptions): Promise<void>;
  uninstall?(opts: InstallOptions): Promise<void>;
}
