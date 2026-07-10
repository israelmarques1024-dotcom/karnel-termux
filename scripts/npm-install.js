#!/usr/bin/env node

/**
 * npm/postinstall helper for Karnel
 *
 * Runs when `npm install -g karnel` is executed.
 * Detects Termux environment and triggers install.sh if appropriate.
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

  console.log('[karnel] Installing Karnel for Termux...');
  try {
    execSync('bash install.sh', {
      cwd: path.resolve(__dirname, '..'),
      stdio: 'inherit',
      env: { ...process.env, KARNEL_NPM_INSTALL: '1' }
    });
    console.log('[karnel] Installation complete! Run "karnel" to get started.');
  } catch (err) {
    console.error('[karnel] Installation failed:', err.message);
    console.log('[karnel] Try running "bash install.sh" manually.');
    process.exit(1);
  }
};

main();
