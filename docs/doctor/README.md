# Karnel Doctor

`karnel doctor` diagnoses the Termux environment, analyzes project code, and
validates the optional Robin OSINT service. It has three operational subcommands:

```bash
karnel doctor termux [--quick] [--fix]
karnel doctor code [options] [directory]
karnel doctor robin [--network]
```

Running `karnel doctor` without a subcommand is equivalent to
`karnel doctor termux`.

## Termux diagnostics

```bash
karnel doctor termux
karnel doctor termux --quick
karnel doctor termux --fix
```

### Options

| Option | Description |
|---|---|
| `--quick`, `-q` | Run essential system, storage, critical-tool, and package-manager checks only |
| `--fix`, `-f` | Apply all queued fixes without the group confirmation prompt |

Quick mode skips extended runtime, AI, shell, process, storage-I/O, and network
sections so it can complete without long probes.

### Diagnostic coverage

The Termux doctor contains more than 30 diagnostic sections, including:

- Android, Termux, CPU, RAM, disk, locale, battery, GPU, and external storage
- shared-storage and Karnel-directory permissions
- 11 critical commands: `git`, `rg`, `jq`, `curl`, `tar`, `node`, `python`,
  `rustc`, `go`, `clang`, and `make`
- dpkg, APT sources, keyring, cache, mirrors, and system clock
- Node.js/npm, Python/pip/venv, PostgreSQL, proot, and glibc compatibility
- Karnel version, CLI link, shell banner, Zsh integration, and caches
- all 31 AI registry commands
- shebangs, broken links, Git identity, SSH keys/server, DNS, HTTPS, and latency
- API keys, shell history, zombie processes, storage I/O, and Termux:API

Each finding is categorized as success, information, warning, or error. The
diagnostic command normally completes successfully even when it reports health
problems; use the report and terminal summary as the source of health status.

### Auto-fix behavior

Interactive mode presents queued corrections after diagnostics. `--fix` skips
only the group confirmation; each callback can still fail and reports its own
status. Corrections can install packages, update configuration, initialize
services, clean caches, or rewrite shell integration. Use a backup before applying
fixes to a customized environment.

### Termux report

The latest report replaces the previous one:

```text
$KARNEL_DATA/doctor_reports/doctor_report_latest.md
```

With the default environment, `$KARNEL_DATA` is
`~/.local/share/karnel-data`. The report is generated after auto-fixes and records
the final applied-fix count. Sections omitted by quick mode are marked `skipped`.

## Code analysis

```bash
karnel doctor code
karnel doctor code --standard /path/to/project
karnel doctor code --deep --json /path/to/project
karnel doctor code --fix /path/to/project
```

The analyzer scans the selected directory to a maximum depth of four, excludes
common generated/vendor directories, detects subprojects, and runs each language
from its first matching manifest directory. Cross-language checks run from the
selected root.

### Options

| Option | Alias | Description |
|---|---|---|
| `--quick` | `-q` | Syntax, formatting, lint, combined lint/format, type checks, and tests; default |
| `--standard` | `-s` | Quick checks plus security, dependencies, coverage, dead code, and complexity |
| `--deep` | `-d` | Every registered category, including docs and build checks |
| `--fix`, `--safe-fix` | - | Apply only fixes classified as safe |
| `--aggressive-fix` | - | Also apply fixes that are not classified as safe |
| `--json` | `-j` | Emit a standalone JSON document on stdout |
| `--help` | `-h` | Show code-analysis help |

### Registry size

The registry contains 76 check definitions and 68 distinct displayed tool labels.
Mode counts refer to registry definitions, not checks that every project runs:

| Mode | Definitions | Distinct tool labels |
|---|---:|---:|
| Quick | 64 | 56 |
| Standard | 74 | 66 |
| Deep | 76 | 68 |

Only rows for detected ecosystems are selected. Cross-language checks are selected
once per project. Placeholder-based checks are skipped if no compatible file exists.

### Detected ecosystems

The detector recognizes 25 labels. C# currently receives cross-language checks;
the other labels have dedicated registry rows.

