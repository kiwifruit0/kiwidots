-- A native palette-driven scheme: every desktop preset works without a plugin download.
local c = require("config.desktop-theme").palette()
vim.cmd("highlight clear")
vim.o.termguicolors = true
local luminance = tonumber(c.bg:sub(2, 3), 16) + tonumber(c.bg:sub(4, 5), 16) + tonumber(c.bg:sub(6, 7), 16)
vim.o.background = luminance > 500 and "light" or "dark"
vim.g.colors_name = "desktop"
local h = function(group, opts) vim.api.nvim_set_hl(0, group, opts) end
for _, group in ipairs({ "Normal", "NormalNC", "SignColumn", "EndOfBuffer" }) do h(group, { fg = c.fg, bg = "NONE" }) end
h("Pmenu", { fg = c.fg, bg = c.surface })
for _, group in ipairs({ "NormalFloat", "TelescopeNormal", "NeoTreeNormal", "NeoTreeNormalNC" }) do h(group, { fg = c.fg, bg = "NONE" }) end
for _, group in ipairs({ "FloatBorder", "WinSeparator", "VertSplit", "TelescopeBorder" }) do h(group, { fg = c.raised }) end
for _, group in ipairs({ "Comment", "LineNr", "NonText", "Whitespace", "Conceal", "@comment" }) do h(group, { fg = c.muted }) end
for _, group in ipairs({ "CursorLineNr", "Title", "Function", "Directory", "@function", "@function.call", "@function.method", "@function.method.call", "@markup.heading" }) do h(group, { fg = c.accent, bold = true }) end
for _, group in ipairs({ "String", "Character", "@string", "@character", "@markup.link.url", "Added", "GitSignsAdd" }) do h(group, { fg = c.green }) end
for _, group in ipairs({ "Constant", "Number", "Boolean", "Float", "@number", "@boolean", "@constant", "@constant.builtin" }) do h(group, { fg = c.orange }) end
for _, group in ipairs({ "Statement", "Conditional", "Repeat", "Label", "Keyword", "Exception", "PreProc", "Include", "Define", "Macro", "@keyword", "@keyword.function", "@keyword.return", "@keyword.import", "@operator" }) do h(group, { fg = c.magenta }) end
for _, group in ipairs({ "Type", "StorageClass", "Structure", "Typedef", "@type", "@type.builtin", "@constructor", "@module", "@attribute" }) do h(group, { fg = c.yellow }) end
for _, group in ipairs({ "Identifier", "@variable", "@variable.parameter", "@variable.member" }) do h(group, { fg = c.fg }) end
for _, group in ipairs({ "Special", "Operator", "Delimiter", "@punctuation", "@tag", "@variable.builtin", "@string.escape" }) do h(group, { fg = c.cyan }) end
for _, group in ipairs({ "Error", "ErrorMsg", "Removed", "GitSignsDelete" }) do h(group, { fg = c.red }) end
for _, group in ipairs({ "WarningMsg", "Changed", "GitSignsChange" }) do h(group, { fg = c.yellow }) end
h("CursorLine", { bg = c.surface })
h("ColorColumn", { bg = c.surface })
h("Visual", { bg = c.raised })
h("PmenuSel", { fg = c.bg, bg = c.accent, bold = true })
h("PmenuSbar", { bg = c.raised })
h("PmenuThumb", { bg = c.accent })
h("Search", { fg = c.bg, bg = c.yellow })
h("IncSearch", { fg = c.bg, bg = c.orange })
h("CurSearch", { link = "IncSearch" })
h("MatchParen", { fg = c.accent, bg = c.raised, bold = true })
h("StatusLine", { fg = c.fg, bg = c.surface })
h("StatusLineNC", { fg = c.muted, bg = c.surface })
h("TabLine", { fg = c.muted, bg = c.surface })
h("TabLineFill", { bg = c.surface })
h("TabLineSel", { fg = c.bg, bg = c.accent, bold = true })
h("WinBar", { fg = c.fg })
h("WinBarNC", { fg = c.muted })
h("Folded", { fg = c.muted, bg = c.surface })
h("FoldColumn", { fg = c.muted })
h("Todo", { fg = c.bg, bg = c.yellow, bold = true })
h("DiffAdd", { fg = c.green, bg = c.surface })
h("DiffDelete", { fg = c.red, bg = c.surface })
h("DiffChange", { fg = c.yellow, bg = c.surface })
h("DiffText", { fg = c.bg, bg = c.yellow })
for kind, color in pairs({ Error = c.red, Warn = c.yellow, Info = c.cyan, Hint = c.green, Ok = c.green }) do
  h("Diagnostic" .. kind, { fg = color })
  h("DiagnosticVirtualText" .. kind, { fg = color })
  h("DiagnosticUnderline" .. kind, { sp = color, undercurl = true })
end
for _, group in ipairs({ "SpellBad", "SpellCap", "SpellLocal", "SpellRare" }) do h(group, { sp = c.red, undercurl = true }) end
h("@markup.strong", { bold = true })
h("@markup.italic", { italic = true })
h("@markup.strikethrough", { strikethrough = true })
h("@markup.raw", { fg = c.green })
h("@markup.link", { fg = c.cyan, underline = true })
h("@lsp.type.parameter", { fg = c.fg })
h("@lsp.type.property", { fg = c.fg })
h("IblIndent", { fg = c.raised })
h("IblScope", { fg = c.muted })
h("TelescopeSelection", { fg = c.accent, bg = c.raised, bold = true })
h("NeoTreeDirectoryName", { fg = c.accent })
h("NeoTreeDirectoryIcon", { fg = c.accent })
h("NeoTreeGitModified", { fg = c.yellow })
h("NeoTreeGitUntracked", { fg = c.green })
h("NoiceCmdlinePopupBorder", { fg = c.accent })
