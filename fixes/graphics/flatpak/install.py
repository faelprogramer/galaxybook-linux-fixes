#!/usr/bin/env python3
"""Install a standard per-user GL.host extension for validated x86_64 branches."""
import argparse,hashlib,json,os,re,shutil,subprocess
from pathlib import Path
p=argparse.ArgumentParser();p.add_argument('action',choices=['install','disable','status'],nargs='?',default='install');p.add_argument('--payload',type=Path);a=p.parse_args()
assert os.geteuid()!=0,'Execute como usuário comum.'
home=Path.home();data=Path(os.environ.get('XDG_DATA_HOME',home/'.local/share'))
extroot=data/'flatpak/extension/org.freedesktop.Platform.GL.host/x86_64'
state=Path(os.environ.get('XDG_STATE_HOME',home/'.local/state'))/'galaxybook-flatpak'
branches=['22.08','23.08','24.08','25.08','26.08']
if a.action=='status':
 for branch in branches:print(branch,'instalado' if (extroot/branch/'.galaxybook-lakefield').is_file() else 'ausente')
 raise SystemExit(0)
if a.action=='disable':
 for branch in branches:
  path=extroot/branch
  if (path/'.galaxybook-lakefield').is_file():shutil.rmtree(path)
 print('Extensões gráficas locais desativadas para novos processos Flatpak. Feche e reabra os aplicativos.')
 raise SystemExit(0)
assert os.uname().release=='7.0.0-38-generic','Kernel fora da versão validada.'
pci=Path('/sys/bus/pci/devices/0000:00:02.0')
assert Path('/sys/class/dmi/id/product_name').read_text().strip()=='767XCL'
for name,val in [('vendor','0x8086'),('device','0x9840'),('subsystem_vendor','0x144d'),('subsystem_device','0xc18b')]:assert (pci/name).read_text().strip()==val
subprocess.run(['systemctl','is-active','--quiet','galaxybook-lakefield-graphics.service'],check=True)
root=Path(__file__).resolve().parent
payload=a.payload or root.parent/'package/flatpak-host'
assert payload.is_dir(),'Pacote Flatpak ausente. Compile-o antes ou use o pacote local fornecido.'
subprocess.run(['sha256sum','--status','-c','SHA256SUMS'],cwd=payload,check=True)
manifest=json.loads((payload/'manifest.json').read_text());assert tuple(map(int,manifest['glibc_max'].split('.')))<=(2,35)
# Refuse unknown preexisting extensions before any configuration writes.
for branch in branches:
 path=extroot/branch
 assert not path.exists() or (path/'.galaxybook-lakefield').is_file(),f'Extensão preexistente não gerenciada: {path}'
state.mkdir(parents=True,exist_ok=True);state.chmod(0o700)
for branch in branches:
 path=extroot/branch;staged=extroot/(branch+'.galaxybook-new')
 assert not staged.exists(),'Diretório temporário preexistente; revisar antes de tentar novamente.'
 staged.parent.mkdir(parents=True,exist_ok=True)
 shutil.copytree(payload,staged,symlinks=True)
 (staged/'.galaxybook-lakefield').write_text('Managed experimental Lakefield GL.host extension\n')
 previous=extroot/(branch+'.galaxybook-old');assert not previous.exists()
 if path.exists():path.rename(previous)
 staged.rename(path)
 if previous.exists():shutil.rmtree(previous)
# Retire only the Sober-specific files created by our previous installer.
desktop=data/'applications/org.vinegarhq.Sober.desktop'
legacy=Path(os.environ.get('XDG_STATE_HOME',home/'.local/state'))/'galaxybook-sober'
if desktop.exists() and 'X-GalaxyBook-Lakefield=true' in desktop.read_text():
 backup=legacy/'desktop-before.desktop'
 if backup.exists():shutil.copy2(backup,desktop)
 else:desktop.unlink()
custom=data/'flatpak/extension/org.freedesktop.Platform.GL.lakefield/x86_64/26.08'
if (custom/'.galaxybook-sober').is_file():shutil.rmtree(custom)
launcher=home/'.local/bin/sober-lakefield'
if launcher.exists() and '# GalaxyBook Lakefield Sober launcher' in launcher.read_text():
 launcher.write_text('#!/usr/bin/env bash\n# GalaxyBook Lakefield Sober launcher (standard Flatpak compatibility alias)\nexec /usr/bin/flatpak run org.vinegarhq.Sober "$@"\n');launcher.chmod(0o755)
if shutil.which('update-desktop-database') and desktop.parent.exists():subprocess.run(['update-desktop-database',str(desktop.parent)],check=True)
print('Gráficos padrão Flatpak instalados: x86_64, ramos 22.08 a 26.08. Abra os aplicativos normalmente.')
print('Não há garantia para outros ramos/arquiteturas, aplicativos sem acesso à GPU ou políticas próprias de renderização.')
