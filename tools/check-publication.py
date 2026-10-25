#!/usr/bin/env python3
"""Reject private/original material in the public Git index."""
from pathlib import Path
import hashlib
import json
import subprocess
import sys

ROOT = Path(__file__).resolve().parent.parent
tracked = subprocess.check_output(['git', 'ls-files', '-z'], cwd=ROOT).decode().split('\0')
excluded = set(json.loads((ROOT / 'tools/excluded-material-hashes.json').read_text()))
problems = []
for name in filter(None, tracked):
    p = Path(name)
    if name.startswith(('application/', 'evidence/', '.tools/', 'dist/', 'release/')):
        problems.append(f'Private/generated directory is tracked: {name}')
    if p.suffix.lower() in ('.exe', '.pcx', '.img', '.pck', '.tpz'):
        problems.append(f'Original/binary distribution file is tracked: {name}')
    if name.startswith('godot/assets/') and not name.startswith('godot/assets/public/'):
        problems.append(f'Artwork outside independently drawn public set: {name}')
    path = ROOT / name
    if path.is_file() and hashlib.sha256(path.read_bytes()).hexdigest() in excluded:
        problems.append(f'Known original material or old screenshot is tracked: {name}')
if problems:
    print('\n'.join(problems), file=sys.stderr)
    sys.exit(1)
print('Publication check: no original/private files or known original bytes in tracked source.')
