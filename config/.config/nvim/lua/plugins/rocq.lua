return {
	{
		"whonore/Coqtail",
		ft = "coq",
		init = function()
			vim.g.loaded_coqtail = 1
			vim.g["coqtail#supported"] = 0
		end,
	},
	{
		"tomtomjhj/vsrocq.nvim",
		ft = "coq",
		dependencies = { "whonore/Coqtail" },
		opts = {
			vsrocq = {
				goals = { diff = { mode = "off" }, messages = { full = true } },
				proof = { mode = "Manual", cursor = { sticky = false } },
				diagnostics = { full = true },
			},
			lsp = {
				cmd = { "vsrocqtop" },
				on_attach = function(client, bufnr)
					-- 1. Setup Keymaps
					local opts = { buffer = bufnr, remap = false }
					vim.keymap.set({ "n", "i" }, "<C-M-j>", "<Cmd>VsRocq stepForward<CR>", opts)
					vim.keymap.set({ "n", "i" }, "<C-M-k>", "<Cmd>VsRocq stepBackward<CR>", opts)
					vim.keymap.set({ "n", "i" }, "<C-M-l>", "<Cmd>VsRocq interpretToPoint<CR>", opts)
					vim.keymap.set({ "n", "i" }, "<C-M-G>", "<Cmd>VsRocq interpretToEnd<CR>", opts)
					vim.keymap.set("n", "<leader>vp", "<Cmd>VsRocq panels<CR>", opts)

					-- 2. Force Highlights after the plugin loads
					-- We use schedule to make sure this runs after vsrocq's own highlight logic
					vim.schedule(function()
						vim.api.nvim_set_hl(0, "CoqtailChecked", {
							bg = "#8fbcbb",
              fg = "#2e3440",
							bold = true,
							default = false, -- Ensure we override the plugin default
						})
					end)
				end,
			},
		},
	},
}
