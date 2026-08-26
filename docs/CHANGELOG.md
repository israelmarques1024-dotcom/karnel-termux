---
title: Documentation Changelog
permalink: /CHANGELOG/
layout: base
---

# Documentation Changelog

## 4.17.11

- Added the **Herdr** CLI to the `utils` module (`karnel install utils --herdr`), with checksum-verified download, atomic install, and Karnel ownership markers.
- Critical runtime fixes:
  - `cursor-cli`, `hermes-agent` and the `doctor` psutil patch now extract archives with the guarded `safe_extract_tar` (path-traversal/symlink protection).
  - `pg schedule` now exports `PATH`/`PREFIX` in the cron job and logs failures instead of discarding output.
  - `pg restore` uses `--single-transaction` and surfaces errors instead of silently retrying.
  - `doctor --fix` no longer auto-applies destructive fixes (install-class, cache wipes, mass symlink deletion) without explicit confirmation; non-interactive sessions skip them (fail-closed).
  - `doctor code --fix` now snapshots each rewritten file to `<file>.karnel-bak` before applying in-place formatters.
  - `_fix_broken_symlinks` only removes broken symlinks that point into Karnel-managed paths.
  - `karnel upgrade` no longer triggers a concurrent update check.
  - `shell.sh` temp directory falls back to `KARNEL_CACHE` instead of `/tmp`.
- Website/documentation overhaul: `karnel open` now resolves to real GitHub source URLs (no more 404s), canonical site URL unified to GitHub Pages, utility-tool count corrected to 13 (Herdr added), cloud-backup docs corrected to rclone, added `karnel upgrade` to the command table, and added favicon/SEO meta + Troubleshooting nav.

## 4.17.10

- Round 10 security/correctness hardening (23 distinct fixes):
  - **Termux `/tmp` fallbacks eliminated** across host-side code
    (`update.sh`, `brain.sh`, `version.sh`, `log.sh`, `agent_actions.sh`,
    `doctor/code_langs.sh`, `supabase`, and the `security/*` tools amass,
    subfinder, ffuf, gobuster, burpsuite, zap) — now use `KARNEL_CACHE`.
  - **`karnel show <module>`** now rejects invalid module names
    (`/`, `..`, `~`), closing a path-traversal / information-disclosure bug.
  - **Agent PLAN (read-only) mode** hardened: blocks `sed`/`awk`/`perl`/
    `xargs`/`make`/`env`/`nohup`/`setsid`, `sed`/`perl -i`, editors,
    `git apply`/`worktree`/`read-tree`/`update-index`, and now also catches
    redirections without a preceding space (`echo x>file`).
  - **Plugin supply chain** fail-closed: installs now require a manifest
    checksum (was silently skipped), and registry installs pin to a committed
    SHA when provided.
  - **`karnel pg backup --schedule`** no longer swallows `crontab` failures
    and uses the escaped DB name to avoid duplicate cron jobs.
  - **Reinstall** now proceeds to install when the uninstall step reports
    "already uninstalled" (rc 2) instead of aborting.
  - **Archive extraction hardened**: `cline`, `goose`, `kiro` AI installers
    and `zork` now use the safe extractors; `zork` also drops literal `/tmp`.
  - Site fully overhauled (navigation, dark mode, GitHub Pages URLs, Liquid
    fixes, consistent front matter).

## 4.17.9

