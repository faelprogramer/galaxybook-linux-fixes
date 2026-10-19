#!/usr/bin/env bash
# Compile as user, against the common Flatpak ABI; no driver is installed here.
set -euo pipefail
[[ $EUID != 0 ]]
root=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
cache=${XDG_CACHE_HOME:-$HOME/.cache}/galaxybook-lakefield/media
mkdir -p "$cache"
for tool in git cmake ninja python3 patchelf readelf strip flatpak; do command -v "$tool" >/dev/null; done
flatpak info org.freedesktop.Sdk//22.08 >/dev/null
fetch() {
 local folder=$1 url=$2 commit=$3
 if [[ ! -d $cache/$folder/.git ]]; then
  git init "$cache/$folder"
  git -C "$cache/$folder" remote add origin "$url"
  git -C "$cache/$folder" fetch --depth=1 origin "$commit"
  git -C "$cache/$folder" checkout --detach FETCH_HEAD
 fi
 [[ $(git -C "$cache/$folder" rev-parse HEAD) == "$commit" ]]
}
fetch media-driver https://github.com/intel/media-driver.git 1d2d8e96aeaba0471dc7fd0a7e85190519758fc5
fetch gmmlib https://github.com/intel/gmmlib.git 5f1c01f46ecbfceec59faef9bf3ba4625fc88fed
patch_id=$(sha256sum "$root/media-driver-lakefield.patch" | cut -d' ' -f1)
if [[ ! -f $cache/patched ]]; then
 git -C "$cache/media-driver" diff --quiet
 git -C "$cache/media-driver" apply --check "$root/media-driver-lakefield.patch"
 git -C "$cache/media-driver" apply "$root/media-driver-lakefield.patch"
 printf '%s\n' "$patch_id" > "$cache/patched"
fi
[[ $(cat "$cache/patched") == "$patch_id" ]] || { echo 'Patch alterado: use um novo XDG_CACHE_HOME.'; exit 1; }
flatpak run --unshare=network --filesystem="$cache" --command=sh org.freedesktop.Sdk//22.08 -eu -c '
 r=$1
 cmake -S "$r/gmmlib" -B "$r/gmm-build22" -G Ninja -DCMAKE_BUILD_TYPE=Release -DBUILD_TYPE=Release -DRUN_TEST_SUITE=OFF -DCMAKE_INSTALL_PREFIX="$r/prefix22" -DCMAKE_INSTALL_LIBDIR=lib
 ninja -C "$r/gmm-build22" -j2
 cmake --install "$r/gmm-build22"
 export PKG_CONFIG_PATH="$r/prefix22/lib/pkgconfig:$r/prefix22/lib64/pkgconfig"
 cmake -S "$r/media-driver" -B "$r/media-build22" -G Ninja -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX="$r/prefix22" -DCMAKE_INSTALL_LIBDIR=lib -DCMAKE_SKIP_RPATH=ON -DMEDIA_BUILD_HARDENING=ON -DENABLE_KERNELS=OFF -DBUILD_CMRTLIB=OFF -DGEN8=OFF -DGEN9=OFF -DGEN11=ON -DGEN11_ICLLP=ON -DGEN11_JSL=OFF -DGEN12=OFF -DMTL=OFF -DARL=OFF -DBMG=OFF -DLNL=OFF -DNVL=OFF -DPTL=OFF -DEncode_VME_Supported=no -DEncode_VDEnc_Supported=no -DCommon_Encode_Supported=no -DJPEG_Encode_Supported=no -DAV1_Decode_Supported=no -DVVC_Decode_Supported=no -DVP_SFC_Supported=no
 ninja -C "$r/media-build22" -j2
 DESTDIR="$r/stage22" cmake --install "$r/media-build22"
' sh "$cache"
python3 "$root/package.py" "$cache" "$root/../package/media"
