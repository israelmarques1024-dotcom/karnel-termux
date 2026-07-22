# Karnel CLI Reference

```bash
karnel <command> [arguments]
```

With no command, Karnel opens its interactive interface (TUI) when a terminal is
available and prints help in noninteractive contexts.

---

## install — Install modules and tools

```bash
karnel install <module>              # Install all tools in a module
karnel install <module> --tool1 --tool2  # Install specific tools only
```

### Modules

| Module    | Description |
|-----------|-------------|
| `lang`    | Node.js, Python, Go, Rust, C/C++, PHP, Perl, Bun |
| `db`      | PostgreSQL, MariaDB, SQLite, MongoDB, Redis |
| `ai`      | 31 AI agents (OpenCode, Claude Code, Ollama, etc.) |
| `editor`  | code-server (VS Code in browser), Neovim, NvChad |
| `dev`     | gh, curl, fzf, bat, lsd, jq, tmux, openssh, snyk (22 tools) |
| `npm`     | TypeScript, NestJS CLI, Prettier, Vercel CLI, etc. |
| `shell`   | ZSH + Oh My Zsh + 10 plugins |
| `ui`      | Font, cursor, extra-keys, banner |
| `auto`    | n8n automation |
| `deploy`  | Vercel, Railway, Netlify CLIs |
| `games`   | Buzz, CTF God, Detective, Tamagotchi, Arcade |
| `network` | Dark Web OSINT, DedSec Network Toolkit |
| `utils`   | fconv, filecheck, notes, qrcode, zork, httptmux (11 scripts) |
| `osint`   | Robin v2.8 — dark web OSINT via Tor + LLM |
| `voice`   | Speech-to-agent via Termux:API |

### Per-module tool flags

| Module    | Flags |
|-----------|-------|
| `ai`      | `--qwen-code`, `--gemini-cli`, `--claude-code`, `--mistral-vibe`, `--openclaude`, `--openclaw`, `--ollama`, `--codex`, `--opencode`, `--mimocode`, `--engram`, `--codegraph`, `--pi`, `--antigravity-cli`, `--minimax-cli`, `--gentle-ai`, `--gga`, `--hermes-agent`, `--kimi-code`, `--command-code`, `--freebuff`, `--kilocode-cli`, `--kiro`, `--crush`, `--cline`, `--odysseus`, `--kimchi-code`, `--omni-route`, `--ctx7`, `--openspec`, `--copilot-termux` |
| `db`      | `--postgresql`, `--mariadb`, `--sqlite`, `--mongodb`, `--redis` |
| `dev`     | `--gh`, `--wget`, `--curl`, `--lsd`, `--bat`, `--proot`, `--ncurses`, `--tmate`, `--openssh`, `--tmux`, `--cloudflared`, `--translate`, `--html2text`, `--jq`, `--bc`, `--tree`, `--fzf`, `--imagemagick`, `--shfmt`, `--make`, `--udocker`, `--snyk` |
| `lang`    | `--bun`, `--nodejs`, `--python`, `--perl`, `--php`, `--rust`, `--clang`, `--golang` |
| `npm`     | `--typescript`, `--nestjs`, `--prettier`, `--live-server`, `--localtunnel`, `--vercel`, `--markserv`, `--psqlformat`, `--ncu`, `--ngrok`, `--turbopack` |
| `shell`   | `--powerlevel10k`, `--zsh-defer`, `--zsh-autosuggestions`, `--zsh-syntax-highlighting`, `--history-substring`, `--zsh-completions`, `--fzf-tab`, `--you-should-use`, `--zsh-autopair`, `--better-npm` |
| `editor`  | `--code-server`, `--neovim`, `--nvchad` |
| `ui`      | `--font`, `--extra-keys`, `--cursor`, `--banner` |
| `auto`    | `--n8n` |
| `deploy`  | `--vercel`, `--railway`, `--netlify` |
| `games`   | `--buzz`, `--ctfgod`, `--detective`, `--pet-friends`, `--tamagotchi`, `--arcade` |
| `network` | `--dark`, `--dedsec-network` |
| `utils`   | `--fconv`, `--filecheck`, `--websites`, `--notes`, `--treex`, `--passman`, `--applaunch`, `--splash`, `--httptmux`, `--zork`, `--qrcode` |

