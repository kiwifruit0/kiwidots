#!/bin/sh

if pgrep -f "kitty.*wiremix" >/dev/null; then
    pkill -f "kitty.*wiremix"
else
    kitty --class wiremix-tui -e wiremix -v output &
fi
