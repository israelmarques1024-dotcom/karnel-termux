# Herdr — terminal AI assistant

[Herdr](https://herdr.dev) is a fast terminal AI assistant CLI, distributed by the
Herdr project and integrated into Karnel Termux as a managed utility.

## Install

```bash
karnel install utils --herdr
```

The installer:
- Resolves the latest release via the official manifest at `https://herdr.dev/latest.json`.
- Verifies the SHA-256 checksum before extracting.
- Installs atomically into `$PREFIX/bin/herdr` and writes a Karnel ownership marker
  (`.karnel-wrapper-herdr`) so the binary is tracked.
- Honors `TMPDIR` / `KARNEL_CACHE` (never hardcodes `/tmp`, which is broken on Termux).

## Uninstall / Update

```bash
karnel uninstall utils --herdr   # clean removal, only the managed binary
karnel update utils --herdr      # re-fetch and re-verify latest release
```

## Usage

```bash
herdr --help
herdr --version
```

See https://herdr.dev for full documentation.
