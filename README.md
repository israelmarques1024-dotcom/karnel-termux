<p align="center">
  <img src="https://raw.githubusercontent.com/israelmarques1024-dotcom/karnel-termux/main/assets/images/karnel-logo.png" alt="Karnel Termux Logo" width="400">
</p>

<p align="center">
  <strong>Transform your Android into a complete development workstation.</strong>
</p>

<p align="center">
  <a href="https://github.com/israelmarques1024-dotcom/karnel-termux">
    <img src="https://img.shields.io/badge/version-4.9.0-0078D4?style=for-the-badge" alt="Version">
  </a>
  <a href="https://www.npmjs.com/package/karnel-termux">
    <img src="https://img.shields.io/npm/v/karnel-termux?style=for-the-badge&logo=npm&color=cb3837" alt="npm">
  </a>
  <a href="https://www.npmjs.com/package/karnel-termux">
    <img src="https://img.shields.io/npm/dt/karnel-termux?style=for-the-badge&logo=npm&color=cb3837" alt="npm downloads">
  </a>
  <a href="https://github.com/israelmarques1024-dotcom/karnel-termux/blob/main/LICENSE">
    <img src="https://img.shields.io/badge/license-MIT-0078D4?style=for-the-badge" alt="License">
  </a>
  <a href="https://termux.dev/">
    <img src="https://img.shields.io/badge/platform-Termux%20%7C%20Android-0078D4?style=for-the-badge" alt="Platform">
  </a>
  <a href="https://kerneltermux.vercel.app">
    <img src="https://img.shields.io/badge/Site-kerneltermux.vercel.app-0078D4?style=for-the-badge" alt="Website">
  </a>
</p>

---

**Karnel Termux** is a modular development environment that transforms Termux into a complete workstation. With a single CLI (`karnel`), install and manage:

Created by **Israel Marques**.

- **31 AI agents** for coding — Claude, Gemini, OpenCode, Ollama, Cline, karnelRoute and more
- **7 languages** — Node.js, Python, Go, Rust, C/C++, PHP, Perl
- **5 databases** — PostgreSQL, MariaDB, SQLite, MongoDB, Redis
- **22 dev tools** — gh, curl, fzf, bat, lsd, jq, tmux, openssh, snyk and more
- **11 utility scripts** — fconv, notes, treex, qrcode, zork and more
- **2 network tools** — dark, dedsec-network
- **3 deploy CLIs** — Vercel, Railway, Netlify
- **Responsible OSINT** — Robin v2.8 through Tor with a loopback-only web UI
- **Professional editor** — code-server (VS Code in browser)
- **Second brain** — Memory system with AI search and idea graph
- **Voice commands** — Speak to your AI agents

> [!IMPORTANT]
> Designed exclusively for **Termux on Android**. Does not work on other platforms.



---

## Installation

### Via curl (recommended)

```bash
bash -c "$(curl -fsSL https://raw.githubusercontent.com/israelmarques1024-dotcom/karnel-termux/main/install.sh)"
```

### Via npm

```bash
npm install -g karnel-termux
```

### Via pnpm

```bash
pnpm add -g karnel-termux
```

After installation, run:

```bash
karnel
```

---

## Usage

### Main Commands

| Command | Description |
|---------|-------------|
| `karnel install <module>` | Install modules and tools |
| `karnel list <module>` | List available tools |
| `karnel show <module> --<tool>` | Show tool documentation |
| `karnel open <module>` | Open documentation in browser |
| `karnel update <module>` | Update modules or karnel |
| `karnel uninstall <module>` | Remove installed modules |
| `karnel reinstall <module>` | Reinstall modules |
| `karnel doctor termux` | Diagnose the Termux environment (30+ sections) |
| `karnel doctor code` | Detect project ecosystems and run code checks |
| `karnel doctor robin` | Diagnose Robin, Tor, dependencies, and local UI |
| `karnel brain` | Second brain — memories and search |
| `karnel env` | Manage environment variables |
| `karnel voice` | Voice commands for AI agents |
| `karnel start editor` | Start code-server (VS Code in browser) |
| `karnel pg` | PostgreSQL manager |
| `karnel init <template>` | Initialize projects with templates |
| `karnel deploy` | Deploy projects (Vercel, Railway, Netlify) |
| `karnel robin` | Manage the Robin OSINT service |
| `karnel --version` | Show installed version |

