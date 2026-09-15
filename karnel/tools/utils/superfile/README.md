# SuperFile

SuperFile is a terminal file manager from yorukot.

- Official source: https://github.com/yorukot/superfile
- Pinned release: `v1.5.0`
- Pinned commit: `fe41cef5e9ee5b16e79981540c49f932a3d4d249`
- Command: `spf`

Karnel builds the pinned release from source with Go. The checkout is kept in `$KARNEL_DATA/superfile` and each build stages a replacement before installing the binary.

## Lifecycle

```bash
karnel install utils --superfile
karnel update utils --superfile
karnel reinstall utils --superfile
karnel uninstall utils --superfile
```
