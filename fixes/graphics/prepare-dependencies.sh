#!/usr/bin/env bash
# Pinned Ubuntu source/build prerequisites; no graphics configuration changes.
set -euo pipefail
[[ $EUID == 0 && $(uname -m) == x86_64 && $(uname -r) == 7.0.0-38-generic ]] || exit 1
[[ $(cat /sys/class/dmi/id/product_name) == 767XCL ]] || exit 1
apt-get -o DPkg::Lock::Timeout=180 install -y --no-install-recommends \
  linux-source-7.0.0=7.0.0-38.38 linux-headers-7.0.0-38-generic \
  git cmake patchelf libva-dev vainfo ffmpeg libigdgmm-dev libpciaccess-dev acl build-essential meson ninja-build pkg-config curl patch python3-mako python3-ply \
  bison flex libdrm-dev libexpat1-dev zlib1g-dev libzstd-dev libudev-dev \
  llvm-21-dev libclang-21-dev libclang-cpp21-dev libclc-21-dev libclc-21 \
  libllvmspirvlib-21-dev spirv-tools spirv-tools-dev glslang-tools \
  libwayland-dev libwayland-egl-backend-dev wayland-protocols libglvnd-dev \
  libx11-dev libx11-xcb-dev libxext-dev libxfixes-dev libxrandr-dev libxxf86vm-dev \
  libxcb-dri2-0-dev libxcb-dri3-dev libxcb-glx0-dev libxcb-present-dev \
  libxcb-sync-dev libxcb-xfixes0-dev libxcb-randr0-dev libxcb-shm0-dev \
  libxcb-keysyms1-dev libxshmfence-dev libvulkan-dev vulkan-tools mesa-utils
[[ $(dpkg-query -W -f='${Version}' linux-source-7.0.0) == 7.0.0-38.38 ]] || exit 1
if [[ ! -f /usr/src/linux-source-7.0.0/drivers/gpu/drm/i915/Makefile ]]; then
  tar --no-same-owner -xf /usr/src/linux-source-7.0.0.tar.bz2 -C /usr/src
fi
printf '%s\n' 'Dependências preparadas. Nenhum driver foi ativado por este passo.'
