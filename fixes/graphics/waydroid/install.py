#!/usr/bin/env python3
"""Manage a reversible, exact-device Android vendor overlay; preserve Android data."""
import argparse,configparser,hashlib,json,os,shutil,subprocess
from pathlib import Path
p=argparse.ArgumentParser();p.add_argument('action',choices=['install','disable','status']);p.add_argument('--payload',type=Path);a=p.parse_args()
assert os.geteuid()==0
state=Path('/var/lib/galaxybook-lakefield/waydroid');record=state/'files.json';cfg=Path('/var/lib/waydroid/waydroid.cfg');overlay=Path('/var/lib/waydroid/overlay')
dropin=Path('/etc/systemd/system/waydroid-container.service.d/50-lakefield.conf')
if a.action=='status':print('Waydroid Lakefield instalado' if record.exists() else 'Waydroid Lakefield ausente');raise SystemExit(0)
def sig(p):return hashlib.sha256(p.read_bytes()).hexdigest() if p.is_file() else None
if a.action=='disable':
 if not record.exists():raise SystemExit(0)
 old=json.loads(record.read_text())
 assert all(not Path(n).exists() or sig(Path(n))==v for n,v in old.items()),'Arquivos alterados: revisão manual necessária.'
 for n in old:Path(n).unlink(missing_ok=True)
 c=configparser.ConfigParser();c.read(cfg);before=json.loads((state/'properties.json').read_text())
 for k,v in before.items():
  if v is None:c['properties'].pop(k,None)
  else:c['properties'][k]=v
 with cfg.open('w') as f:c.write(f)
 dropin.unlink(missing_ok=True);record.unlink();subprocess.run(['systemctl','daemon-reload'],check=True)
 subprocess.run(['waydroid','upgrade','--offline'],check=True);print('Sobreposição gráfica removida; dados Android preservados.');raise SystemExit(0)
assert os.uname().release=='7.0.0-38-generic'
assert Path('/sys/class/dmi/id/product_name').read_text().strip()=='767XCL'
pci=Path('/sys/bus/pci/devices/0000:00:02.0')
for k,v in [('vendor','0x8086'),('device','0x9840'),('subsystem_vendor','0x144d'),('subsystem_device','0xc18b')]:assert (pci/k).read_text().strip()==v
subprocess.run(['systemctl','is-active','--quiet','galaxybook-lakefield-graphics.service'],check=True)
source=a.payload or Path(__file__).resolve().parent.parent/'package/waydroid'
subprocess.run(['sha256sum','--status','-c','SHA256SUMS'],cwd=source,check=True)
m=json.loads((source/'manifest.json').read_text());assert m['android_sdk']==33 and m['architecture']=='x86_64'
c=configparser.ConfigParser();c.read(cfg);assert c.has_section('properties')
old=json.loads(record.read_text()) if record.exists() else {}
files={overlay/f.relative_to(source):f for f in (source/'vendor').rglob('*') if f.is_file()}
for dest in files:assert not dest.exists() or str(dest) in old and sig(dest)==old[str(dest)],f'Sobreposição preexistente preservada: {dest}'
assert not dropin.exists() or '# GalaxyBook Lakefield' in dropin.read_text()
if old and dropin.exists() and all(dest.exists() and sig(dest)==sig(src) for dest,src in files.items()) and all(c['properties'].get(k)==v for k,v in {'ro.hardware.gralloc':'gbm','ro.hardware.egl':'mesa','debug.mesa.intel.force.probe':'9840'}.items()):
 print('Integração Waydroid já atualizada.');raise SystemExit(0)
state.mkdir(parents=True,exist_ok=True)
props={'ro.hardware.gralloc':'gbm','ro.hardware.egl':'mesa','debug.mesa.intel.force.probe':'9840'}
if not (state/'properties.json').exists():
 (state/'properties.json').write_text(json.dumps({k:c['properties'].get(k) for k in props},indent=2)+'\n');shutil.copy2(cfg,state/'waydroid.cfg.before')
for dest,src in files.items():
 dest.parent.mkdir(parents=True,exist_ok=True);tmp=dest.with_name(dest.name+'.galaxybook-new');shutil.copy2(src,tmp);tmp.chmod(0o755);tmp.replace(dest)
record.write_text(json.dumps({str(f):sig(f) for f in files},indent=2)+'\n')
for k,v in props.items():c['properties'][k]=v
with cfg.open('w') as f:c.write(f)
dropin.parent.mkdir(parents=True,exist_ok=True);dropin.write_text('# GalaxyBook Lakefield\n[Unit]\nWants=galaxybook-lakefield-graphics.service\nAfter=galaxybook-lakefield-graphics.service\n')
subprocess.run(['systemctl','daemon-reload'],check=True)
subprocess.run(['waydroid','upgrade','--offline'],check=True)
print('Mesa Android instalado. Valide SurfaceFlinger e o jogo antes de confirmar a solução.')
