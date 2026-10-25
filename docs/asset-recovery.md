# Public artwork

Public releases use new SVG artwork authored in `tools/generate_artwork.py`.
The generator reads no DOS files, extracted graphics or supplied enhanced images.
The original game's portrait, horse sprites and adaptations are excluded.

The sprites depict independently drawn horses and jockeys using SVG paths,
ellipses and articulated leg poses. Six silk colours identify the runners.
There are 24 gallop cells (four phases for each runner) and six fallen-rider
poses, plus an independently drawn horse badge for the title screen.

- **Pixel graphics:** 32-pixel SVG renders with nearest-neighbour filtering.
- **Illustrated graphics:** a 64-pixel-cell SVG atlas with smooth filtering.
- **Animated horses:** the track's code-drawn horses with moving legs.

Saved graphics preference keys remain compatible with earlier private builds.
Graphics choices do not change racing rules, player state or RNG consumption.

Regenerate the source assets with:

```sh
python3 tools/generate_artwork.py
```

All generated files under `godot/assets/public/` are MIT-licensed.
