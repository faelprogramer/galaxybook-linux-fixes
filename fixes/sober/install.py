#!/usr/bin/env python3
"""Per-user Sober Vulkan integration for the validated Lakefield installation."""
import hashlib,json,os,re,shutil,subprocess,sys
from pathlib import Path
home=Path.home()
data=Path(os.environ.get('XDG_DATA_HOME',home/'.local/share'))
state=Path(os.environ.get('XDG_STATE_HOME',home/'.local/state'))/'galaxybook-sober'
ext=data/'flatpak/extension/org.freedesktop.Platform.GL.lakefield/x86_64/26.08'
desktop=data/'applications/org.vinegarhq.Sober.desktop'
launcher=home/'.local/bin/sober-lakefield'
marker='X-GalaxyBook-Lakefield=true'
action=sys.argv[1] if len(sys.argv)>1 else '--install'
assert os.geteuid()!=0,'Execute como usuário comum.'
if action=='--disable':
 if desktop.exists() and marker in desktop.read_text():
  backup=state/'desktop-before.desktop'
  if backup.exists():shutil.copy2(backup,desktop)
  else:desktop.unlink()
 config=home/'.var/app/org.vinegarhq.Sober/config/sober/config.json'
 backup=state/'config-before.json'
 if config.exists() and backup.exists() and re.search(r'"use_opengl"\s*:\s*true',backup.read_text()):
  config.write_text(re.sub(r'("use_opengl"\s*:\s*)false',r'\g<1>true',config.read_text(),count=1))
 if launcher.exists() and '# GalaxyBook Lakefield Sober launcher' in launcher.read_text():launcher.unlink()
 if (ext/'.galaxybook-sober').is_file():shutil.rmtree(ext)
 if shutil.which('update-desktop-database'):subprocess.run(['update-desktop-database',str(desktop.parent)],check=True)
 print('Integração Sober removida. A correção gráfica do sistema foi preservada.')
 sys.exit(0)
assert action=='--install','Opções: --install --disable'
pci=Path('/sys/bus/pci/devices/0000:00:02.0')
assert Path('/sys/class/dmi/id/product_name').read_text().strip()=='767XCL'
for key,value in [('vendor','0x8086'),('device','0x9840'),('subsystem_vendor','0x144d'),('subsystem_device','0xc18b')]:assert (pci/key).read_text().strip()==value
assert os.uname().release=='7.0.0-38-generic'
subprocess.run(['systemctl','is-active','--quiet','galaxybook-lakefield-graphics.service'],check=True)
base=Path('/opt/galaxybook-lakefield')
subprocess.run(['sha256sum','--status','-c','SHA256SUMS'],cwd=base,check=True)
assert subprocess.check_output(['flatpak','info','--show-runtime','org.vinegarhq.Sober'],text=True).strip()=='org.gnome.Platform/x86_64/51','Runtime não validado.'
metadata=subprocess.check_output(['flatpak','info','--show-metadata','org.gnome.Platform//51'],text=True)
assert 'versions = 26.08;' in metadata,'Ramo gráfico não validado.'
source=base/'mesa/lib/libvulkan_intel.so'
if ext.exists() and not (ext/'.galaxybook-sober').exists():
 # Adopt only the exact minimal extension used in the successful local test.
 existing={str(p.relative_to(ext)) for p in ext.rglob('*') if p.is_file()}
 assert existing=={'lib/libvulkan_intel.so','vulkan/icd.d/intel_lakefield.json'},'Extensão preexistente desconhecida.'
 assert hashlib.sha256((ext/'lib/libvulkan_intel.so').read_bytes()).digest()==hashlib.sha256(source.read_bytes()).digest()
state.mkdir(parents=True,exist_ok=True);state.chmod(0o700)
if desktop.exists() and marker not in desktop.read_text():
 assert not (state/'desktop-before.desktop').exists(),'Já existe backup; revisar antes de sobrescrever.'
 shutil.copy2(desktop,state/'desktop-before.desktop')
config=home/'.var/app/org.vinegarhq.Sober/config/sober/config.json'
if config.exists():
 text=config.read_text()
 if re.search(r'"use_opengl"\s*:\s*true',text):
  if not (state/'config-before.json').exists():shutil.copy2(config,state/'config-before.json')
  config.write_text(re.sub(r'("use_opengl"\s*:\s*)true',r'\g<1>false',text,count=1))
(ext/'lib').mkdir(parents=True,exist_ok=True)
(ext/'vulkan/icd.d').mkdir(parents=True,exist_ok=True)
shutil.copy2(source,ext/'lib/libvulkan_intel.so')
icd=json.loads((base/'mesa/share/vulkan/icd.d/intel_icd.x86_64.json').read_text())
icd['ICD']['library_path']='/usr/lib/x86_64-linux-gnu/GL/lakefield/lib/libvulkan_intel.so'
(ext/'vulkan/icd.d/intel_lakefield.json').write_text(json.dumps(icd,indent=2)+'\n')
(ext/'.galaxybook-sober').write_text('Local Vulkan extension for Samsung 767XCL / Sober GNOME 51 / GL 26.08\n')
exported=Path('/var/lib/flatpak/exports/share/applications/org.vinegarhq.Sober.desktop')
if not exported.exists():exported=data/'flatpak/exports/share/applications/org.vinegarhq.Sober.desktop'
text=exported.read_text()
flags='--env=VK_DRIVER_FILES=/usr/lib/x86_64-linux-gnu/GL/lakefield/vulkan/icd.d/intel_lakefield.json --env=INTEL_FORCE_PROBE=9840'
assert 'Exec=/usr/bin/flatpak run ' in text
text=text.replace('Exec=/usr/bin/flatpak run ',f'Exec=env FLATPAK_GL_DRIVERS=lakefield:default /usr/bin/flatpak run {flags} ')
text=text.replace('[Desktop Entry]','[Desktop Entry]\n'+marker,1)
desktop.parent.mkdir(parents=True,exist_ok=True);desktop.write_text(text)
launcher.parent.mkdir(parents=True,exist_ok=True)
launcher.write_text('#!/usr/bin/env bash\n# GalaxyBook Lakefield Sober launcher\nset -euo pipefail\nexport FLATPAK_GL_DRIVERS=lakefield:default\nexec /usr/bin/flatpak run '+flags+' org.vinegarhq.Sober "$@"\n');launcher.chmod(0o755)
if shutil.which('update-desktop-database'):subprocess.run(['update-desktop-database',str(desktop.parent)],check=True)
print('Pronto: abra Sober pelo menu de aplicativos ou execute ~/.local/bin/sober-lakefield.')
print('Esta integração não requer acesso do Sober à pasta /opt nem altera a Mesa do desktop.')
