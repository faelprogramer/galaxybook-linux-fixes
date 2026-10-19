#!/usr/bin/env python3
"""Package only Android x86_64 graphics libraries, never Linux/glibc libraries."""
import hashlib,json,os,shutil,subprocess,sys
from pathlib import Path
stage,out,strip=map(Path,sys.argv[1:4]);assert os.geteuid()!=0 and out.name=='waydroid'
tmp=out.with_name(out.name+'.new');assert not tmp.exists();tmp.mkdir(parents=True)
lib=tmp/'vendor/lib64';egl=lib/'egl';hw=lib/'hw';egl.mkdir(parents=True);hw.mkdir()
def copy(pattern,directory,name=None):
 files=[p for p in stage.rglob(pattern) if p.is_file()]
 assert len(files)==1,(pattern,files)
 dest=directory/(name or files[0].name);shutil.copy2(files[0],dest)
 subprocess.run([str(strip),'--strip-unneeded',str(dest)],check=True)
 return dest
for name in ['libEGL_mesa.so','libGLESv1_CM_mesa.so','libGLESv2_mesa.so']:copy(name,egl)
for name in ['libgallium_dri.so','libgbm_mesa.so','libdrm.so','libexpat.so']:copy(name,lib)
(lib/'gbm').mkdir()
copy('dri_gbm.so',lib/'gbm')
copy('libvulkan_intel.so',hw,'vulkan.intel.so')
needed={}
for p in tmp.rglob('*.so'):
 info=subprocess.check_output(['readelf','-d',str(p)],text=True)
 assert 'libc.so.6' not in info and 'libstdc++.so.6' not in info,(p,info)
 needed[str(p.relative_to(tmp))]=[line.strip() for line in info.splitlines() if 'NEEDED' in line]
(tmp/'manifest.json').write_text(json.dumps({'format':1,'hardware':'Samsung767XCL 8086:9840/144d:c18b','mesa':'26.0.8','android_sdk':33,'architecture':'x86_64','ndk':'r30','experimental':True,'cts_validated':False,'needed':needed},indent=2)+'\n')
(tmp/'SHA256SUMS').write_text(''.join(hashlib.sha256(p.read_bytes()).hexdigest()+'  ./'+str(p.relative_to(tmp))+'\n' for p in sorted(tmp.rglob('*')) if p.is_file() and p.name!='SHA256SUMS'))
assert not out.exists(),'Review the previous Android payload before replacing it.'
tmp.rename(out);print('Android x86_64 payload:',out)
