#!/usr/bin/env python3
"""Compatibility entry point for the standard Flatpak graphics integration."""
from pathlib import Path
import subprocess,sys
root=Path(__file__).resolve().parents[1]/'graphics'
if not root.exists():root=Path(__file__).resolve().parents[1]
if not (root/'package/flatpak-host/manifest.json').exists():
 print('Use o pacote integrado do Desktop ou compile primeiro: bash fixes/graphics/graphics.sh --build-flatpak')
 raise SystemExit(1)
raise SystemExit(subprocess.call(['/usr/bin/bash',str(root/'graphics.sh'),'--install']))
