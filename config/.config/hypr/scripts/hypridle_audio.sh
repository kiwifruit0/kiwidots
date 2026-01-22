#!/bin/bash

if audio-playing; then
  echo "audio playing"
  exit 1
else
  if [ $1 = "dim" ]; then
    echo "dimming screen"
    brightnessctl -s set 20%-
  elif [ $1 = "sleep" ]; then
    echo "suspending"
    systemctl suspend 
  else
    echo "provide argument 'dim' or 'sleep'"
    exit 1
  fi
fi

