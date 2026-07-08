# openspec

Spec-Driven Development framework for AI workflow orchestration.

## What is it?

[openspec](https://github.com/fission-ai/openspec) bridges human intent and AI output with structured technical specifications. It stores specs in an `/openspec/` directory to guide AI agents toward accurate, maintainable code.

## Install

```bash
omni install ai --openspec
```

## Usage

```bash
# Initialize openspec in current project
openspec init

# Create a proposal
openspec proposal create "Feature Name"

# Generate spec from proposal
openspec spec generate
```

## Requirements

- Node.js (install with `omni install lang --nodejs`)

---

*Source: devcorex/core-termux, adapted for Omni by israel marques*
