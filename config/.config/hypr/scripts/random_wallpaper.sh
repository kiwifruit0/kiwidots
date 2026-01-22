#!/bin/sh

WALLPAPER_DIR="$HOME/.config/hypr/wallpapers/current/"

random_wallpaper=$(find "$WALLPAPER_DIR" -type f | shuf -n 1)

sed -e "s~<wp>~${random_wallpaper}~g" $HOME/.config/hypr/scripts/hyprpaper.template > $HOME/.config/hypr/hyprpaper.conf
