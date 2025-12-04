return {
	"nvim-neo-tree/neo-tree.nvim",
	branch = "v3.x",
	keys = {
		{ "<leader>t", "<cmd>Neotree toggle<cr>", desc = "Explorer NeoTree (root dir)" },
	},
	dependencies = {
		"nvim-lua/plenary.nvim",
		"MunifTanjim/nui.nvim",
		"nvim-tree/nvim-web-devicons", -- optional, but recommended
	},
	lazy = false, -- neo-tree will lazily load itself
	---@module 'neo-tree'
	---@type neotree.Config
	opts = {
		event_handlers = {
			{
				event = "file_opened",
				handler = function()
					require("neo-tree.command").execute({ action = "close" })
				end,
			},
		},
	},
}
