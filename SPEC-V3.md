# macsetup v3 — Status + Reset Commands

## 1. `--status` command

Live-scan the machine and show what macsetup has changed vs a fresh Mac.

### What to check:
- **Brew formulas**: list all installed, categorize as "managed by macsetup" (in any module's items list) vs "unknown"
- **Brew casks**: same categorization
- **npm globals**: check for claude-code, openclaw
- **Dotfile symlinks**: check if ~/.aliases, ~/.exports, ~/.zshrc, etc. are symlinks pointing to ~/.macsetup/dotfiles/
- **Shell tools**: oh-my-zsh installed? powerline-shell? fonts?
- **macOS defaults**: for each section in the macos module, read current values and show if they differ from macOS factory defaults
- **Environment**: ANDROID_HOME set? SSH keys present?
- **State file**: show last run info if exists

### Output format:
Use @clack/prompts log.info with colored output. Group by category. Use ✅ for managed items, ⚠️ for unmanaged items found, ☐ for items not installed.

### Implementation:
Add to src/index.ts as a new option `--status`. Create src/status.ts with the scanning logic.

```typescript
// src/status.ts
export async function showStatus(rootDir: string): Promise<void> {
  // 1. Run `brew list --formula` and `brew list --cask` to get all installed
  // 2. Compare against all module item lists to categorize
  // 3. Check dotfile symlinks
  // 4. Check shell tools (oh-my-zsh dir, powerline-shell command, fonts)
  // 5. Read macOS defaults for known keys and compare to factory
  // 6. Check env vars
  // 7. Show state file info
  // 8. Print everything with @clack/prompts
}
```

## 2. Defaults Backup System

Before applying any macOS defaults, snapshot the current values so they can be restored.

### Backup file: `~/.macsetup-defaults-backup.json`

```json
{
  "created": "2026-02-26T19:00:00Z",
  "defaults": {
    "com.apple.dock": {
      "autohide": false,
      "tilesize": 48,
      "magnification": false
    },
    "com.apple.finder": {
      "ShowStatusBar": false,
      "ShowPathbar": false
    },
    "-g": {
      "KeyRepeat": 6,
      "InitialKeyRepeat": 68
    }
  }
}
```

### Implementation:
- In src/modules/macos.ts: before writing any defaults, read the current value first and store it
- Create src/defaults-backup.ts with load/save/restore functions
- Only create backup on FIRST run (don't overwrite existing backup)
- The backup represents the "before macsetup" state

```typescript
// src/defaults-backup.ts
export async function loadDefaultsBackup(): Promise<DefaultsBackup | null>;
export async function saveDefaultsBackup(backup: DefaultsBackup): Promise<void>;
export async function backupDefault(domain: string, key: string): Promise<void>;
export async function restoreAllDefaults(dryRun: boolean): Promise<void>;
```

### How backupDefault works:
```bash
defaults read <domain> <key>
```
If the key exists, store its value. If it doesn't exist (exit code 1), store `__NOT_SET__` so we know to `defaults delete` it on restore.

### How restoreAllDefaults works:
For each entry in the backup:
- If value is `__NOT_SET__`: `defaults delete <domain> <key>`
- Otherwise: `defaults write <domain> <key> -<type> <value>`

## 3. `--reset` command

Undo everything macsetup could have touched. More aggressive than `--uninstall`.

### What it does:
1. **Restore macOS defaults** from backup file (if exists)
2. **Uninstall ALL brew formulas** that are in any macsetup module
3. **Uninstall ALL brew casks** that are in any macsetup module
4. **Uninstall npm globals**: claude-code, openclaw
5. **Remove dotfile symlinks** (don't delete the originals in ~/.macsetup)
6. **Remove oh-my-zsh**: `rm -rf ~/.oh-my-zsh`
7. **Remove powerline-shell config**: `rm -rf ~/.config/powerline-shell`
8. **Remove ANDROID_HOME** lines from ~/.exports
9. **Remove SSH keys**: SKIP (too dangerous)
10. **Remove git config**: SKIP (too dangerous)
11. **Clear state file**
12. **Clear defaults backup** (it's been restored)
13. **Optionally remove Homebrew itself** (prompt: "Also remove Homebrew? This is rarely needed.")

### Safety:
- Always show full preview first (like --uninstall does)
- Require explicit confirmation
- `--reset --dry-run` shows preview without doing anything
- NEVER touch SSH keys or git config (too dangerous)
- Warn loudly before proceeding

### Implementation:
Add to src/index.ts as `--reset` option. Create src/reset.ts with the logic.

## 4. Integrate defaults backup into macos module

Modify src/modules/macos.ts install function:
- Before the first `defaultsWrite` call for any section, call `backupDefault(domain, key)` for each key we're about to write
- Only backup if backup file doesn't already exist (first run protection)

## DO NOT:
- Change any existing module behavior
- Change profile formats
- Break existing --uninstall, --diff, --export
- Touch SSH keys or git config in reset
- Delete ~/.macsetup directory in reset

## Build & Verify:
- `npm run build` must succeed
- `node dist/index.js --help` must show --status and --reset
- Commit with conventional commits
