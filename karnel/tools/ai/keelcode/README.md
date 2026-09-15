# KeelCode

KeelCode is a hosted coding-agent CLI from KeelCode AI.

- Official package: `@keelcode-ai/keelcode`
- Command: `keelcode`
- Homepage: https://keelcode.ai
- License: SEE LICENSE (proprietary)

## Termux compatibility

KeelCode is distributed as pre-built binaries for Linux (glibc) and does not officially support Android/Bionic libc. Karnel Termux provides a compatibility shim that:

1. Installs the official npm package `@keelcode-ai/keelcode`.
2. Downloads the `linux-arm64` native binary alongside the launcher.
3. Wraps the execution with `grun` (from the `glibc-runner` Termux package) to provide the expected glibc runtime.

**Requirements:**
- `glibc-runner` (from `glibc-repo`)
- Node.js (npm)

**Note:** This is an adaptation to make the tool functional on Termux. The underlying binary remains the official KeelCode build.

## Lifecycle

```bash
karnel install ai --keelcode
karnel update ai --keelcode
karnel reinstall ai --keelcode
karnel uninstall ai --keelcode
```
