return {
	"folke/noice.nvim",
	dependencies = {
		"MunifTanjim/nui.nvim",
	},
	opts = {
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
		routes = {
			{
				filter = { error = true },
				view = "popup",
			},
		},

		cmdline = {
			view = "cmdline_popup",
		},
		views = {
			popup = {
				win_options = {
					wrap = false,
				},
			},

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
	},
}
