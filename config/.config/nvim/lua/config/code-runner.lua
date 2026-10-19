local M = {}

M.setup = function()
  local opts = { noremap = true, silent = true }

  vim.keymap.set("n", "<leader>rb", function()
    vim.cmd("!echo; %:p")
  end)

  vim.keymap.set("n", "<leader>rp", function()
    vim.cmd("silent !kitty @ launch --location=hsplit --bias=40 \"zsh -c 'python3 %'\" &")
  end, vim.tbl_extend("force", opts, { desc = "Run Python in tmux pane below" }))
end

return M
