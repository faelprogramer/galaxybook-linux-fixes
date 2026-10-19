#!/usr/bin/env bash
# One administrator authentication for the native driver and available modules.
set -euo pipefail
[[ $EUID == 0 ]]
root=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
user=${1:?Specify the desktop account}
[[ $user =~ ^[a-z_][a-z0-9_-]*$ && $(id -u "$user") -ge 1000 ]]
base=/opt/galaxybook-lakefield
if [[ ! -d $base ]]; then
 /usr/bin/bash "$root/package/install.sh" "$user"
else
 /usr/bin/bash "$root/restore.sh"
fi
(cd "$base" && sha256sum --status -c SHA256SUMS)
for file in user-environment.sh start-graphics.sh access-user.py user-access.conf uninstall.sh; do
 install -m644 "$root/$file" "$base/$file"
done
chmod 755 "$base/"*.sh "$base/access-user.py"
install -d -m755 /etc/systemd/user-environment-generators /etc/systemd/system/user@.service.d
install -m755 "$base/user-environment.sh" /etc/systemd/user-environment-generators/50-galaxybook-lakefield
install -m644 "$base/user-access.conf" /etc/systemd/system/user@.service.d/50-galaxybook-lakefield.conf
python3 - "$base" <<'MANIFEST'
from pathlib import Path
import hashlib,sys
b=Path(sys.argv[1]);p=b/'SHA256SUMS';files=['user-environment.sh','start-graphics.sh','access-user.py','user-access.conf','uninstall.sh'];lines=[x for x in p.read_text().splitlines() if not any(x.endswith('  ./'+f) for f in files)];lines.extend(hashlib.sha256((b/f).read_bytes()).hexdigest()+'  ./'+f for f in files);p.write_text('\n'.join(lines)+'\n')
MANIFEST
if [[ -f $root/package/media/manifest.json ]]; then
 python3 "$root/media/install.py" --payload "$root/package/media"
fi
systemctl daemon-reload
"$base/access-user.py" --all
if command -v flatpak >/dev/null && [[ -f $root/package/flatpak-host/manifest.json ]]; then
 python3 "$root/flatpak/install-system.py" install --payload "$root/package/flatpak-host"
fi
if ! systemctl is-active --quiet galaxybook-lakefield-graphics.service; then
 echo 'Driver preparado para o próximo reinício. Depois confirme a imagem para concluir as integrações.'
 exit 0
fi
if command -v snap >/dev/null && [[ -f $root/package/flatpak-host/manifest.json ]]; then
 python3 "$root/snap/install.py" install --payload "$root/package/flatpak-host"
fi
if command -v waydroid >/dev/null && [[ -f $root/package/waydroid/manifest.json ]]; then
 python3 "$root/waydroid/install.py" install --payload "$root/package/waydroid"
fi

if command -v waydroid >/dev/null; then python3 "$root/waydroid/install-launcher.py" install; fi