- Hardened installer and runtime security across the toolkit:
  - `droid` binary install now refuses when no published SHA-256 digest is
    available (fail-closed) instead of silently skipping verification.
  - `keelcode` and `supabase` now extract archives through the hardened
    `safe_extract_tar` (rejects symlink/absolute-path traversal) instead of
    raw `tar`.
  - Restored OpenCode installation: upstream publishes no checksum, so
    `github_download_and_extract` warns instead of refusing (other tools that
    publish checksums remain fail-closed).
  - `cursor-cli` now validates the downloaded bundle is a real gzip archive
    before extraction.
  - Agent PLAN (read-only) mode write-guard hardened: now blocks `sed -i` /
    `perl -i`, full-screen editors, and file descriptors like `2>file`.
  - Agent compaction no longer drops the freshly built summary during the
    trim safety-net.
  - `voice` uninstall no longer removes `termux-api` unless Karnel installed it.
  - `karnel show` no longer depends on `realpath` (portable fallback).
  - `karnel update` reports the accurate installed version instead of a
    misleading `latest`.
  - Reinstall no longer deletes the ownership marker before confirming the
    install, preventing a tool from being orphaned on install failure.

## 4.17.8

- Documentation site reconciled with the GitHub Pages deployment: the `Publish
  Docs` workflow (`.github/workflows/docs.yml`) builds Jekyll from `docs/` and
  deploys to GitHub Pages, so the live documentation URL is
  `https://israelmarques1024-dotcom.github.io/karnel-termux/`.
- `docs/CHANGELOG.md` is now a rendered page (added front matter + permalink)
  and all internal links to it use the clean `/CHANGELOG/` path.
- Tool counts verified against the actual `karnel/tools/*` and
  `karnel/tools/ai/*` directories: 45 AI tools, 3 editors, 8 languages,
  5 databases, 22 dev tools, 11 npm packages, 10 shell plugins, 4 UI
  components, 4 deploy CLIs, 6 games, 2 network tools, 12 utility tools,
  30 security tools, 1 automation tool.

## 4.17.7

- Documentation site overhauled: valid `_config.yml`, cayman-compatible custom
  stylesheet that imports the full theme, a workflow that builds Jekyll before
  deploying to GitHub Pages, and tool counts reconciled with the actual
  `karnel/tools/*` and `karnel/tools/ai/*` directories (45 AI tools, 3 editors,
  8 languages, 5 databases, 22 dev tools, 11 npm packages, 10 shell plugins,
  4 UI components, 4 deploy CLIs, 6 games, 2 network tools, 12 utility tools,
  30 security tools, 1 automation tool).

## 4.16.1 - 2026-08-22

- `karnel agent ask/run`: when the model endpoint is unreachable and Cactus is
  not installed, the agent now says so explicitly and offers to install Cactus
  on the spot (`karnel install ai --cactus`) instead of printing a generic
  "start your server" hint that referenced a binary the user did not have.
- Cactus glibc installer: fresh installs are now pinned to the tested
  `cactus-compute` version (2.0.1) — the previous unpinned spec silently pulled
  2.1.x with a ~1.5 GB torch/CUDA dependency chain; updates keep the
  `>=2,<3` range used by the proot path.
- Cactus glibc installer: pip output is now streamed live (and mirrored to the
  install log) instead of being hidden behind an indeterminate spinner, which
  made multi-minute downloads look frozen.
- Credits: devcorex credited as a core agent contributor in `karnel agent`
  help/REPL screens and project READMEs.

## 4.16.0 - 2026-08-20

- Rebranded fully to Karnel: removed every remaining reference to DevCoreX and
  core-termux across contributors, CLI `open` targets, completions, docs and
  agent utilities.
- `nvchad` editor tool now installs the official upstream `NvChad/starter`
  (pinned to a reviewed commit) instead of a third-party fork.
- Added the `karnel agent` subsystem (agent.sh, agent_actions.sh, agent_llm.sh,
  agent_markdown.sh) with voice, markdown and LLM helper utilities.
- Hardened AI installers: cursor-cli (atomic staging download + ownership
  markers), walkie, codegraph (correct Termux shebang), engram, gentle-ai,
  command-code, ctx7, openspec, freebuff, hermes-agent, mistral-vibe, openclaw
  and hugging-face (pinned dependency).
- Supply-chain tests now accept non-executable asset modes (644/660/664) so the
  suite passes on Android shared storage, and the package checker handles the
  npm >= 12 object-shaped pack report.
