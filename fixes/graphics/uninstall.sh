#!/usr/bin/env bash
# Disable future activation without unloading a GPU used by a running desktop.
set -euo pipefail
[[ $EUID == 0 ]] || exit 1
systemctl disable galaxybook-lakefield-graphics.service || true
systemctl stop galaxybook-lakefield-first-boot-recovery.timer || true
rm -f -- /etc/systemd/user-environment-generators/50-galaxybook-lakefield
rm -f -- /etc/udev/rules.d/99-galaxybook-lakefield-render.rules
rm -f -- /etc/systemd/system/galaxybook-lakefield-graphics.service
rm -f -- /run/galaxybook-lakefield/render-node
rm -f -- /var/lib/galaxybook-lakefield/pending-first-boot
rm -f -- /etc/systemd/system/user@.service.d/50-galaxybook-lakefield.conf
systemctl daemon-reload
udevadm control --reload-rules
printf '%s\n' 'Disabled. Reboot to return to stock graphics. Private files retained for rollback/history.'