### Modules

| Module | Description | Installation |
|--------|-------------|--------------|
| `lang` | Node.js, Python, Go, Rust, C/C++, PHP, Perl | `karnel install lang` |
| `db` | PostgreSQL, MariaDB, SQLite, MongoDB, Redis | `karnel install db` |
| `ai` | 31 AI agents for coding | `karnel install ai` |
| `editor` | code-server (VS Code in browser) | `karnel install editor` |
| `dev` | gh, curl, fzf, bat, lsd, jq and more | `karnel install dev` |
| `npm` | TypeScript, NestJS CLI, Prettier and more | `karnel install npm` |
| `shell` | ZSH + Oh My Zsh + 10 plugins | `karnel install shell` |
| `ui` | Font, cursor, extra-keys, banner | `karnel install ui` |
| `auto` | Automation with n8n | `karnel install auto` |
| `deploy` | Vercel, Railway, Netlify | `karnel install deploy` |
| `games` | Buzz, CTF God, Detective, Tamagotchi and more | `karnel install games` |
| `network` | Dark Web OSINT, DedSec Network Toolkit | `karnel install network` |
| `utils` | fconv, notes, treex, passman, applaunch, qrcode, zork and more | `karnel install utils` |
| `osint` | Robin v2.8, Tor, Streamlit, and LLM providers | `karnel install osint` |
| `voice` | Speech-to-agent through Termux:API | `karnel install voice` |

---

## Robin OSINT

Robin is an independent AI-assisted dark-web OSINT project. Karnel pins the
tested `v2.8` release, installs native Termux scientific dependencies, binds the
web interface only to `127.0.0.1`, and keeps application code separate from
provider configuration and saved investigations.

```bash
karnel install osint --robin
karnel robin config
karnel robin start
karnel robin doctor --network
```

Open `http://127.0.0.1:8501` only after the health check succeeds. Use Robin
solely for lawful, authorized, and ethical research. Tor does not guarantee
anonymity, external LLM traffic normally bypasses Tor, providers may process
submitted data, and AI output is not verified evidence.

Uninstall and reinstall preserve `$KARNEL_CONFIG/robin/.env` and
`$KARNEL_DATA/robin/investigations`. Permanent deletion requires the explicit
`karnel robin purge-data` command.

See the bundled reference with `karnel show osint --robin`.

---

## AI Agents (31)

```bash
karnel install ai                             # Install all
karnel install ai --opencode --ollama         # Install specific agents
```

<details>
<summary><strong>View complete agent list</strong></summary>

| Agent | Flag | Description |
|-------|------|-------------|
| **Qwen Code** | `--qwen-code` | Alibaba coding assistant |
| **Gemini CLI** | `--gemini-cli` | Google Gemini assistant |
| **Claude Code** | `--claude-code` | Anthropic CLI with Claude AI |
| **Mistral Vibe** | `--mistral-vibe` | Mistral command-line assistant |
| **OpenClaude** | `--openclaude` | Open source Claude Code alternative |
| **OpenClaw** | `--openclaw` | Personal AI assistant |
| **Ollama** | `--ollama` | Run open source LLMs locally |
| **Codex CLI** | `--codex` | OpenAI coding agent |
| **OpenCode** | `--opencode` | Open source terminal agent |
| **MiMoCode** | `--mimocode` | Fast open source AI agent |
| **Engram** | `--engram` | Persistent memory system |
| **CodeGraph** | `--codegraph` | Code structure analysis |
| **Pi** | `--pi` | Minimalist terminal harness |
| **Antigravity CLI** | `--antigravity-cli` | Terminal interface for Antigravity |
| **MiniMax CLI** | `--minimax-cli` | Generate text, image, video and audio |
| **Gentle AI** | `--gentle-ai` | AI workflow ecosystem |
| **GGA** | `--gga` | Multi-provider automated code review |
| **Hermes Agent** | `--hermes-agent` | Nous Research self-improving agent |
| **Kimi Code** | `--kimi-code` | Kimi Code CLI |
| **Command Code** | `--command-code` | Agent that learns your style |
| **Freebuff** | `--freebuff` | Free community agent |
| **Kilo Code CLI** | `--kilocode-cli` | Native glibc CLI for Termux |
| **Kiro CLI** | `--kiro` | AWS AI coding assistant |
| **Crush CLI** | `--crush` | Charm AI agents CLI |
| **Odysseus** | `--odysseus` | Odysseus coding assistant |
| **Kimchi CLI** | `--kimchi-code` | Kimchi AI agent |
| **Cline CLI** | `--cline` | Autonomous coding agent (via proot-distro) |
| **omniRoute** | `--omni-route` | AI gateway with 236+ providers |
| **Context7** | `--ctx7` | Documentation for AI assistants |
| **OpenSpec** | `--openspec` | Spec-Driven Development |
| **Copilot-Termux** | `--copilot-termux` | GitHub Copilot CLI adapted for Termux |

