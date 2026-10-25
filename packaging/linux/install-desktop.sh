#!/usr/bin/env bash
# Run from the extracted Linux release to add it to your application menu.
set -euo pipefail
game_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
data_dir="${XDG_DATA_HOME:-$HOME/.local/share}"
app_id=io.github.rknell.race-the-nags
test -x "$game_dir/RaceTheNags.x86_64"
mkdir -p "$data_dir/applications" "$data_dir/icons/hicolor/512x512/apps"
cp "$game_dir/icon.png" "$data_dir/icons/hicolor/512x512/apps/$app_id.png"
# Desktop Exec fields have their own escaping rules, separate from shell quoting.
game_exec="$game_dir/RaceTheNags.x86_64"
game_exec="${game_exec//\\/\\\\\\\\}"
game_exec="${game_exec//\$/\\\\\$}"
game_exec="${game_exec//\`/\\\\\`}"
game_exec="${game_exec//\"/\\\\\"}"
game_exec="${game_exec//%/%%}"
while IFS= read -r line; do
    case "$line" in
        Exec=*) printf 'Exec="%s"\n' "$game_exec" ;;
        *) printf '%s\n' "$line" ;;
    esac
done < "$game_dir/$app_id.desktop" > "$data_dir/applications/$app_id.desktop"
printf 'Installed Race the Nags in your application menu. Keep the game in %s\n' "$game_dir"
