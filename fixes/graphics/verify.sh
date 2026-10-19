#!/usr/bin/env bash
# Read-only checks: require an Intel renderer and a compositor submitting work.
set -euo pipefail
base=/opt/galaxybook-lakefield
[[ $(uname -r) == 7.0.0-38-generic ]] || { echo 'Kernel fora da versão validada.'; exit 1; }
systemctl is-active --quiet galaxybook-lakefield-graphics.service
[[ $(readlink -f /sys/bus/pci/devices/0000:00:02.0/driver) == /sys/bus/pci/drivers/i915 ]]
[[ $(modinfo -F lkf_experiment "$base/i915.ko") == render-only-preserve-bootfb-9840-samsung-c18b-v2 ]]
[[ -r /run/galaxybook-lakefield/render-node ]]
info=$(glxinfo -B 2>&1)
printf '%s\n' "$info"
/usr/bin/grep -q 'Accelerated: yes' <<< "$info"
/usr/bin/grep -q 'OpenGL renderer string: Mesa Intel(R) UHD Graphics (Lakefield experimental)' <<< "$info"
python3 - <<'PY'
import os,re
from pathlib import Path
found=False
for proc in Path('/proc').iterdir():
 if not proc.name.isdigit(): continue
 try:
  if proc.stat().st_uid!=os.getuid() or (proc/'comm').read_text().strip()!='gnome-shell': continue
  maps=(proc/'maps').read_text()
  assert '/opt/galaxybook-lakefield/mesa/lib/libgallium' in maps, 'Desktop não carregou a Mesa privada.'
  engine=0
  for f in (proc/'fdinfo').iterdir():
   try: s=f.read_text()
   except OSError: continue
   if re.search(r'^drm-driver:\s+i915$',s,re.M):
    m=re.search(r'^drm-engine-render:\s+(\d+) ns',s,re.M)
    if m: engine=max(engine,int(m[1]))
  assert engine>0, 'Ainda não foi observada renderização do desktop na GPU; mova uma janela e tente novamente.'
  print(f'Desktop GNOME: GPU Intel ativa; tempo de renderização observado: {engine/1e9:.3f} s.')
  found=True
 except FileNotFoundError: continue
assert found, 'Desktop GNOME deste usuário não encontrado.'
PY
printf '%s\n' 'OK: aceleração gráfica Intel e desktop confirmados.'
