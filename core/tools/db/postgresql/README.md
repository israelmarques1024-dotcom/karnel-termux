# PostgreSQL

Advanced open-source relational database

**Package:** postgresql  
**Author:** israel676767  
**Repository:** https://github.com/israel676767/omni  
**Official:** https://www.postgresql.org  
**Type:** Database (pkg)  
**License:** PostgreSQL License

## Description

PostgreSQL is a powerful, open-source object-relational database system with over 30 years of active development. It has a strong reputation for reliability, feature robustness, and performance. Omni Catalyst includes a dedicated manager (`core pg`) for starting, stopping, and managing PostgreSQL instances.

## Dependencies

- Installed via pkg
- Data directory managed by `core pg`

## Install

```bash
core install db --postgresql
```

## Uninstall

```bash
core uninstall db --postgresql
```

## Update

```bash
core update db --postgresql
```

## Notes

- Managed via `core pg` commands (start, stop, restart, status, init, create, drop, list, shell)
- Logs: `~/.cache/omni/postgresql.log`
- Automatic data directory detection
- Support for existing installations

