A playable Godot reconstruction of Race the Nags with Original and Remastered rules, three independently drawn graphics styles, persistent racing history, manual and automatic betting, and local multiplayer for up to six players.

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
This independent recreation ships new code, new artwork and a new 217-horse
roster under MIT. No original DOS programs, recovered/adapted original sprites,
extracted roster or decompiled code is included. See `THIRD_PARTY_NOTICES.md`.
Godot's MIT licence is included separately.
