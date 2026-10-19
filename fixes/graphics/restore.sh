#!/usr/bin/env bash
# Re-enable an intact local installation for the next boot only.
set -euo pipefail
[[ $EUID == 0 ]]
base=/opt/galaxybook-lakefield
pci=/sys/bus/pci/devices/0000:00:02.0
[[ $(uname -r) == 7.0.0-38-generic && $(cat "$base/kernel-release") == 7.0.0-38-generic ]]
[[ $(cat /sys/class/dmi/id/product_name) == 767XCL &&
   $(cat "$pci/vendor") == 0x8086 && $(cat "$pci/device") == 0x9840 &&
   $(cat "$pci/subsystem_vendor") == 0x144d && $(cat "$pci/subsystem_device") == 0xc18b ]]
(cd "$base" && sha256sum -c SHA256SUMS)
[[ $(modinfo -F lkf_experiment "$base/i915.ko") == render-media-preserve-bootfb-9840-samsung-c18b-v4 ]]
uid=$(cat "$base/target-uid")
[[ ${PKEXEC_UID:-$uid} =~ ^[0-9]+$ ]]
if systemctl is-active --quiet galaxybook-lakefield-graphics.service; then
  echo 'A correção já está ativa. Use --verify.'; exit 0
fi
install -d -m755 /etc/systemd/user-environment-generators /etc/udev/rules.d /var/lib/galaxybook-lakefield
install -m755 "$base/user-environment.sh" /etc/systemd/user-environment-generators/50-galaxybook-lakefield
install -m644 "$base/galaxybook-lakefield.service" /etc/systemd/system/galaxybook-lakefield-graphics.service
cat > /etc/udev/rules.d/99-galaxybook-lakefield-render.rules <<'RULE'
SUBSYSTEM=="drm", ENV{DEVPATH}=="/devices/pci0000:00/0000:00:02.0/drm/card[0-9]*", DRIVERS=="i915", ENV{ID_SEAT}="seat-lkf-render", TAG-="seat", TAG-="master-of-seat", TAG-="uaccess"
SUBSYSTEM=="drm", ENV{DEVPATH}=="/devices/pci0000:00/0000:00:02.0/drm/renderD[0-9]*", DRIVERS=="i915", ENV{ID_SEAT}="seat-lkf-render", TAG-="seat", TAG-="master-of-seat", TAG-="uaccess", MODE="0660"
RULE
printf '%s\n' "$(cat /proc/sys/kernel/random/boot_id)" > /var/lib/galaxybook-lakefield/pending-first-boot
udevadm control --reload-rules
install -d -m755 /etc/systemd/system/user@.service.d
install -m644 "$base/user-access.conf" /etc/systemd/system/user@.service.d/50-galaxybook-lakefield.conf
chmod 755 "$base/access-user.py"
systemctl daemon-reload
systemctl enable galaxybook-lakefield-graphics.service
echo 'Restaurada para o próximo reinício. Confirme a tela com --confirm em até 10 minutos após iniciar.'
