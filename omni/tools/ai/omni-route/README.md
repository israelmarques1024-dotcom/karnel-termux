# omniRoute

**AI Gateway CLI** — 236+ AI providers via a single endpoint.

**Package:** omni-route  
**Author:** israel676767  
**Repository:** https://github.com/israel676767/omni  
**Official:** https://omniroute.online  
**npm:** https://www.npmjs.com/package/omniroute  
**Type:** AI Gateway (npm package with smart wrapper)  
**License:** MIT

## Description

omniRoute is the Omni Catalyst wrapper for the official `omniroute` npm package — an AI Gateway that provides 236+ AI providers via a single endpoint, with auto-fallback to free providers and smart routing with compression (15-95% token savings).

## Installation

```bash
omni install ai --omni-route
```

## Usage

```bash
omni-route                         # Start AI gateway on localhost:20128
omni-route serve --daemon           # Start as background daemon
omni-route serve --daemon --no-open # Daemon without browser
omni-route stop                     # Stop the server
omni-route --help                   # Show all commands
omni-route --version                # Show version
```

## Dashboard

Access the web dashboard at:
- **URL:** http://localhost:20128
- **Setup:** Configure providers at `/dashboard`
- **API Base:** `http://localhost:20128/v1`

## Architecture

The wrapper uses a **3-tier fallback** strategy:

1. **Local install** (`~/.omni/packages/omniroute/`) — Fast, no download on subsequent runs
2. **npm install** (first run) — Downloads and caches locally with `--ignore-scripts`
3. **npx** (last resort) — Falls back to on-demand execution

### Playwright-core Patch (Termux/Android)

On Termux, the `playwright-core` module throws `"Unsupported platform: android"`, which crashes the server. The wrapper automatically patches 3 occurrences in `coreBundle.js` to return `process.env.HOME + "/.cache"` instead, allowing the server to start. This patch is re-applied automatically on every execution (including after `npm update`).

## Commands

| Command | Description |
|---------|-------------|
| `omni-route` | Shortcut to omniroute |
| `omni-route serve` | Start the server |
| `omni-route serve --daemon` | Run in background |
| `omni-route stop` | Stop the daemon |

## Notes

- Installed via npm package: `omniroute` (official)
- Data directory: `~/.omniroute/` (auto-generated config)
- Default port: 20128
- Dashboard requires `INITIAL_PASSWORD` (auto-generated on first run)
- For external access, configure `JWT_SECRET` and `API_KEY_SECRET` in `.env`

## Links

- Website: https://omniroute.online
- GitHub: https://github.com/diegosouzapw/OmniRoute
- npm: https://www.npmjs.com/package/omniroute

## Related

- `omni ia routes` — List installed AI CLI tools
- `omni ia sessions` — View active AI sessions
- `omni install ai --omni-route` — Install