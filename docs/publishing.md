# Building and publishing releases

Repository: https://github.com/rknell/race-the-nags

Browser game: https://rknell.github.io/race-the-nags/

Downloads: https://github.com/rknell/race-the-nags/releases/latest

## Build locally on Linux

Godot's version is pinned in `.godot-version`. Python 3, curl, unzip and
sha512sum are required. Setup downloads official editor/export templates and
checks their upstream SHA-512 sums.

```sh
./tools/setup-godot.sh
./tools/test.sh
python3 tools/release.py --version 0.1.0
```

The release script replaces only the generated `release/` directory. The
existing development build under `dist/` is independent.

Four ZIPs and `SHA256SUMS.txt` are generated under `release/artifacts/`:

- Linux x86_64: release runtime and PCK (extract together).
- Windows x86_64: executable with embedded game data.
- macOS universal: app bundle for Intel and Apple Silicon, ad-hoc signed.
- Web: landing page and game, ready for static HTTP(S) hosting.

Serve the Web version with `python3 -m http.server 8000 --directory release/site`
and open http://localhost:8000/. Do not open its HTML directly from disk.
The Web export is single-threaded and does not need cross-origin isolation
headers. It is not a PWA and does not promise offline availability.

## Automated publishing

`.github/workflows/release.yml` runs tests and exports all four targets on
pushes to `main`, version tags, and manual dispatch.

- Successful `main` builds deploy `release/site` to GitHub Pages.
- Tags starting with `v` publish the four ZIPs and checksums as a GitHub Release.
- All builds retain downloads as workflow artifacts.
- GitHub Pages must use GitHub Actions as its publishing source.

For a new release, commit changes and update `docs/release-notes.md`, then:

```sh
git push origin main
git tag v0.1.1
git push origin v0.1.1
```

The tag becomes the version in the archive filenames and macOS bundle. The
workflow must pass before publishing a release. The initial version is 0.1.0.

## Testing and platform limits

The full gameplay/UI/persistence suite runs on Linux, followed by a smoke test
of the exported Linux runtime and packed artwork. Web builds should also be
played in a browser, checking save/continue, sound and controls. Native macOS
and Windows runtime testing requires those operating systems; successful
cross-export alone does not verify their behavior.

macOS builds are not Developer ID signed or notarized. Windows builds are not
code-signed. Signing and notarization can be added later with the appropriate
credentials. Keep credentials in GitHub Actions secrets, never in this repo.

Browser saves use the browser's storage and are separate from desktop saves.
Private browsing, blocked storage and clearing website data can prevent or
remove persistent progress. Desktop players updating to Flatpak in the future
would need their saves migrated to its application-specific storage path.

## Licensing and publication checks

The public implementation, artwork and stable roster use MIT. Original DOS
materials, recovered or adapted artwork and private decompiled evidence are
excluded from both the public source and releases. See `THIRD_PARTY_NOTICES.md`.
`tools/check-publication.py` checks the tracked source and generated packs before
publishing. Private local copies remain ignored and must never be force-added.
