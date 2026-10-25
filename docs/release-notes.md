A playable Godot reconstruction of Race the Nags with Original and Remastered rules, restored Classic graphics plus new Illustrated and Animated styles, persistent racing history, manual and automatic betting, and local multiplayer for up to six players.

## Play

- **Browser:** https://rknell.github.io/race-the-nags/
- **Linux x86_64:** download the Linux ZIP, extract it, and run `RaceTheNags.x86_64` (mark executable if your archive tool removes permissions).
- **Windows x86_64:** download the Windows ZIP, extract it, and run `RaceTheNags.exe`.
- **macOS Intel / Apple Silicon:** download the macOS ZIP, extract it, and open `Race the Nags.app`. The app is ad-hoc signed, not Developer ID signed or notarized; macOS may block launch. Use the browser version if you prefer. See Apple's instructions for opening an app from an unidentified developer: https://support.apple.com/guide/mac-help/open-an-app-by-overriding-security-settings-mh40616/mac.
- **Self-hosted web:** extract the Web ZIP and serve the entire folder over HTTP(S); opening the HTML directly from disk does not work.

Browser saves are local to that browser and website, and may be lost if site data is cleared. Desktop saves and browser saves are separate. The interface is designed primarily for desktop screens. Windows downloads are not signed and may trigger reputation warnings.

`SHA256SUMS.txt` contains hashes of all four downloads. Automated tests and Linux smoke tests run before release; Windows and macOS builds are exported but have not been played on those operating systems.

## Attribution

Inspired by Race the Nags by Richard “Dick” Olsen / Olsen Outdoors (1992).
Classic graphics restore 31 original portrait and horse/rider images, credited
to the original creator. They retain their original rights and are excluded
from MIT. The new code, new artwork and new roster use MIT. No DOS programs,
raw PCX/IMG files or decompiled code are included.

This free, non-commercial tribute includes a rightsholder/heir/estate takedown
commitment and contact route in `THIRD_PARTY_NOTICES.md`. That notice does not
establish permission for reuse of original graphics. Godot's MIT licence is
included separately.
