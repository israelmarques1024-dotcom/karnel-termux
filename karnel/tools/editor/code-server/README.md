# code-server

VS Code in the browser, running on Termux.

## What is it?

[code-server](https://github.com/coder/code-server) lets you run VS Code on any machine and access it in the browser. On Termux/Android, it gives you a full VS Code experience without needing a desktop environment.

## Install

```bash
karnel install editor --code-server
```

## Usage

```bash
# Start code-server (binds to localhost:8080 by default)
code-server .

# Start on a specific port
code-server . --bind-addr 0.0.0.0:8080

# Start with a password
code-server . --auth password
```

Then open `http://localhost:8080` in your browser.

## How it works

- Uses `tur-repo` package repository (required for Termux)
- Installs via `pkg install code-server`
- Runs as a local web server
- Access via any browser on the device

## Notes

- For best experience, use a Chromium-based browser
- The terminal inside code-server uses Termux's shell
- Extensions install normally through the VS Code marketplace
- First run generates a config at `~/.config/code-server/config.yaml`
