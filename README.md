# @jarmourato/macsetup

Interactive macOS setup CLI for provisioning machines from scratch. One command to install dev tools, configure defaults, and get productive.

## Quick Start

```bash
# Run directly from GitHub (no clone needed)
npx github:ultronservant/dotfiles#feat/npx-cli --profile work

# Or with a specific profile
npx github:ultronservant/dotfiles#feat/npx-cli --profile minimal
```

## Commands

```bash
# Install a profile
macsetup --profile work

# Check what's installed vs what a profile expects
macsetup --status

# Create or edit a profile interactively
macsetup --edit

# Full reset — undo everything macsetup installed
macsetup --reset

# Reset preview (no changes)
macsetup --reset --dry-run

# Install preview
macsetup --profile work --dry-run

# Run a single module
macsetup --module terminal

# Show diff from previous run
macsetup --diff

# Export current state as profile YAML
macsetup --export
```

## Profiles

Built-in profiles live in `profiles/`:

| Profile | Description |
|---------|------------|
| `work` | Full dev setup: iOS, Android, Docker, AI tools, all the apps |
| `server` | Media/homeserver: Plex, Docker, backup scripts |
| `minimal` | Core tools + terminal + shell essentials |

Custom profiles saved via `--edit` go to `~/.dotfiles/profiles/` and are automatically picked up by `--profile`.

### Create Your Own

```bash
macsetup --edit
```

Walk through an interactive wizard:
1. Pick a base profile or start fresh
2. Toggle modules (bundles like Terminal are yes/no, others are multiselect)
3. Add custom brew formulas/casks
4. Preview the YAML
5. Save locally or get PR instructions to share with the team

## What Gets Installed

### Required (always)
- Xcode CLI tools, Homebrew, Node.js, SSH key, Git config, shell dotfiles

### Modules

| Module | Items |
|--------|-------|
| **Core Tools** | jq, curl, wget, tree, bat, fd, ripgrep, htop |
| **Terminal** | oh-my-zsh, powerline-shell, Highway theme, Meslo fonts |
| **Languages** | Python (pyenv), Ruby (rbenv + bundler) |
| **iOS Dev** | Xcode (via xcodes), swiftlint, swiftformat, xcbeautify, ASC CLI |
| **Android Dev** | Android Studio, OpenJDK, bundletool, env setup, SDK licenses |
| **Cloud** | Docker Desktop, docker-compose |
| **Apps** | Chrome, VS Code, SourceTree, Proxyman |
| **Communication** | Slack, Zoom, Telegram, WhatsApp |
| **Productivity** | Bitwarden, Setapp |
| **Media** | Spotify, IINA |
| **AI Tools** | Claude, ChatGPT, Claude Code CLI, Codex CLI |
| **Mac App Store** | LanScan, Things 3, Magnet |
| **macOS Defaults** | Dock, Finder, Keyboard, Trackpad, Mouse, Power, Screenshots, etc. |
| **Cleanup** | Remove GarageBand, iMovie, Keynote, Numbers, Pages |

## File Layout

```
~/.dotfiles/
  files/          # Dotfile copies (symlinked from ~/)
  config/         # state.json, defaults-backup.json
  profiles/       # Custom profiles from --edit
```

macsetup keeps everything in `~/.dotfiles/`. Home directory stays clean.

## Reset

```bash
macsetup --reset
```

Undoes everything:
- Restores macOS defaults from backup
- Uninstalls all brew formulas and casks
- Uninstalls Mac App Store apps, npm globals
- Removes dotfile symlinks, oh-my-zsh, powerline, fonts
- Cleans tool data dirs (~/.pyenv, ~/.rbenv, ~/.claude, ~/.gem)
- Removes homeserver artifacts
- Prompts for sudo when needed
- Shows per-item progress throughout

Safety skips: SSH keys, git config, machine name. Telegram optionally skipped (control channel).

## Repo Layout

```
src/            # TypeScript CLI
profiles/       # Built-in YAML profiles
dotfiles/       # Source dotfiles (copied to ~/.dotfiles/files/)
Terminal/       # Terminal theme + powerline config
Xcode/          # Xcode template macros
Scripts/        # Legacy bash scripts (reference)
```

## Development

```bash
npm install
npm run build       # Build with tsup
npm run typecheck   # Type check
npm run dev         # Watch mode
```
