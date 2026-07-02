import os

replacements = {
    "Omni-Catalyst": "Omni",
    "omni-catalyst": "omni",
    "israelCapivaraOmniCatalyst": "israel marques",
    "Israel Marques": "israel marques"
}

project_dir = "/data/data/com.termux/files/home/omni"

for root, dirs, files in os.walk(project_dir):
    if '.git' in dirs:
        dirs.remove('.git')
    for file in files:
        if file == 'replace.py':
            continue
        filepath = os.path.join(root, file)
        try:
            with open(filepath, 'r', encoding='utf-8') as f:
                content = f.read()
            
            new_content = content
            for old, new in replacements.items():
                new_content = new_content.replace(old, new)
            
            if new_content != content:
                with open(filepath, 'w', encoding='utf-8') as f:
                    f.write(new_content)
                print(f"Updated {filepath}")
        except Exception as e:
            pass
