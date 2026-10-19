#!/usr/bin/python3
"""Explain the single active Android session limitation instead of failing silently."""
import os,pwd,re,subprocess,sys
try:
 status=subprocess.check_output(['/usr/bin/waydroid','status'],text=True,timeout=10,env={**os.environ,'LC_ALL':'C'})
 owner=re.search(r'^Session user:\s*([^\s(]+)',status,re.M)
 if owner and owner.group(1)!=pwd.getpwuid(os.getuid()).pw_name:
  msg='O Android ainda está aberto na conta '+owner.group(1)+'.\n\nNessa conta, use o menu “Parar Waydroid” ou saia da conta antes de abrir aqui. A instalação atual permite uma sessão Android por vez; os dados de cada conta não serão copiados.'
  print(msg,file=sys.stderr)
  if os.environ.get('DISPLAY') or os.environ.get('WAYLAND_DISPLAY'):
   subprocess.run(['/usr/bin/zenity','--warning','--title=Waydroid em outra conta','--text='+msg])
  raise SystemExit(1)
except (subprocess.SubprocessError,FileNotFoundError):pass
os.execv('/usr/bin/waydroid',['waydroid',*sys.argv[1:]])
