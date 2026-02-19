return {
	"shaunsingh/nord.nvim",

	lazy = false,
	config = function()
		vim.cmd.colorscheme("nord")
		vim.g.nord_contrast = false
		vim.g.nord_disable_background = true
	end,
}
