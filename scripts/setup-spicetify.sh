#!/bin/bash
set -euo pipefail

for tool in curl spicetify; do
    command -v "$tool" >/dev/null || { echo "Missing dependency: $tool" >&2; exit 1; }
done

spotify_dir="${XDG_DATA_HOME:-$HOME/.local/share}/spotify-launcher/install/usr/share/spotify"
prefs_path="${XDG_CONFIG_HOME:-$HOME/.config}/spotify/prefs"
if [[ ! -d "$spotify_dir" || ! -f "$prefs_path" ]]; then
    echo "Open Spotify through spotify-launcher, log in, then close it before running this script." >&2
    exit 1
fi

theme_tmp=$(mktemp -d)
trap 'rm -rf "$theme_tmp"' EXIT
theme_url="https://raw.githubusercontent.com/spicetify/spicetify-themes/master/text"
for file in color.ini user.css; do
    curl --fail --silent --show-error --location "$theme_url/$file" --output "$theme_tmp/$file"
done

theme_dir="$(dirname "$(spicetify -c)")/Themes/text"
mkdir -p "$theme_dir"
mv "$theme_tmp/color.ini" "$theme_tmp/user.css" "$theme_dir/"

spicetify config spotify_path "$spotify_dir" prefs_path "$prefs_path" \
    current_theme text color_scheme Nord inject_css 1 replace_colors 1
theme_switch="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)/config/.local/bin/theme-switch"
if [[ -x "$theme_switch" ]]; then
    "$theme_switch" --restore --no-reload
fi
spicetify --no-restart backup apply
echo "Applied text with the desktop palette. Start Spotify to see the theme."
