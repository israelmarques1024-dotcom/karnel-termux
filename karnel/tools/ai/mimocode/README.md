# MiMoCode

Xiaomi's AI coding agent — fast, local, and open-source

**Package:** mimocode  
**Author:** israel676767  
**Repository:** https://github.com/israel676767/karnel  
**Official:** https://github.com/XiaomiMiMo/MiMo-Code  
**Type:** AI coding agent (Binary + glibc bootstrapper)  
**License:** MIT

## Description

MiMo Code is Xiaomi's AI coding agent — fast, local, and open-source. It provides intelligent code completion, refactoring suggestions, and natural language code generation directly in your terminal.

## Dependencies

- glibc-repo, glibc, clang, curl, tar

## Install

```bash
karnel install ai --mimocode
```

## Uninstall

```bash
karnel uninstall ai --mimocode
```

## Update

```bash
karnel update ai --mimocode
```

## Notes

- Native installation requires `glibc-repo`, `glibc`, `clang`, and other dependencies (installed automatically)
- The real binary is stored in `~/.local/share/karnel-data/mimocode/`
- A small C bootstrapper (`mimocode_helper.c`) handles ELF loading via the glibc dynamic linker
- Data directory: `~/.local/share/karnel-data/mimocode/`