```bash
karnel install ai --opencode --ollama
karnel install db --postgresql --sqlite
karnel install dev --gh --fzf --jq
karnel install network --dark
karnel install utils --fconv --notes --qrcode
```

---

## uninstall — Remove modules and tools

```bash
karnel uninstall <module>
karnel uninstall <module> --tool1 --tool2
```

Same modules and flags as `install`. Removes installed packages, binaries, and
configurations.

```bash
karnel uninstall ai --opencode --ollama
karnel uninstall db --postgresql --sqlite
```

---

## reinstall — Uninstall + install a module

```bash
karnel reinstall <module>
karnel reinstall <module> --tool1 --tool2
```

Performs `uninstall` followed by `install` for the selected module or tools.

---

## update — Update modules or framework

```bash
karnel update <module>            # Update all tools in a module
karnel update <module> --tool1    # Update specific tools
karnel update karnel              # Update the Karnel-Termux package only
karnel update core                # Same as karnel update karnel
```

---

## upgrade — Upgrade the Karnel framework

```bash
karnel upgrade
```

No arguments. Runs `git pull origin main` on the Karnel checkout, re-sources
the environment, verifies the `karnel` symlink, runs cleanup, and shows the
new version.

---

## list — List available tools in a module

```bash
karnel list <module>
```

Displays a formatted table of all tools in a module with their install flag,
binary/command name, and current install status.

| Module    | Lists |
|-----------|-------|
| `lang`    | 8 languages |
| `db`      | 5 databases |
| `ai`      | 31 AI agents |
| `editor`  | 3 editor components |
| `dev`     | 22 development tools |
| `npm`     | 11 npm global modules |
| `shell`   | 10 ZSH plugins |
| `ui`      | 4 UI components |
| `auto`    | 1 automation tool (n8n) |
| `deploy`  | 3 deploy CLIs |
| `games`   | 6 games |
| `network` | 2 network tools |
| `utils`   | 11 utility scripts |
| `osint`   | Robin OSINT |

```bash
karnel list ai
karnel list dev
karnel list network
karnel list utils
```

---

## show — Show documentation for a tool

```bash
karnel show <module> --<tool>      # Show README for a specific tool
karnel show <module>               # List all tools in the module
karnel show backup                 # Show backup documentation
karnel show restore                # Show restore documentation
karnel show all --<tool>           # Search for tool across all modules
```

Renders the tool's `README.md` with `glow` (if installed), `pygmentize`, or
plain `cat`.

```bash
karnel show ai --opencode
karnel show db --postgresql
karnel show dev --gh
karnel show osint --robin
karnel show network --dark
karnel show utils --zork
```

---

## open — Open documentation in browser

```bash
karnel open <target>
```

Opens the official documentation page for a module or tool using
`termux-open-url`. Base URL: `https://kerneltermux.vercel.app`

| Target           | Opens |
|------------------|-------|
| `karnel` / `help` | Overview |
| `lang`           | Language modules |
| `db`             | Database modules |
| `ai`             | AI tools |
| `editor`         | Code editor |
| `dev`            | Dev tools |
| `npm`            | Node.js tools |
| `shell`          | ZSH shell |
| `ui`             | Termux UI |
| `auto`           | Automation tools |
| `deploy`         | Deploy CLIs |
| `games`          | Games |
| `cleanup`        | Cache cleanup |
| `network`        | Network tools |
| `utils`          | Utility tools |
| `osint` / `robin` | OSINT tools |

```bash
karnel open ai
karnel open db
karnel open network
karnel open utils
```

---

## search — Search tools and memories

```bash
karnel search <query>
```

Searches:
1. **Tool registries** — matches tool IDs and names across all modules
2. **Brain memories** — full-text search of stored memories via `grep -ri`

```bash
karnel search postgres
karnel search react hooks
```

---

## status — System overview

```bash
karnel status
```

No arguments. Displays:
- Disk free space
- RAM usage (total, free, low-memory warning)
- System uptime
- Service status: PostgreSQL, code-server, omni-route, Robin
- Internet connectivity (ping to 8.8.8.8)
- Karnel version and last update check

