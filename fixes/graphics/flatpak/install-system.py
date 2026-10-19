#!/usr/bin/python3
"""Manage the GL.host extension for all users, without accessing their homes."""
import argparse,os,shutil,subprocess
from pathlib import Path
p=argparse.ArgumentParser();p.add_argument('action',choices=['install','disable','status']);p.add_argument('--payload',type=Path);a=p.parse_args();assert os.geteuid()==0
root=Path('/var/lib/flatpak/extension/org.freedesktop.Platform.GL.host/x86_64');branches=['22.08','23.08','24.08','25.08','26.08']
if a.action=='status':
 for b in branches:print(b,'installed' if (root/b/'.galaxybook-lakefield').exists() else 'absent')
 raise SystemExit(0)
if a.action=='disable':
 for b in branches:
  if (root/b/'.galaxybook-lakefield').is_file():shutil.rmtree(root/b)
 raise SystemExit(0)
src=a.payload or Path(__file__).resolve().parent.parent/'package/flatpak-host'
subprocess.run(['sha256sum','--status','-c','SHA256SUMS'],cwd=src,check=True)
for b in branches:
 assert not (root/b).exists() or (root/b/'.galaxybook-lakefield').is_file(),'Unknown existing extension'
 assert not (root/(b+'.new')).exists() and not (root/(b+'.old')).exists()
root.mkdir(parents=True,exist_ok=True)
for b in branches:
 tmp=root/(b+'.new');shutil.copytree(src,tmp,symlinks=True);(tmp/'.galaxybook-lakefield').write_text('Managed experimental Lakefield GL.host extension\n')
 if (root/b).exists():(root/b).rename(root/(b+'.old'))
 tmp.rename(root/b)
 if (root/(b+'.old')).exists():shutil.rmtree(root/(b+'.old'))
# Retire only our marked user extensions after the system copy is complete.
for row in Path('/etc/passwd').read_text().splitlines():
 fields=row.split(':')
 if len(fields)!=7 or not 1000<=int(fields[2])<65534:continue
 home=Path(fields[5]).resolve()
 if not home.is_relative_to(Path('/home')):continue
 for b in branches:
  old=home/'.local/share/flatpak/extension/org.freedesktop.Platform.GL.host/x86_64'/b
  if not old.is_symlink() and old.resolve().is_relative_to(home) and (old/'.galaxybook-lakefield').is_file():shutil.rmtree(old)
print('Flatpak GL.host installed system-wide for existing and future accounts.')
