#!/usr/bin/env node
const { execSync } = require("child_process");
const path = require("path");
const fs = require("fs");

const PROJECT = process.cwd();

const BINDINGS = {
  "lightningcss": { android: "lightningcss-android-arm64", linux: "lightningcss-linux-arm64-gnu" },
  "@tailwindcss/oxide": { android: "@tailwindcss/oxide-android-arm64", linux: "@tailwindcss/oxide-linux-arm64-gnu" },
  "@unrs/resolver-binding": { android: "@unrs/resolver-binding-android-arm64", linux: "@unrs/resolver-binding-linux-arm64-gnu" },
};

function detectPM() {
  if (fs.existsSync(path.join(PROJECT, "pnpm-lock.yaml"))) return "pnpm";
  if (fs.existsSync(path.join(PROJECT, "yarn.lock"))) return "yarn";
  if (fs.existsSync(path.join(PROJECT, "bun.lockb"))) return "bun";
  return "npm";
}

function findPnpmParentDir(pkg) {
  const pnpmDir = path.join(PROJECT, "node_modules", ".pnpm");
  if (!fs.existsSync(pnpmDir)) return null;
  try {
    const entries = fs.readdirSync(pnpmDir);
    const prefix = pkg.replace("/", "+") + "@";
    for (const e of entries) {
      if (e.startsWith(prefix)) {
        const inner = path.join(pnpmDir, e, "node_modules", pkg, "node_modules");
        return fs.existsSync(inner) ? inner : null;
      }
    }
  } catch {}
  return null;
}

function variantExists(pkg, variant) {
  if (fs.existsSync(path.join(PROJECT, "node_modules", variant))) return true;
  const pnpmParent = findPnpmParentDir(pkg);
  if (pnpmParent && fs.existsSync(path.join(pnpmParent, variant))) return true;
  return false;
}

function getAndroidVersion(pkg) {
  const pnpmParent = findPnpmParentDir(pkg);
  if (pnpmParent) {
    const androidDir = path.join(pnpmParent, BINDINGS[pkg].android);
    const pkgFile = path.join(androidDir, "package.json");
    if (fs.existsSync(pkgFile)) {
      return JSON.parse(fs.readFileSync(pkgFile, "utf8")).version;
    }
  }
  const dir = path.join(PROJECT, "node_modules", BINDINGS[pkg].android);
  const pkgFile = path.join(dir, "package.json");
  if (fs.existsSync(pkgFile)) {
    return JSON.parse(fs.readFileSync(pkgFile, "utf8")).version;
  }
  return null;
}

function main() {
  if (process.platform !== "linux") process.exit(0);

  const pm = detectPM();
  if (!pm) process.exit(0);

  let changed = false;

  for (const [parentPkg, pair] of Object.entries(BINDINGS)) {
    const parentDir = path.join(PROJECT, "node_modules", parentPkg);
    if (!fs.existsSync(parentDir)) {
      const pnpmParent = findPnpmParentDir(parentPkg);
      if (!pnpmParent) continue;
    }

    if (variantExists(parentPkg, pair.linux)) continue;
    if (!variantExists(parentPkg, pair.android)) continue;

    const ver = getAndroidVersion(parentPkg);
    if (!ver) continue;

    const spec = `${pair.linux}@${ver}`;
    process.stdout.write(`  Installing ${spec}... `);
    try {
      execSync(`${pm} add ${spec}`, { cwd: PROJECT, stdio: "pipe", timeout: 60000 });
      process.stdout.write("\u2713\n");
      changed = true;
    } catch (e) {
      process.stdout.write(`\u2717 (${e.message.split("\n")[0]})\n`);
    }
  }

  if (changed) process.stdout.write("\n");
}

main();
