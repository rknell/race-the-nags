#!/usr/bin/env bash
# Install the pinned Linux editor and desktop/web templates, checking upstream hashes.
set -euo pipefail
root="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
version="$(cat "$root/.godot-version")"
downloads="$root/.tools/downloads"
base="https://github.com/godotengine/godot/releases/download/$version-stable"
mkdir -p "$downloads"
curl -fsSL --retry 3 "$base/SHA512-SUMS.txt" -o "$downloads/SHA512-SUMS.txt"
for name in "Godot_v$version-stable_linux.x86_64.zip" "Godot_v$version-stable_export_templates.tpz"; do
  if [[ ! -f "$downloads/$name" ]]; then
    curl -fL --retry 3 "$base/$name" -o "$downloads/$name.part"
    mv "$downloads/$name.part" "$downloads/$name"
  fi
  (cd "$downloads"; awk -v name="$name" '$2 == name || $2 == "*" name {print}' SHA512-SUMS.txt > "$name.sha512"; test -s "$name.sha512"; sha512sum -c "$name.sha512")
done
unzip -oq "$downloads/Godot_v$version-stable_linux.x86_64.zip" -d "$root/.tools"
chmod +x "$root/.tools/Godot_v$version-stable_linux.x86_64"
templates="${XDG_DATA_HOME:-$HOME/.local/share}/godot/export_templates/$version.stable"
mkdir -p "$templates"
# Android/iOS and debug templates are not needed by this project's release builds.
unzip -oj "$downloads/Godot_v$version-stable_export_templates.tpz" \
  templates/version.txt templates/linux_release.x86_64 templates/windows_release_x86_64.exe \
  templates/macos.zip templates/web_nothreads_debug.zip templates/web_nothreads_release.zip -d "$templates"
