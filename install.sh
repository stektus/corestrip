#!/bin/bash
# Install (or upgrade) the widget for the current user.
set -euo pipefail

cd "$(dirname "$0")"
ID="io.github.stektus.corestrip"
TARGET="${XDG_DATA_HOME:-$HOME/.local/share}/plasma/plasmoids/$ID"

if [ -d "$TARGET" ]; then
    kpackagetool6 --type Plasma/Applet --upgrade package
else
    kpackagetool6 --type Plasma/Applet --install package
fi

echo "Installed to $TARGET"
echo "Add it from: right-click the panel -> Add or Manage Widgets... -> Corestrip"
