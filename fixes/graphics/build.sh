#!/usr/bin/env bash
# Reproduce the exact, locally validated Samsung Lakefield experiment.
# Run as the desktop user. Source compilation is never done as administrator.
set -euo pipefail
[[ $EUID != 0 ]] || { echo 'Execute a compilação como usuário comum.' >&2; exit 1; }
root=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
[[ $(uname -r) == 7.0.0-38-generic ]] || { echo 'Kernel fora da versão validada.' >&2; exit 1; }
[[ $(dpkg-query -W -f='${Version}' linux-source-7.0.0) == 7.0.0-38.38 ]] || {
  echo 'É necessário o código-fonte Ubuntu 7.0.0-38.38.' >&2; exit 1;
}
[[ -d /usr/src/linux-source-7.0.0/drivers/gpu/drm/i915 &&
   -d /lib/modules/$(uname -r)/build ]] || exit 1
for tool in gcc g++ make python3 meson ninja patch curl sha256sum strip pkg-config; do
  command -v "$tool" >/dev/null || { echo "Dependência ausente: $tool" >&2; exit 1; }
done
pkg-config --exists libdrm expat libzstd libudev wayland-client wayland-server \
  wayland-egl-backend wayland-protocols libglvnd x11 xcb-dri3 xcb-present xcb-sync xshmfence
jobs=${JOBS:-2}
[[ $jobs =~ ^[1-4]$ ]] || exit 1
cache=${XDG_CACHE_HOME:-$HOME/.cache}/galaxybook-lakefield/builds
mkdir -p "$cache"
patch_id=$(cat "$root/patches/i915-lakefield-render-only.patch" \
  "$root/patches/mesa-lakefield-firmware-kms.patch" | sha256sum | cut -c1-12)
work=$cache/7.0.0-38-$patch_id
mkdir -p "$work"
archive=$cache/mesa-26.0.8.tar.xz
if [[ ! -f $archive ]]; then
  curl --fail --location --proto '=https' --tlsv1.2 \
    https://archive.mesa3d.org/mesa-26.0.8.tar.xz -o "$archive.download"
  mv -- "$archive.download" "$archive"
fi
printf '%s  %s\n' caf1c0061a68e88dfa74967a7e780c0e85d65b6c4e334cd69095a5dc54ad78bc "$archive" | sha256sum -c -
if [[ ! -f $work/kernel-ready ]]; then
  [[ ! -e $work/i915 ]] || { echo 'Compilação parcial: use outro diretório de cache.' >&2; exit 1; }
  cp -a /usr/src/linux-source-7.0.0/drivers/gpu/drm/i915 "$work/i915"
  (cd "$work/i915" && patch --fuzz=0 --batch -p1 < "$root/patches/i915-lakefield-render-only.patch")
  python3 - "$work/i915" <<'PY'
import sys
from pathlib import Path
root=Path(sys.argv[1])
p=root/'Makefile';s=p.read_text()
line='obj-$(CONFIG_DRM_I915_GVT_KVMGT) += kvmgt.o'
assert s.count(line)==1
s=s.replace(line,'# External render-only experiment excludes kvmgt module.')
s+='\nccflags-y += -I/usr/src/linux-source-7.0.0/drivers/gpu/drm/i915\n'
p.write_text(s)
for p in root.rglob('*.h'):
 s=p.read_text()
 if '../../drivers/gpu/drm/i915' in s:
  p.write_text(s.replace('../../drivers/gpu/drm/i915',str(root)))
PY
  touch "$work/kernel-ready"
fi
make -C "/lib/modules/$(uname -r)/build" M="$work/i915" -j"$jobs" modules
if [[ ! -f $work/mesa-ready ]]; then
  [[ ! -e $work/mesa-26.0.8 ]] || { echo 'Fonte Mesa parcial: use outro diretório de cache.' >&2; exit 1; }
  tar -xf "$archive" -C "$work"
  (cd "$work/mesa-26.0.8" && patch --fuzz=0 --batch -p1 < "$root/patches/mesa-lakefield-firmware-kms.patch")
  touch "$work/mesa-ready"
fi
setup=()
[[ ! -f $work/mesa-build/meson-private/coredata.dat ]] || setup+=(--reconfigure)
meson setup "${setup[@]}" "$work/mesa-build" "$work/mesa-26.0.8" \
  --prefix=/opt/galaxybook-lakefield/mesa --libdir=lib --buildtype=release \
  -Dgallium-drivers=iris,llvmpipe -Dvulkan-drivers=intel -Dplatforms=x11,wayland \
  -Dglx=dri -Dglvnd=enabled -Degl=enabled -Dgbm=enabled -Dllvm=enabled \
  -Dvideo-codecs=[] -Dgallium-va=disabled -Dgallium-rusticl=false \
  -Dgles1=disabled -Dgles2=enabled -Dbuild-tests=false
ninja -C "$work/mesa-build" -j"$jobs"
DESTDIR="$work/stage" meson install -C "$work/mesa-build"
package=$work/package
mkdir -p "$package/payload/bin"
payload=$package/payload
mkdir -p "$payload/mesa"
cp -a "$work/stage/opt/galaxybook-lakefield/mesa/." "$payload/mesa/"
cp "$work/i915/i915.ko" "$payload/i915.ko"
strip --strip-debug "$payload/i915.ko"
cp "$root"/{start-graphics.sh,user-environment.sh,first-boot-monitor.sh,recover-first-boot.sh,uninstall.sh,galaxybook-lakefield.service} "$payload/"
cp "$root/install.sh" "$package/install.sh"
chmod 755 "$payload"/*.sh "$package/install.sh"
printf '%s\n' 7.0.0-38-generic > "$payload/kernel-release"
gcc -O2 -Wall -Wextra -Werror \
  -I"$work/mesa-26.0.8/include" -I"$work/mesa-26.0.8/src/gbm/main" \
  $(pkg-config --cflags libdrm) "$root/sources/gbm-smoke.c" \
  -L"$payload/mesa/lib" -Wl,-rpath,/opt/galaxybook-lakefield/mesa/lib \
  -lEGL -lGLESv2 -lgbm -ldrm -o "$payload/bin/gbm-smoke"
icds=("$payload/mesa/share/vulkan/icd.d/"intel_icd*.json)
[[ ${#icds[@]} == 1 && -f ${icds[0]} ]] || exit 1
printf '/opt/galaxybook-lakefield/mesa/share/vulkan/icd.d/%s\n' \
  "$(basename "${icds[0]}")" > "$payload/vulkan-icd-path"
(cd "$payload" && find . -type f ! -name SHA256SUMS -print0 | sort -z | xargs -0 sha256sum > SHA256SUMS)
if [[ ! -e $root/package && ! -L $root/package ]]; then ln -s -- "$package" "$root/package"; fi
printf '\nPacote compilado: %s\n'  "$package"
printf 'Instalação: pkexec /usr/bin/bash %q %q\n' "$package/install.sh" "$USER"
printf '%s\n' 'A instalação não reinicia a sessão atual. O primeiro arranque exige validação da imagem.'
