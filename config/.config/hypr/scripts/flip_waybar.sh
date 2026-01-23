#!/bin/sh

waybar_config="$HOME/.config/waybar/config.jsonc"
# read current position
position=$(jq -r '.position' $waybar_config)

# toggle position
if [ "$position" = "top" ]; then
    new_position="bottom"
else
    new_position="top"
fi

# update config
jq --arg pos "$new_position" '
  if ($pos | IN("top","bottom")) then
    .position = $pos
    | with_entries(
        if .key | test("^margin-") then
          .key = ("margin-" + $pos)
        else
          .
        end
      )
  else
    error("argument must be \"top\" or \"bottom\"")
  end
' $waybar_config > config.tmp && mv config.tmp $waybar_config

