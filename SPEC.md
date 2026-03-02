# @jarmourato/macsetup — NPX Interactive CLI Spec

## Goal
Replace the bash-based dotfiles setup with an interactive `npx @jarmourato/macsetup` CLI tool. Keep all existing functionality (profiles, encryption, macOS defaults, symlinks, dependencies) but wrap it in a beautiful TUI with module toggling.

## How It Should Work

```bash
# Interactive mode — asks what to install
npx @jarmourato/macsetup

# Use a preset profile
npx @jarmourato/macsetup --profile dev

# Dry run — preview without executing
npx @jarmourato/macsetup --dry-run

# Run a single module
npx @jarmourato/macsetup --module terminal

# Show diff since last run
npx @jarmourato/macsetup --diff

# Export current state as profile
npx @jarmourato/macsetup --export
```

## Architecture

### Tech Stack
- TypeScript (compiled to JS)
- `@clack/prompts` for interactive TUI (same style as create-next-app, Claude Code setup)
- `execa` for shell command execution
- `yaml` for profile parsing
- `chalk` for colored output
- `commander` for CLI args
- Build with `tsup` (simple, fast bundler)

### Project Structure

```
src/
  index.ts              # CLI entry point (commander + @clack/prompts flow)
  types.ts              # Shared types
  config.ts             # Load/save ~/.macsetup.config.yaml and state
  state.ts              # State management (~/.macsetup-state.json)
  runner.ts             # Module execution engine (dry-run aware)
  utils/
    shell.ts            # execa wrappers for brew, defaults write, etc.
    detect.ts           # Detect machine info (chip, RAM, macOS version)
    keychain.ts         # Keychain integration for encryption password
  modules/
    index.ts            # Module registry
    core.ts             # git, gh, curl, wget, jq, tree, bat, fd, ripgrep, htop, mas
    terminal.ts         # oh-my-zsh, powerline, theme, fonts, .zshrc setup
    shell.ts            # Dotfile symlinks (.aliases, .exports, .zshrc, .gitconfig, .paths, .gemrc, .ruby-version)
    macos.ts            # All macOS defaults (dock, finder, keyboard, trackpad, etc.)
    node.ts             # Node.js via fnm
    python.ts           # Python via pyenv
    ruby.ts             # Ruby via rbenv + bundler
    ios.ts              # swiftlint, swiftformat, cocoapods, fastlane, carthage, xcbeautify
    cloud.ts            # docker, terraform, ansible, awscli, kubernetes-cli
    apps.ts             # Cask apps (browsers, dev tools, productivity)
    comms.ts            # Communication apps (slack, zoom, whatsapp, telegram)
    productivity.ts     # bitwarden, spotify, things3, etc.
    ai.ts               # claude, chatgpt, openclaw, claude-code CLI
    ssh.ts              # SSH key generation and config
    git.ts              # Global gitconfig, gitignore
    xcode.ts            # Xcode installation + templates + defaults
    encryption.ts       # Decrypt encrypted files using keychain password
    cleanup.ts          # Remove bloatware apps (GarageBand, iMovie, etc.)
    macos-complex.ts    # Complex defaults (dock folders, photos, spotlight, sourcetree, etc.)
    mas.ts              # Mac App Store apps
profiles/
  dev.yaml              # Dev profile (migrate from .dotfiles.dev.yaml)
  server.yaml           # Server profile (migrate from .dotfiles.mediaserver.yaml)
  minimal.yaml          # New: just core + terminal + shell + macos + node
scripts/
  encrypt_files.sh      # Keep existing encryption script
  decrypt_files.sh      # Keep existing decryption script
dotfiles/               # The actual dotfiles to symlink
  .aliases              # From existing repo
  .exports              # From existing repo
  .zshrc                # From existing repo
  .paths                # From existing repo
  .gemrc                # From existing repo
  .ruby-version         # From existing repo
Terminal/               # Keep existing terminal assets
  Highway.terminal
  powerline-shell-config.json
  set_up_terminal.sh
package.json
tsconfig.json
tsup.config.ts
README.md
```

### Module Interface

Each module must implement:

```typescript
interface Module {
  name: string;           // e.g., "core"
  label: string;          // e.g., "Core Tools"
  description: string;    // e.g., "git, gh, curl, jq, ripgrep, bat, fd, tree"
  dependencies?: string[]; // Other module names this depends on
  detect(): Promise<DetectResult>;  // What's already installed
  install(opts: InstallOptions): Promise<void>;  // Install everything
  uninstall?(opts: InstallOptions): Promise<void>; // Optional removal
}

interface DetectResult {
  installed: string[];    // Already installed items
  missing: string[];      // Items that need installation
  partial: boolean;       // Some installed, some not
}

interface InstallOptions {
  dryRun: boolean;
  profile: ProfileConfig;
  verbose: boolean;
  state: StateManager;
}
```

