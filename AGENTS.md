# Omni

**Author:** israel marques

Omni is a Termux environment manager. The project is at `~/omni/` with code under `core/`.

- CLI commands: `core` and `omni` (both in PATH)
- Main entry: `core/bin/core` or `core/bin/omni`
- Modules: `core/tools/` (ai, dev, lang, db, shell, ui, npm, editor, auto)
- Utils: `core/utils/` (banner.sh, bootstrap.sh, env.sh, log.sh, colors.sh)

<!-- CODEGRAPH_START -->
## CodeGraph

In repositories indexed by CodeGraph (a `.codegraph/` directory exists at the repo root), reach for it BEFORE grep/find or reading files when you need to understand or locate code:

- **MCP tools** (when available): `codegraph_explore` answers most code questions in one call — the relevant symbols' verbatim source plus the call paths between them. `codegraph_node` returns one symbol's source + callers, or reads a whole file with line numbers. If the tools are listed but deferred, load them by name via tool search.
- **Shell** (always works): `codegraph explore "<symbol names or question>"` and `codegraph node <symbol-or-file>` print the same output.

If there is no `.codegraph/` directory, skip CodeGraph entirely — indexing is the user's decision.
<!-- CODEGRAPH_END -->
