# omniRoute

**AI Gateway CLI** - Wrapper for official `omniroute` npm package.

## Installation

```bash
omni install ai --omni-route
```

This creates a wrapper that runs the official package via `npx`:
```bash
npm install -g omniroute  # Official package
```

## Usage

```bash
omniroute          # Start AI gateway on localhost:20128
omniroute --help   # Show all commands
```

Features:
- 236+ AI providers via one endpoint
- Auto-fallback to free providers  
- Smart routing with compression (15-95% token savings)
- Dashboard at `http://localhost:20128/dashboard`

## Docs

- Website: https://omniroute.online
- GitHub: https://github.com/diegosouzapw/OmniRoute
- npm: https://www.npmjs.com/package/omniroute

## Related

- `omni ia routes` - List installed AI CLI tools
- `omni ia sessions` - View active AI sessions