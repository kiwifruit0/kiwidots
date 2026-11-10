-- Main Hyprland configuration. Larger groups live in modules/.
-- Source of truth for the migration: hyprland.conf and its imported modules.
local home = os.getenv("HOME")
-- Theme setup must never prevent the rest of the desktop (especially binds) loading.
local theme = { active_border = "rgb(81a1c1)", inactive_border = "rgba(46,52,64,0)" }
local ok, selected_theme = pcall(dofile, home .. "/.config/desktop-theme/current/hyprland.lua")
if ok and type(selected_theme) == "table" then
    theme.active_border = selected_theme.active_border or theme.active_border
    theme.inactive_border = selected_theme.inactive_border or theme.inactive_border
end

-- Monitors: laptop, known external displays, then the fallback rule.
hl.monitor({ output = "eDP-1", mode = "2944x1840@90", position = "auto", scale = "auto", cm = "auto" })
hl.monitor({ output = "desc:Dell Inc. DELL U38", mode = "preferred", position = "auto-center-up", scale = 1.333 })
hl.monitor({ output = "desc:Dell Inc. DELL S2722DC", mode = "preferred", position = "auto-center-up", scale = 1.333 })
hl.monitor({ output = "desc:Sony SONY TV", mode = "preferred", position = "auto-center-up", scale = 1 })
hl.monitor({ output = "", mode = "preferred", position = "auto-center-up", scale = "auto" })

hl.config({ xwayland = { force_zero_scaling = true } })

-- Keep 1-3 on the laptop and send 4-6 to any connected external display.
require("modules.workspaces")

-- Start once per Hyprland session.
hl.on("hyprland.start", function()
	hl.exec_cmd("hyprsunset & hypridle & awww-daemon & xsettingsd")
	hl.exec_cmd("$HOME/.config/hypr/scripts/apply-gtk-settings.sh")
	hl.exec_cmd("$HOME/.local/bin/theme-switch --restore; waybar & dunst")
	hl.exec_cmd("$HOME/.config/hypr/scripts/wallpaper-monitor.sh")
	hl.exec_cmd("dbus-update-activation-environment --systemd WAYLAND_DISPLAY DISPLAY XDG_CURRENT_DESKTOP HYPRLAND_INSTANCE_SIGNATURE && systemctl --user start hyprpolkitagent")
	hl.exec_cmd("hyprctl dispatch workspace 1")
	hl.exec_cmd("rfkill unblock all")
end)

-- Session environment.
hl.env("XCURSOR_SIZE", "16")
hl.env("XCURSOR_THEME", "Bibata-Modern-Classic")
hl.env("HYPRCURSOR_THEME", "Bibata-Modern-Classic")
hl.env("HYPRCURSOR_SIZE", "16")
hl.env("HYPRSHOT_DIR", home .. "/pictures/screenshots")
hl.env("ZDOTDIR", home .. "/.config/zsh")
hl.env("XDG_CONFIG_HOME", home .. "/.config")
hl.env("XDG_CACHE_HOME", home .. "/.cache")
hl.env("XDG_DATA_HOME", home .. "/.local/share")
hl.env("SUDO_EDITOR", "/usr/bin/nvim")
hl.env("EDITOR", "/usr/bin/nvim")
hl.env("GDK_SCALE", "2")
hl.env("GTK_DPI_SCALE", "1")
hl.env("QT_SCALE_FACTOR", "2")
hl.env("QT_QPA_PLATFORMTHEME", "qt5ct")

hl.config({
	general = {
		gaps_in = 3,
		gaps_out = 5,
		border_size = 1,
		col = {
			active_border = theme.active_border,
			inactive_border = theme.inactive_border,
		},
		resize_on_border = true,
		allow_tearing = false,
		layout = "dwindle",
		snap = { enabled = true },
	},
	decoration = {
		rounding = 8,
		rounding_power = 2,
		shadow = {
			enabled = false,
			range = 10,
			render_power = 3,
			color = "rgba(0,0,0,1)",
		},
		blur = {
			enabled = true,
			size = 10,
			passes = 3,
			noise = 0.02,
			special = true,
		},
	},
	animations = { enabled = true },
	dwindle = { preserve_split = true },
	master = { new_status = "master" },
	misc = {
		force_default_wallpaper = 0,
		disable_hyprland_logo = true,
	},
	input = {
		kb_layout = "gb",
		kb_variant = ",qwerty",
		kb_model = "",
		kb_options = "",
		kb_rules = "",
		follow_mouse = 1,
		sensitivity = 1,
		accel_profile = "flat",
		touchpad = {
			natural_scroll = true,
			scroll_factor = 0.25,
		},
	},
})

-- The old config grants hyprpm this permission without enabling enforcement.
hl.permission({ binary = "/usr/(bin|local/bin)/hyprpm", type = "plugin", mode = "allow" })

hl.gesture({ fingers = 3, direction = "horizontal", action = "workspace" })
hl.gesture({ fingers = 3, direction = "down", action = "float", mode = "tile" })
hl.gesture({ fingers = 3, direction = "up", action = "float", mode = "float" })

require("modules.animations")
require("modules.windowrules")
require("modules.binds")
