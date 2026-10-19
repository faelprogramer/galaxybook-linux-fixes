#!/usr/bin/env bash
# systemd user environment generator; output only after successful boot preflight.
set -eu
base=/opt/galaxybook-lakefield
[[ -r $base/target-uid && -r /run/galaxybook-lakefield/render-node ]] || exit 0
[[ $(id -u) == $(cat "$base/target-uid") ]] || exit 0
[[ $(uname -r) == $(cat "$base/kernel-release") ]] || exit 0
IFS= read -r node < /run/galaxybook-lakefield/render-node
[[ $node == /dev/dri/renderD[0-9]* && -r $node && -w $node ]] || exit 0
[[ $(readlink -f "/sys/class/drm/${node##*/}/device") == /sys/devices/pci0000:00/0000:00:02.0 ]] || exit 0
[[ -r /sys/module/i915/lkf_experiment || -d /sys/module/i915 ]] || exit 0
printf '%s\n' \
  "LD_LIBRARY_PATH=$base/mesa/lib" \
  "LIBGL_DRIVERS_PATH=$base/mesa/lib/dri" \
  "__EGL_VENDOR_LIBRARY_FILENAMES=$base/mesa/share/glvnd/egl_vendor.d/50_mesa.json" \
  'INTEL_FORCE_PROBE=9840' \
  'MESA_LOADER_DRIVER_OVERRIDE=iris' \
  'LKF_EXPERIMENTAL_FIRMWARE_KMS=1' \
  "LKF_RENDER_NODE=$node"
if [[ -r $base/vulkan-icd-path ]]; then
  printf 'VK_DRIVER_FILES=%s\n' "$(cat "$base/vulkan-icd-path")"
fi
