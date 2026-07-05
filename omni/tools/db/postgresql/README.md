# PostgreSQL

Advanced open-source relational database

**Package:** postgresql  
**Author:** israel676767  
**Repository:** https://github.com/israel676767/omni  
**Official:** https://www.postgresql.org  
**Type:** Database (pkg)  
**License:** PostgreSQL License

## Description

PostgreSQL is a powerful, open-source object-relational database system with over 30 years of active development. It has a strong reputation for reliability, feature robustness, and performance. Omni Catalyst includes a dedicated manager (`omni pg`) for starting, stopping, and managing PostgreSQL instances.

## Dependencies

- Installed via pkg
- Data directory managed by `omni pg`

## Install

```bash
omni install db --postgresql
```

## Uninstall

```bash
omni uninstall db --postgresql
```

## Update

```bash
omni update db --postgresql
```

## Notes

- Managed via `omni pg` commands (start, stop, restart, status, init, create, drop, list, shell)
- Logs: `~/.cache/omni/postgresql.log`
- Automatic data directory detection
- Support for existing installations

