#!/usr/bin/python3
from pathlib import Path
import hashlib,json,os,re,shutil,subprocess,sys
assert os.geteuid()!=0
root,out=map(lambda x:Path(x).resolve(),sys.argv[1:3]);assert out.name=='media'
final=out;out=out.with_name('media.new');assert not out.exists();out.parent.mkdir(parents=True,exist_ok=True)
plugins=list((root/'stage22').rglob('iHD_drv_video.so'));assert len(plugins)==1,plugins
(out/'lib/dri').mkdir(parents=True)
shutil.copy2(plugins[0],out/'lib/dri/iHD_drv_video.so')
for p in (root/'prefix22/lib').glob('libigdgmm.so*'):
 if p.is_symlink():(out/'lib'/p.name).symlink_to(os.readlink(p))
 elif p.is_file():shutil.copy2(p,out/'lib'/p.name)
subprocess.run(['patchelf','--set-rpath','$ORIGIN/..',str(out/'lib/dri/iHD_drv_video.so')],check=True)
versions=set();cxx=set()
for p in (out/'lib').rglob('*'):
 if p.is_file() and not p.is_symlink():
  subprocess.run(['strip','--strip-unneeded',str(p)],check=True)
  info=subprocess.check_output(['readelf','--version-info',str(p)],text=True);versions.update(re.findall(r'\bGLIBC_([0-9.]+)',info));cxx.update(re.findall(r'\bGLIBCXX_([0-9.]+)',info))
key=lambda s:tuple(map(int,s.split('.')))
assert max(map(key,versions))<=(2,35)
assert max(map(key,cxx))<=(3,4,30)
(out/'licenses').mkdir()
for folder in ['media-driver','gmmlib']:
 files=[p for p in (root/folder).iterdir() if p.is_file() and p.name.lower().startswith(('license','copying'))]
 for p in files:shutil.copy2(p,out/'licenses'/(folder+'-'+p.name))
(out/'manifest.json').write_text(json.dumps({'format':1,'hardware':'8086:9840 Samsung144d:c18b','media_driver':'26.1.5 experimental Lakefield','gmmlib':'22.9.0','glibc_max':max(versions,key=key),'glibcxx_max':max(cxx,key=key),'encode_enabled':False,'vpp_enabled':False,'decode_validated':['H264ConstrainedBaseline1080p','H264High720p','HEVCMain8bit720p','VP9Profile0_720p'],'note':'Source variant validated on exact hardware; a rebuild must be verified again. No encoding/VPP or Android MediaCodec claim.'},indent=2)+'\n')
(out/'SHA256SUMS').write_text(''.join(hashlib.sha256(p.read_bytes()).hexdigest()+'  ./'+str(p.relative_to(out))+'\n' for p in sorted(out.rglob('*')) if p.is_file() and not p.is_symlink() and p.name!='SHA256SUMS'))
print('Candidate ABI validated:',max(versions,key=key),max(cxx,key=key))

if final.exists():
 assert (final/'manifest.json').is_file()
 shutil.rmtree(final)
out.rename(final)
