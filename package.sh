#!/bin/bash
# Build a .plasmoid bundle — the format store.kde.org and
# "Get New Widgets" expect (a zip with metadata.json at the root).
set -euo pipefail

cd "$(dirname "$0")"

python3 - <<'PY'
import json
import os
import zipfile

meta = json.load(open("package/metadata.json"))
version = meta["KPlugin"]["Version"]
os.makedirs("dist", exist_ok=True)
out = os.path.join("dist", f"corestrip-{version}.plasmoid")

with zipfile.ZipFile(out, "w", zipfile.ZIP_DEFLATED) as bundle:
    for root, dirs, files in os.walk("package"):
        dirs[:] = [d for d in dirs if not d.startswith(".")]
        for name in sorted(files):
            if name.startswith("."):
                continue
            path = os.path.join(root, name)
            bundle.write(path, os.path.relpath(path, "package"))

print(out, f"({os.path.getsize(out) // 1024} KiB)")
PY
