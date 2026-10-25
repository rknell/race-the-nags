#!/usr/bin/env bash
# Validate upstream desktop metadata; this does not create or submit a Flatpak manifest.
set -euo pipefail
root="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
desktop-file-validate "$root/packaging/linux/io.github.rknell.race-the-nags.desktop"
appstreamcli validate --strict "$root/packaging/linux/io.github.rknell.race-the-nags.metainfo.xml"
