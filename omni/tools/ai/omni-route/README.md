# omniRoute

**AI CLI Manager with Web Interface for Termux**

A simple web-based interface to manage and run installed AI CLI tools.

## Installation

```bash
omni install ai --omni-route
```

## Usage

```bash
omni-route start   # Start web interface
omni-route stop    # Stop web interface  
omni-route status  # Check status

# Open in browser:
# http://localhost:7331
```

## Features

- Visual grid of installed AI CLIs (opencode, claude, gemini, ollama, etc.)
- One-click launch from web interface
- Shows installation status for each tool
- Glassmorphism UI design optimized for Termux

## Dependencies

- Python 3 + Flask (auto-installed via pip)
- Installed AI CLIs (install via `omni install ai`)

## Related

- Run `omni ia sessions` to view active sessions
- Run `omni ia routes` to view installed AI CLI paths