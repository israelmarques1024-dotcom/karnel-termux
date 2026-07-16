# Karnel CLI Reference

```bash
karnel <command> [arguments]
```

With no command, Karnel opens its interactive interface when a terminal is
available and prints help in noninteractive contexts.

## Top-level commands

| Command | Purpose |
|---|---|
| `karnel --version` | Print the installed version |
| `karnel help` | Print command and module help |
| `karnel install` | Install modules or selected tools |
| `karnel uninstall` | Remove modules or selected tools |
| `karnel reinstall` | Reinstall modules or selected tools |
| `karnel update` | Update modules or the framework |
| `karnel upgrade` | Upgrade the Karnel framework checkout |
| `karnel list` | List module tools |
| `karnel show` | Show bundled tool documentation |
| `karnel open` | Open official web documentation |
| `karnel search` | Search tools and stored memories |
| `karnel status` | Print a concise system overview |
| `karnel doctor` | Open diagnostics; see below |
| `karnel brain` | Manage the local second-brain store |
| `karnel env` | Manage shell environment exports |
| `karnel voice` | Capture speech and dispatch an AI agent |
| `karnel ia` | Manage AI sessions, routes, and installation |
| `karnel init` | Configure or scaffold supported project templates |
| `karnel deploy` | Deploy with Vercel, Railway, or Netlify |
| `karnel pg` | Manage PostgreSQL |
| `karnel start` | Start supported services |
| `karnel backup` | Back up Termux and Karnel configuration |
| `karnel restore` | Restore a backup |
| `karnel cleanup` | Clean caches, logs, and temporary files |

Run a command without required arguments to see its command-specific usage.

## Doctor

Doctor has exactly two operational subcommands:

```bash
karnel doctor termux [--quick] [--fix]
karnel doctor code [options] [directory]
```

`karnel doctor` defaults to `karnel doctor termux`.

### Termux

```bash
karnel doctor termux
karnel doctor termux --quick
karnel doctor termux --fix
```

Termux mode runs more than 30 health sections across Android resources,
permissions, package managers, runtimes, PostgreSQL, Karnel, AI commands, shell
configuration, processes, storage, and networking.

### Code

```bash
karnel doctor code
karnel doctor code --standard /path/to/project
karnel doctor code --deep --json /path/to/project
karnel doctor code --fix /path/to/project
```

| Option | Description |
|---|---|
| `--quick`, `-q` | Run the quick registry set; default |
| `--standard`, `-s` | Add security, dependency, coverage, dead-code, and complexity checks |
| `--deep`, `-d` | Run all 76 registered definitions |
| `--fix`, `--safe-fix` | Apply fixes classified as safe |
| `--aggressive-fix` | Also apply fixes without a safe classification |
| `--json`, `-j` | Emit standalone JSON |
| `--help`, `-h` | Print code-analysis help |

See the [complete Doctor reference](../doctor/README.md) for check counts,
supported ecosystems, tools, reports, JSON schema, and safety details.
