#!/usr/bin/env bash
# Build Android libraries separately: Linux/Flatpak libraries cannot run on Bionic.
set -euo pipefail
[[ $EUID != 0 ]]
root=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)
cache=${XDG_CACHE_HOME:-$HOME/.cache}/galaxybook-lakefield/android
mkdir -p "$cache/empty-pc"
ndk=${ANDROID_NDK_HOME:?Set ANDROID_NDK_HOME to the extracted official Android NDK r30}
[[ -x $ndk/toolchains/llvm/prebuilt/linux-x86_64/bin/x86_64-linux-android33-clang ]]
archive=$cache/mesa-26.0.8.tar.xz
if [[ ! -f $archive ]]; then
 curl --fail --location --proto '=https' --tlsv1.2 https://archive.mesa3d.org/mesa-26.0.8.tar.xz -o "$archive.download"
 mv "$archive.download" "$archive"
fi
printf '%s  %s\n' caf1c0061a68e88dfa74967a7e780c0e85d65b6c4e334cd69095a5dc54ad78bc "$archive" | sha256sum -c -
if [[ ! -f $cache/patched ]]; then
 [[ ! -e $cache/mesa-26.0.8 ]]
 tar -xf "$archive" -C "$cache"
 (cd "$cache/mesa-26.0.8" && patch --batch --fuzz=0 -p1 < "$root/patches/mesa-lakefield-firmware-kms.patch")
 touch "$cache/patched"
fi
python3 - "$cache" "$ndk" <<'CROSS'
from pathlib import Path
import sys
cache,ndk=map(Path,sys.argv[1:]);tc=ndk/'toolchains/llvm/prebuilt/linux-x86_64/bin'
lines=['[binaries]',f"c = '{tc}/x86_64-linux-android33-clang'",f"cpp = ['{tc}/x86_64-linux-android33-clang++', '-fno-exceptions', '-fno-unwind-tables', '-fno-asynchronous-unwind-tables', '-static-libstdc++']",f"ar = '{tc}/llvm-ar'",f"strip = '{tc}/llvm-strip'","pkg-config = 'pkg-config'",'[host_machine]',"system = 'android'","cpu_family = 'x86_64'","cpu = 'x86_64'","endian = 'little'",'[properties]','needs_exe_wrapper = true',f"pkg_config_libdir = '{cache}/empty-pc'"]
(cache/'cross.ini').write_text('\n'.join(lines)+'\n')
CROSS
export PATH="${XDG_CACHE_HOME:-$HOME/.cache}/galaxybook-lakefield/native-tools:$PATH"
reconfigure=; [[ ! -f $cache/build/meson-private/coredata.dat ]] || reconfigure=--reconfigure
meson setup $reconfigure --cross-file "$cache/cross.ini" "$cache/build" "$cache/mesa-26.0.8" \
 --prefix=/vendor --libdir=lib64 --buildtype=release --force-fallback-for=libdrm,expat \
 -Dplatforms=android -Dplatform-sdk-version=33 -Dandroid-stub=true \
 -Dandroid-libbacktrace=disabled -Dperfetto=disabled -Degl=enabled -Dglx=disabled \
 -Dglvnd=disabled -Dgles1=enabled -Dgles2=enabled -Dgbm=enabled \
 -Degl-lib-suffix=_mesa -Dgles-lib-suffix=_mesa \
 -Dgallium-drivers=iris -Dvulkan-drivers=intel -Dllvm=disabled -Dmesa-clc=system \
 -Dzstd=disabled -Dgallium-va=disabled -Dvideo-codecs=[] -Dbuild-tests=false -Dspirv-tools=disabled
ninja -C "$cache/build" -j1
DESTDIR="$cache/stage" meson install -C "$cache/build"
printf 'Android staging: %s\n' "$cache/stage/vendor"

mkdir -p "$root/package"
python3 "$root/waydroid/package.py" "$cache/stage/vendor" "$root/package/waydroid" "$ndk/toolchains/llvm/prebuilt/linux-x86_64/bin/llvm-strip"
