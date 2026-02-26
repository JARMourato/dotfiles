# @jarmourato/macsetup

Interactive macOS setup CLI that replaces the legacy bootstrap bash flow with `npx @jarmourato/macsetup`.

## Usage

```bash
# Interactive flow
npx @jarmourato/macsetup

# Preset profile
npx @jarmourato/macsetup --profile dev

# Dry run
npx @jarmourato/macsetup --dry-run

# Single module
npx @jarmourato/macsetup --module terminal

# Show state diff from previous run
npx @jarmourato/macsetup --diff

# Export current state as profile YAML
npx @jarmourato/macsetup --export
```

## Profiles

Profiles are in `profiles/`:

- `dev.yaml`: full development setup
- `server.yaml`: media/server-oriented setup
- `minimal.yaml`: core + terminal + shell + macos + node

Each profile defines:

- `modules`: enabled setup modules
- `config`: per-module overrides (git, apps/comms/productivity, mas, cleanup, macos defaults, language runtimes)

## Modules

Implemented modules:

- `core`
- `terminal`
- `shell`
- `macos`
- `macos-complex`
- `node`
- `python`
- `ruby`
- `ios`
- `cloud`
- `apps`
- `comms`
- `productivity`
- `ai`
- `ssh`
- `git`
- `xcode`
- `encryption`
- `cleanup`
- `mas`

## Repo Layout

- `src/`: TypeScript CLI/runtime/modules
- `profiles/`: YAML profile configs
- `dotfiles/`: source dotfiles linked to `$HOME`
- `Scripts/`: legacy bash scripts kept for reference
- `Terminal/`: terminal assets and setup script
- `Xcode/`: Xcode templates/macros

## Build

```bash
npm install
npm run build
```

`package.json` bin is configured as:

```json
{
  "bin": {
    "macsetup": "./dist/index.js"
  }
}
```

## Notes

- Existing bash scripts are intentionally kept.
- Encrypted file mechanism is unchanged and still uses the existing scripts.
- Dotfile contents are unchanged; they are now mirrored in `dotfiles/` for symlink management.