---

## doctor — Diagnostics

```bash
karnel doctor                       # Defaults to termux
karnel doctor termux [--quick] [--fix]
karnel doctor code [options] [directory]
karnel doctor robin [--network]
```

### termux

```bash
karnel doctor termux                # 30+ health sections
karnel doctor termux --quick        # Essential checks only
karnel doctor termux --fix          # Apply fixes without confirmation
```

Covers: Android, Termux, CPU, RAM, disk, locale, battery, GPU, storage,
permissions, 11 critical commands, package managers, runtimes, PostgreSQL,
Karnel, AI commands, shell config, processes, networking.

### code

```bash
karnel doctor code                              # Quick registry set (default)
karnel doctor code --standard /path/to/project   # + security, deps, coverage
karnel doctor code --deep --json /path/to/project # All 76 definitions
karnel doctor code --fix /path/to/project        # Apply safe fixes
```

| Option | Description |
|--------|-------------|
| `--quick`, `-q` | 64 definitions; default |
| `--standard`, `-s` | 74 definitions; adds security, deps, dead-code, complexity |
| `--deep`, `-d` | All 76 definitions |
| `--fix`, `--safe-fix` | Apply fixes classified as safe |
| `--aggressive-fix` | Also apply unclassified fixes |
| `--json`, `-j` | Standalone JSON output |
| `--help`, `-h` | Print help |

Recognizes 25 ecosystem labels. Writes timestamped reports to
`$KARNEL_DATA/doctor_code_reports/`.

### robin

```bash
karnel doctor robin                 # Source, venv, Tor, Streamlit, config
karnel doctor robin --network       # Also verify HTTPS through Tor
```

Never calls an LLM. `--network` adds a small HTTPS request routed through Tor.

---

## robin — OSINT tool management

```bash
karnel robin <subcommand> [options]
```

| Subcommand | Description |
|------------|-------------|
| `start`    | Start Tor + Robin web interface on 127.0.0.1:8501 |
| `stop`     | Stop the managed Robin interface |
| `status`   | Show installation and runtime state |
| `config`   | Show protected provider configuration |
| `doctor`   | Run local diagnostics |
| `update`   | Reconcile with Karnel's pinned Robin release |
| `purge-data` | Permanently delete config and investigations |

| Flag | Applies to | Description |
|------|------------|-------------|
| `--accept-responsible-use` | `start` | Skip the responsible-use acknowledgement prompt |
| `--network` | `doctor` | Test Tor traffic with an HTTPS request |
| `--yes` | `purge-data` | Non-interactive confirmation |

```bash
karnel robin start
karnel robin start --accept-responsible-use
karnel robin doctor --network
karnel robin purge-data --yes
```

See the [Robin reference](../../karnel/tools/osint/robin/README.md) for detailed
lifecycle, data locations, and troubleshooting.

---

## brain — Second brain / personal memory

```bash
karnel brain <subcommand> [options]
```

| Subcommand | Description |
|------------|-------------|
| `init`     | Initialize brain directory and GitHub repo |
| `save`     | Save a new memory (interactive) |
| `search`   | Search memories by keywords or tags |
| `ls` / `list` | List memories, optionally filtered by category |
| `edit`     | Edit a memory in `$EDITOR` |
| `delete` / `rm` | Delete a specific memory |
| `reset` / `destroy` | Delete the entire brain |
| `show` / `view` | View a memory with its relations |
| `graph` / `map` | Visualize memory connections |
| `skill` / `skills` | Create an AI skill from related memories |
| `relate`   | Link two memories by slug |
| `sync`     | Push/pull to a private GitHub repo |
| `ask`      | Ask AI a question with brain context |
| `config` / `ai-config` | Configure AI provider for `ask` |

### brain ask

```bash
karnel brain ask "What did I learn about React?"
karnel brain ask --only-memories "How to configure PostgreSQL?"
```

| Flag | Description |
|------|-------------|
| `--only-memories`, `-m` | Answer from memory only (no live AI generation) |

### brain config

```bash
karnel brain config                    # Show current config
karnel brain config <key> <value>      # Set a config value
```

