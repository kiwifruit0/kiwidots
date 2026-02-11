#!/bin/bash

handle() {
  case $1 in
    monitoradded*) 
      wallpaper=$(awww query | head -n1 | cut -f9 -d ' ')

      awww img $wallpaper -t grow --transition-pos 0.65,0.65 
      ;;
  esac
}

# listen to hyprland events
socat -U - UNIX-CONNECT:$XDG_RUNTIME_DIR/hypr/$HYPRLAND_INSTANCE_SIGNATURE/.socket2.sock | while read -r line; do handle "$line"; done