- AI registry count updated to 45 verified tools; all 26 isolated test suites
  pass.

## 4.15.2 - 2026-08-16

- Implemented the previously missing `karnel brain add "text"` subcommand.
  `karnel brain save` (interactive) told non-interactive users to use
  `karnel brain add` when a terminal was unavailable, but the subcommand did
  not exist and fell through to "Unknown subcommand". `add` now saves a memory
  non-interactively with optional `--title`, `--category` and `--tags`.
- Fixed memory slug lookup in `karnel brain show/relate/edit/delete`. The help
  documents `karnel brain show slug-name`, but stored memories use
  `YYYY-MM-DD_<slug>.md` filenames and lookups required the exact, full,
  date-prefixed basename. A shared `_brain_find_memory` helper now resolves the
  bare slug (falls back to `*_<slug>.md`) so the documented short form works.
- Removed a duplicated `glow` rendering block in `karnel brain show`.
- `karnel brain search` (and related memory search in `ask`/`save` suggestions and
  `delete` relation clean-up) now falls back to `grep -r` when `ripgrep` is not
  installed, instead of failing with "ripgrep not found". Environments without
  `rg` (fresh minimal containers, CI runners) can now search memories.

- Fixed the plugin registry pin: `PLUGIN_REGISTRY_COMMIT` now points to
  `f19d3cd` (registry commit that pins reviewed plugin sources to commits/
  tags instead of moving `main`), with the matching registry checksum
  `ea82bf2f...`. Plugin updates previously failed with a "Checksum mismatch"
  whenever a plugin repository advanced ahead of the stale registry snapshot.

## 4.15.0 - 2026-08-14

- Replaced the unavailable GGA fork with the official Gentleman Guardian
  Angel v2.10.1, pinned by commit, with Termux-safe staging, ownership
  verification, rollback, and non-destructive uninstall.
- Made backup/restore transactional: staged configs, ancestor symlink
  rejection, signal-safe rollback, concurrent backup isolation, validated
  snapshot names, and explicit package/configuration phase separation.
- Hardened lifecycle ownership so pre-existing installs are never adopted,
  arbitrary handler exit codes are treated as failures, and stale or empty
  locks are recovered safely.
- Pinned release/npm/installer together: the npm package carries a validated
  `RELEASE_COMMIT`, the release workflow is serialized per tag and refuses
  divergent partial publications, and the installer activates only a verified,
  clean checkout.
- Authenticated security and AI installers with fixed versions and official
  SHA-256 checksums, safe archive extraction, staging, and rollback; unverifiable
  upstream assets now fail closed instead of executing unauthenticated bytes.
- Fixed the npm postinstall to distinguish the npm bin symlink from a complete
  managed installation, and removed the deprecated `curl | bash` guidance.
- Updated ShellCheck/syntax/test gates to 294 scripts and added regression
  suites for backup, lifecycle, installer integrity, and AI installer hardening.

## 4.14.0 - 2026-08-14

- Added tested Cactus 2.0.1 support on ARM64 through Ubuntu Proot with an
  isolated compatible Python runtime.
- Added the official Hugging Face `hf` CLI in an isolated native Termux
  environment, using HTTP transport when the optional Xet Android wheel is
  unavailable.
- Made the AI registry authoritative for TUI selection, route discovery, and
  lifecycle dispatch, with contracts covering all 43 registered tools.
- Fixed AI reinstall and uninstall error propagation, unknown status handling,
  binary alias summaries, ownership checks, and stale tool counts.

## 4.13.11 - 2026-08-10

- Hardened installers to preserve user-managed commands and data, with atomic
  staging for downloaded payloads and native binaries.
- Added verified plugin registry snapshots, npm release pinning, and regression
  contracts for installers, ownership, and package postinstall behavior.
- Added Android-compatible Railway installation through Ubuntu Proot and
  verified Railway and Netlify CLI installation on Termux.
