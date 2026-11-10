# Desktop themes

Run `theme-switch` or press **Super+Ctrl+T**. Type to filter, Enter to apply,
Escape to cancel. **Super+Ctrl+W** chooses a wallpaper for the current theme.

```sh
theme-switch --list
theme-switch dracula
theme-switch evergreen                 # alias for Everforest
theme-switch catppuccin                # alias for Catppuccin Mocha
theme-switch catppuccin-latte          # light theme
theme-switch nord
theme-switch --previous
theme-switch --current
theme-switch dracula --dry-run
theme-switch dracula --wallpaper ~/Pictures/forest.png
theme-switch --restore --no-reload      # write settings without contacting apps
```

The bundled themes are Nord, Dracula, Everforest, Gruvbox, Tokyo Night, and all
four Catppuccin flavours: Mocha, Macchiato, Frappé and Latte. `catpuccin` and
`tokyonight` are accepted aliases too. Each preset includes an original 3840×2400
procedural pixel landscape; regenerate them with `python3 scripts/generate-theme-wallpapers.py`.
No downloads or Python packages are needed to switch themes (Python 3.11+).

## Installation

New installations run `./install.sh`; it links the configuration and initializes
Nord. On a machine already using this checkout, run:

```sh
python3 scripts/setup-themes.py --dry-run
python3 scripts/setup-themes.py
theme-switch nord
```

The migration script links the new command and theme resources, and backs up
existing GTK appearance files before replacing their links. It expects the other
app directories to already be linked to this checkout; use the main installer on
a fresh machine. It does not install packages, restart the session or require root.
New Qt applications use the `qt5ct` / `qt6ct` platform plugins; both are included in
`install.sh --desktop`. Log out and in once if the Qt platform environment was not
already set. Other desktop changes work in the current session.

## What changes

| Surface | Behaviour |
| --- | --- |
| Wallpaper | awww applies to all monitors; remembered per theme and reapplied on monitor hotplug/login |
| Hyprland | Active/inactive borders; reloads with existing layouts and all key bindings preserved |
| Hyprlock | Text, password field, border and error colours on the next lock |
| Kitty | All 16 ANSI colours, background, foreground, selection, cursor, tabs and borders; open windows reload |
| Waybar | Shared semantic CSS colours, keeping the existing bar layout; open bars reload |
| Rofi | App launcher, theme picker and wallpaper picker use the same palette |
| Dunst | Generated full config preserves notification behaviour; running daemon reloads |
| GTK 2/3/4 | Recoloured Nordic widgets, GTK settings, XSettings and dark/light GSettings preference |
| Qt 5/6 | Fusion palette through qt5ct/qt6ct; unrelated fonts/icons/preferences retained |
| Neovim | Original `shaunsingh/nord.nvim` syntax for Nord; palette-driven `desktop` scheme for other presets; Neo-tree and Telescope share the editor background; open editors refresh within 1.5 seconds |
| tmux | Status, active window, pane borders, messages and selections; running default server reloads |
| Zsh | Oh My Posh palette and shell highlights; highlights update at the next prompt |
| Codex CLI | Generates `kiwidots.tmTheme` and sets only `tui.theme`; reopen an existing session |
| Claude Code | Generates a custom `kiwidots` theme and sets only the theme preference; reopen once to select it |
| Spotify | Follows the palette when Spicetify's **text** theme is configured; applies without restarting Spotify |

After updating the Neovim theme integration, restart existing Neovim sessions once.
Nord uses the original plugin with `nord_contrast = false` and
`nord_disable_background = true`. Other presets retain the generated syntax palette.
Neo-tree and Telescope inherit `Normal`, including its transparent background;
selection highlights remain visible.

The Codex UI inherits Kitty's terminal palette, with a matching custom syntax
scheme using the [official OpenAI custom-theme format](https://learn.chatgpt.com/docs/cli-customization).
Claude uses its [documented custom-theme tokens](https://code.claude.com/docs/en/terminal-config#create-a-custom-theme).
Once Claude has selected `custom:kiwidots`, its theme file watcher can pick up
subsequent palette edits live. The switcher never kills either coding assistant.

The GTK widget geometry and bitmap assets remain the vendored Nordic design;
these are palette adaptations, rather than downloads of every upstream GTK port.
Some GTK/libadwaita apps restrict custom styling or need reopening. Qt apps may
need reopening. Existing shells launched before installation need a new shell
once to acquire the prompt integration. New prompts then read the stable palette
file. tmux servers started with a custom `-L`/`-S` socket must source the generated
tmux fragment themselves. System login screens, browser/website themes, applications
with their own private themes, and ChatGPT's desktop/web UI are outside these app
configuration integrations. CLI Codex/Claude themes do not control those apps.

Spotify's Marketplace and third-party themes keep their own settings. To opt into
the text theme already supported by this repository, run `./scripts/setup-spicetify.sh`;
it installs text and selects the current desktop palette. Nothing changes Spotify's
active theme or installed extensions without that opt-in.

## Add any palette

Copy `palettes/dracula.json` to `themes/my-theme.json`, change its `name`,
`variant` (`dark` or `light`), thirteen semantic `colors` and sixteen `ansi` colours.
Use a filename containing only lowercase letters, numbers and hyphens. The `source`
field records the upstream palette's provenance. Custom files override matching
bundled names. They are data, never sourced as shell scripts or Lua code.

Add `wallpapers/my-theme.png`, or supply a wallpaper on the first switch:

```sh
theme-switch my-theme --wallpaper ~/Pictures/my-theme.webp
```

That choice is remembered. Put more PNG/JPG/WebP images in
`themes/my-theme/wallpapers/` to include them in its wallpaper picker. Nord's
picker also includes the original `~/.config/hypr/wallpapers/current/` collection.
Preset palette provenance is recorded in each JSON file. The wallpaper art is
original procedural work; its generator is included in the repository.

## State and recovery

`current` is a Git-ignored symlink in this configuration directory. It points to
one complete generated snapshot under `$XDG_STATE_HOME/kiwidots-theme/generations`
(default `~/.local/state/kiwidots-theme/generations`). Switching builds the new
snapshot first, validates shared settings, backs up originals, and atomically
replaces the pointer. It retains the current and previous snapshot; repeated
switches do not accumulate large generated themes or modify tracked app files.
Do not copy the ignored `current` link between machines: initialize on each machine.
Each machine/user should have its own checkout.

Original Codex, Claude, Qt and applicable Spicetify settings are backed up once
under `~/.local/state/kiwidots-theme/backups/`, as are GTK files replaced by the
migration helper. Backups can contain private settings: they stay outside Git,
with private permissions. The switcher preserves unrelated settings and leaves
malformed JSON/TOML untouched. A failed settings write rolls back the shared
settings and pointer; it does not signal applications. An unusual inline Codex
`tui = {...}` table is refused with a message: expand it to `[tui]` first.

Use `theme-switch nord` to return to Nord, or `theme-switch --previous` to undo a
theme choice. `theme-switch --restore` reapplies the selection at login. Cancelling
either picker is a no-op. Missing optional apps are skipped. If a daemon is absent,
its generated configuration still applies when it is next started. Hyprland has
an independent Nord fallback so a missing or broken theme file cannot prevent
keyboard bindings from registering.

Run `python3 -m unittest discover -s tests` from the repository. Theme tests use
isolated homes, including failed-write recovery, dark/light Neovim updates and
Hyprland loading with missing or broken theme files; they never signal your desktop.
