#!/usr/bin/python3
"""Install only the private, exact-hardware VA-API payload; never reload i915."""
import argparse,hashlib,json,os,shutil,subprocess
from pathlib import Path
p=argparse.ArgumentParser();p.add_argument('--payload',type=Path,required=True);a=p.parse_args();assert os.geteuid()==0
base=Path('/opt/galaxybook-lakefield');src=a.payload.resolve()
assert os.uname().release=='7.0.0-38-generic'
assert Path('/sys/class/dmi/id/product_name').read_text().strip()=='767XCL'
pci=Path('/sys/bus/pci/devices/0000:00:02.0')
for name,value in [('vendor','0x8086'),('device','0x9840'),('subsystem_vendor','0x144d'),('subsystem_device','0xc18b')]:assert (pci/name).read_text().strip()==value
assert subprocess.check_output(['modinfo','-F','lkf_experiment',str(base/'i915.ko')],text=True).strip()=='render-media-preserve-bootfb-9840-samsung-c18b-v4','Use o módulo de vídeo V4 validado.'
subprocess.run(['sha256sum','--status','-c','SHA256SUMS'],cwd=base,check=True)
subprocess.run(['sha256sum','--status','-c','SHA256SUMS'],cwd=src,check=True)
d=json.loads((src/'manifest.json').read_text());assert tuple(map(int,d['glibc_max'].split('.')))<=(2,35)
assert (src/'lib/dri/iHD_drv_video.so').is_file()
target=base/'media';tmp=base/'media.new';old=base/'media.old'
assert not tmp.exists() and not old.exists()
assert not target.exists() or (target/'.galaxybook-lakefield').is_file(),'Diretório de vídeo preexistente não gerenciado.'
shutil.copytree(src,tmp,symlinks=True)
for f in tmp.rglob('*'):
 if f.is_symlink():assert not os.path.isabs(os.readlink(f)) and f.resolve().is_relative_to(tmp.resolve())
 else:f.chmod(0o755 if f.is_dir() else 0o644)
(tmp/'.galaxybook-lakefield').write_text('Managed private Lakefield VA-API payload\n')
if target.exists():target.rename(old)
tmp.rename(target)
manifest=base/'SHA256SUMS';lines=[s for s in manifest.read_text().splitlines() if not s.split('  ',1)[-1].startswith('./media/')]
for f in sorted(target.rglob('*')):
 if f.is_file() and not f.is_symlink():lines.append(hashlib.sha256(f.read_bytes()).hexdigest()+'  ./'+str(f.relative_to(base)))
manifest.write_text('\n'.join(lines)+'\n')
subprocess.run(['sha256sum','--status','-c','SHA256SUMS'],cwd=base,check=True)
if old.exists():shutil.rmtree(old)
print('VA-API privado instalado. Novas sessões locais recebem o ambiente; nenhum módulo foi recarregado.')
