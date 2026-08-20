#!/bin/bash
# Build a .plasmoid bundle — the format store.kde.org and
# "Get New Widgets" expect (a zip with metadata.json at the root).
#
#   ./package.sh              build every widget
#   ./package.sh corestrip    build one
set -euo pipefail

cd "$(dirname "$0")"

python3 - "$@" <<'PY'
import json
import os
import sys
import zipfile

widgets = sys.argv[1:] or sorted(
    name for name in os.listdir("widgets")
    if os.path.isfile(os.path.join("widgets", name, "package", "metadata.json"))
)

os.makedirs("dist", exist_ok=True)

for widget in widgets:
    root = os.path.join("widgets", widget, "package")
    if not os.path.isfile(os.path.join(root, "metadata.json")):
        sys.exit(f"unknown widget: {widget}")

    version = json.load(open(os.path.join(root, "metadata.json")))["KPlugin"]["Version"]
    out = os.path.join("dist", f"{widget}-{version}.plasmoid")

    with zipfile.ZipFile(out, "w", zipfile.ZIP_DEFLATED) as bundle:
        for base, dirs, files in os.walk(root):
            dirs[:] = [d for d in dirs if not d.startswith(".")]
            for name in sorted(files):
                if name.startswith("."):
                    continue
                path = os.path.join(base, name)
                bundle.write(path, os.path.relpath(path, root))

    print(out, f"({os.path.getsize(out) // 1024} KiB)")
PY
