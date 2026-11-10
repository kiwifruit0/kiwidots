#!/bin/bash
set -eu
socat -U - "UNIX-CONNECT:$XDG_RUNTIME_DIR/hypr/$HYPRLAND_INSTANCE_SIGNATURE/.socket2.sock" |
    while IFS= read -r event; do
        case "$event" in
            monitoradded*) "$HOME/.local/bin/theme-switch" --apply-wallpaper ;;
        esac
    done
