#!/usr/bin/env bash
set -euo pipefail
root="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
version="$(cat "$root/.godot-version")"
runtime="${GODOT_BIN:-$root/.tools/Godot_v$version-stable_linux.x86_64}"
# Isolate tests from real player settings and saves.
data_dir="$(mktemp -d)"
trap 'rm -rf "$data_dir"' EXIT
export XDG_DATA_HOME="$data_dir"
"$runtime" --headless --path "$root/godot" --editor --import --quit
for suite in model ui form form_ui history graphics persistence auto remastered_bets game_over bazooka; do
  "$runtime" --headless --path "$root/godot" --script "tests/${suite}_test.gd"
done
