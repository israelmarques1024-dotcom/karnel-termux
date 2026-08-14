# Documentation Changelog

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