### Interactive Flow

1. Detect machine (Apple Silicon/Intel, RAM, macOS version)
2. Show welcome banner with machine info
3. Ask: "What kind of setup?" → Full Dev / Server / Minimal / Custom
4. If Custom: show checklist of all modules with descriptions, pre-check based on detection
5. If profile chosen: show what will be installed, ask to confirm or customize
6. Ask for git config (name, email) if not in profile
7. Handle SSH key setup if ssh module selected
8. Handle keychain password for encryption if encryption module selected
9. Show summary of what will be installed/configured
10. Confirm and execute with progress spinners
11. Save state to ~/.macsetup-state.json
12. Save config to ~/.macsetup.config.yaml for future runs

### State File (~/.macsetup-state.json)

```json
{
  "lastRun": "2026-02-26T14:00:00Z",
  "profile": "dev",
  "modules": {
    "core": { "installed": ["git", "gh", "jq", "bat"], "version": "1.0.0" },
    "apps": { "installed": ["google-chrome", "vscode"], "version": "1.0.0" }
  },
  "machine": { "chip": "Apple M4", "ram": "36GB", "os": "macOS 15.3" }
}
```

### Profile YAML Format (profiles/dev.yaml)

Migrate the existing .dotfiles.dev.yaml and .dotfiles.mediaserver.yaml into the new format. The profile selects which modules to enable AND can override per-module config:

```yaml
name: dev
description: "Full development machine setup"
modules:
  - core
  - terminal
  - shell
  - macos
  - macos-complex
  - node
  - python
  - ruby
  - ios
  - cloud
  - apps
  - comms
  - productivity
  - ai
  - ssh
  - git
  - xcode
  - encryption
  - cleanup
  - mas

config:
  git:
    user_name: "JARMourato"
    user_email: "joao.armourato@gmail.com"
  apps:
    casks:
      - google-chrome
      - vscode
      - sublime-text
      # ... etc
  comms:
    casks:
      - slack
      - zoom
      - whatsapp
      - telegram
  mas:
    apps:
      - { id: 472226235, name: "LanScan" }
      - { id: 904280696, name: "Things 3" }
  cleanup:
    remove:
      - "GarageBand.app"
      - "iMovie.app"
      - "Keynote.app"
      - "Numbers.app"
      - "Pages.app"
  macos:
    # All the user_defaults from existing YAML — same structure
    dock:
      autohide: false
      tile_size: 40
      # ... etc
    finder:
      # ... etc
    keyboard:
      # ... etc
```

### Key Implementation Notes

1. **Shell execution**: Use `execa` for all shell commands. Wrap `brew install`, `defaults write`, `sudo pmset`, etc. in helper functions in `utils/shell.ts`. Show spinner per command.

2. **macOS defaults**: Port ALL defaults from the existing `set_up_user_defaults.sh` and `set_up_complex_defaults.sh`. Use the YAML config to drive which defaults to apply. The `macos.ts` module reads config and runs the appropriate `defaults write` commands.

3. **Encryption**: Keep the existing `encrypt_files.sh` and `decrypt_files.sh` scripts. The `encryption.ts` module calls them via shell, handling keychain password retrieval.

4. **Terminal setup**: Keep the existing `set_up_terminal.sh` but call it from the `terminal.ts` module.

5. **Symlinks**: The `shell.ts` module handles creating symlinks from `dotfiles/` to `$HOME/`.

6. **Idempotent**: Every module should check what's already installed before acting. `brew list` to check formulas/casks, `command -v` for CLI tools, `defaults read` for preferences.

7. **Progress**: Use `@clack/prompts` spinner for each operation. Group related operations under a single spinner message.

8. **Error handling**: Don't crash on individual failures. Log the error, continue with next item, report summary at end.

9. **package.json bin field**: Set `"bin": { "macsetup": "./dist/index.js" }` so `npx @jarmourato/macsetup` works.

10. **Keep existing files**: Don't delete existing bash scripts yet — they serve as reference. The new CLI replaces `bootstrap.sh` as the entry point.

## What to Build Now

1. Scaffold the project (package.json, tsconfig, tsup config)
2. Build the CLI entry point with commander + @clack/prompts
3. Implement the module system and registry
4. Implement ALL modules (port logic from existing bash scripts)
5. Implement profile loading from YAML
6. Implement state management
7. Implement dry-run mode
8. Move existing dotfiles into dotfiles/ directory
9. Create profiles from existing YAML configs
10. Update README with new usage
11. Make sure `npm pack` / `npx` works

## DO NOT

- Delete existing bash scripts (keep for reference)
- Change the encrypted files or encryption mechanism
- Modify the actual dotfile contents (.aliases, .exports, .zshrc, etc.)
- Add tests yet (we'll add them later)
- Publish to npm (we'll do that manually)
