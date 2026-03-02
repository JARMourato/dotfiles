# @jarmourato/dotfiles

Interactive macOS setup CLI for provisioning machines from scratch. One command to install dev tools, configure defaults, and get productive.

## Quick Start

```bash
# Run directly from GitHub (no clone needed)
npx github:JARMourato/dotfiles --profile work
```

## Commands

All commands use `npx github:JARMourato/dotfiles` (or just `dotfiles` if installed globally via `npm install -g`).

```bash
# Install a profile
npx github:JARMourato/dotfiles --profile work

# Check what's installed vs what a profile expects
npx github:JARMourato/dotfiles --status

# Create or edit a profile interactively
npx github:JARMourato/dotfiles --edit

# Full reset — undo everything
npx github:JARMourato/dotfiles --reset

# Dry run (preview, no changes)
npx github:JARMourato/dotfiles --profile work --dry-run
npx github:JARMourato/dotfiles --reset --dry-run

# Run a single module
npx github:JARMourato/dotfiles --module terminal

# Pull latest dotfiles from repo
dotfiles --pull

# Push local dotfile changes to repo
dotfiles --push

# Show diff from previous run
npx github:JARMourato/dotfiles --diff

# Export current state as profile YAML
npx github:JARMourato/dotfiles --export
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
npx github:JARMourato/dotfiles --edit
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
  repo/           # Git clone of the dotfiles repo (push/pull support)
  files/          # Dotfile copies (symlinked from ~/)
  config/         # state.json, defaults-backup.json
  profiles/       # Custom profiles from --edit
```

Everything stays in `~/.dotfiles/`. Home directory stays clean.

## Sync

On first install, the repo is cloned to `~/.dotfiles/repo/`. This gives you full git push/pull support:

```bash
# Edit a dotfile
vim ~/.aliases

# Push your changes back to the repo
dotfiles --push

# On another machine, pull the latest
dotfiles --pull
```

The flow:
1. **Install** clones the repo → `~/.dotfiles/repo/`
2. Dotfiles are copied from repo → `~/.dotfiles/files/` and symlinked to `~/`
3. **Push** copies edited files back to repo, commits, and pushes
4. **Pull** fetches latest, copies to `~/.dotfiles/files/`, re-symlinks

For push access, make sure your SSH key is added to GitHub.

## Reset

```bash
npx github:JARMourato/dotfiles --reset
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
