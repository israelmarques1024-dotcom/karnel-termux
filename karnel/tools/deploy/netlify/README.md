# Netlify CLI

Command-line client installed globally from the `netlify-cli` npm package.
Karnel pins fresh installs to `netlify-cli@27.1.1` and requires Node.js 22.13.0
or newer. The `update` action follows the npm package's current published
version rather than reapplying the fresh-install pin.

- Install: `karnel install deploy --netlify`
- Update: `karnel update deploy --netlify`
- Reinstall: `karnel reinstall deploy --netlify`
- Uninstall: `karnel uninstall deploy --netlify`
- Executable: `netlify`
- Requirements: Node.js `>=22.13.0`, npm, and network access to the npm registry
