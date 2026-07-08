#!/usr/bin/env node

/**
 * npm/postinstall helper for Omni
 *
 * Runs when `npm install -g omni` is executed.
 * Detects Termux environment and triggers install.sh if appropriate.
 */

const fs = require('fs');
const path = require('path');
const { execSync } = require('child_process');

const isTermux = () => {
  return (
    process.env.PREFIX &&
    process.env.PREFIX.includes('/com.termux') &&
    fs.existsSync('/data/data/com.termux')
  );
};

const isAlreadyInstalled = () => {
  try {
    const symlink = process.env.PREFIX + '/bin/omni';
    const target = execSync('readlink -f "' + symlink + '"', { encoding: 'utf8' }).trim();
    const ourTarget = path.resolve(__dirname, '..', 'omni/bin/omni');
    return target === ourTarget;
  } catch {
    return false;
  }
};

const main = () => {
  if (!isTermux()) {
    console.log('[omni] Not a Termux environment — skipping install.');
    console.log('[omni] Run "bash install.sh" manually if needed.');
    process.exit(0);
  }

  if (isAlreadyInstalled()) {
    console.log('[omni] Omni is already installed and up-to-date.');
    process.exit(0);
  }

  console.log('[omni] Installing Omni for Termux...');
  try {
    execSync('bash install.sh', {
      cwd: path.resolve(__dirname, '..'),
      stdio: 'inherit',
      env: { ...process.env, OMNI_NPM_INSTALL: '1' }
    });
    console.log('[omni] Installation complete! Run "omni" to get started.');
  } catch (err) {
    console.error('[omni] Installation failed:', err.message);
    console.log('[omni] Try running "bash install.sh" manually.');
    process.exit(1);
  }
};

main();
