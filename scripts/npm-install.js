#!/usr/bin/env node

/**
 * npm/postinstall helper for Karnel
 *
 * Runs when `npm install -g karnel-termux` is executed.
 * Detects Termux environment and triggers install.sh if appropriate.
 *
 * This script is OPTIONAL — the `karnel` CLI works from the npm bin symlink
 * without it. The full install clones the repo and sets up dependencies.
 */

const fs = require('fs');
const path = require('path');
const { execSync, execFileSync } = require('child_process');
const packageVersion = require('../package.json').version;
const releaseCommitPath = path.resolve(__dirname, '../karnel/RELEASE_COMMIT');

const isTermux = () => {
  if (process.env.KARNEL_TEST_TERMUX === '1') return true;
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
    const dataHome = process.env.XDG_DATA_HOME || path.join(process.env.HOME, '.local/share');
    const installedTarget = path.join(dataHome, 'karnel', 'karnel/bin/karnel');
    return target === installedTarget && fs.existsSync(path.join(dataHome, 'karnel', '.git'));
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

const main = () => {
  if (!isTermux()) {
    console.log('[karnel] Not a Termux environment — skipping install.');
    console.log('[karnel] Run "bash install.sh" manually if needed.');
    process.exit(0);
  }

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
    const releaseCommit = fs.readFileSync(releaseCommitPath, 'utf8').trim();
    if (!/^[0-9a-f]{40}$/.test(releaseCommit)) {
      throw new Error('package contains an invalid RELEASE_COMMIT');
    }
    execFileSync('bash', ['install.sh', '--ref', `v${packageVersion}`, '--commit', releaseCommit], {
      cwd: path.resolve(__dirname, '..'),
      stdio: 'inherit',
      env: process.env
    });
    console.log('[karnel] Installation complete! Run "karnel" to get started.');
  } catch (err) {
    console.error('[karnel] Installation failed:', err.message);
    console.log('[karnel] Try running "bash install.sh" manually.');
    process.exit(1);
  }
};

main();
