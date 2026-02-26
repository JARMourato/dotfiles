# macsetup v2 — Drill-Down Customization Refactor

## Summary
Refactor the interactive CLI so that "Custom" mode (and preset tweaking) lets users drill into each module and pick individual items, not just toggle entire modules.

## Required (always run, no toggle)
These run automatically — user doesn't see them as options:
- Xcode CLI tools (detect/install)
- Homebrew (detect/install)  
- Node.js (already installed by bootstrap shim)
- SSH key setup
- Git config (name/email prompt)
- Shell dotfiles (symlinks for .aliases, .exports, .zshrc, .paths, .gemrc, .ruby-version)

Implement these as a `required` phase that runs before any optional modules.

## Optional Modules (two-level drill-down)
Each module has individually selectable items:

### Core Tools
Items: jq, curl, wget, tree, bat, fd, ripgrep, htop
All are brew formulas.

### Terminal
Items: oh-my-zsh, powerline, theme (Highway), fonts (Meslo LG)

### Languages
Items: python (pyenv), ruby (rbenv + bundler)
Note: Node.js is NOT here — it's a required prerequisite.

### iOS Dev
Items: swiftlint, swiftformat, cocoapods, fastlane, carthage, xcbeautify

### Cloud
Items: docker, docker-compose, terraform, ansible, awscli, kubernetes-cli

### Apps
Items: google-chrome, visual-studio-code, sublime-text, sourcetree, proxyman, charles, postman, cursor, sf-symbols

### Communication
Items: slack, zoom, whatsapp, telegram

### Productivity
Items: bitwarden, spotify, iina, betterzip, setapp, dockdoor, openaudible

### AI Tools
Items: claude (cask), chatgpt (cask), claude-code (npm: @anthropic-ai/claude-code), openclaw (npm)

### Mac App Store
Items: LanScan (472226235), Things 3 (904280696), Magnet (441258766)

### macOS Defaults (pick SECTIONS, not individual settings)
Items/sections: dock, finder, keyboard, trackpad, mouse, power, screenshots, menu-bar, hot-corners, language-region, activity-monitor, app-store, terminal, time-machine, xcode
Each section applies all its settings from the profile YAML config. User toggles sections on/off, not individual defaults within a section.

### macOS Complex Defaults
Items/sections: dock-folders, photos, spotlight, bluetooth-audio, printing, keyboard-shortcuts, scroll-behavior, login-window, sourcetree, advanced-trackpad
Same as above — toggle sections.

### Cleanup (apps to remove)
Items: GarageBand.app, iMovie.app, Keynote.app, Numbers.app, Pages.app

### Encryption
Single toggle: decrypt encrypted dotfiles (yes/no)

### Xcode (full install)
Single toggle: install Xcode via xcodes (yes/no)

## Interactive Flow

### Step 1: Welcome
```
◆ macsetup
│
│  Machine: Apple M4 Max • 36GB • macOS 15.3
│
```

### Step 2: Setup kind
```
◆ What kind of setup?
│  ● Full Dev
│  ○ Server
│  ○ Minimal
│  ○ Custom
│  ○ Use last config (dev)
```

### Step 3a: If Custom → module selection
```
◆ Select modules to install:
│  ◻ Core Tools (jq, curl, bat, ripgrep, ...)
│  ◻ Terminal (oh-my-zsh, powerline, theme)
│  ◻ Languages (python, ruby)
│  ◻ iOS Dev (swiftlint, fastlane, ...)
│  ◻ Cloud (docker, terraform, ...)
│  ◻ Apps (Chrome, VS Code, ...)
│  ◻ Communication (Slack, Zoom, ...)
│  ◻ Productivity (Bitwarden, Spotify, ...)
│  ◻ AI Tools (Claude, ChatGPT, ...)
│  ◻ Mac App Store
│  ◻ macOS Defaults
│  ◻ macOS Complex Defaults
│  ◻ Cleanup
│  ◻ Encryption
│  ◻ Xcode
```

### Step 3b: For each selected module → item drill-down
```
◆ Core Tools — select packages:
│  ◼ jq
│  ◼ curl
│  ◻ wget
│  ◼ bat
│  ◻ tree
│  ◼ fd
│  ◼ ripgrep
│  ◻ htop
```

