return {
	{
		"kawre/leetcode.nvim",
		dependencies = {
			"nvim-telescope/telescope.nvim",
			"nvim-lua/plenary.nvim",
			"MunifTanjim/nui.nvim",
			-- "3rd/image.nvim",
		},
		opts = {
			picker = { provider = "telescope" },
			lang = "python3",
			injector = {
				["python3"] = {
					imports = function(default_imports)
						vim.list_extend(default_imports, { "from .leetcode import *" })
						return default_imports
					end,
					after = { "def test():", "    print('test')" },
				},
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
					bold = true,
				},
			},
		},
	},
}
