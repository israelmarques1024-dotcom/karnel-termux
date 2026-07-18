#!/usr/bin/env node

const { execFileSync } = require("node:child_process");

const output = execFileSync(
  "npm",
  ["pack", "--dry-run", "--json", "--ignore-scripts"],
  { encoding: "utf8" },
);
const reports = JSON.parse(output);
if (!Array.isArray(reports) || reports.length !== 1) {
  throw new Error("npm pack returned an unexpected report");
}

const report = reports[0];
const paths = report.files.map((file) => file.path);
const forbidden = paths.filter((path) =>
  /(^|\/)(__pycache__|\.git|\.github)(\/|$)|\.(pyc|pyo|log)$/i.test(path),
);
if (forbidden.length > 0) {
  throw new Error(`Forbidden package artifacts:\n${forbidden.join("\n")}`);
}

const required = [
  "karnel/cli/commands/robin.sh",
  "karnel/modules/osint.sh",
  "karnel/tools/osint/robin/common.sh",
  "karnel/tools/osint/robin/install.sh",
  "karnel/tools/osint/robin/README.md",
  "karnel/tools/osint/robin/requirements-termux.txt",
];
for (const path of required) {
  if (!paths.includes(path)) {
    throw new Error(`Required package file is missing: ${path}`);
  }
}

const packageVersion = require("../package.json").version;
if (report.version !== packageVersion) {
  throw new Error(`Packed version ${report.version} does not match ${packageVersion}`);
}

console.log(
  `Package: ${report.entryCount} files, ${report.size} bytes, version ${report.version}, no forbidden artifacts`,
);
