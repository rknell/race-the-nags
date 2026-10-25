# Linux desktop integration and Flathub readiness

Prepared on 25 October 2026. **Not submitted to Flathub.**

## Prepared upstream files

- `io.github.rknell.race-the-nags.desktop`: application-menu entry; expects an installed `race-the-nags` command.
- `io.github.rknell.race-the-nags.metainfo.xml`: AppStream listing metadata for the existing v0.1.2 game, with screenshots, developer and release information, and play-money gambling/cartoon-violence ratings.
- `io.github.rknell.race-the-nags.svg`: a scalable icon based on the independently drawn horse-badge study. It does not replace the game's enhanced graphics.
- `../../tools/validate-linux-metadata.sh`: desktop/AppStream validation.

The application ID corresponds to the existing GitHub repository. These files
are desktop metadata, not a Flatpak build manifest, installer or package.
No game code or graphics preferences were changed by this preparation.

## Checks completed

`desktop-file-validate` passed. `appstreamcli validate --strict` passed with
AppStream 1.0.2, including network validation of screenshot URLs. Flatpak 1.14.6
and flatpak-builder 1.4.2 are installed locally. No Flatpak has been built,
installed or smoke-tested for this app; that awaits a human-authored manifest.

Run metadata validation again with:

```sh
./tools/validate-linux-metadata.sh
```

## Submission constraints

Flathub's [current AI policy](https://docs.flathub.org/docs/for-app-authors/requirements#generative-ai-policy)
prohibits AI-authored/assisted manifests and agent-operated submission PRs.
A human must independently write the manifest and perform submission, including
the submission text and review interaction. Other AI-generated material requires
disclosure and is reviewed at Flathub's discretion. This directory was created
with AI assistance and must not be presented as human-authored packaging.

The [licensing requirements](https://docs.flathub.org/docs/for-app-authors/requirements#license)
also require redistribution rights. The current game includes original graphics
without documented reuse permission. A takedown offer is not a redistribution
licence. `MIT AND LicenseRef-proprietary` describes the mixed licensing in the
metadata; it does not assert clearance or grant rights.

The app's short public development history may also require a reviewer
exception under the [development-history requirement](https://docs.flathub.org/docs/for-app-authors/requirements#insufficient-development-history).

## Human handoff

Before submission, resolve the asset rights or decide on a separately approved
edition using rights-cleared artwork. Do not silently remove or substitute the
project creator's enhanced graphics. Recheck the project's licence declaration
and AppStream metadata against the edition actually being submitted.

Use Flathub's [official submission guide](https://docs.flathub.org/docs/for-app-authors/submission)
for independent manifest authoring, local build/install tests, linting and the
submission PR. This directory intentionally contains no manifest, PR body,
submission commit message, or review-response draft.

For a human disclosure assessment, the known development record is: most or
all of the newly written GDScript implementation, build tools, documentation,
workflows and SVG studies were AI-authored or AI-assisted. These desktop
metadata files and icon preparation are AI-assisted. Classic art predates this
project; enhanced images were supplied by the project creator, whose creation
process must be confirmed by that creator rather than guessed. The human
submitter must assess the approximate extent and write their own disclosure.

After a human-authored manifest exists, AI may help with research and debugging
without authoring manifest content or automating submission/review interactions.
