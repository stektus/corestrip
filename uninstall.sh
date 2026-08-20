#!/bin/bash
# Remove a widget for the current user.
#
#   ./uninstall.sh corestrip
set -euo pipefail

cd "$(dirname "$0")"

widgets=("$@")
if [ ${#widgets[@]} -eq 0 ]; then
    mapfile -t widgets < <(cd widgets && ls -d */ | tr -d /)
fi

for widget in "${widgets[@]}"; do
    root="widgets/$widget/package"
    id=$(python3 -c "import json;print(json.load(open('$root/metadata.json'))['KPlugin']['Id'])")
    kpackagetool6 --type Plasma/Applet --remove "$id"
    echo "Removed $widget ($id)"
done
