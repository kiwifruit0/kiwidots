#!/bin/bash

# Function to focus or launch application
focus_or_launch() {
    local app_class="$1"
    local launch_cmd="$2"
    
    if hyprctl clients -j | jq -e ".[] | select(.class == \"$app_class\")" > /dev/null 2>&1; then
        hyprctl dispatch focuswindow "class:^($app_class)$"
    else
        $launch_cmd &
    fi
}

# Use desktop entry if available (most reliable)
if [ -n "$DUNST_DESKTOP_ENTRY" ]; then
    case "${DUNST_DESKTOP_ENTRY,,}" in
        *vesktop*)
            focus_or_launch "vesktop" "vesktop"
            ;;
        *discord*)
            focus_or_launch "discord" "discord"
            ;;
        *firefox*)
            focus_or_launch "firefox" "firefox"
            ;;
        *spotify*)
            focus_or_launch "Spotify" "spotify"
            ;;
        *)
            gtk-launch "$DUNST_DESKTOP_ENTRY" &
            ;;
    esac
else
    # Fallback to app name
    case "${DUNST_APP_NAME,,}" in
        vesktop)
            focus_or_launch "vesktop" "vesktop"
            ;;
        discord)
            focus_or_launch "discord" "discord"
            ;;
        firefox)
            focus_or_launch "firefox" "firefox"
            ;;
        spotify)
            focus_or_launch "Spotify" "spotify"
            ;;
        *)
            ${DUNST_APP_NAME,,} &
            ;;
    esac
fi
