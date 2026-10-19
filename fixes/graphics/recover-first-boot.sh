#!/usr/bin/env bash
# Restore stock graphics after an unconfirmed first boot; private files retained.
set -euo pipefail
[[ $EUID == 0 ]] || exit 1
[[ -f /var/lib/galaxybook-lakefield/pending-first-boot ]] || exit 0
systemctl disable galaxybook-lakefield-graphics.service
rm -f -- /etc/systemd/user-environment-generators/50-galaxybook-lakefield
rm -f -- /etc/udev/rules.d/99-galaxybook-lakefield-render.rules
rm -f -- /run/galaxybook-lakefield/render-node
mv -- /var/lib/galaxybook-lakefield/pending-first-boot \
  /var/lib/galaxybook-lakefield/first-boot-rolled-back
systemctl daemon-reload
udevadm control --reload-rules
logger -t galaxybook-lakefield 'Unconfirmed first boot: private GPU setup disabled; rebooting to stock graphics.'
systemctl reboot
