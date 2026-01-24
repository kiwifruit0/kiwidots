#!/bin/bash

# Use full path
DIR="$HOME/.config/hypr/wallpapers/current"

# Ensure awww is running
pgrep -x "awww-daemon" > /dev/null || awww init

# Selection Menu
# Note: we use -p (prompt) just to give it a title
CHOICE=$(ls "$DIR" | while read -r file; do
    # This formats the line for Rofi: Label\0icon\x1f/full/path/to/image.jpg
    echo -en "$file\0icon\x1f$DIR/$file\n"
done | rofi -dmenu -i -p "Wallpapers" -theme ~/.config/rofi/wallpaper.rasi)

# Apply wallpaper
if [ -n "$CHOICE" ]; then
    awww img "$DIR/$CHOICE" --transition-type grow --transition-pos 0.65,0.65
fi
