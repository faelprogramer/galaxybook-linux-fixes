#!/usr/bin/env bash
# Read-only checks: require an Intel renderer and a compositor submitting work.
set -euo pipefail
base=/opt/galaxybook-lakefield
[[ $(uname -r) == 7.0.0-38-generic ]] || { echo 'Kernel fora da versão validada.'; exit 1; }
systemctl is-active --quiet galaxybook-lakefield-graphics.service
[[ $(readlink -f /sys/bus/pci/devices/0000:00:02.0/driver) == /sys/bus/pci/drivers/i915 ]]
[[ $(modinfo -F lkf_experiment "$base/i915.ko") == render-media-preserve-bootfb-9840-samsung-c18b-v4 ]]
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

if [[ -f $base/media/lib/dri/iHD_drv_video.so ]]; then
 python3 - <<'VAAPI'
import os,shutil,subprocess
from pathlib import Path
settings=subprocess.check_output(['/etc/systemd/user-environment-generators/50-galaxybook-lakefield'],text=True)
env=os.environ.copy()
for line in settings.splitlines():
 key,value=line.split('=',1);env[key]=value
assert env.get('LIBVA_DRIVER_NAME')=='iHD','Vídeo privado não habilitado para esta conta.'
assert list((Path('/sys/class/drm')/Path(env['LKF_RENDER_NODE']).name/'device/drm').glob('card*/engine/vcs*')),'Motores de vídeo ausentes.'
if shutil.which('vainfo'):
 subprocess.run(['vainfo','--display','drm','--device',env['LKF_RENDER_NODE']],env=env,check=True)
 print('VA-API: driver e perfis disponíveis. Testes reais de decodificação estão registrados em VALIDATION.md.')
else:print('Bibliotecas/motores de vídeo presentes; instale vainfo para consultar os perfis.')
VAAPI
fi
