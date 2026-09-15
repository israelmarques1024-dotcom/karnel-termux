# AMP Code CLI

AMP Code is an AI coding agent by Sourcegraph that runs directly in your terminal.

**Package:** `@ampcode/cli`  
**Official:** https://ampcode.com  
**Type:** glibc-binary

## Installation

```bash
karnel install ai --ampcode
```

## Usage

```bash
amp                      # Start interactive mode
amp "your prompt"        # Start with an initial prompt
amp -x "your prompt"     # Execute a single task and exit
amp login                # Sign in to your Amp account
```

## Management

```bash
karnel show ai --ampcode
karnel update ai --ampcode
karnel reinstall ai --ampcode
karnel uninstall ai --ampcode
```
