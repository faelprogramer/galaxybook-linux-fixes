#!/usr/bin/python3
import os,shutil,subprocess,sys
from pathlib import Path
assert os.geteuid()==0
marker='X-GalaxyBook-Lakefield=true'
dest=Path('/usr/local/share/applications/Waydroid.desktop');helper=Path('/usr/local/libexec/galaxybook-waydroid')
if sys.argv[1]=='disable':
 if dest.exists() and marker in dest.read_text():dest.unlink();helper.unlink(missing_ok=True)
 raise SystemExit(0)
assert sys.argv[1]=='install'
assert not dest.exists() or marker in dest.read_text(),'Existing unmanaged Waydroid launcher'
source=Path('/usr/share/applications/Waydroid.desktop')
if not source.exists():raise SystemExit(0)
helper.parent.mkdir(parents=True,exist_ok=True);shutil.copy2(Path(__file__).parent/'launch-user.py',helper);helper.chmod(0o755)
s=source.read_text();assert s.count('Exec=waydroid\n')==1;s=s.replace('Exec=waydroid\n','Exec=/usr/local/libexec/galaxybook-waydroid\n'+marker+'\n');dest.parent.mkdir(parents=True,exist_ok=True);dest.write_text(s);dest.chmod(0o644)
if shutil.which('update-desktop-database'):subprocess.run(['update-desktop-database',str(dest.parent)],check=True)
