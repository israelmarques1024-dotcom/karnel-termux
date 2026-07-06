# Omni

**Author:** israel marques

Omni is a Termux environment manager. The project is at `~/omni/` with code under `omni/`.

- CLI command: `omni` (in PATH)
- Main entry: `omni/bin/omni`
- Module orchestrators: `omni/modules/` (ai.sh, auto.sh, db.sh, deploy.sh, dev.sh, editor.sh, lang.sh, npm.sh, shell.sh, ui.sh, voice.sh)
- Tool installers: `omni/tools/` (ai/*, auto/*, db/*, deploy/*, dev/*, editor/*, lang/*, npm/*, shell/*, ui/*, voice/*)
- CLI commands: `omni/cli/commands/` (install.sh, uninstall.sh, update.sh, reinstall.sh, list.sh, show.sh, open.sh, doctor.sh, brain.sh, env.sh, init.sh, pg.sh, voice.sh, ia.sh)
- CLI commands: AI subcommands include `omni ia sessions`, `omni ia routes`, `omni ia list`, `omni ia install`
- omniRoute: installed via `omni install ai --omni-route`; wrapper binary `omni-route`; project files under `omni/tools/ai/omni-route/`
- Utils: `omni/utils/` (banner.sh, bootstrap.sh, colors.sh, env.sh, log.sh)

<!-- CODEGRAPH_START -->
## CodeGraph

In repositories indexed by CodeGraph (a `.codegraph/` directory exists at the repo root), reach for it BEFORE grep/find or reading files when you need to understand or locate code:

- **MCP tools** (when available): `codegraph_explore` answers most code questions in one call — the relevant symbols' verbatim source plus the call paths between them. `codegraph_node` returns one symbol's source + callers, or reads a whole file with line numbers. If the tools are listed but deferred, load them by name via tool search.
- **Shell** (always works): `codegraph explore "<symbol names or question>"` and `codegraph node <symbol-or-file>` print the same output.

If there is no `.codegraph/` directory, skip CodeGraph entirely — indexing is the user's decision.
<!-- CODEGRAPH_END -->
