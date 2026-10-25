# Artwork and provenance

## Classic — 1992 graphics

Classic uses the original title portrait and 30 horse/rider images, credited
to Richard “Dick” Olsen / Olsen Outdoors, 1992. They were decoded from the
supplied NAG.PCX and PONY.IMG without redrawing or AI enhancement. Transparency
keys the original flat background colour. File sources and SHA-256 hashes are
recorded in `godot/assets/heritage/provenance.json`.

Only these 31 selected images are shipped. The DOS executables, raw PCX/IMG
files, manuals and decompiled evidence remain excluded. These images are not
MIT-licensed; no additional permission for reuse in this reconstruction has
been documented. See [preservation and takedown notice](../THIRD_PARTY_NOTICES.md).

## Enhanced graphics restored from the supplied files

The project creator's three enhanced images are preserved byte-for-byte under
`godot/assets/heritage/enhanced/`:

- `nag_transparent_endhanced.png`: the enhanced title portrait, also used by Animated.
- `horse_sheet_enhanced.png`: 24 gallop frames arranged in four columns and six rows.
- `pony_sheet_enhanced.png`: the six fallen-rider poses, with the original crop
  positions and padding restored to avoid including arrow graphics.

Their SHA-256 hashes are recorded in the provenance manifest. They are excluded
from the MIT grant alongside the original imagery, with the same preservation
and takedown notice. No enhanced images were regenerated or replaced.

## Code-drawn animation and SVG studies

Animated uses the track's code-drawn moving horses and the supplied enhanced
portrait. Alternative independently drawn SVG studies remain under
`godot/assets/public/`, with their generator in `tools/generate_artwork.py`.
These SVG studies are not used in place of the supplied Enhanced graphics.
The code-drawn animation and SVG studies are MIT-licensed.

Saved graphics preference keys are unchanged. Switching styles does not change
racing rules, player state or RNG consumption.
