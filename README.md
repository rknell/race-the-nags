# Race the Nags — independent Godot recreation

A horse racing game inspired by Dick Olsen's 1992 **Race the Nags**. The public
version contains a new GDScript implementation, independently drawn artwork
and 217 newly composed horse names. It does not include the original DOS game,
recovered sprites, enhanced adaptations of those sprites, or decompiled code.

**[Play in your browser](https://rknell.github.io/race-the-nags/)** ·
**[Download for Linux, Windows, macOS or Web](https://github.com/rknell/race-the-nags/releases/latest)**

![The game's title screen with independently drawn artwork](docs/title-screen.png)

## Play

Enter one to six player names and head to the track. Each player starts with
$50 of play money. Select a stake, runner and bet type, then start the race.
Minimum stake is $2; the maximum is $1,000 or the available bankroll.

- **Original rules:** the recovered motion, odds and Win/Place/Show rules,
  implemented anew in Godot. Original refers to the rules, not bundled DOS code
  or original artwork. Win finishes first, Place top two and Show top three.
- **Remastered:** persistent speed, stamina and consistency, recent form, and
  additional Quinella, Exacta, Trifecta and Box Trifecta bets. See
  [Remastered rules](docs/form-mode.md).
- **Graphics:** new Pixel sprites, new Illustrated sprites, or code-drawn
  Animated horses. Graphics can change without affecting a race or its RNG.
- **Automatic racing:** choose a horse-selection strategy, bet type, race count
  and stake. A $0 stake uses 10% of the bankroll, with a $2 minimum.
- **Persistence:** remembered names, preferences, save/continue, racing form and
  separate records for each ruleset. When every player has less than $2, the
  visit ends and a final scoreboard appears.

Desktop archives need no Godot installation. Extract the whole ZIP and run:

| Platform | Application |
| --- | --- |
| Linux x86_64 | `RaceTheNags.x86_64` (keep the PCK beside it) |
| Windows x86_64 | `RaceTheNags.exe` |
| macOS Intel / Apple Silicon | `Race the Nags.app` |

macOS is ad-hoc signed, not Developer ID signed or notarized. Windows is
unsigned. Linux is smoke-tested; Windows and macOS builds are cross-exported
and have not been played on those operating systems.

Browser progress belongs to that browser and website. Clearing site data can
remove saves; browser and desktop saves do not synchronize. Best on a desktop
or laptop. Browser keyboard shortcuts may take precedence over game shortcuts.

| Control | Action |
| --- | --- |
| Space | Start / next race when outside a form control |
| Escape | Pause / close a window |
| F1 | Help |
| F8 | Save |
| F10 | Toggle sound |

Saves use Godot's `user://` directory, normally
`~/.local/share/godot/app_userdata/Race the Nags/` on Linux.
Older private-build saves remain readable, but may contain their old horse
names; their roster IDs now refer to the new public stable.

## Build and publish

Developed with Godot 4.7.2, pinned in `.godot-version`.

```sh
./tools/setup-godot.sh
./tools/test.sh
python3 tools/release.py --version 0.1.0
```

The release script creates four ZIPs and SHA-256 checksums in
`release/artifacts/`, plus a ready-to-host website in `release/site/`.
`./launch.sh` runs the local development build; `./tools/build.sh` rebuilds it.
You can also import `godot/project.godot` in the editor and press F5.

Pushes to `main` run tests and deploy GitHub Pages. Tags beginning with `v`
publish GitHub Releases after the checks pass. See
[building and publishing](docs/publishing.md).

## Artwork and provenance

All public horse sprites and portraits are new SVG drawings defined in
`tools/generate_artwork.py`. Run that script to regenerate them without reading
any original game files. See [public artwork](docs/asset-recovery.md).

The new rules implementation was informed by analysis of the original game.
Original DOS materials and private reverse-engineering evidence are excluded
from the public source and release packages. Original authorship is credited
as historical inspiration; this recreation is not endorsed by the author.

The new code, artwork, data and documentation are **MIT-licensed**. Godot's
licence is included separately. See [third-party notices](THIRD_PARTY_NOTICES.md).
