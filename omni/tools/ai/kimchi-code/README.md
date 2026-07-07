# Kimchi CLI

Terminal coding agent powered by Kimchi's multi-model orchestration by CAST AI.

**Package:** kimchi-code  
**Author:** israel676767  
**Repository:** https://github.com/israel676767/omni  
**Official:** https://github.com/getkimchi/kimchi  
**Type:** AI coding agent (Binary download)  
**License:** MIT

## Description

Kimchi is a standalone terminal coding agent — not an OpenCode plugin. It configures AI coding assistants to use CAST AI's open-source models. Terminal coding agent powered by Kimchi's multi-model orchestration.

## Dependencies

- curl, tar
- proot-distro (for Termux/Android)

## Install

```bash
omni install ai --kimchi-code
```

## Uninstall

```bash
omni uninstall ai --kimchi-code
```

## Update

```bash
omni update ai --kimchi-code
```

## Usage

```bash
kimchi                    # Launch interactive TUI
kimchi setup              # First-time configuration wizard
```

## Notes

- Binary downloaded from GitHub releases: `getkimchi/kimchi`
- Command: `kimchi`
- Data directory: `~/.local/share/omni-data/kimchi/`
- Runs inside proot-distro Ubuntu on Termux for glibc compatibility
- Switch model with `/model` or `Ctrl+P`
- Docs: https://docs.kimchi.dev
