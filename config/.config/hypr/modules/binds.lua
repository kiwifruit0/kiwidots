-- Key and mouse bindings from modules/binds.conf.
hl.config({ binds = { hide_special_on_workspace_change = true } })

local mod = "SUPER"
local home = os.getenv("HOME")
local hyprScripts = home .. "/.config/hypr/scripts/"

-- Applications and session tools.
hl.bind(mod .. " + CTRL + T", hl.dsp.exec_cmd(home .. "/.local/bin/theme-switch"))
hl.bind(mod .. " + T", hl.dsp.exec_cmd("kitty"))
hl.bind(mod .. " + E", hl.dsp.exec_cmd("thunar"))
hl.bind(mod .. " + A", hl.dsp.exec_cmd("pkill rofi || rofi -show drun"))
hl.bind(mod .. " + Y", hl.dsp.exec_cmd("kitty -e yazi"))
hl.bind(mod .. " + CTRL + W", hl.dsp.exec_cmd("pkill rofi || " .. home .. "/.config/rofi/scripts/wp-switch.sh"))
hl.bind(mod .. " + CTRL + L", hl.dsp.exec_cmd("hyprlock --no-fade-in"))
hl.bind(mod .. " + F", hl.dsp.exec_cmd("zen-browser"))
hl.bind(mod .. " + D", hl.dsp.exec_cmd("hyprshot -m region"))
hl.bind(mod .. " + SHIFT + D", hl.dsp.exec_cmd("hyprshot -m window"))
hl.bind(mod .. " + CTRL + D", hl.dsp.exec_cmd("hyprshot -m output"))
hl.bind(mod .. " + SHIFT + A", hl.dsp.exec_cmd(hyprScripts .. "tui-popup.sh wiremix wiremix -v output"))
hl.bind(mod .. " + SHIFT + B", hl.dsp.exec_cmd(hyprScripts .. "tui-popup.sh bluetui bluetui"))
hl.bind(mod .. " + R", hl.dsp.exec_cmd("if pgrep waybar > /dev/null; then killall waybar; fi; waybar &"))
hl.bind(mod .. " + SHIFT + R", hl.dsp.exec_cmd("killall waybar && " .. hyprScripts .. "flip_waybar.sh && waybar &"))
hl.bind(mod .. " + SHIFT + C", hl.dsp.exec_cmd("hyprpicker | wl-copy"))


-- Window actions.
hl.bind(mod .. " + Q", hl.dsp.window.close())
hl.bind(mod .. " + SHIFT + ALT + CTRL + M", hl.dsp.exit())
hl.bind(mod .. " + CTRL + P", hl.dsp.window.pin())
hl.bind(mod .. " + V", hl.dsp.layout("togglesplit"))
hl.bind(mod .. " + SHIFT + F", hl.dsp.window.fullscreen())
hl.bind(mod .. " + W", hl.dsp.window.float({ action = "toggle" }))

local directions = { H = "left", L = "right", K = "up", J = "down" }
for key, direction in pairs(directions) do
    hl.bind(mod .. " + " .. key, hl.dsp.focus({ direction = direction }))
    hl.bind(mod .. " + ALT + " .. key, hl.dsp.window.swap({ direction = direction }))
end

for i = 1, 10 do
    local key = tostring(i % 10)
    hl.bind(mod .. " + " .. key, hl.dsp.focus({ workspace = i }))
    hl.bind(mod .. " + SHIFT + " .. key, hl.dsp.window.move({ workspace = i }))
end

local resize = { L = { 30, 0 }, H = { -30, 0 }, K = { 0, -30 }, J = { 0, 30 } }
for key, delta in pairs(resize) do
    hl.bind(mod .. " + SHIFT + " .. key,
        hl.dsp.window.resize({ x = delta[1], y = delta[2], relative = true }),
        { repeating = true })
end

hl.bind(mod .. " + S", hl.dsp.workspace.toggle_special("music"))
hl.bind(mod .. " + SHIFT + S", hl.dsp.window.move({ workspace = "special:music" }))
hl.bind(mod .. " + G", hl.dsp.workspace.toggle_special("helper"))
hl.bind(mod .. " + SHIFT + G", hl.dsp.window.move({ workspace = "special:helper" }))

hl.bind(mod .. " + mouse_down", hl.dsp.focus({ workspace = "e+1" }))
hl.bind(mod .. " + mouse_up", hl.dsp.focus({ workspace = "e-1" }))
hl.bind(mod .. " + mouse:272", hl.dsp.window.drag(), { mouse = true })
hl.bind(mod .. " + mouse:273", hl.dsp.window.resize(), { mouse = true })

-- Hardware keys retain the old locked/repeating flags.
local lockedRepeat = { locked = true, repeating = true }
hl.bind("XF86AudioRaiseVolume", hl.dsp.exec_cmd("wpctl set-volume -l 1 @DEFAULT_AUDIO_SINK@ 5%+"), lockedRepeat)
hl.bind("XF86AudioLowerVolume", hl.dsp.exec_cmd("wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-"), lockedRepeat)
hl.bind("XF86AudioMute", hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"), lockedRepeat)
hl.bind("XF86AudioMicMute", hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle"), lockedRepeat)
hl.bind("XF86MonBrightnessUp", hl.dsp.exec_cmd("brightnessctl -n1 set 5%+"), lockedRepeat)
hl.bind("XF86MonBrightnessDown", hl.dsp.exec_cmd("brightnessctl -n2 set 5%-"), lockedRepeat)

local locked = { locked = true }
hl.bind("XF86AudioNext", hl.dsp.exec_cmd("playerctl next"), locked)
hl.bind("XF86AudioPause", hl.dsp.exec_cmd("playerctl play-pause"), locked)
hl.bind("XF86AudioPlay", hl.dsp.exec_cmd("playerctl play-pause"), locked)
hl.bind("XF86AudioPrev", hl.dsp.exec_cmd("playerctl previous"), locked)
hl.bind("XF86AudioMicMute", hl.dsp.exec_cmd("playerctl play-pause"), locked)
hl.bind(mod .. " + SHIFT + right", hl.dsp.exec_cmd("playerctl next"), locked)
hl.bind(mod .. " + SHIFT + left", hl.dsp.exec_cmd("playerctl previous"), locked)
hl.bind(mod .. " + SHIFT + space", hl.dsp.exec_cmd("playerctl play-pause"), locked)
