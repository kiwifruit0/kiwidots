return {
	"saghen/blink.cmp",
	dependencies = {
		"rafamadriz/friendly-snippets",
	},
	version = "1.*",
	keys = {
		{ "<c-h>", "<cmd><C-U>TmuxNavigateLeft<cr>" },
	},
	opts = {
		keymap = { preset = "default", ["<C-f>"] = { "select_and_accept" } },
		appearance = {
			nerd_font_variant = "mono",
			-- Add this to use normal background
			use_nvim_cmp_as_default = false,
		},
		completion = {
			documentation = { auto_show = true },
			menu = {
				draw = {
					-- This makes the completion menu use Normal highlight group
					columns = { { "label", "label_description", gap = 1 }, { "kind_icon", "kind" } },
				},
			},
		},
		fuzzy = { implementation = "prefer_rust_with_warning" },
		signature = { enabled = true },
	},
	config = function(_, opts)
		require("blink.cmp").setup(opts)

		-- Override the highlight groups to match Normal background
		vim.api.nvim_set_hl(0, "BlinkCmpMenu", { link = "Normal" })
		vim.api.nvim_set_hl(0, "BlinkCmpMenuBorder", { link = "Normal" })
		vim.api.nvim_set_hl(0, "BlinkCmpDoc", { link = "Normal" })
		vim.api.nvim_set_hl(0, "BlinkCmpDocBorder", { link = "Normal" })

		-- Fix the kind labels (Text, Snippet, etc.)
		vim.api.nvim_set_hl(0, "BlinkCmpKind", { link = "Normal" })
		vim.api.nvim_set_hl(0, "BlinkCmpKindText", { link = "Normal" })
		vim.api.nvim_set_hl(0, "BlinkCmpKindSnippet", { link = "Normal" })
		vim.api.nvim_set_hl(0, "BlinkCmpKindFunction", { link = "Normal" })
		vim.api.nvim_set_hl(0, "BlinkCmpKindVariable", { link = "Normal" })
		vim.api.nvim_set_hl(0, "BlinkCmpKindKeyword", { link = "Normal" })
		vim.api.nvim_set_hl(0, "BlinkCmpKindClass", { link = "Normal" })
		vim.api.nvim_set_hl(0, "BlinkCmpKindModule", { link = "Normal" })
	end,
}
