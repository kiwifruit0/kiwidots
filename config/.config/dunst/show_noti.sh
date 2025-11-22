#!/bin/bash

# Fetch the notification content passed through Dunst
CONTENT=$(echo "$1")

# Using Rofi to display the content
echo -e "$CONTENT" | rofi -dmenu -p "Notification"
