#!/usr/bin/env python3
"""Package the Linux userspace build for standard Flatpak and Snap integration."""
import hashlib,json,os,re,shutil,subprocess,sys
from pathlib import Path
assert os.geteuid()!=0
stage,out=map(Path,sys.argv[1:3]);assert out.name=='flatpak-host'
staged=out.with_name(out.name+'.new');assert not staged.exists()
staged.parent.mkdir(parents=True,exist_ok=True)
shutil.copytree(stage,staged,symlinks=True)
# Use the matching oldest-supported libdrm ABI; do not bundle libc, libstdc++
# or LLVM over application runtimes.
subprocess.run(['flatpak','run','--filesystem='+str(staged.resolve()),'--command=sh','org.freedesktop.Sdk//22.08','-eu','-c','cp -L /usr/lib/x86_64-linux-gnu/libdrm.so.2 "$1/lib/libdrm.so.2"','sh',str(staged.resolve())],check=True)
for p in list((staged/'lib').rglob('*')):
 if p.is_file() and not p.is_symlink() and '.so' in p.name:subprocess.run(['strip','--strip-unneeded',str(p)],check=True)
(staged/'glvnd/egl_vendor.d').mkdir(parents=True,exist_ok=True)
(staged/'vulkan/icd.d').mkdir(parents=True,exist_ok=True)
(staged/'glvnd/egl_vendor.d/10_galaxybook_lakefield.json').write_text(json.dumps({'file_format_version':'1.0.0','ICD':{'library_path':'/usr/lib/x86_64-linux-gnu/GL/host/lib/libEGL_mesa.so.0'}},indent=2)+'\n')
icds=list((staged/'share/vulkan/icd.d').glob('intel_icd*.json'));assert len(icds)==1
icd=json.loads(icds[0].read_text());icd['ICD']['library_path']='/usr/lib/x86_64-linux-gnu/GL/host/lib/libvulkan_intel.so'
(staged/'vulkan/icd.d/00_galaxybook_lakefield.json').write_text(json.dumps(icd,indent=2)+'\n')
versions=set();cxx=set()
for p in (staged/'lib').rglob('*'):
 if not p.is_file() or p.is_symlink() or '.so' not in p.name:continue
 info=subprocess.check_output(['readelf','--version-info',str(p)],text=True)
 versions.update(re.findall(r'\bGLIBC_([0-9.]+)',info));cxx.update(re.findall(r'\bGLIBCXX_([0-9.]+)',info))
def key(s):return tuple(map(int,s.split('.')))
maximum=max(versions,key=key);assert key(maximum)<=(2,35),maximum
if cxx:assert key(max(cxx,key=key))<=(3,4,30)
manifest={'format':1,'hardware':'Samsung767XCL 8086:9840/144d:c18b','mesa':'26.0.8','sdk':'org.freedesktop.Sdk/x86_64/22.08','glibc_max':maximum,'glibcxx_max':max(cxx,key=key) if cxx else None,'drivers':['iris','softpipe','intel Vulkan'],'experimental':True,'cts_validated':False}
(staged/'manifest.json').write_text(json.dumps(manifest,indent=2)+'\n')
(staged/'SHA256SUMS').write_text(''.join(hashlib.sha256(p.read_bytes()).hexdigest()+'  ./'+str(p.relative_to(staged))+'\n' for p in sorted(staged.rglob('*')) if p.is_file() and not p.is_symlink() and p.name!='SHA256SUMS'))
if out.exists():
 assert (out/'manifest.json').is_file(),'Pacote anterior desconhecido.'
 shutil.rmtree(out)
staged.rename(out)
print('Pacote Linux compatível criado:',out,'GLIBC<=',maximum)
