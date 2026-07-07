# omniRoute

**AI CLI Routes Manager**

List and manage installed AI CLI tools.

## Installation

```bash
# Via npm (global):
npm install -g @omnitermux/omni-route

# Via Omni (Termux):
omni install ai --omni-route
```

## Usage

```bash
omni-route list           # List installed AI CLIs
omni-route show <cli>     # Show CLI path

# Examples:
omni-route list
omni-route show opencode
```

## Supported CLIs

Lists: opencode, claude, codex, qwen, hermes, odysseus, ollama, gemini, kilow, engram, freebuff

## Related

- Run `omni ia sessions` to view active sessions
- Run `omni ia routes` to view installed AI CLI paths