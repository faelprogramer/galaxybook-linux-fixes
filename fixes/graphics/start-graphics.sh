#!/usr/bin/env bash
# Exact-machine experimental rendering support. Firmware keeps panel control.
set -euo pipefail
[[ $EUID == 0 ]] || exit 1
base=/opt/galaxybook-lakefield
state=/run/galaxybook-lakefield
pci=/sys/bus/pci/devices/0000:00:02.0
mkdir -p "$state"
rm -f -- "$state/render-node"
log() { printf '%s\n' "$*"; logger -t galaxybook-lakefield -- "$*"; }
# A new kernel must be reviewed/rebuilt explicitly, never forced to use this .ko.
expected_kernel=$(cat "$base/kernel-release")
if [[ $(uname -r) != "$expected_kernel" ]]; then
  log "Kernel $(uname -r) is outside the validated build $expected_kernel; retaining stock software graphics."
  exit 0
fi
[[ $(cat /sys/class/dmi/id/product_name) == 767XCL &&
   $(cat "$pci/vendor") == 0x8086 && $(cat "$pci/device") == 0x9840 &&
   $(cat "$pci/subsystem_vendor") == 0x144d && $(cat "$pci/subsystem_device") == 0xc18b ]] || exit 1
[[ ! -e /sys/module/i915 && ! -L $pci/driver ]] || {
  log 'A GPU driver is already present; refusing to replace it.'; exit 1;
}
[[ $(cat /sys/class/graphics/fb0/name) == simpledrmdrmfb &&
   -d $pci/simple-framebuffer.0 ]] || exit 1
[[ $(modinfo -F lkf_experiment "$base/i915.ko") == render-only-preserve-bootfb-9840-samsung-c18b-v2 ]] || exit 1
[[ $(modinfo -F vermagic "$base/i915.ko") == "$expected_kernel "* ]] || exit 1
loaded=0
failure() {
  rc=$?
  trap - EXIT
  if ((rc)); then
    rm -f -- "$state/render-node"
    if [[ $loaded == 1 ]]; then rmmod i915 || true; fi
    log "Preflight failed (status $rc); no private graphics environment enabled."
  fi
  exit "$rc"
}
trap failure EXIT
IFS=, read -r -a dependencies <<< "$(modinfo -F depends "$base/i915.ko")"
for dep in "${dependencies[@]}"; do [[ -z $dep ]] || modprobe -- "$dep"; done
insmod "$base/i915.ko" force_probe=9840 enable_guc=0 disable_display=1
loaded=1
[[ $(readlink -f "$pci/driver") == /sys/bus/pci/drivers/i915 ]] || exit 1
nodes=("$pci"/drm/renderD*)
[[ ${#nodes[@]} == 1 && -e ${nodes[0]} ]] || exit 1
node=/dev/dri/$(basename "${nodes[0]}")
cards=("$pci"/drm/card[0-9]*)
[[ ${#cards[@]} == 1 && -e ${cards[0]} ]] || exit 1
uid=$(cat "$base/target-uid")
ready=0
for ((i=0;i<48;i++)); do
  if [[ -e $node &&
        $(udevadm info -q property "${cards[0]}" | sed -n 's/^ID_SEAT=//p') == seat-lkf-render ]]; then
    ready=1
    break
  fi
  sleep 0.25
done
[[ $ready == 1 && $(cat /sys/class/graphics/fb0/name) == simpledrmdrmfb ]] || exit 1
# Grant only the selected local user access; do not assign device ownership
# to a non-system account in udev.
setfacl -m "u:$uid:rw" "$node"
# A real shader + PRIME framebuffer import must pass before user sessions
# receive the private driver paths. The framebuffer is never displayed here.
env -u LIBGL_ALWAYS_SOFTWARE -u GALLIUM_DRIVER -u MESA_GL_VERSION_OVERRIDE \
  LD_LIBRARY_PATH="$base/mesa/lib" LIBGL_DRIVERS_PATH="$base/mesa/lib/dri" \
  __EGL_VENDOR_LIBRARY_FILENAMES="$base/mesa/share/glvnd/egl_vendor.d/50_mesa.json" \
  INTEL_FORCE_PROBE=9840 MESA_LOADER_DRIVER_OVERRIDE=iris \
  LKF_EXPERIMENTAL_FIRMWARE_KMS=1 LKF_RENDER_NODE="$node" \
  timeout --kill-after=2s 35s "$base/bin/gbm-smoke" /dev/dri/card0 > "$state/preflight.log" 2>&1
printf '%s\n' "$node" > "$state/render-node.tmp"
chmod 644 "$state/render-node.tmp"
mv -f -- "$state/render-node.tmp" "$state/render-node"
"$base/access-user.py" --all
log "Validated rendering and firmware framebuffer sharing on $node; user graphics environment enabled."

if [[ -f /var/lib/galaxybook-lakefield/pending-first-boot ]]; then
  systemd-run --no-block --unit=galaxybook-lakefield-first-boot-monitor --collect \
    --property=Type=oneshot --property=TimeoutStartSec=620 \
    /usr/bin/bash "$base/first-boot-monitor.sh"
fi