</details>

---

## karnel doctor

Doctor has three operational subcommands:

```bash
karnel doctor termux                 # 30+ Termux/Karnel diagnostic sections
karnel doctor termux --quick         # Run essential system/package checks only
karnel doctor termux --fix           # Apply queued fixes without group confirmation

karnel doctor code                   # Quick project analysis
karnel doctor code --standard .      # Add security, deps, coverage and complexity
karnel doctor code --deep --json .   # All 76 definitions as standalone JSON
karnel doctor code --fix .           # Apply fixes classified as safe
karnel doctor robin                  # Robin/Tor/dependency diagnostics
karnel doctor robin --network        # Also verify traffic through Tor
```

Running `karnel doctor` without a subcommand defaults to `termux`.

The code analyzer recognizes 25 ecosystem labels and contains 76 check
definitions across 68 distinct tool labels. It detects subprojects, executes
checks in the matching project or subproject directory, preserves command exit status, and writes
timestamped text reports under `$KARNEL_DATA/doctor_code_reports/`.

Read the **[complete Doctor reference](docs/doctor/README.md)** for modes,
supported ecosystems, tool coverage, JSON schema, reports, and auto-fix safety.

---

## karnel brain — Second Brain

Integrated memory system with text search, AI-assisted questions, and graph visualization.

```bash
karnel brain save "my idea"         # Save a thought
karnel brain search "postgres"     # Search local memories by text
karnel brain graph                 # Visualize idea connections
karnel brain sync                  # Sync with private GitHub
```

---

## karnel voice

Capture audio from microphone, review in editor, copy to clipboard, and dispatch any AI agent with the transcribed prompt.

```bash
karnel voice opencode              # Record -> edit -> opencode run
karnel voice text                  # Record -> edit -> print to terminal
karnel voice claude-code --lang en # Speak in English -> claude -p
karnel voice "!"                   # Shortcut for "text"
```

### Supported Agents (15)

| Agent | Command executed |
|-------|-----------------|
| `kilo` | `kilo --prompt "..."` |
| `opencode` | `opencode run "..."` |
| `claude-code` | `claude -p "..."` |
| `codex` | `codex "..."` |
| `gemini-cli` | `gemini -p "..."` |
| `hermes-agent` | `hermes chat -q "..."` |
| `kimi-code` | `kimi -p "..."` |
| `mimocode` | `mimo run "..."` |
| `mistral-vibe` | `vibe --prompt "..."` |
| `openclaude` | `openclaude --bg "..."` |
| `pi` | `pi -p "..."` |
| `qwen-code` | `qwen -p "..."` |
| `crush` | `crush "..."` |
| `kiro` | `kiro-cli "..."` |
| `text` | Prints prompt to terminal |

### Options

| Flag | Description |
|------|-------------|
| `--lang <code>` | Speech language: `pt-BR`, `en-US`, `es`, etc |
| `--raw` | Skip editor, use raw capture |
| `--no-clip` | Don't copy prompt to clipboard |

### Flow

```
Microphone -> termux-speech-to-text -> editor (edit) -> clipboard -> AI agent
```

1. Speak the prompt
2. Review and correct in editor
3. Prompt is copied to clipboard
4. AI agent is dispatched with the prompt

### Requirements

- Termux:API: `pkg install termux-api`
- App Termux:API: https://kerneltermux.vercel.app/termux/api
- Editor: `karnel install editor`

---

## karnel pg — PostgreSQL

Manage PostgreSQL databases with simple commands:

```bash
karnel pg init && karnel pg start      # Initialize and start server
karnel pg create myapp               # Create a database
karnel pg shell                      # Open psql console
```

