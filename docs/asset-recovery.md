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

## New artwork

Illustrated uses the independently drawn SVG atlas and horse badge defined in
`tools/generate_artwork.py`. Animated uses the track's code-drawn horses and
new badge. Run the generator to regenerate new SVGs without reading DOS files.
New SVG assets under `godot/assets/public/` are MIT-licensed.

Graphics preferences remain compatible with earlier builds. Switching styles
does not change racing rules, player state or RNG consumption.
