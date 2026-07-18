# Karnel Architecture

## Project Structure

```
karnel-termux/
├── karnel/
│   ├── bin/karnel              # Entry point (bash script, in PATH)
│   ├── cli/
│   │   ├── karnel.sh           # Main CLI dispatcher (TUI + command routing)
│   │   └── commands/           # Each subcommand is a separate file
│   │       ├── help.sh
│   │       ├── install.sh
│   │       ├── doctor.sh       # Doctor command + inline checks
│   │       ├── doctor/         # Doctor code subsystem (4 modules)
│   │       ├── brain.sh
│   │       ├── env.sh
│   │       ├── pg.sh
│   │       ├── voice.sh
│   │       ├── init.sh
│   │       ├── deploy.sh
│   │       ├── ... (25 files)
│   ├── modules/                # Module orchestrators
│   │       ├── ai.sh           # AI agent installer
│   │       ├── lang.sh         # Language installer
│   │       ├── db.sh           # Database installer
│   │       ├── dev.sh          # Dev tools installer
│   │       └── ...
│   ├── tools/                  # Individual tool installers
│   │   ├── ai/                 # 31 AI agents
│   │   ├── lang/               # 7 languages
│   │   ├── db/                 # 5 databases
│   │   ├── dev/                # 32 dev tools
│   │   ├── editor/             # Code editor
│   │   ├── npm/                # Global npm packages
│   │   ├── shell/              # ZSH plugins
│   │   ├── ui/                 # Termux UI
│   │   ├── auto/               # Automation
│   │   ├── deploy/             # Deploy CLIs
│   │   └── osint/              # Robin OSINT integration
│   └── utils/                  # Shared utilities
│       ├── bootstrap.sh        # Import mechanism, shell detection
│       ├── banner.sh           # ASCII banners
│       ├── colors.sh           # ANSI color definitions
│       ├── log.sh              # Logging (info, warn, error, success, box)
│       └── env.sh              # Environment variable utilities
├── install.sh                  # Bootstrap installer
├── package.json                # npm publishing
├── scripts/npm-install.js      # postinstall hook
├── assets/                     # Images, logos
├── tests/                      # Test scripts
└── docs/                       # Documentation
```

## Import Mechanism

Karnel uses a custom `import()` function instead of `source`:

```bash
import() {
  local base="${KARNEL_PATH}"
  local path="${1//@/$base}.sh"
  if [[ -f "$path" ]]; then
    source "$path"
  else
    echo "Import failed: $path" >&2
    exit 1
  fi
}

# Usage:
import "@/utils/log"
import "@/cli/commands/doctor/code"
```

The `@` symbol is replaced with `$KARNEL_PATH`. This avoids hardcoded paths.

### Critical Scope Implication

Because `import()` calls `source` from within a function, any `declare` statement
at the top level of a sourced file creates a **local** variable scoped to `import()`,
not a global. This is a common source of bugs.

**Rules:**
- `declare -A` at top level → **local** to `import()` ❌
- `declare -gA` inside a function → **global** ✅
- `VAR=value` updates the nearest dynamically scoped variable
- `local var` inside a function → **local** ✅

Persistent imported state should use `declare -g` explicitly rather than relying
on the caller's dynamic scope.

## Module System

Each module (`lang`, `db`, `ai`, `dev`, etc.) has:

1. A **module orchestrator** in `karnel/modules/<name>.sh` — handles installation logic
2. Individual **tool installers** in `karnel/tools/<name>/<tool>/install.sh` — each installs one tool

Robin uses a managed layout because its configuration and investigations are
persistent user data:

- Source checkout: `$KARNEL_TOOLS/osint/robin/app`
- Virtual environment: `$KARNEL_TOOLS/osint/robin/.venv`
- Provider configuration: `$KARNEL_CONFIG/robin/.env`
- Investigations: `$KARNEL_DATA/robin/investigations`
- PID and logs: `$KARNEL_RUN` and `$KARNEL_LOGS`

The upstream release and commit are pinned in `tools/osint/robin/common.sh`.
Candidate source and virtualenv trees are verified before replacing the active
installation. Uninstall does not delete persistent data.

### Tool Installer Pattern

```bash
_tool_dependencies() { ... }    # Declare dependencies
_tool_install() { ... }          # Install the tool
_tool_postinstall() { ... }      # Post-installation setup
```

## Doctor Subsystem Architecture

See [Doctor System](./doctor/README.md) for the complete breakdown of the doctor code analysis engine.
