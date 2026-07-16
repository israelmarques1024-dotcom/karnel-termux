# Documentation Changelog

## Unreleased - 2026-07-16

### Doctor command surface

- Added `karnel doctor code` alongside the existing Termux diagnostics.
- Kept exactly two operational Doctor subcommands: `termux` and `code`.
- Removed the stale `karnel doctor fix` entry from the main help. Termux fixes remain
  available through `karnel doctor termux --fix`.
- Synchronized the Doctor AI probe and documentation with the 31-entry registry,
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
