local M = {}

M.setup = function()
	local opts = { noremap = true, silent = true }
	local shell = os.getenv("SHELL")

	vim.keymap.set("n", "<leader>rh", function()
		vim.cmd('silent !tmux split-window -v -l 15 "ghci %" &')
	end, vim.tbl_extend("force", opts, { desc = "Run Haskell (GHCi) REPL below with current file" }))

	vim.keymap.set("n", "<leader>rp", function()
		vim.cmd(string.format("silent !tmux split-window -v -l 15 \"%s -c 'python3 %% ; exec %s'\" &", shell, shell))
	end, vim.tbl_extend("force", opts, { desc = "Run Python in tmux pane below" }))

  vim.keymap.set("n", "<leader>rb", function()
    vim.cmd(string.format("silent !tmux split-window -v -l 15 \"%s -c 'bash %% ; exec %s'\" &", shell, shell))
  end, vim.tbl_extend("force", opts, { desc = "Run Bash script in tmux pane below" }))
end

return M
