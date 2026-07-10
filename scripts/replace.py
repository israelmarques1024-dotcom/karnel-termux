import os
import sys

replacements = {
    "Omni-Catalyst": "Omni",
    "omni-catalyst": "omni",
}

project_dir = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))

if not os.path.isdir(project_dir):
    print(f"Directory not found: {project_dir}", file=sys.stderr)
    sys.exit(1)

for root, dirs, files in os.walk(project_dir):
    if ".git" in dirs:
        dirs.remove(".git")
    if "node_modules" in dirs:
        dirs.remove("node_modules")
    for file in files:
        if file == "replace.py":
            continue
        filepath = os.path.join(root, file)
        try:
            with open(filepath, "r", encoding="utf-8") as f:
                content = f.read()
            new_content = content
            for old, new in replacements.items():
                new_content = new_content.replace(old, new)
            if new_content != content:
                with open(filepath, "w", encoding="utf-8") as f:
                    f.write(new_content)
                print(f"Updated {filepath}")
        except (OSError, UnicodeDecodeError):
            pass