---

## karnel init — Project Templates

Create pre-configured projects in seconds:

```bash
cd my-app && karnel init next         # Next.js + TypeScript + Tailwind
cd my-api && karnel init express      # Express + TypeORM
cd backend && karnel init nest        # NestJS + authentication
```

| Template | Description |
|----------|-------------|
| `next` | Next.js with Turbopack, TypeScript, Tailwind, React Query, Zustand |
| `react` | React + Vite with modern structure |
| `express` | Express API with TypeScript + TypeORM + migrations |
| `nest` | NestJS with TypeORM and JWT auth |
| `python` | FastAPI with SQLModel/SQLAlchemy |
| `go` | Go with Gin or Fiber |
| `rust` | Rust with Axum or Actix Web |

---

## karnel env

Manage environment variables securely:

```bash
karnel env set OPENAI_API_KEY        # Add key (hidden input)
karnel env list                      # List variables
karnel env ls                        # List variables
```

---

## karnel deploy

Deploy your projects directly from terminal:

```bash
karnel deploy vercel                  # Deploy to Vercel
karnel deploy railway                 # Deploy to Railway
karnel deploy netlify                 # Deploy to Netlify
```

Platform CLIs are installed automatically.

---

## karnel open

Open documentation for any module or tool in browser:

```bash
karnel open ai                        # Open AI module docs
karnel open db                        # Open DB module docs
karnel open ai --opencode             # Open OpenCode docs on site
```

Documentation loads from https://kerneltermux.vercel.app.

---

## Documentation

- [Documentation index](docs/README.md)
- [CLI reference](docs/cli/README.md)
- [Doctor reference](docs/doctor/README.md)
- [Architecture](docs/ARCHITECTURE.md)
- [Documentation changelog](docs/CHANGELOG.md)
- [Official website](https://kerneltermux.vercel.app)

---

## Examples

```bash
# Install databases
karnel install db --postgresql --sqlite

# Install specific AI agents
karnel install ai --opencode --ollama --claude-code

# View available tools
karnel list ai

# View tool documentation
karnel show ai --opencode

# Update everything
karnel update karnel

# Reinstall a module
karnel reinstall shell

# Full diagnosis
karnel doctor

# Deploy directly
karnel deploy vercel
```

---

## Project Structure

```
karnel/
├── karnel/
│   ├── bin/           # Binary (karnel)
│   ├── cli/
│   │   ├── commands/  # CLI commands (install, list, show, etc.)
│   │   └── karnel.sh    # Main CLI (with TUI)
│   ├── modules/       # Module orchestrators
│   ├── tools/         # Tool installers
│   │   ├── ai/        # 31 AI agents
│   │   ├── lang/      # Languages
│   │   ├── db/        # Databases
│   │   ├── dev/       # 22 dev tools
│   │   ├── editor/    # Code editor
│   │   ├── npm/       # Global npm packages
│   │   ├── shell/     # ZSH plugins
│   │   ├── ui/        # Termux interface
│   │   ├── auto/      # Automation
│   │   ├── network/   # 2 network tools
│   │   ├── utils/     # 11 utility tools
│   │   └── deploy/    # Deploy CLIs
│   └── utils/         # Utilities (banner, log, env, etc.)
├── install.sh         # Installation script
├── package.json       # npm/pnpm publishing
└── .github/workflows/ # CI/CD
```

---

## Configuration

### Environment Variables

```bash
export KARNEL_DEBUG=1      # Debug logs
```

### Directories

| Directory | Description |
|-----------|-------------|
| `~/.local/share/karnel-data/` | Persistent tool data |
| `~/.cache/karnel/` | Logs and cache |
| `~/.config/karnel/` | User configuration |

---

## Automatic Updates

The framework checks for updates every 24 hours in background.

```bash
karnel update karnel     # Update the framework
```

---

## Support the Project

If Karnel Termux has been useful to you, consider supporting via Pix or starring on GitHub — it helps other developers discover the project.

**Pix:** `037f07bd-a326-42b6-a5a3-f29b36e703db`

---

## License

MIT © Israel Marques

---

<p align="center">
  <a href="https://kerneltermux.vercel.app">
    <img src="https://img.shields.io/badge/Full%20Documentation-0078D4?style=for-the-badge" alt="Documentation">
  </a>
</p>
