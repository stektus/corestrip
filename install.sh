#!/bin/bash
# Install (or upgrade) a widget for the current user.
#
#   ./install.sh              install every widget
#   ./install.sh corestrip    install one
set -euo pipefail

cd "$(dirname "$0")"

widgets=("$@")
if [ ${#widgets[@]} -eq 0 ]; then
    mapfile -t widgets < <(cd widgets && ls -d */ | tr -d /)
fi

for widget in "${widgets[@]}"; do
    root="widgets/$widget/package"
    if [ ! -f "$root/metadata.json" ]; then
        echo "unknown widget: $widget" >&2
        exit 1
    fi

    id=$(python3 -c "import json;print(json.load(open('$root/metadata.json'))['KPlugin']['Id'])")
    target="${XDG_DATA_HOME:-$HOME/.local/share}/plasma/plasmoids/$id"

    if [ -d "$target" ]; then
        kpackagetool6 --type Plasma/Applet --upgrade "$root"
    else
        kpackagetool6 --type Plasma/Applet --install "$root"
    fi

    echo "Installed $widget to $target"
done

echo "Add them from: right-click the panel -> Add or Manage Widgets..."
