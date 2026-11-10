#!/bin/sh
set -eu

gsettings set org.gnome.desktop.interface gtk-theme Kiwidots
gsettings set org.gnome.desktop.interface icon-theme Adwaita
gsettings set org.gnome.desktop.interface font-name 'Adwaita Sans 11'
gsettings set org.gnome.desktop.interface cursor-theme Bibata-Modern-Classic
gsettings set org.gnome.desktop.interface cursor-size 16
# theme-switch --restore applies the saved light/dark preference.
