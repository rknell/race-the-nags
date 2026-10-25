#!/usr/bin/env bash
set -euo pipefail
project_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
if [[ -x "$project_dir/dist/RaceTheNags.x86_64" ]]; then
  game_runtime="$(readlink -f -- "$project_dir/dist/RaceTheNags.x86_64")"
  exec "$game_runtime" --main-pack "$(dirname -- "$game_runtime")/RaceTheNags.pck" "$@"
fi
if [[ -n "${GODOT_BIN:-}" ]]; then
  exec "$GODOT_BIN" --path "$project_dir/godot" "$@"
fi
if [[ -x "$project_dir/.tools/Godot_v4.7.2-stable_linux.x86_64" ]]; then
  exec "$project_dir/.tools/Godot_v4.7.2-stable_linux.x86_64" --path "$project_dir/godot" "$@"
fi
exec godot --path "$project_dir/godot" "$@"
