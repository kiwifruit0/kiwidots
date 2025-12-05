return {
	"christoomey/vim-tmux-navigator",
	lazy = false,
	cmd = {
		"TmuxNavigateLeft",
		"TmuxNavigateDown",
		"TmuxNavigateUp",
		"TmuxNavigateRight",
		"TmuxNavigatePrevious",
		"TmuxNavigatorProcessList",
	},
	keys = {
		{ "<C-h>", "<cmd>TmuxNavigateLeft<cr>", silent = true },
		{ "<C-j>", "<cmd>TmuxNavigateDown<cr>", silent = true },
		{ "<C-k>", "<cmd>TmuxNavigateUp<cr>", silent = true },
		{ "<C-l>", "<cmd>TmuxNavigateRight<cr>", silent = true },
		{ "<C-\\>", "<cmd>TmuxNavigatePrevious<cr>", silent = true },
	},
}