### Step 3c: If preset (Dev/Server/Minimal) → show summary with option to customize
```
◆ Dev profile selected. Customize items?
│  ● No, install everything
│  ○ Yes, let me adjust
```
If "Yes" → same drill-down flow as Custom, but pre-filled with the preset selections.

### Step 4: Git config (if not in profile)
### Step 5: Encryption password (if encryption selected)
### Step 6: Summary + confirm
### Step 7: Run required phase → then optional modules
### Step 8: Save profile YAML + state

## New Profile YAML Format

```yaml
name: dev
description: "Full development setup"

# Per-module item selections
core: [jq, curl, wget, tree, bat, fd, ripgrep, htop]
terminal: [oh-my-zsh, powerline, theme, fonts]
languages: [python, ruby]
ios: [swiftlint, swiftformat, cocoapods, fastlane, carthage, xcbeautify]
cloud: [docker, docker-compose, terraform, ansible, awscli, kubernetes-cli]
apps: [google-chrome, visual-studio-code, sublime-text, sourcetree, proxyman, charles, postman, cursor, sf-symbols]
comms: [slack, zoom, whatsapp, telegram]
productivity: [bitwarden, spotify, iina, betterzip, setapp, dockdoor, openaudible]
ai: [claude, chatgpt, claude-code, openclaw]
mas:
  - {id: 472226235, name: LanScan}
  - {id: 904280696, name: "Things 3"}
  - {id: 441258766, name: Magnet}
macos: [dock, finder, keyboard, trackpad, mouse, power, screenshots, menu-bar, hot-corners, language-region, activity-monitor, app-store, terminal, time-machine, xcode]
macos_complex: [dock-folders, photos, spotlight, bluetooth-audio, printing, keyboard-shortcuts, scroll-behavior, login-window, advanced-trackpad]
cleanup: [GarageBand.app, iMovie.app, Keynote.app, Numbers.app, Pages.app]
encryption: true
xcode: true

config:
  git:
    user_name: "JARMourato"
    user_email: "joao.armourato@gmail.com"
  python_versions: ["3.12"]
  ruby_version: "3.4.1"
  macos:
    dock:
      autohide: false
      tile_size: 40
      # ... all defaults settings stay the same
    finder:
      # ...
    # etc.
```

## Implementation Changes

### 1. New required phase (src/required.ts)
- Runs before optional modules
- Checks/installs: xcode-select, homebrew, node detection, ssh, git config, dotfile symlinks
- No user interaction beyond git name/email prompt
- Not skippable

### 2. Module registry refactor (src/modules/*.ts)
Each module now exports:
```typescript
interface ModuleV2 {
  name: string;
  label: string;
  description: string;
  // All available items with labels
  items: Array<{ id: string; label: string; description?: string }>;
  // Which items are selected by default in custom mode
  defaultItems: string[];
  // Dependencies on other modules (not items)
  dependencies?: string[];
  // Install specific items only
  install(items: string[], opts: InstallOptions): Promise<void>;
  // Detect which items are already installed
  detect(items: string[], opts: InstallOptions): Promise<DetectResult>;
}
```

### 3. Updated interactive flow (src/index.ts)
- Required phase runs first (no prompt)
- Module selection → item drill-down for each selected module
- Preset profiles pre-fill items, with "customize?" prompt
- Summary shows exact items per module before confirming

### 4. Profile loading
- New YAML format: module names as keys with item arrays
- Backward compatible: if `modules: [...]` array format detected, treat as all items selected
- `config:` section stays the same for macOS defaults values

### 5. Profiles to update
- profiles/dev.yaml — all items selected
- profiles/server.yaml — slim selection (core basics, docker, no iOS/cloud/AI)  
- profiles/minimal.yaml — core essentials + terminal only

### 6. Remove the `node` module
Node.js is required/pre-installed. Remove src/modules/node.ts and references to it.

### 7. Merge shell + ssh + git into required phase
These are required, not optional. Move their logic into src/required.ts. Remove as standalone modules.

## DO NOT
- Change macOS defaults values/settings (only the toggle mechanism)
- Delete existing bash scripts
- Change encryption mechanism
- Change dotfile contents
- Break the bootstrap.sh shim
- Change the package.json name or bin field

## Build & Verify
- `npm run build` must succeed
- `node dist/index.js --help` must show updated options
- Commit with conventional commits
