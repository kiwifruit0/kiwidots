return {
	"3rd/image.nvim",
	lazy = true,
	build = false,
	opts = {
		backend = "kitty",
		processor = "magick_cli",
		integrations = {
			markdown = { enabled = false },
			asciidoc = { enabled = false },
			typst = { enabled = false },
			neorg = { enabled = false },
			syslang = { enabled = false },
		},
		hijack_file_patterns = {},
	},
}
