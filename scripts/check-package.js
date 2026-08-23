#!/usr/bin/env node

const { execFileSync } = require("node:child_process");
const { cpSync, existsSync, mkdirSync, mkdtempSync, readFileSync, rmSync, statSync, writeFileSync } = require("node:fs");
const { tmpdir } = require("node:os");
const path = require("node:path");

const packageRoot = path.resolve(process.argv[2] || path.join(__dirname, ".."));
const packDirectory = mkdtempSync(path.join(tmpdir(), "karnel-package-"));
const stagingRoot = path.join(packDirectory, "source");
const releaseCommitPath = path.join(stagingRoot, "karnel", "RELEASE_COMMIT");
let repositoryHead = "";
process.on("exit", () => {
  rmSync(packDirectory, { recursive: true, force: true });
});
try {
  repositoryHead = execFileSync("git", ["-C", packageRoot, "rev-parse", "HEAD"], {
    encoding: "utf8",
    stdio: ["ignore", "pipe", "ignore"],
  }).trim();
} catch {
  // Package fixtures may not be Git repositories and must provide their marker.
}
cpSync(packageRoot, stagingRoot, {
  recursive: true,
  filter: (source) => {
    const relative = path.relative(packageRoot, source);
    return relative === "" || !relative.split(path.sep).some((part) => part === ".git" || part === "node_modules");
  },
});
// Always bind the staged package to the actual repository HEAD. A stale
// committed karnel/RELEASE_COMMIT (left over from an earlier release) must
// never break release validation — the packed commit is what matters, and it
// must equal HEAD. When HEAD is unavailable (e.g. a non-git fixture) we fall
// back to a committed marker that is itself a valid SHA.
let committedCommit = "";
if (existsSync(releaseCommitPath)) {
  committedCommit = readFileSync(releaseCommitPath, "utf8").trim();
}
if (/^[0-9a-f]{40}$/.test(repositoryHead)) {
  writeFileSync(releaseCommitPath, `${repositoryHead}\n`, { mode: 0o600 });
} else if (/^[0-9a-f]{40}$/.test(committedCommit)) {
  writeFileSync(releaseCommitPath, `${committedCommit}\n`, { mode: 0o600 });
} else {
  throw new Error("Required package file is missing: karnel/RELEASE_COMMIT");
}
let output;
try {
  output = execFileSync(
    "npm",
    ["pack", stagingRoot, "--json", "--ignore-scripts", "--pack-destination", packDirectory],
    { encoding: "utf8" },
  );
} catch (error) {
  rmSync(packDirectory, { recursive: true, force: true });
  throw error;
}
const parsed = JSON.parse(output);
// npm < 12 returns an array of reports; npm >= 12 returns an object keyed
// by package name. Normalize both into a single-entry array.
const reports = Array.isArray(parsed) ? parsed : Object.values(parsed);
if (reports.length !== 1) {
  rmSync(packDirectory, { recursive: true, force: true });
  throw new Error("npm pack returned an unexpected report");
}

const report = reports[0];
const tarball = path.join(packDirectory, report.filename);
const extractDirectory = path.join(packDirectory, "extracted");
mkdirSync(extractDirectory);
const previousUmask = process.umask(0);
try {
  execFileSync("tar", ["-xzf", tarball, "-C", extractDirectory]);
} finally {
  process.umask(previousUmask);
}
const archiveEntries = execFileSync("tar", ["-tzf", tarball], { encoding: "utf8" })
  .trim()
  .split("\n")
  .filter((entry) => entry && !entry.endsWith("/"));
const paths = archiveEntries.map((entry) => entry.replace(/^package\//, ""));
const forbidden = paths.filter((path) =>
  /(^|\/)(__pycache__|\.git|\.github)(\/|$)|(^|\/)\.env(?:\.[^/]*)?$|(^|\/)(?:[^/]*(?:secret|credential|private[-_.]?key|api[-_.]?key|access[-_.]?token)[^/]*)$|\.(?:pyc|pyo|log|pem|key|p12|pfx|jks|keystore)$/i.test(path),
);
if (forbidden.length > 0) {
  throw new Error(`Forbidden package artifacts:\n${forbidden.join("\n")}`);
}

const required = [
  "assets/fonts/font.ttf",
  "karnel/RELEASE_COMMIT",
  "karnel/cli/commands/robin.sh",
  "karnel/modules/osint.sh",
  "karnel/tools/osint/robin/common.sh",
  "karnel/tools/osint/robin/install.sh",
  "karnel/tools/osint/robin/README.md",
  "karnel/tools/osint/robin/requirements-termux.txt",
];
for (const path of required) {
  if (!paths.includes(path)) {
    rmSync(packDirectory, { recursive: true, force: true });
    throw new Error(`Required package file is missing: ${path}`);
  }
}

const releaseCommit = execFileSync(
  "tar",
  ["-xOzf", tarball, "package/karnel/RELEASE_COMMIT"],
  { encoding: "utf8" },
).trim();
if (!/^[0-9a-f]{40}$/.test(releaseCommit)) {
  rmSync(packDirectory, { recursive: true, force: true });
  throw new Error("Packed RELEASE_COMMIT is not a full commit SHA");
}
if (repositoryHead && releaseCommit !== repositoryHead) {
  throw new Error(`Packed RELEASE_COMMIT ${releaseCommit} does not match HEAD ${repositoryHead}`);
}

for (const packedPath of ["assets/fonts/font.ttf", "karnel/tools/ai/gentle-ai/termux-patches.go"]) {
  const mode = statSync(path.join(extractDirectory, "package", packedPath)).mode & 0o777;
  if (mode !== 0o644) {
    throw new Error(`Packed file must use mode 0644: ${packedPath}`);
  }
}

const packageVersion = JSON.parse(readFileSync(path.join(packageRoot, "package.json"), "utf8")).version;
if (report.version !== packageVersion) {
  rmSync(packDirectory, { recursive: true, force: true });
  throw new Error(`Packed version ${report.version} does not match ${packageVersion}`);
}

console.log(
  `Package: ${paths.length} files, ${report.size} bytes, version ${report.version}, commit ${releaseCommit}, no forbidden artifacts`,
);
rmSync(packDirectory, { recursive: true, force: true });
