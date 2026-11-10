local M = {}
local path = (vim.env.XDG_CONFIG_HOME or (vim.env.HOME .. "/.config")) .. "/desktop-theme/current"
local active
local applied

function M.palette()
  local chunk = loadfile(path .. "/palette.lua")
  if chunk then
    local ok, colors = pcall(chunk)
    if ok then return colors end
  end
  return { theme = "nord", variant = "dark", bg = "#2e3440", surface = "#3b4252", raised = "#434c5e", muted = "#8996ab",
    fg = "#d8dee9", accent = "#81a1c1", secondary = "#8fbcbb", red = "#bf616a",
    green = "#a3be8c", yellow = "#ebcb8b", magenta = "#b48ead", cyan = "#88c0d0", orange = "#d08770" }
end

function M.backgrounds()
  local palette = M.palette()
  if palette.theme == "nord" then
    for _, group in ipairs({ "IblIndent", "IblWhitespace" }) do
      vim.api.nvim_set_hl(0, group, { fg = palette.surface })
    end
  end
  for _, group in ipairs({ "NormalFloat", "NeoTreeNormal", "NeoTreeNormalNC", "NeoTreeFloatNormal",
    "NeoTreeEndOfBuffer", "NeoTreeSignColumn", "TelescopeNormal", "TelescopePromptNormal",
    "TelescopeResultsNormal", "TelescopePreviewNormal" }) do
    vim.api.nvim_set_hl(0, group, { link = "Normal" })
  end
  for _, group in ipairs({ "FloatBorder", "NeoTreeFloatBorder", "TelescopeBorder", "TelescopePromptBorder",
    "TelescopeResultsBorder", "TelescopePreviewBorder" }) do
    local highlight = vim.api.nvim_get_hl(0, { name = group, link = false })
    highlight.bg = nil
    vim.api.nvim_set_hl(0, group, highlight)
  end
end

function M.refresh(force)
  local target = vim.uv.fs_realpath(path)
  if not force and target == active and vim.g.colors_name == applied then return end
  active = target
  local palette = M.palette()
  if palette.theme == "nord" then
    vim.g.nord_contrast = false
    vim.g.nord_disable_background = true
    vim.o.background = "dark"
    -- Lazy loads the original Nord plugin; use the generated palette until it is available.
    if not pcall(vim.cmd.colorscheme, "nord") then vim.cmd.colorscheme("desktop") end
  else
    vim.cmd.colorscheme("desktop")
  end
  M.backgrounds()
  applied = vim.g.colors_name
end

function M.setup()
  M.refresh()
  local group = vim.api.nvim_create_augroup("DesktopTheme", { clear = true })
  vim.api.nvim_create_autocmd("ColorScheme", { group = group, callback = M.backgrounds })
  -- Allow plugin ColorScheme hooks; event data must not become the force argument.
  vim.api.nvim_create_autocmd({ "FocusGained", "TermLeave" }, {
    group = group,
    nested = true,
    callback = function() M.refresh() end,
  })
  -- Also catches switches made in another window without terminal focus events.
  local timer = vim.uv.new_timer()
  timer:start(1500, 1500, vim.schedule_wrap(M.refresh))
  vim.api.nvim_create_autocmd("VimLeavePre", { group = group, once = true, callback = function()
    timer:stop()
    timer:close()
  end })
end

return M
