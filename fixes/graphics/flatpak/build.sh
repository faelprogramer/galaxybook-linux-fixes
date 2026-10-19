#!/usr/bin/env bash
# Build graphics userspace against the oldest supported Flatpak ABI, not Ubuntu.
set -euo pipefail
[[ $EUID != 0 ]]
root=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)
cache=${XDG_CACHE_HOME:-$HOME/.cache}/galaxybook-lakefield/flatpak
mkdir -p "$cache"
flatpak info org.freedesktop.Sdk//22.08 >/dev/null
native=${XDG_CACHE_HOME:-$HOME/.cache}/galaxybook-lakefield/native-tools
mkdir -p "$cache/tools"
for tool in mesa_clc vtn_bindgen2 glslangValidator; do
 [[ -x $native/$tool ]] || { echo 'Compile primeiro a solução principal para gerar os compiladores Mesa.'; exit 1; }
 printf '#!/usr/bin/env bash\nexec flatpak-spawn --host --directory="$PWD" %q "$@"\n' "$native/$tool" > "$cache/tools/$tool"
 chmod 755 "$cache/tools/$tool"
done
archive=$cache/mesa-26.0.8.tar.xz
if [[ ! -f $archive ]]; then
 curl --fail --location --proto '=https' --tlsv1.2 https://archive.mesa3d.org/mesa-26.0.8.tar.xz -o "$archive.download"
 mv -- "$archive.download" "$archive"
fi
printf '%s  %s\n' caf1c0061a68e88dfa74967a7e780c0e85d65b6c4e334cd69095a5dc54ad78bc "$archive" | sha256sum -c -
if [[ ! -f $cache/patched ]]; then
 [[ ! -e $cache/mesa-26.0.8 ]]
 tar -xf "$archive" -C "$cache"
 (cd "$cache/mesa-26.0.8" && patch --batch --fuzz=0 -p1 < "$root/patches/mesa-lakefield-firmware-kms.patch")
 touch "$cache/patched"
fi
if [[ ! -f $cache/container-path-patched ]]; then
 (cd "$cache/mesa-26.0.8" && patch --batch --fuzz=0 -p1 < "$root/patches/mesa-container-driver-path.patch")
 touch "$cache/container-path-patched"
fi
# Small pinned Python build dependencies are installed only in the build cache.
if [[ ! -d $cache/pydeps22/yaml ]]; then
 flatpak run --share=network --filesystem="$cache" --command=python3 org.freedesktop.Sdk//22.08 \
  -m pip install --target="$cache/pydeps22" meson==1.9.1 PyYAML==6.0.3 Mako==1.3.10 MarkupSafe==3.0.4 packaging==25.0
fi
if [[ ! -d $cache/protocols/share/wayland-protocols ]]; then
 mkdir -p "$cache/protocols/share" "$cache/protocols/lib/pkgconfig"
 cp -a /usr/share/wayland-protocols "$cache/protocols/share/"
 version=$(pkg-config --modversion wayland-protocols)
 printf 'prefix=%s\n pkgdatadir=${prefix}/share/wayland-protocols\nName: Wayland Protocols\nDescription: Protocol XML definitions\nVersion: %s\n' "$cache/protocols" "$version" > "$cache/protocols/lib/pkgconfig/wayland-protocols.pc"
fi
# Restrict source/build access to this cache, with no network during compilation.
flatpak run --unshare=network --talk-name=org.freedesktop.Flatpak --filesystem="$cache" --command=sh org.freedesktop.Sdk//22.08 -eu -c '
 cache=$1
 export PATH="$cache/pydeps22/bin:$cache/tools:$PATH"
 export PYTHONPATH="$cache/pydeps22"
 export PKG_CONFIG_PATH="$cache/protocols/lib/pkgconfig"
 if [ -f "$cache/build22/meson-private/coredata.dat" ]; then reconfigure=--reconfigure; else reconfigure=; fi
 meson setup $reconfigure "$cache/build22" "$cache/mesa-26.0.8" \
 --prefix=/usr/lib/x86_64-linux-gnu/GL/host --libdir=lib --buildtype=release \
 -Dgallium-drivers=iris,softpipe -Dvulkan-drivers=intel -Dplatforms=x11,wayland \
 -Dglx=dri -Dglvnd=enabled -Degl=enabled -Dgbm=enabled -Dllvm=disabled -Dmesa-clc=system \
 -Dvideo-codecs=[] -Dgallium-va=disabled -Dgallium-rusticl=false \
 -Dgles1=disabled -Dgles2=enabled -Dbuild-tests=false
 ninja -C "$cache/build22" -j2
 DESTDIR="$cache/stage22" meson install -C "$cache/build22"
 ' sh "$cache"
printf 'Flatpak payload: %s\n' "$cache/stage22/usr/lib/x86_64-linux-gnu/GL/host"
mkdir -p "$root/package"
python3 "$root/flatpak/package.py" "$cache/stage22/usr/lib/x86_64-linux-gnu/GL/host" "$root/package/flatpak-host"