- Synchronized CLI, GitHub README, npm metadata, and site documentation.
- Corrected the portable npm postinstall fixture used by release validation.

## 4.13.10 - 2026-08-06

- Included root documentation in the npm package and synchronized help, TUI, and release assets.

## 4.13.9 - 2026-08-06

- Completed tool documentation coverage and corrected CLI references, commands, flags, links, and catalog counts.

## 4.13.8 - 2026-08-06

- Added KeelCode through the official `@keelcode-ai/keelcode` npm package.
- Added SuperFile built from pinned upstream source `v1.5.0`.

## 4.13.7 - 2026-08-04

### Plugin System

- Registry entries may now share a repository when each uses a distinct plugin
  path, enabling multiple reviewed plugins from the official registry source.
- Plugin removal acquires the lifecycle lock before recovery and deletion,
  preventing a concurrent update from restoring a removed plugin.
- Registry downloads refuse HTTPS-to-HTTP redirect downgrades.

## 4.13.6 - 2026-08-03

### Fixes

- Reject missing values for `karnel voice --lang` before argument parsing can
  consume another option.
- Harden plugin command validation by rejecting hidden, non-shell, symlinked,
  and undeclared command entries.
- Permit the documented root plugin path (`"path": "."`) in reviewed registry
  entries while retaining traversal protection.
- Clarified CLI help, deployment requirements, and site documentation so they
  match current behavior.

## 4.13.5 - 2026-08-01

### Release hardening

- `karnel update karnel` now resolves the latest GitHub release tag, downloads the
  tag-pinned `karnel-termux-install.sh` and `.sha256` assets, verifies the SHA-256
  checksum before running, and only then falls back to git/npm/pnpm. The Release
  workflow attaches both immutable installer assets to each tag.
- GitHub Releases are created before npm publishing, so a failing npm publish no
  longer blocks the release.
- The site catalog CI now verifies that the generated catalog has not drifted from
  a pinned CLI checkout (`generate-catalog.mjs --check`).

### Fixes

- Repaired the Freebuff installer (release tag, asset name, download URL, binary
  rename) and verified install/update on Termux aarch64.
- `karnel list` detects Kiro, KiloCode, and Cursor via any of their binaries.
- Added troubleshooting documentation covering npm tokens, releases, Vercel, and
  update failures.
- Synchronized documentation with the 39-entry AI registry and the 4 deploy CLIs.

## 4.9.0 - 2026-07-20

### New modules

- Added `network` module with 2 tools: dark (Dark Web OSINT Tor crawler) and
  dedsec-network (multi-purpose network scanner/OSINT/pentest).
- Added `utils` module with 11 utility scripts: fconv, filecheck, websites,
  notes, treex, passman, applaunch, splash, httptmux, zork, and qrcode.

### Documentation

- Created READMEs for all 13 new tools under `karnel/tools/network/` and
  `karnel/tools/utils/`.
- Updated `open.sh` with `network` and `utils` targets for browser docs.
- Updated root README, docs index, CLI reference, and architecture docs with
  the new module counts and tool descriptions.
- Bumped version to 4.9.0.

## 4.8.0 - 2026-07-18

### Robin OSINT

- Added the `osint` module and `karnel robin` lifecycle command.
- Pinned Robin `v2.8` and validated its source commit before activation.
- Added a transactional source/venv installation path for Termux aarch64.
- Separated application code, provider configuration, and investigations.
- Added safe migration from the original single-directory layout.
- Added process identity validation, Streamlit readiness checks, Tor probes,
  versioned responsible-use acknowledgement, and explicit data purge.
- Added `karnel start robin`, global status integration, and
  `karnel doctor robin [--network]`.

### Quality and release

- Expanded catalog documentation from 24 to 32 development tools.
- Added complete Bash/Zsh syntax validation, Robin contract tests, ShellCheck
  error gating, npm package inspection, CI, and release automation.