| Manifest or file | Detected label | Framework metadata |
|---|---|---|
| `package.json`, `tsconfig.json` | JavaScript, TypeScript | Next.js, Nuxt, Vite, Angular, React, Vue, Svelte, Astro, Express, Fastify, NestJS, Hono |
| `pyproject.toml`, requirements files, `Pipfile`, `setup.*`, `manage.py`, `*.py` | Python | Django, FastAPI, Flask, pytest, tox, Poetry |
| `go.mod`, `*.go` | Go | - |
| `Cargo.toml`, `*.rs` | Rust | - |
| `Gemfile`, `*.rb` | Ruby | - |
| `composer.json`, `*.php` | PHP | - |
| `pubspec.yaml`, `*.dart` | Dart | Flutter |
| `CMakeLists.txt`, C/C++ Makefiles | C/C++ | CMake |
| `pom.xml`, Gradle files, Java/Kotlin files | Java, Kotlin | Maven, Gradle |
| `*.csproj`, `*.fsproj`, `*.vbproj` | C# | .NET |
| `Dockerfile`, Compose files | Docker | - |
| `*.tf` | Terraform | - |
| Ansible playbooks | Ansible | - |
| `mix.exs`, `*.ex`, `*.exs` | Elixir | - |
| Cabal files, `stack.yaml` | Haskell | - |
| Rockspec/Lua config, `*.lua` | Lua | - |
| `Package.swift`, `*.swift` | Swift | - |
| `Project.toml`, `Manifest.toml` | Julia | - |
| `build.zig` | Zig | - |
| `*.nix`, `flake.lock` | Nix | - |
| `.github/workflows/*.{yml,yaml}` | GitHub Actions | - |
| `*.sh`, `*.bash`, `*.zsh` | Shell | - |
| `*.sql` | SQL | - |

### Registered tools

| Ecosystem | Tool labels |
|---|---|
| JavaScript | ESLint, Prettier, npm audit, Vitest, Jest, markdownlint-cli2 |
| TypeScript | TypeScript compiler, Biome, ESLint, Prettier |
| Python | AST syntax parsing, Ruff, Pyright, mypy, Bandit, pip-audit, pytest, pytest-cov, Vulture, Radon |
| Shell | Bash, Zsh, ShellCheck, shfmt, checkmake |
| SQL | SQLFluff |
| Go | gofmt, go vet, Staticcheck, govulncheck, go test |
| Rust | cargo check/test/audit, rustfmt, Clippy |
| C/C++ | Clang syntax, clang-format, clang-tidy |
| Java | javac |
| Docker | Hadolint, Docker Compose |
| Terraform | terraform fmt/validate, TFLint |
| PHP | PHP lint, PHPStan, PHPUnit |
| Ruby | Ruby syntax, RuboCop |
| Dart | dart analyze/format |
| Elixir | mix compile/format/test |
| Kotlin | Detekt, ktlint |
| Swift | swift build, SwiftLint |
| Haskell | HLint |
| Lua | luac, Selene, StyLua |
| Nix | nix flake check, Statix |
| Julia | Julia package tests |
| Zig | zig build/fmt |
| GitHub Actions | actionlint |
| Ansible | ansible-lint |
| Cross-language | yamllint, jq, xmllint, Trivy, Semgrep |

JavaScript and TypeScript checks use `npx --no-install`; Doctor never downloads a
missing package merely to run a diagnostic.

### Execution and severity

- Project-wide language commands execute from the first matching manifest directory;
  cross-language commands execute from the selected root.
- File-oriented checks analyze the first compatible file found after pruning common
  generated directories.
- Exit status is authoritative: nonzero status and timeout are errors, including
  failures that produce no output.
- Successful commands with empty output are `ok`.
- Nonempty output is classified with error/warning keywords, otherwise as `info`.
- The report retains the first five output lines per check.

### JSON output

`--json` suppresses the colored preamble and emits one standalone object:

```json
{
  "directory": "/path/to/project",
  "results": [
    {
      "severity": "ok",
      "language": "Shell",
      "tool": "bash",
      "category": "syntax",
      "count": 0,
      "detail": ""
    }
  ]
}
```

Fix progress, when JSON and a fix mode are combined, is written to stderr so stdout
remains parseable.

### Code report

Text mode writes a timestamped report:

```text
$KARNEL_DATA/doctor_code_reports/doctor_code_YYYYMMDD_HHMMSS.txt
```

JSON mode does not create a text report.

## Implementation map

```text
karnel/cli/commands/doctor.sh              Termux diagnostics and routing
karnel/cli/commands/doctor/fixes.sh        Termux fix callbacks
karnel/cli/commands/doctor/code.sh         Code CLI parsing and orchestration
karnel/cli/commands/doctor/code_detect.sh  Ecosystem and subproject detection
karnel/cli/commands/doctor/code_langs.sh   Registry, parser, availability, commands
karnel/cli/commands/doctor/code_exec.sh    Execution, severity, fixes, reports
```

Imported files execute inside the `import()` Bash function. Persistent declarations
therefore use `declare -g` or `declare -gA`; ordinary top-level `declare` would be
local to the import call.

## Verification

Regression coverage lives in `tests/smoke.sh` and verifies nested module syntax,
the 76-entry registry, pipeline-safe parsing, mode counts, hidden GitHub workflow
detection, scoped NestJS detection, TypeScript, and Python manifests.

See [the 2026-07-16 changelog](../CHANGELOG.md) for the complete audit and hardening
record.
