return {
	"nvimtools/none-ls.nvim",
	keys = {
		{
			"<leader>gf",
			function()
				if vim.bo.filetype == "python" then
					vim.lsp.buf.code_action({
						context = { only = { "source.organizeImports" } },
						apply = true,
						filter = function(action)
							return action.kind == "source.organizeImports"
						end,
					})
					vim.lsp.buf.format({ async = false, name = "ruff" })
				else
					vim.lsp.buf.format({ async = false })
				end
			end,
			desc = "Format buffer",
		},
	},
	config = function()
		local null_ls = require("null-ls")

		-- custom ormolu fallback
		local ormolu = {
			method = null_ls.methods.FORMATTING,
			filetypes = { "haskell" },
			generator = null_ls.generator({
				command = "$/.local/share/nvim/mason/bin/ormolu",
				args = { "--stdin-input-file", "$FILENAME" },
				to_stdin = true,
			}),
		}

		null_ls.setup({
			sources = {
				null_ls.builtins.formatting.stylua,
				null_ls.builtins.formatting.clang_format.with({
					extra_args = {
						"--style=" .. [[{
            BasedOnStyle: LLVM,
            ColumnLimit: 80,
            BreakConstructorInitializers: BeforeColon,
            PackConstructorInitializers: Never
            }]],
					},
				}),
				ormolu,
			},
		})
	end,
}