- Corrected competing stderr redirections in three installers.

## Unreleased - 2026-07-16

### Doctor command surface

- Added `karnel doctor code` alongside the existing Termux diagnostics.
- Kept exactly two operational Doctor subcommands: `termux` and `code`.
- Removed the stale `karnel doctor fix` entry from the main help. Termux fixes remain
  available through `karnel doctor termux --fix`.
- Synchronized the Doctor AI probe and documentation with the 39-entry registry,
  including Copilot-Termux.

### Code analysis engine

- Added project detection for 25 language and ecosystem labels.
- Added a registry with 76 check definitions and 68 distinct tool labels.
- Added quick, standard, and deep modes with 64, 74, and 76 definitions,
  respectively.
- Added text reports and clean JSON output.
- Added safe and unclassified auto-fix modes.
- Added bounded subproject discovery through four directory levels.

### Correctness fixes

- Declared persistent arrays with `declare -g`/`declare -gA` so they survive the
  function-scoped `import()` mechanism.
- Replaced space-delimited tool output with one registry record per line.
- Added a parser that preserves shell pipelines inside registry commands.
- Fixed file discovery that incorrectly expected NUL-delimited `find` output.
- Run language checks and fixes inside the matching manifest directory while
  keeping cross-language checks at the requested project root.
- Preserve command exit statuses, including silent failures and timeouts.
- Quote sample file paths with Bash `%q` before shell execution.
- Prevent `npx` checks from downloading packages by using `--no-install`.
- Resolve compound tool labels such as `npm audit`, `go test`, `cargo test`, and
  `docker compose` to their real executables.
- Run gofmt over discovered Go files instead of passing a directory, and send
  javac output to the temporary directory instead of `/dev/null`.
- Parse Python files through `ast` instead of `compileall`, preventing diagnostics
  from creating `__pycache__` artifacts in the analyzed project.
- Run cross-language checks once per project instead of once per detected language.
- Skip placeholder-based checks when no compatible sample file exists.
- Apply fixes only to findings, preserve the target directory, and report failed
  fix commands accurately.
- Match fixes by both tool and category so tools with multiple checks do not apply
  unrelated corrections.
- Emit standalone JSON with the analyzed directory, result count, category,
  severity, and details.
- Record the requested target directory in text reports instead of `$PWD`.

### Detection fixes

- Preserve the root directory through recursive scans so subprojects are registered.
- Scan `.github/workflows` and detect GitHub Actions YAML files.
- Merge YAML detection so GitHub Actions is no longer shadowed by Ansible rules.
- Recognize scoped Angular and NestJS packages.
- Associate framework names with their language for terminal display.
- Detect Python for all supported Python manifest variants.
- Normalize manifest records for JavaScript, Django, CMake, Maven, Gradle, and .NET.

### Termux diagnostics

- Made `--quick` stop after essential system and package checks instead of running
  the extended network and I/O probes.
- Added explicit timeouts to Termux information and battery probes so a missing or
  unresponsive Termux:API service cannot block the full diagnostic run.
- Generate the Markdown report after auto-fixes so the `Fixed` count is accurate.
- Use explicit `skipped` values for quick-mode sections in the report.
- Fixed Python cache cleanup so version-directory globs expand correctly.
- Quote packages returned by `pip check` before reinstalling them.

### Verification

- Expanded `tests/smoke.sh` from 10 to 14 checks.
- Added syntax coverage for nested Doctor modules.
- Added registry count and pipeline-parsing regression tests.
- Added GitHub Actions, Python manifest, TypeScript, and NestJS detection tests.
- Verified clean JSON with Python's standard JSON parser.
- Verified modified shell files with ShellCheck at style severity.

## Security note

Doctor executes third-party analysis tools in the selected project. Review tool
configuration and use version control before enabling fixes. `npx` checks do not
install missing packages automatically.