Keys: `provider`, `default_model`, `context_max_size`, `cache_enabled`,
`only_memories`.

### brain ls

```bash
karnel brain ls                        # All memories by category
karnel brain ls react                  # Filter by category
```

### brain relate

```bash
karnel brain relate <slug-a> <slug-b>  # Link two memories
```

### brain edit / delete / show

```bash
karnel brain edit <slug>
karnel brain delete <slug>
karnel brain show <slug>
```

---

## env — Environment variables

```bash
karnel env <subcommand>
```

| Subcommand | Description |
|------------|-------------|
| `set`      | Create or update a variable (interactive, hidden input) |
| `unset`    | Remove a variable (interactive) |
| `ls` / `list` | List all user-defined variables |

Targets `~/.zshrc` (falls back to `~/.bashrc`). Sensitive values (containing
`SECRET`, `TOKEN`, `API`, `KEY`, `PASSWORD`, `CREDENTIAL`) are masked when
listed.

```bash
karnel env set
karnel env unset
karnel env ls
```

---

## voice — Speech-to-agent

```bash
karnel voice [agent] [options]
```

Captures audio via `termux-speech-to-text`, opens the transcript in `$EDITOR`,
copies to clipboard, and dispatches the AI agent.

### Agent targets

| Agent         | Command executed |
|---------------|-----------------|
| `kilo`        | `kilo --prompt "..."` |
| `opencode`    | `opencode run "..."` |
| `claude-code` | `claude -p "..."` |
| `codex`       | `codex "..."` |
| `gemini-cli`  | `gemini -p "..."` |
| `hermes-agent` | `hermes chat -q "..."` |
| `kimi-code`   | `kimi -p "..."` |
| `mimocode`    | `mimo run "..."` |
| `mistral-vibe` | `vibe --prompt "..."` |
| `openclaude`  | `openclaude --bg "..."` |
| `pi`          | `pi -p "..."` |
| `qwen-code`   | `qwen -p "..."` |
| `crush`       | `crush "..."` |
| `kiro`        | `kiro-cli "..."` |
| `text`        | Print prompt to stdout (no agent) |
| `!`           | Alias for `text` |

### Options

| Flag | Description |
|------|-------------|
| `--lang <code>` | Speech language: `pt-BR`, `en-US`, `es`, etc. |
| `--raw` | Skip the editor step |
| `--no-clip` | Skip clipboard copy |
| `--help`, `-h` | Show help |

### Flow

```
Microphone → termux-speech-to-text → editor (edit) → clipboard → AI agent
```

```bash
karnel voice opencode                 # Speak → edit → opencode run
karnel voice claude-code --lang pt-BR # Portuguese → claude -p
karnel voice text --raw               # Capture → print (no edit)
karnel voice text --no-clip           # Capture → edit → print
```

---

## ia — AI agent manager

```bash
karnel ia <command> [options]
```

| Command | Description |
|---------|-------------|
| `sessions` | List all AI conversation sessions |
| `install`  | Install an AI tool (`karnel ia install <tool>`) |
| `routes` / `launchers` | Show all available AI CLI methods with paths |

```bash
karnel ia sessions
karnel ia sessions --all
karnel ia install omni-route
karnel ia routes
```

---

## init — Project scaffolding

```bash
karnel init <template>
karnel init                          # Auto-detect from existing files
```

| Template | Project type |
|----------|-------------|
| `next` / `nextjs` | Next.js + TypeScript + Tailwind |
| `react` / `vite` | React + Vite |
| `nest` / `nestjs` | NestJS + TypeORM + JWT |
| `express` / `exp` | Express + TypeScript + TypeORM |
| `python` / `fastapi` | FastAPI + SQLModel/SQLAlchemy |
| `go` / `gin` | Go with Gin or Fiber |
| `rust` / `axum` | Rust with Axum or Actix Web |

Auto-detection checks for `package.json`, `requirements.txt`, `go.mod`,
`Cargo.toml`.

```bash
cd my-app && karnel init next
cd my-api && karnel init express
cd . && karnel init                   # Auto-detect
```

---

## deploy — Deploy projects

```bash
karnel deploy <tool> [args...]
```

