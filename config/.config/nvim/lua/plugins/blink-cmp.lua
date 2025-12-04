return {
	"saghen/blink.cmp",
	dependencies = {
		"rafamadriz/friendly-snippets",
		"zbirenbaum/copilot.lua",
		"giuxtaposition/blink-cmp-copilot",
	},
	version = "1.*",
	keys = {
		{ "<c-h>", "<cmd><C-U>TmuxNavigateLeft<cr>" },
	},
	opts = {
		sources = {
			default = { "lsp", "path", "snippets", "buffer", "copilot" },
			providers = {
				copilot = {
					name = "copilot",
					module = "blink-cmp-copilot",
					score_offset = 100,
					async = true,
				},
			},
		},
		keymap = { preset = "default", ["<C-f>"] = { "select_and_accept" } },
		appearance = {
			nerd_font_variant = "mono",
			use_nvim_cmp_as_default = false,
		},
		completion = {
			documentation = { auto_show = true },
			menu = {
				draw = {
					columns = { { "label", "label_description", gap = 1 }, { "kind_icon", "kind" } },
				},
			},
		},
		fuzzy = { implementation = "prefer_rust_with_warning" },
		signature = { enabled = true },
	},
	config = function(_, opts)
		-- Setup copilot first
		require("copilot").setup({
			suggestion = { enabled = false },
			panel = { enabled = false },
		})

		-- Then setup blink.cmp
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
