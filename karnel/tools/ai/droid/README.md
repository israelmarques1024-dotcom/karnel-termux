# Factory Droid CLI

**Droid** is an enterprise-grade AI coding agent from Factory. It operates in your terminal to plan, implement, test, and review code across your entire codebase.

- **Official Site:** https://factory.ai/product/cli
- **GitHub:** https://github.com/Factory-AI/factory
- **Documentation:** https://docs.factory.ai/cli/getting-started/quickstart

## Usage

```bash
droid                  # Start interactive session
droid exec "query"     # Headless task execution
droid login            # Authenticate with Factory
droid --version        # Show version
```

On Termux, Droid runs from an Ubuntu proot-distro container and installs the
pinned `@factory/cli@0.190.0` npm package there.
