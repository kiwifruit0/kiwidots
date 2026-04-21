return {
	"folke/noice.nvim",
	dependencies = {
		"MunifTanjim/nui.nvim",
	},
	config = function()
		require("noice").setup({
			lsp = {
				progress = {
					enabled = false,
				},

				signature = {
					auto_open = {
						enabled = false,
					},
				},
			},

			cmdline = {
				view = "cmdline_popup",
			},
			views = {
				cmdline_popup = {
					position = {
						row = "50%",
						col = "50%",
					},
					border = {
						style = "rounded",
					},
				},
			},
		})
	end,
}
