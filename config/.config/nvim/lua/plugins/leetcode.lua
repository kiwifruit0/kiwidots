return {
	{
		"kawre/leetcode.nvim",
		dependencies = {
			"nvim-telescope/telescope.nvim",
			"nvim-lua/plenary.nvim",
			"MunifTanjim/nui.nvim",
			"3rd/image.nvim",
		},
		opts = {
			picker = { provider = "telescope" },
			lang = "cpp",
			injector = {
				["cpp"] = {
					before = {
						"#include <vector>",
						"#include <string>",
						"#include <algorithm>",
						"using namespace std;",
					},
				},
			},
			theme = {
				["case_focus_ok"] = {
          bg = vim.api.nvim_get_hl(0, { name = "DiagnosticOk" }).fg,
          fg = vim.api.nvim_get_hl(0, { name = "Normal" }).bg,
          bold = true },
			},
		},
	},
	{
		"3rd/image.nvim",
		build = false,
		opts = {
			processor = "magick_cli",
		},
	},
}
