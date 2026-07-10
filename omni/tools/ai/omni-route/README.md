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

### Termux / Android Native Fixes (root cause of "Internal Server Error" 500)

OmniRoute bundles `better-sqlite3` (and `sqlite-vec`) as **prebuilt `linux-x64` glibc**
native addons. On Termux/Android the runtime is **aarch64 + Bionic libc** and
`process.platform` reports `android`, so those addons fail to load
(`dlopen: cannot locate symbol …`). With no working database, every HTTP request
returns `500` and the logs show an `out of memory` DB-probe death spiral.

The installer fixes this **definitively** (no workarounds) by rebuilding the
native addons from source for the running Node/ABI:

1. **Rebuild native modules** — `better-sqlite3` and `sqlite-vec` are recompiled
   with Termux's `clang` against the local Node headers. `node-gyp` mis-detects
   Termux as Android and demands `android_ndk_path`; the installer supplies a
   dummy value so the Android gyp config resolves while Termux's clang compiles.
2. **Instrumentation resilience** — Next.js `registerInstrumentation()` used to
   *re-throw* any error from OmniRoute's (non-critical) instrumentation hook and
   crash the whole server. The installer patches Next's
   `instrumentation-globals.external.js` so a hook error is logged and the server
   keeps running (the real application database is unaffected).

Both fixes are re-applied automatically on every `install` / `update`, so a fresh
or updated install keeps working on Termux/Android.

### Resetting a corrupted database

If `~/.omniroute/storage.sqlite` becomes corrupt, OmniRoute cannot auto-recover
and renames it to `storage.sqlite.probe-failed-*`. Remove those files and let the
server recreate a fresh database:

```bash
rm -f ~/.omniroute/storage.sqlite{,-wal,-shm} ~/.omniroute/storage.sqlite.probe-failed-*
omni-route serve --daemon
```

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