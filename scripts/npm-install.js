#!/usr/bin/env node

/**
 * npm/postinstall helper for Karnel
 *
 * Runs when `npm install -g karnel` is executed.
 * Detects Termux environment and triggers install.sh if appropriate.
 *
 * This script is OPTIONAL — the `karnel` CLI works from the npm bin symlink
 * without it. The full install clones the repo and sets up dependencies.
 */

const fs = require('fs');
const path = require('path');
const { execSync, execFileSync } = require('child_process');

const isTermux = () => {
  return (
    process.env.PREFIX &&
    process.env.PREFIX.includes('/com.termux') &&
    fs.existsSync('/data/data/com.termux')
  );
};

const npmConfigGet = (key) => {
  try {
    return execSync(`npm config get ${key} 2>/dev/null`, { encoding: 'utf8' }).trim();
  } catch {
    return '';
  }
};

const isPostinstallBlocked = () => {
  const ignoreScripts = npmConfigGet('ignore-scripts');
  if (ignoreScripts === 'true') return true;
  const allowScripts = npmConfigGet('allow-scripts');
  if (allowScripts && !allowScripts.includes('karnel-termux')) return true;
  return false;
};

const isAlreadyInstalled = () => {
  try {
    const symlink = process.env.PREFIX + '/bin/karnel';
    const target = execFileSync('readlink', ['-f', symlink], { encoding: 'utf8' }).trim();
    const ourTarget = path.resolve(__dirname, '..', 'karnel/bin/karnel');
    return target === ourTarget;
  } catch {
    return false;
  }
};

const binSymlinkExists = () => {
  try {
    const symlink = process.env.PREFIX + '/bin/karnel';
    return fs.existsSync(symlink);
  } catch {
    return false;
  }
};

const enforceNpmSponsorPolicy = () => {
  try {
    const home = process.env.HOME;
    if (!home) return;

    const configBase = process.env.XDG_CONFIG_HOME || path.join(home, '.config');
    const configDir = path.join(configBase, 'karnel');
    const sourceFile = path.join(configDir, 'install-source');
    const stateFile = path.join(configDir, 'sponsors');

    fs.mkdirSync(configDir, { recursive: true, mode: 0o700 });
    fs.writeFileSync(sourceFile, 'npm\n', { encoding: 'utf8', mode: 0o600 });
    fs.writeFileSync(stateFile, 'off\n', { encoding: 'utf8', mode: 0o600 });
    fs.chmodSync(sourceFile, 0o600);
    fs.chmodSync(stateFile, 0o600);
  } catch (error) {
    console.warn('[karnel] Could not persist npm sponsor policy:', error.message);
  }
};

const main = () => {
  if (!isTermux()) {
    console.log('[karnel] Not a Termux environment — skipping install.');
    console.log('[karnel] Run "bash install.sh" manually if needed.');
    process.exit(0);
  }

  enforceNpmSponsorPolicy();

  if (isAlreadyInstalled()) {
    console.log('[karnel] Karnel is already installed and up-to-date.');
    process.exit(0);
  }

  if (isPostinstallBlocked()) {
    console.log('[karnel] Postinstall blocked by npm allow-scripts/ignore-scripts.');
    console.log('[karnel] The karnel CLI is already available via npm bin symlink.');
    console.log('[karnel] Run "karnel --version" to verify it works.');
    console.log('[karnel] For full setup, run:');
    console.log('[karnel]   npm install -g --allow-scripts=karnel-termux karnel-termux');
    console.log('[karnel]   # or manually: bash install.sh');
    process.exit(0);
  }

  if (binSymlinkExists()) {
    console.log('[karnel] Updating Karnel for Termux...');
  } else {
    console.log('[karnel] Installing Karnel for Termux...');
  }

  try {
    execSync('bash install.sh', {
      cwd: path.resolve(__dirname, '..'),
      stdio: 'inherit',
      env: { ...process.env, KARNEL_NPM_INSTALL: '1' }
    });
    enforceNpmSponsorPolicy();
    console.log('[karnel] Installation complete! Run "karnel" to get started.');
  } catch (err) {
    console.error('[karnel] Installation failed:', err.message);
    console.log('[karnel] Try running "bash install.sh" manually.');
    process.exit(1);
  }
};

main();