| Tool | Platform |
|------|----------|
| `vercel` | Vercel (passes remaining args to `vercel`) |
| `railway` | Railway |
| `netlify` | Netlify |

```bash
karnel deploy vercel
karnel deploy vercel --prod
karnel deploy railway
karnel deploy netlify
```

---

## pg — PostgreSQL manager

```bash
karnel pg <command> [args]
```

| Command | Description |
|---------|-------------|
| `start` | Start PostgreSQL server |
| `stop` | Stop PostgreSQL server |
| `restart` | Restart PostgreSQL server |
| `status` | Check PostgreSQL status |
| `init` | Initialize PostgreSQL database |
| `create <name>` | Create a database |
| `drop <name>` | Drop a database (interactive confirmation) |
| `backup [name]` | Backup a database (gzip + SHA256) |
| `restore [name] [file]` | Restore a database from backup |
| `list` / `ls` | List all databases |
| `list-backups` / `backups` | List backups with size, date, integrity |
| `schedule` | Schedule automatic backups via cron |
| `shell` / `psql` | Open psql shell |

Backup uses `pg_dump -F c -b` piped through `gzip` with SHA256 checksum.
Retains the last 10 backups per database. Schedule supports Daily (2:00 AM),
Weekly (Sundays 2:00 AM), or Hourly.

```bash
karnel pg init && karnel pg start
karnel pg create myapp
karnel pg shell
karnel pg backup myapp
karnel pg restore myapp /path/to/backup.gz
karnel pg schedule
```

---

## start — Start services

```bash
karnel start <target> [args]
```

| Target | Description |
|--------|-------------|
| `editor [port]` | Start code-server (default port: 8080) |
| `robin` | Start Tor + Robin (delegates to `karnel robin start`) |

```bash
karnel start editor
karnel start editor 8080
karnel start robin
```

---

## backup — Full Termux backup

```bash
karnel backup [--cloud]
```

Creates `$KARNEL_DATA/backups/termux-<timestamp>.tar.gz` with SHA256 checksum.

### Included in backup

- All packages (`dpkg --get-selections`)
- Karnel tool manifest
- Shell configs (`.bashrc`, `.zshrc`, `.profile`)
- Termux configs (fonts, colors, properties)
- SSH keys
- `~/.config` app configs
- APT repositories

### Options

| Flag | Description |
|------|-------------|
| `--cloud` | Upload to Google Drive via `rclone` (remote named `karnel`) |
| `--help`, `-h` | Show help |

```bash
karnel backup
karnel backup --cloud
```

---

## restore — Full Termux restore

```bash
karnel restore [<file>] [--cloud]
```

### What it restores

- Shell configs to `~/`
- Termux configs
- SSH keys
- `~/.config` directory
- APT sources
- Package list (via `dpkg --set-selections` + `apt-get dselect-upgrade`)
- Karnel tools (from manifest)

Verifies SHA256 checksum automatically if available.

### Options

| Argument | Description |
|----------|-------------|
| `<file>` | Path to a specific backup file |
| `--cloud` | Download and restore from Google Drive |
| `--help`, `-h` | Show help |

```bash
karnel restore
karnel restore /path/to/backup.tar.gz
karnel restore --cloud
```

---

## cleanup — Clean caches and temp files

```bash
karnel cleanup
```

Cleans:
- npm cache (`npm cache clean --force`)
- pip cache (`pip cache purge`)
- Karnel install logs (`install_*.log`)
- Python `__pycache__` directories
- pkg cache (`pkg clean -y`)
- Karnel banner and tip caches

---

## version — Print version

```bash
karnel version
```

Prints the installed Karnel version string (`$KARNEL_VERSION`).

---

## --version — Print version (flag form)

```bash
karnel --version
```

Equivalent to `karnel version`.

---

## help — Print top-level help

```bash
karnel help
```

Prints the main help screen with all commands and module targets.

---

## Module targets reference

These modules work with `install`, `uninstall`, `reinstall`, `update`, `list`,
`show`, and `open`:

`ai` `auto` `db` `deploy` `dev` `editor` `games` `lang` `network` `npm`
`osint` `shell` `ui` `utils` `voice`
