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
  "LIBGL_DRIVERS_PATH=$base/mesa/lib/dri:/var/lib/snapd/lib/gl/dri:/usr/lib/x86_64-linux-gnu/GL/host/lib/dri" \
  "__EGL_VENDOR_LIBRARY_DIRS=$base/mesa/share/glvnd/egl_vendor.d:/var/lib/snapd/lib/glvnd/egl_vendor.d:/usr/lib/x86_64-linux-gnu/GL/glvnd/egl_vendor.d:/usr/share/glvnd/egl_vendor.d" \
  'INTEL_FORCE_PROBE=9840' \
  'MESA_LOADER_DRIVER_OVERRIDE=iris' \
  'LKF_EXPERIMENTAL_FIRMWARE_KMS=1' \
  "LKF_RENDER_NODE=$node"
# Vulkan uses native distribution ICDs with the private library search path,
# and container-native driver discovery.
# Do not export host-only absolute ICD/vendor filenames into sandboxes.

# Old Snap Vulkan loaders require the legacy variable; Flatpak filters it.
# A SONAME chooses the native private driver or Snap driver through its loader path.
if [[ -f /var/lib/snapd/lib/vulkan/icd.d/00_galaxybook_lakefield.json ]]; then
 printf '%s\n' 'VK_ICD_FILENAMES=/var/lib/snapd/lib/vulkan/icd.d/00_galaxybook_lakefield.json'
fi
