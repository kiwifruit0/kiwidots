#!/bin/sh

app="$1"
title="$2"
shift 2

class="popup-tui"

if pgrep -f "kitty.*--class[ =]$class" >/dev/null; then
    pkill -f "kitty.*--class[ =]$class"
else
    kitty --class "$class" --title "$title" -e "$app" "$@" &
fi
