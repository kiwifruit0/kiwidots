# kiwidots

These are my dotfiles and setup for arch linux with hyprland. They are structured to be managed with stow, but some packages require manual installation detailed below.

# Installation
Run `./install.sh` and verify symlinks have been created. Follow instructions from the manual installation section

## Manual Installation Steps

### ly

To get a coloured background in ly, the systemd service needs to be updated.

Edit the file `/lib/systemd/system/ly.service` and add the following in the `[Service]` section:
```
ExecStartPre=/usr/bin/printf '%%b' '\e]P03b4252\e]P7FFFFFF\ec'
```
