# kiwidots

These are my Arch Linux / Hyprland dotfiles, managed with GNU Stow.

# Installation
Run the installer as your normal user from any directory. The checkout can live
anywhere; it does not have to be `~/dotfiles`. Install GNU Stow first
(`sudo pacman -Syu --needed stow` on Arch).

```sh
./install.sh --dry-run                 # Preview home configuration and conflicts
./install.sh                           # Link home configuration only; no sudo
./install.sh --system --dry-run        # Preview all system configuration
./install.sh --home --system           # Link both scopes; system changes use sudo
./install.sh --spicetify               # Only set up Spotify's theme
./install.sh --desktop --dry-run       # Preview the Arch desktop setup
./install.sh --desktop                 # Install packages, link configs, enable services
```

Scopes can be combined. Every selected Stow scope is checked for conflicts before
any changes, package installation, downloads, or sudo. Back up and move conflicting
files named in the output, then rerun; the installer never adopts or overwrites them.
An existing directory with unrelated files can remain in place. Dry runs do not
install packages, download assets, change services, or request sudo.

The final summary lists completed steps. A failure stops further work, but does
not roll back earlier package installations or links.

## Arch desktop setup

`--desktop` installs the explicit list in [desktop/packages.txt](desktop/packages.txt)
using `pacman -Syu --needed`, including a full system upgrade. Pacman retains its
normal confirmation prompts. The list covers Hyprland, awww, Waybar, Kitty, Rofi,
Dunst, Thunar, locking/idle/night light, screenshots, Wiremix, Bluetui, PipeWire,
Bluetooth, NetworkManager, portals, a privilege prompt, keyboard remapping, and the
fonts/icons and small utilities used by these configs. All packages come from the
official repositories; no AUR helper or build toolchain is installed.

It also installs missing Znap and the pinned Oh My Posh binary used by Kitty's Zsh
configuration, plus only the Bibata Modern Classic cursor variant. Release downloads
are checksum-verified; existing installed copies are kept. Znap downloads the declared
shell plugins on first shell startup. The installer does not change your login shell.

Desktop mode links the home configuration and system keyboard/audio/battery files.
It skips legacy Ly and suspend unit files unless `--system` is explicitly included.
Hypridle locks the session before suspend. Bluetooth, NetworkManager, keyd, PipeWire,
WirePlumber and the battery timer are enabled for the next login/boot. The setup
script does not start or restart services; package upgrades run their normal hooks.
If systemd-networkd or ConnMan is enabled, NetworkManager
is left disabled and setup prints the remaining manual step. Start Hyprland through
your existing login manager or run `start-hyprland` from a TTY; no display manager is
installed or replaced.

Browsers, editors, developer toolchains, tmux, Yazi, media players and other
application-specific tools are outside this package list. Their existing configs
or key bindings can still be present. Spotify/Spicetify remains a separate opt-in.
Review monitor scaling and device-specific keyboard mappings for a different machine.

On an existing installation, GTK settings, CSS/asset links, the default cursor
settings, `~/.zshrc`, and `~/.themes/Nordic-darker` may already exist outside Stow.
Keep a backup of those files (or the whole Nordic-darker directory) and move them
aside before applying the new links. Leave unrelated files such as GTK bookmarks
in place.

## Desktop themes

Press **Super+Ctrl+T** or run `theme-switch` to choose a desktop theme.
Nord, Dracula, Everforest, Gruvbox, Tokyo Night and all four Catppuccin flavours
are bundled with matching wallpapers. **Super+Ctrl+W** picks and remembers a
wallpaper for the selected theme.

```sh
theme-switch dracula
theme-switch catppuccin
theme-switch evergreen
theme-switch --previous
theme-switch nord
```

On an existing Stow desktop, run `python3 scripts/setup-themes.py` once to link
the new command/resources and back up existing GTK appearance files, then run
`theme-switch nord`. New home installations initialize the theme automatically.

The switcher covers the wallpaper, Hyprland, Hyprlock, Kitty, Rofi, Waybar, Dunst,
GTK 2/3/4, Qt 5/6, Neovim, tmux, Zsh, Codex CLI and Claude Code. Spotify follows
when the repository's Spicetify text theme is configured. See the
[theme guide](config/.config/desktop-theme/README.md) for exact reload behaviour,
custom palettes, backups, limitations and recovery commands.

GTK palettes use the tracked Nordic-darker widget design and assets, retaining
its upstream GPL-3.0 licence from [EliverLara/Nordic](https://github.com/EliverLara/Nordic).
The original snapshot's optional missing selection/color-button images remain
unchanged. Bibata Modern Classic comes from the
[upstream 2.0.6 release](https://github.com/ful1e5/Bibata_Cursor/releases/tag/v2.0.6).
Its cursor binaries stay outside Git. Versions and checksums for Bibata and Oh My
Posh are recorded in `scripts/setup-desktop.sh`.

## Checks

Run `python -m unittest discover -s tests` for isolated installer checks. They use
temporary home directories and mock privileged/package/service operations.

## Manual Installation Steps

### Spicetify

Install `spotify-launcher`, `spicetify-cli` (AUR), and `curl`. Open Spotify,
log in and leave it running for at least a minute on first install, then close it.
Run:

```sh
./scripts/setup-spicetify.sh
```

This downloads the upstream [text theme](https://github.com/spicetify/spicetify-themes/tree/master/text),
selects the current desktop palette, and applies it to the user-owned Spotify install
managed by `spotify-launcher`. Existing extensions and custom apps are preserved.
Spicetify's generated config, backups, and downloaded theme files stay outside Git.

Rerun the script to update the theme. Subsequent desktop theme switches also update its palette. After Spotify updates, close Spotify and run
`spicetify --no-restart backup apply`, then reopen it. Update `spicetify-cli` through
your AUR helper if it needs compatibility fixes for a newer Spotify version.

### ly

To get a coloured background in ly, the systemd service needs to be updated.

Edit the file `/lib/systemd/system/ly.service` and add the following in the `[Service]` section:
```
ExecStartPre=/usr/bin/printf '%%b' '\e]P03b4252\e]P7FFFFFF\ec'
```
