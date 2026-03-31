vim.g.mapleader = " "

-- general
vim.keymap.set("n", "<leader>pv", vim.cmd.Ex)

-- centering when scrolling and searching
vim.keymap.set("n", "n", "nzz")
vim.keymap.set("n", "N", "Nzz")
vim.keymap.set("n", "<C-u>", "<C-u>zz")
vim.keymap.set("n", "<C-d>", "<C-d>zz")

-- copying and pasting to system clipboard
vim.keymap.set("v", "<leader>y", '"+y')
vim.keymap.set("n", "<leader>y", '"+yy')
vim.keymap.set({ "n", "v" }, "<leader>pp", '"+p')

--vim.keymap.set("n", "<leader>rh", function()
--  vim.cmd('silent !tmux split-window -v -l 15 "ghci %" &')
--end, { desc = "Open GHCi REPL below with current file" })
