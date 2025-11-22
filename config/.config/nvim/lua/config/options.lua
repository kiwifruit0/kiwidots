-- general settings
vim.opt.relativenumber = true
vim.opt.termguicolors = true
vim.cmd('set ignorecase smartcase')

-- tab options
vim.opt.expandtab = true
vim.opt.tabstop = 2
vim.opt.shiftwidth = 2
vim.opt.softtabstop = 2

-- global window borders
vim.o.winborder = 'rounded'

-- haskell
vim.cmd([[
  syntax on
  filetype plugin indent on
]])

