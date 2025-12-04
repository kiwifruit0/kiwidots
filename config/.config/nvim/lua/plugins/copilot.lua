return {
	{
		"zbirenbaum/copilot.lua",
		cmd = "Copilot",
		event = "InsertEnter",
		config = function()
			require("copilot").setup({
				suggestion = {
					enabled = true,
					auto_trigger = true,
					keymap = {
						accept = "<C-j>",
						next = "<M-]>",
						prev = "<M-[>",
						dismiss = "<C-l>",
					},
				},
				panel = { enabled = false },
			})
		end,
	},

	{
		"giuxtaposition/blink-cmp-copilot",
		dependencies = { "zbirenbaum/copilot.lua" },
	},
}
