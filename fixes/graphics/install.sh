#!/usr/bin/env bash
# Install an already built and validated payload. Never replaces distro Mesa.
set -euo pipefail
[[ $EUID == 0 ]] || { echo 'Administrator authentication required.' >&2; exit 1; }
source_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
target_user=${1:?Specify the local account that will use the GPU}
[[ $target_user =~ ^[a-z_][a-z0-9_-]*$ ]] || exit 1
uid=$(id -u "$target_user")
[[ $uid -ge 1000 ]] || exit 1
home=$(getent passwd "$target_user" | cut -d: -f6)
[[ -d $home && $home == /* ]] || exit 1
base=/opt/galaxybook-lakefield
pci=/sys/bus/pci/devices/0000:00:02.0
[[ $(cat /sys/class/dmi/id/product_name) == 767XCL &&
   $(cat "$pci/vendor") == 0x8086 && $(cat "$pci/device") == 0x9840 &&
   $(cat "$pci/subsystem_vendor") == 0x144d && $(cat "$pci/subsystem_device") == 0xc18b ]] || exit 1
[[ $(uname -r) == $(cat "$source_dir/payload/kernel-release") ]] || exit 1
[[ ! -e $base && ! -L $base &&
   ! -e /etc/systemd/system/galaxybook-lakefield-graphics.service &&
   ! -e /etc/systemd/user-environment-generators/50-galaxybook-lakefield &&
   ! -e /etc/udev/rules.d/99-galaxybook-lakefield-render.rules ]] || {
  echo 'Installation path/configuration already exists; refusing to overwrite.' >&2; exit 1;
}
(cd "$source_dir/payload" && sha256sum -c SHA256SUMS)
[[ $(modinfo -F lkf_experiment "$source_dir/payload/i915.ko") == render-media-preserve-bootfb-9840-samsung-c18b-v4 ]] || exit 1
# If a validated temporary render driver is already active, check the exact
# staged GLVND/GBM payload before making any persistent filesystem changes.
render_nodes=("$pci"/drm/renderD*)
if [[ ${#render_nodes[@]} == 1 && -e ${render_nodes[0]} ]]; then
  node=/dev/dri/$(basename "${render_nodes[0]}")
  staged=$source_dir/payload/mesa
  env -u LIBGL_ALWAYS_SOFTWARE -u GALLIUM_DRIVER -u MESA_GL_VERSION_OVERRIDE \
    LD_LIBRARY_PATH="$staged/lib" LIBGL_DRIVERS_PATH="$staged/lib/dri" \
    GBM_BACKENDS_PATH="$staged/lib/gbm" \
    __EGL_VENDOR_LIBRARY_FILENAMES="$staged/share/glvnd/egl_vendor.d/50_mesa.json" \
    INTEL_FORCE_PROBE=9840 MESA_LOADER_DRIVER_OVERRIDE=iris \
    LKF_EXPERIMENTAL_FIRMWARE_KMS=1 LKF_RENDER_NODE="$node" \
    timeout --kill-after=2s 35s "$source_dir/payload/bin/gbm-smoke" /dev/dri/card0
fi

install -d -m755 /opt
cp -a -- "$source_dir/payload" "$base"
chown -R root:root "$base"
chmod -R go-w "$base"
printf '%s\n' "$uid" > "$base/target-uid"
printf '%s\n' "$home" > "$base/target-home"
install -d -m755 /etc/systemd/user-environment-generators /etc/udev/rules.d \
  /var/lib/galaxybook-lakefield
install -m644 "$base/galaxybook-lakefield.service" \
  /etc/systemd/system/galaxybook-lakefield-graphics.service
install -m755 "$base/user-environment.sh" \
  /etc/systemd/user-environment-generators/50-galaxybook-lakefield
# Match the direct i915 DRM nodes, never the firmware simple-framebuffer child.
cat > /etc/udev/rules.d/99-galaxybook-lakefield-render.rules <<RULE
SUBSYSTEM=="drm", ENV{DEVPATH}=="/devices/pci0000:00/0000:00:02.0/drm/card[0-9]*", DRIVERS=="i915", ENV{ID_SEAT}="seat-lkf-render", TAG-="seat", TAG-="master-of-seat", TAG-="uaccess"
SUBSYSTEM=="drm", ENV{DEVPATH}=="/devices/pci0000:00/0000:00:02.0/drm/renderD[0-9]*", DRIVERS=="i915", ENV{ID_SEAT}="seat-lkf-render", TAG-="seat", TAG-="master-of-seat", TAG-="uaccess", MODE="0660"
RULE
install -d -m700 -o "$uid" -g "$(id -g "$target_user")" \
  "$home/.cache/galaxybook-lakefield"
printf '%s\n' "$(cat /proc/sys/kernel/random/boot_id)" > \
  /var/lib/galaxybook-lakefield/pending-first-boot
udevadm control --reload-rules
install -d -m755 /etc/systemd/system/user@.service.d
install -m644 "$base/user-access.conf" /etc/systemd/system/user@.service.d/50-galaxybook-lakefield.conf
chmod 755 "$base/access-user.py"
systemctl daemon-reload
systemd-analyze verify /etc/systemd/system/galaxybook-lakefield-graphics.service
systemctl enable galaxybook-lakefield-graphics.service
printf '%s\n' 'Installed for next boot. Current graphics session was not restarted.' \
  'First boot automatically rolls back after 10 minutes unless the usable display is confirmed.'
