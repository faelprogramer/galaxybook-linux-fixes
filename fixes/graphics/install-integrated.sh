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
# The source installation entry point must match the selected local account.
[[ $(cat "$base/target-uid") == $(id -u "$user") ]]
(cd "$base" && sha256sum --status -c SHA256SUMS)
install -m755 "$root/user-environment.sh" "$base/user-environment.sh"
install -d -m755 /etc/systemd/user-environment-generators
install -m755 "$base/user-environment.sh" /etc/systemd/user-environment-generators/50-galaxybook-lakefield
# Update only this changed core script in the payload's own integrity manifest.
python3 - "$base" <<'PY'
from pathlib import Path
import hashlib,sys
base=Path(sys.argv[1]);p=base/'SHA256SUMS';lines=p.read_text().splitlines()
assert sum(s.endswith('  ./user-environment.sh') for s in lines)==1
p.write_text('\n'.join(hashlib.sha256((base/'user-environment.sh').read_bytes()).hexdigest()+'  ./user-environment.sh' if s.endswith('  ./user-environment.sh') else s for s in lines)+'\n')
PY
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
