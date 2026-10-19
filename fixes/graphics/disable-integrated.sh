#!/usr/bin/env bash
set -euo pipefail
[[ $EUID == 0 ]]
root=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
python3 "$root/waydroid/install-launcher.py" disable
python3 "$root/waydroid/install.py" disable
python3 "$root/snap/install.py" disable
python3 "$root/flatpak/install-system.py" disable
/usr/bin/bash "$root/uninstall.sh"
