#!/usr/bin/env python3
"""Export and package all four release targets from the pinned Godot project."""
import argparse
import hashlib
import os
from pathlib import Path
import shutil
import subprocess
import zipfile

ROOT = Path(__file__).resolve().parent.parent


def run(*args):
    subprocess.run([str(arg) for arg in args], check=True, cwd=ROOT)


def zip_tree(source, target):
    with zipfile.ZipFile(target, 'w', zipfile.ZIP_DEFLATED) as archive:
        for path in sorted(source.rglob('*')):
            if path.is_file():
                archive.write(path, path.relative_to(source))


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--version', default='0.1.0')
    args = parser.parse_args()
    version = args.version.removeprefix('v')
    if not version or any(c not in '0123456789abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ.-' for c in version):
        parser.error('version must contain only letters, digits, periods and hyphens')
    engine = (ROOT / '.godot-version').read_text().strip()
    runtime = os.environ.get('GODOT_BIN', str(ROOT / f'.tools/Godot_v{engine}-stable_linux.x86_64'))
    out = ROOT / 'release'
    if out.exists():
        shutil.rmtree(out)
    for name in ('linux', 'windows', 'macos', 'site/play', 'artifacts'):
        (out / name).mkdir(parents=True)
    run(runtime, '--headless', '--path', ROOT / 'godot', '--editor', '--import', '--quit')
    exports = [('Linux', 'linux/RaceTheNags.x86_64'), ('Windows', 'windows/RaceTheNags.exe'),
               ('macOS', 'macos/RaceTheNags.zip'), ('Web', 'site/play/index.html')]
    # Set macOS bundle version for this export without changing checked-in presets.
    presets_path = ROOT / 'godot/export_presets.cfg'
    presets = presets_path.read_text()
    try:
        presets_path.write_text(presets.replace('application/short_version="0.1.0"', f'application/short_version="{version}"')
                               .replace('application/version="0.1.0"', f'application/version="{version}"'))
        for preset, filename in exports:
            run(runtime, '--headless', '--path', ROOT / 'godot', '--export-release', preset, out / filename)
    finally:
        presets_path.write_text(presets)
    artifacts = out / 'artifacts'
    for platform in ('linux', 'windows', 'macos'):
        folder = out / platform
        for notice in ('README.md', 'THIRD_PARTY_NOTICES.md', 'LICENSE', 'GODOT-LICENSE.txt'):
            if (ROOT / notice).exists():
                shutil.copy2(ROOT / notice, folder / notice)
        archive_path = artifacts / f'RaceTheNags-{version}-{platform}.zip'
        if platform == 'macos':
            # Keep Godot's app bundle permissions and symlinks intact.
            shutil.copy2(folder / 'RaceTheNags.zip', archive_path)
            with zipfile.ZipFile(archive_path, 'a', zipfile.ZIP_DEFLATED) as archive:
                for path in sorted(folder.iterdir()):
                    if path.is_file() and path.suffix != '.zip':
                        archive.write(path, path.name)
        else:
            zip_tree(folder, archive_path)
    shutil.copy2(ROOT / 'web/index.html', out / 'site/index.html')
    shutil.copy2(ROOT / 'docs/title-screen.png', out / 'site/screenshot.png')
    for notice in ('THIRD_PARTY_NOTICES.md', 'LICENSE', 'GODOT-LICENSE.txt'):
        if (ROOT / notice).exists():
            shutil.copy2(ROOT / notice, out / 'site' / notice)
    (out / 'site/.nojekyll').touch()
    zip_tree(out / 'site', artifacts / f'RaceTheNags-{version}-web.zip')
    with (artifacts / 'SHA256SUMS.txt').open('w') as sums:
        for path in sorted(artifacts.glob('*.zip')):
            sums.write(f'{hashlib.sha256(path.read_bytes()).hexdigest()}  {path.name}\n')
    print(f'Release archives: {artifacts}\nGitHub Pages files: {out / "site"}')


if __name__ == '__main__':
    main()
