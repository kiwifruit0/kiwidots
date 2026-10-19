-- Window and layer behavior from modules/windowrules.conf.
hl.window_rule({
    name = "suppress-maximize-events",
    match = { class = ".*" },
    suppress_event = "maximize",
})

hl.window_rule({
    name = "fix-xwayland-drags",
    match = { class = "^$", title = "^$", xwayland = true, float = true, fullscreen = false, pin = false },
    no_focus = true,
})

hl.window_rule({ match = { class = "^(popup-tui)$" }, float = true, center = true, size = { 800, 400 } })
hl.window_rule({ match = { title = "^(bluetui)$" }, size = { 1000, 500 } })

hl.window_rule({ match = { class = "spotify" }, workspace = "special:magic" })
hl.layer_rule({ match = { namespace = "selector" }, no_anim = true })
hl.window_rule({ match = { class = "Sxiv" }, float = true, center = true, size = { 1000, 600 } })
hl.window_rule({ match = { class = "com.soton.sddp.App" }, float = true })
hl.window_rule({ match = { class = "^zen$", title = "^(Extension)" }, float = true })
hl.window_rule({ match = { class = "Tk" }, float = true, center = true })
hl.window_rule({ match = { class = "thunar", title = "Rename.*" }, float = true })

-- Java / SceneBuilder flickering fixes.
hl.window_rule({
    match = { class = "^SceneBuilder$", title = "^SceneBuilder$" },
    no_focus = true,
    no_initial_focus = true,
    border_size = 0,
    no_shadow = true,
})
local sceneBuilderApp = [[^(com\.oracle\.javafx\.scenebuilder\.app\.SceneBuilderApp)$]]
hl.window_rule({ match = { class = sceneBuilderApp, float = true }, no_initial_focus = true })
hl.window_rule({ match = { class = sceneBuilderApp, float = false }, stay_focused = true })
