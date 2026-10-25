#!/usr/bin/env python3
"""Check publication boundaries and the exact selected heritage-artwork files."""
from pathlib import Path
import hashlib
import json
import subprocess
import sys

ROOT = Path(__file__).resolve().parent.parent
tracked = subprocess.check_output(['git', 'ls-files', '-z'], cwd=ROOT).decode().split('\0')
excluded = set(json.loads((ROOT / 'tools/excluded-material-hashes.json').read_text()))
heritage = json.loads((ROOT / 'godot/assets/heritage/provenance.json').read_text())['files']
allowed_art = {'godot/assets/heritage/' + name: info['sha256'] for name, info in heritage.items()}
def path_digest(path):
    return hashlib.sha256(path.read_bytes()).hexdigest() if path.is_file() else None

problems = []
if len(allowed_art) != 34:
    problems.append("Expected 31 Classic images and three owner-supplied enhanced images")
for name in filter(None, tracked):
    p = Path(name)
    if name.startswith(('application/', 'evidence/', '.tools/', 'dist/', 'release/')):
        problems.append(f'Private/generated directory is tracked: {name}')
    if p.suffix.lower() in ('.exe', '.pcx', '.img', '.pck', '.tpz'):
        problems.append(f'Original/binary distribution file is tracked: {name}')
    approved = name in allowed_art and path_digest(ROOT / name) == allowed_art[name]
    if name.startswith('godot/assets/') and not name.startswith(('godot/assets/public/', 'godot/assets/heritage/')):
        problems.append(f'Artwork outside selected publication sets: {name}')
    if name.startswith('godot/assets/heritage/') and name != 'godot/assets/heritage/provenance.json':
        if name.endswith('.import'):
            if name[:-7] not in allowed_art:
                problems.append(f'Import metadata without an approved asset: {name}')
        elif not approved:
            problems.append(f'Heritage artwork is missing from the exact hash allowlist: {name}')
    path = ROOT / name
    if path.is_file() and hashlib.sha256(path.read_bytes()).hexdigest() in excluded and not approved:
        problems.append(f'Known original material or old screenshot is tracked: {name}')
if problems:
    print('\n'.join(problems), file=sys.stderr)
    sys.exit(1)
print('Publication check: only the 31 Classic and three owner-supplied Enhanced images are allowed; DOS files and private evidence excluded.')
