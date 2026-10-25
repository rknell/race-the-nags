#!/usr/bin/env python3
"""Create the public game's independently drawn SVG artwork. No source assets are read."""
from pathlib import Path
import math

ROOT = Path(__file__).resolve().parent.parent
OUT = ROOT / 'godot/assets/public'
SILKS = ['#eee7d7', '#ed6a5a', '#62b9eb', '#efc45e', '#68bd8e', '#c396d7']
COATS = ['#b97b51', '#735146', '#c99461', '#675d58', '#97715b', '#c5b3a1']


def svg(body, width, height, view=None):
    return f'<svg xmlns="http://www.w3.org/2000/svg" width="{width}" height="{height}" viewBox="{view or f"0 0 {width} {height}"}">{body}</svg>\n'


def horse(runner, phase, fallen=False):
    coat, silk = COATS[runner], SILKS[runner]
    body = ''
    # Four independently articulated legs, lifted in alternating pairs.
    for leg in range(4):
        x = [20, 25, 39, 43][leg]
        swing = math.sin(phase * math.pi / 2 + leg * 1.6) * 8
        knee_x = x + swing * .55
        hoof_x = x + swing
        body += f'<path d="M{x} 38 L{knee_x:.1f} 48 L{hoof_x:.1f} 55" fill="none" stroke="{coat}" stroke-width="3.3" stroke-linecap="round"/>'
        body += f'<path d="M{hoof_x-1:.1f} 55 h4" stroke="#26382e" stroke-width="2.5"/>'
    body += f'''<path d="M18 30 Q9 28 8 39 Q12 34 19 35" fill="#3f352f"/>
<path d="M17 30 Q25 23 41 29 L46 20 L48 13 L52 20 L58 23 Q62 27 58 30 L50 29 L45 39 Q34 44 20 39 Z" fill="{coat}"/>
<path d="M41 29 L46 20 L48 13 L50 21 L46 32" fill="#493b32"/>
<circle cx="54" cy="24" r="1.1" fill="#13251e"/>
<path d="M52 28 L45 26 L37 28" fill="none" stroke="#eee1bf" stroke-width="1"/>
<path d="M27 29 Q33 25 39 29 L37 36 L27 35 Z" fill="{silk}"/>'''
    if fallen:
        body += f'<path d="M6 54 l10 -4 l6 5" stroke="{silk}" stroke-width="4" fill="none"/><circle cx="5" cy="51" r="3" fill="#ecc7a0"/>'
    else:
        body += f'''<path d="M29 25 L35 18 L42 23 L38 28" fill="{silk}"/>
<path d="M32 27 L27 33 L34 36" fill="none" stroke="#26382e" stroke-width="3"/>
<path d="M40 23 L45 27" fill="none" stroke="#ecc7a0" stroke-width="2.3"/>
<circle cx="38" cy="15" r="3.4" fill="#ecc7a0"/>
<path d="M34 15 Q34 9 39 11 L43 15 Z" fill="{silk}"/>'''
    return body


def portrait():
    return '''<circle cx="96" cy="96" r="89" fill="#193e32" stroke="#dfbd74" stroke-width="3"/>
<path d="M35 157 Q42 119 68 101 L72 61 L66 29 L88 49 L104 36 L107 62 L139 80 Q162 93 150 110 Q140 119 120 111 L111 149 L139 159 Z" fill="#bc875a"/>
<path d="M35 157 Q42 119 68 101 L72 61 L66 29 L78 42 L82 79 Q77 117 62 149 Z" fill="#f3dfb8"/>
<path d="M104 36 L107 62 L118 73 L101 70 Z" fill="#80563f"/>
<path d="M102 74 Q111 74 117 80" fill="none" stroke="#3a3029" stroke-width="4" stroke-linecap="round"/>
<circle cx="111" cy="82" r="3.5" fill="#142b22"/>
<circle cx="144" cy="100" r="2.5" fill="#80563f"/>
<path d="M126 91 L118 113 L91 105 L94 80" fill="none" stroke="#f2d08a" stroke-width="4"/>
<circle cx="119" cy="109" r="5" fill="none" stroke="#f2d08a" stroke-width="3"/>
<path d="M116 114 Q101 148 72 153" fill="none" stroke="#f2d08a" stroke-width="2"/>
<path d="M49 165 H145" stroke="#dfbd74" stroke-width="3" stroke-linecap="round"/>'''


def main():
    (OUT / 'pixel').mkdir(parents=True, exist_ok=True)
    cells = []
    for i in range(30):
        runner = i // 4 if i < 24 else i - 24
        phase = i % 4 if i < 24 else 0
        art = horse(runner, phase, i >= 24)
        (OUT / 'pixel' / f'horse_{i:02d}.svg').write_text(svg(art, 32, 32, '0 0 64 64'))
        cells.append(f'<g transform="translate({i%4*64} {i//4*64})">{art}</g>')
    (OUT / 'horse-sheet.svg').write_text(svg(''.join(cells), 256, 512))
    (OUT / 'portrait.svg').write_text(svg(portrait(), 192, 192))
    (OUT / 'portrait-pixel.svg').write_text(svg(portrait(), 64, 64, '0 0 192 192'))
    print('Created 33 independently authored SVG assets.')


if __name__ == '__main__':
    main()
