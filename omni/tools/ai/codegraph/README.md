# CodeGraph

Analyzes your codebase structure and dependencies to improve navigation

**Package:** codegraph  
**Author:** israel676767  
**Repository:** https://github.com/israel676767/omni  
**Official:** https://github.com/colbymchenry/codegraph  
**Type:** Code analysis tool (Binary)  
**License:** MIT

## Description

CodeGraph analyzes your codebase structure and dependencies to improve navigation. It generates interactive graphs showing relationships between files, functions, classes, and modules, making it easier to navigate and refactor large projects.

## Dependencies

- nodejs-lts, ripgrep, sqlite, git, python, clang, make, curl

## Install

```bash
omni install ai --codegraph
```

## Uninstall

```bash
omni uninstall ai --codegraph
```

## Update

```bash
omni update ai --codegraph
```

## Notes

- Downloads the latest ARM64 binary from GitHub releases
- Wrapper script installed to `$PREFIX/bin/codegraph`
- Data stored in `$OMNI_DATA/codegraph-linux-arm64/`

