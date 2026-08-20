#!/bin/bash
# Remove the widget for the current user.
set -euo pipefail

kpackagetool6 --type Plasma/Applet --remove io.github.stektus.corestrip
echo "Removed. Remove it from the panel first if it is still there."
