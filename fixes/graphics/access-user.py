#!/usr/bin/python3
"""Grant the validated render node to local normal accounts, including new logins."""
import os,re,stat,subprocess,sys
from pathlib import Path
if os.geteuid()!=0:raise SystemExit('Root required')
local={int(row.split(':')[2]) for row in Path('/etc/passwd').read_text().splitlines() if len(row.split(':'))==7 and 1000<=int(row.split(':')[2])<65534}
if len(sys.argv)!=2:raise SystemExit(2)
if sys.argv[1]=='--all':uids=sorted(local)
elif sys.argv[1].isdigit():uids=[int(sys.argv[1])] if int(sys.argv[1]) in local else []
else:raise SystemExit(2)
b=Path('/opt/galaxybook-lakefield');p=Path('/run/galaxybook-lakefield/render-node')
if not p.is_file() or os.uname().release!=(b/'kernel-release').read_text().strip():raise SystemExit(0)
node=p.read_text().strip()
if not re.fullmatch('/dev/dri/renderD[0-9]+',node):raise SystemExit(1)
if not Path(node).exists():raise SystemExit(0)
assert stat.S_ISCHR(Path(node).stat().st_mode)
dev=Path('/sys/class/drm')/Path(node).name/'device'
assert dev.resolve()==Path('/sys/devices/pci0000:00/0000:00:02.0')
assert (dev/'driver').resolve().name=='i915'
for uid in uids:subprocess.run(['/usr/bin/setfacl','-m',f'u:{uid}:rw',node],check=True)
