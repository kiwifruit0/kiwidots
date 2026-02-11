-- general settings
vim.opt.number = true
vim.opt.signcolumn = "no"
vim.opt.relativenumber = true
vim.opt.termguicolors = true
vim.cmd("set ignorecase smartcase")
vim.opt.scrolloff = 10
vim.opt.showtabline = 0
vim.opt.cursorline = true

-- tab options
vim.opt.expandtab = true
vim.opt.tabstop = 2
vim.opt.shiftwidth = 2
vim.opt.softtabstop = 2

-- global window borders
vim.o.winborder = "rounded"

-- haskell
vim.cmd([[
  syntax on
  filetype plugin indent on
]])

vim.cmd([[
  hi CursorLineNr guifg=#FFFFFF guibg=NONE gui=bold
]])
