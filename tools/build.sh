#!/usr/bin/env bash
set -euo pipefail
project_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
godot_runtime="${GODOT_BIN:-$project_dir/.tools/Godot_v4.7.2-stable_linux.x86_64}"
mkdir -p "$project_dir/dist"
"$godot_runtime" --headless --path "$project_dir/godot" --editor --import --quit
"$godot_runtime" --headless --path "$project_dir/godot" --script tests/model_test.gd
"$godot_runtime" --headless --path "$project_dir/godot" --script tests/ui_test.gd
"$godot_runtime" --headless --path "$project_dir/godot" --script tests/form_test.gd
"$godot_runtime" --headless --path "$project_dir/godot" --script tests/form_ui_test.gd
"$godot_runtime" --headless --path "$project_dir/godot" --script tests/history_test.gd
"$godot_runtime" --headless --path "$project_dir/godot" --script tests/graphics_test.gd
"$godot_runtime" --headless --path "$project_dir/godot" --script tests/persistence_test.gd
"$godot_runtime" --headless --path "$project_dir/godot" --script tests/auto_test.gd
"$godot_runtime" --headless --path "$project_dir/godot" --script tests/remastered_bets_test.gd
"$godot_runtime" --headless --path "$project_dir/godot" --script tests/game_over_test.gd
"$godot_runtime" --headless --path "$project_dir/godot" --script tests/bazooka_test.gd
mkdir -p "$project_dir/dist/releases"
release_dir="$(mktemp -d "$project_dir/dist/releases/build-XXXXXXXX")"
"$godot_runtime" --headless --path "$project_dir/godot" --export-pack Linux "$release_dir/RaceTheNags.pck"
# The existing Godot editor binary also runs PCK games without an editor UI.
# This avoids installing export templates; a release template can replace it.
cp --reflink=auto "$godot_runtime" "$release_dir/RaceTheNags.x86_64"
chmod +x "$release_dir/RaceTheNags.x86_64"
# Godot reopens pack files for lazy resource reads. Keep every release at its
# own path: replacing a running game's PCK invalidates its cached file offsets.
"$release_dir/RaceTheNags.x86_64" --headless --script "$project_dir/tools/verify_pack.gd"
release_name="$(basename -- "$release_dir")"
ln -s "releases/$release_name/RaceTheNags.pck" "$release_dir/pack-link"
ln -s "releases/$release_name/RaceTheNags.x86_64" "$release_dir/executable-link"
mv -Tf "$release_dir/pack-link" "$project_dir/dist/RaceTheNags.pck"
mv -Tf "$release_dir/executable-link" "$project_dir/dist/RaceTheNags.x86_64"
cp "$project_dir/README.md" "$project_dir/dist/README.md"
"$project_dir/dist/RaceTheNags.x86_64" --headless --quit-after 3
