#!/usr/bin/env python3
"""Export platform sizes from the original app icon (requires Pillow)."""
from pathlib import Path

from PIL import Image

ROOT = Path(__file__).resolve().parent.parent
SOURCE = ROOT / 'godot/assets/public/branding/app-icon.png'


def main():
    with Image.open(SOURCE) as image:
        image = image.convert('RGBA')
        image.resize((256, 256), Image.Resampling.LANCZOS).save(SOURCE.with_name('boot-icon.png'))
        for name, size in [('icon-32.png', 32), ('apple-touch-icon.png', 180),
                           ('icon-192.png', 192), ('icon-512.png', 512)]:
            image.resize((size, size), Image.Resampling.LANCZOS).save(ROOT / 'web' / name)
        image.save(ROOT / 'web/favicon.ico', sizes=[(s, s) for s in (16, 32, 48, 64, 128, 256)])
        image.resize((512, 512), Image.Resampling.LANCZOS).save(
            ROOT / 'packaging/linux/io.github.rknell.race-the-nags.png')
    print('Exported website and Linux icons from', SOURCE.relative_to(ROOT))


if __name__ == '__main__':
    main()
