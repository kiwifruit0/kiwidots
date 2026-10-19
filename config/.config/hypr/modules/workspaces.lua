local laptop = "eDP-1"
local assigned_output

for i = 1, 3 do
    hl.workspace_rule({ workspace = tostring(i), monitor = laptop, default = (i == 1) })
end

local function update_workspaces()
    local external
    for _, monitor in ipairs(hl.get_monitors()) do
        if monitor.name ~= laptop then
            -- Keep the current external display when several are connected.
            if monitor.name == assigned_output then
                external = monitor
                break
            end
            if not external or monitor.id < external.id then
                external = monitor
            end
        end
    end

    local output = external and external.name or laptop
    if output ~= assigned_output then
        assigned_output = output
        for i = 4, 6 do
            hl.workspace_rule({
                workspace = tostring(i),
                monitor = output,
                default = (external ~= nil and i == 4),
            })
        end
    end

    -- Rules place new workspaces; explicitly move existing ones after hotplug.
    for i = 1, 6 do
        local target = i <= 3 and laptop or output
        local workspace = hl.get_workspace(i)
        if workspace and hl.get_monitor(target)
            and (not workspace.monitor or workspace.monitor.name ~= target) then
            hl.dispatch(hl.dsp.workspace.move({ workspace = i, monitor = target }))
        end
    end
end

update_workspaces()
hl.on("hyprland.start", update_workspaces)
hl.on("config.reloaded", update_workspaces)
hl.on("monitor.added", update_workspaces)
-- The layout event sees the remaining outputs after a monitor is removed.
hl.on("monitor.layout_changed", update_workspaces)
