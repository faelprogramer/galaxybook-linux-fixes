#!/usr/bin/env python3
"""Manage only our driver files in Snap's shared host graphics directories."""
import argparse,hashlib,json,os,shutil,subprocess
from pathlib import Path
p=argparse.ArgumentParser();p.add_argument('action',choices=['install','disable','status'],nargs='?',default='install');p.add_argument('--payload',type=Path);a=p.parse_args()
assert os.geteuid()==0,'É necessária autenticação administrativa.'
state=Path('/var/lib/galaxybook-lakefield/snap-files.json')
if a.action=='status':
 print('Integração Snap instalada' if state.exists() else 'Integração Snap ausente');raise SystemExit(0)
old=json.loads(state.read_text()) if state.exists() else {}
def signature(path):
 if path.is_symlink():return 'link:'+os.readlink(path)
 return 'sha256:'+hashlib.sha256(path.read_bytes()).hexdigest() if path.is_file() else None
if a.action=='disable':
 changed=[]
 for name,expected in old.items():
  f=Path(name)
  if not f.exists() and not f.is_symlink():continue
  if signature(f)!=expected:changed.append(name);continue
  f.unlink()
 assert not changed,'Arquivos modificados foram preservados: '+', '.join(changed)
 state.unlink(missing_ok=True)
 print('Drivers Snap locais removidos; feche e reabra os aplicativos.')
 raise SystemExit(0)
assert os.uname().release=='7.0.0-38-generic'
pci=Path('/sys/bus/pci/devices/0000:00:02.0')
assert Path('/sys/class/dmi/id/product_name').read_text().strip()=='767XCL'
for name,value in [('vendor','0x8086'),('device','0x9840'),('subsystem_vendor','0x144d'),('subsystem_device','0xc18b')]:assert (pci/name).read_text().strip()==value
subprocess.run(['systemctl','is-active','--quiet','galaxybook-lakefield-graphics.service'],check=True)
source=a.payload or Path(__file__).resolve().parent.parent/'package/flatpak-host'
subprocess.run(['sha256sum','--status','-c','SHA256SUMS'],cwd=source,check=True)
manifest=json.loads((source/'manifest.json').read_text());assert tuple(map(int,manifest['glibc_max'].split('.')))<=(2,35)
common=Path('/var/lib/snapd/lib/gl')
files={common/f.relative_to(source/'lib'):f for f in (source/'lib').rglob('*') if f.is_file() or f.is_symlink()}
configs={
 Path('/var/lib/snapd/lib/glvnd/egl_vendor.d/10_galaxybook_lakefield.json'):{'file_format_version':'1.0.0','ICD':{'library_path':str(common/'libEGL_mesa.so.0')}},
 Path('/var/lib/snapd/lib/vulkan/icd.d/00_galaxybook_lakefield.json'):{'file_format_version':'1.0.1','ICD':{'api_version':'1.4.335','library_arch':'64','library_path':'libvulkan_intel.so'}}}
# Never overwrite another driver or administrator-managed file.
for target in [*files,*configs]:
 if target.exists() or target.is_symlink():assert str(target) in old and signature(target)==old[str(target)],f'Arquivo preexistente não gerenciado: {target}'
for target,src in files.items():
 target.parent.mkdir(parents=True,exist_ok=True)
 if src.is_symlink():
  assert not os.path.isabs(os.readlink(src))
  assert src.resolve().is_relative_to(source.resolve())
  if target.is_symlink() and os.readlink(target)==os.readlink(src):continue
  tmp=target.with_name(target.name+'.galaxybook-new');assert not tmp.exists() and not tmp.is_symlink()
  tmp.symlink_to(os.readlink(src));tmp.replace(target)
 else:
  tmp=target.with_name(target.name+'.galaxybook-new');assert not tmp.exists()
  shutil.copy2(src,tmp);tmp.chmod(0o755);tmp.replace(target)

for target,value in configs.items():
 if target.exists():assert str(target) in old and signature(target)==old[str(target)],f'Configuração preexistente: {target}'
 target.parent.mkdir(parents=True,exist_ok=True);target.write_text(json.dumps(value,indent=2)+'\n');target.chmod(0o644)
new={str(f):signature(f) for f in [*files,*configs]}
state.parent.mkdir(parents=True,exist_ok=True);state.write_text(json.dumps(new,indent=2)+'\n');state.chmod(0o644)
print('Drivers Snap locais instalados para as bases x86_64 compatíveis com glibc >=2.35 e interface opengl.')
