# Oh-My-Pi (omp)

Enhanced AI coding agent — standalone binary built with `bun build --compile`.

**Repository:** https://github.com/can1357/oh-my-pi  
**Author:** Can Boluk  
**Type:** AI coding agent (standalone binary + native Rust addons)

## Description

Oh-My-Pi is an enhanced version of the Pi coding agent with:
- Native Rust addons: AST grep, diff, syntax highlighting, fuzzy find, shell execution
- Session management, resume, and history
- Multi-model support with various LLM providers
- Tool system: Edit, read, bash, LSP, PTY, and web tools
- MCP support for extensibility

## Installation

```bash
karnel install ai --oh-my-pi
```

## Usage

```bash
omp --help
omp --version
omp                           # Interactive session
omp -p "Explain this codebase"  # One-shot prompt
```

## Management

```bash
karnel update ai --oh-my-pi
karnel reinstall ai --oh-my-pi
karnel uninstall ai --oh-my-pi
```
