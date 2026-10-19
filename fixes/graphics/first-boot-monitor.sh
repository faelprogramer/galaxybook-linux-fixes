#!/usr/bin/env bash
# One-time reversible installation validation. Confirmation contains only boot ID.
set -euo pipefail
[[ $EUID == 0 ]] || exit 1
base=/opt/galaxybook-lakefield
pending=/var/lib/galaxybook-lakefield/pending-first-boot
[[ -f $pending ]] || exit 0
home=$(cat "$base/target-home")
boot_id=$(cat /proc/sys/kernel/random/boot_id)
confirmation=$home/.cache/galaxybook-lakefield/confirmed-boot
systemd-run --unit=galaxybook-lakefield-first-boot-recovery --on-active=600s \
  /usr/bin/bash "$base/recover-first-boot.sh"
for ((i=0;i<610;i++)); do
  if [[ -f $confirmation && ! -L $confirmation ]] &&
     [[ $(head -c 64 -- "$confirmation") == "$boot_id" ]]; then
    systemctl stop galaxybook-lakefield-first-boot-recovery.timer
    rm -f -- "$pending"
    logger -t galaxybook-lakefield 'First boot display confirmed; automatic rollback cancelled.'
    exit 0
  fi
  sleep 1
done
