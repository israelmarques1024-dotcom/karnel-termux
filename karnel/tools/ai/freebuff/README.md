# Freebuff

A 100% free coding agent, right from your terminal

**Package:** freebuff  
**Author:** israel676767  
**Repository:** https://github.com/israel676767/karnel-termux  
**Official:** https://freebuff.com
**Releases:** https://github.com/CodebuffAI/codebuff
**Type:** AI coding agent (Binary + glibc bootstrapper)  
**License:** MIT

## Description

Freebuff is the free coding agent: a free CLI coding agent and Freebuff Web, the free way to build full-stack apps. No subscription, no setup, no lock-in. Karnel Termux offers two installation methods: native with glibc support for best performance, or via proot-distro Ubuntu container for maximum compatibility.

## Dependencies

- **Native mode:** glibc-repo, glibc, clang, git, curl, tar
- **Proot mode:** proot-distro, curl, ca-certificates, tar

## Install

```bash
karnel install ai --freebuff
```

You will be prompted to choose:

1. **Native (recommended)** — Compiles a glibc bootstrapper and downloads the latest Freebuff binary from GitHub releases
2. **Proot-distro (alternative)** — Runs Freebuff inside an Ubuntu proot-distro container

## Uninstall

```bash
karnel uninstall ai --freebuff
```

## Update

```bash
karnel update ai --freebuff
```

## Notes

- **Native mode** requires `glibc-repo`, `glibc`, `clang`, and other dependencies (installed automatically)
- The native binary is stored in `~/.local/share/karnel-data/freebuff/`
- A small C bootstrapper (`freebuff_helper.c`) handles ELF loading via the glibc dynamic linker
- **Proot mode** uses `proot-distro ubuntu` and downloads the binary directly inside the container
- Version is fetched automatically from GitHub releases (`CodebuffAI/codebuff-community`)
- Data directory: `~/.local/share/karnel-data/freebuff/`
