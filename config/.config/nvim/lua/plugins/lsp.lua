return {
	{
		"mason-org/mason.nvim",
		opts = {},
	},
	{
		"mason-org/mason-lspconfig.nvim",
		opts = {},
		dependencies = { "mason-org/mason.nvim" },
	},
	{
		"neovim/nvim-lspconfig",
		lazy = false,
		dependencies = {
			"mason-org/mason.nvim",
			"mason-org/mason-lspconfig.nvim",
		},
		keys = {
			{ "gd", vim.lsp.buf.definition, desc = "Go to definition" },
			-- { "gr", vim.lsp.buf.references, desc = "Find references" },
			{ "gi", vim.lsp.buf.implementation, desc = "Go to implementation" },
			{ "K", vim.lsp.buf.hover, desc = "Hover documentation" },
			{ "<leader>rn", vim.lsp.buf.rename, desc = "Rename symbol" },
			{ "<leader>ca", vim.lsp.buf.code_action, desc = "Code action" },
			{ "[d", vim.diagnostic.goto_prev, desc = "Go to previous diagnostic" },
			{ "]d", vim.diagnostic.goto_next, desc = "Go to next diagnostic" },
			{ "<leader>e", vim.diagnostic.open_float, desc = "Show diagnostic under cursor" },
			{ "<leader>q", vim.diagnostic.setloclist, desc = "Open diagnostics list" },
		},
		config = function()
			-- for packages to install / with manual config
			local pkgs = {
				bashls = {},
				-- lua packages
				lua_ls = {
					root_markers = {
						"init.lua",
						".luarc.json",
						".luarc.jsonc",
						".luacheckrc",
						".stylua.toml",
						"stylua.toml",
						"selene.toml",
						"selene.yml",
						".git",
					},
					settings = {
						Lua = {
							diagnostics = { globals = { "vim" } },
							workspace = { checkThirdParty = false },
							telemetry = { enable = false },
							formattingProvider = "stylua",
						},
					},
				},
				pylsp = {
					settings = {
						pylsp = {
							plugins = {
								pyflakes = { enabled = false },
								pycodestyle = { enabled = false },
								autopep8 = { enabled = false },
								yapf = { enabled = false },
								mccabe = { enabled = false },
								pylsp_mypy = { enabled = false },
								pylsp_black = { enabled = false },
								pylsp_isort = { enabled = false },
							},
						},
					},
				},
				ruff = {
					settings = {
						format = { enabled = true },
						organizeImports = true,
						lint = {
							enable = true,
							select = { "E", "F", "W" },
						},
					},
				},
				hls = {},
				clangd = {
					cmd = {
						"clangd",
						"--background-index",
						"--clang-tidy",
						"--header-insertion=iwyu",
						"--completion-style=detailed",
						"--function-arg-placeholders=true", -- FIXED
					},

					filetypes = { "c", "cpp", "h", "hpp", "objc", "objcpp", "cuda" },
				},
			}

			-- install servers in server list
			require("mason").setup()
			require("mason-lspconfig").setup({
				ensure_installed = vim.tbl_keys(pkgs),
			})

			-- load all servers and configs
			for name, cfg in pairs(pkgs) do
				cfg.capabilities = require("blink.cmp").get_lsp_capabilities(cfg.capabilities or {})
				vim.lsp.config(name, cfg)
				vim.lsp.enable(name)
			end

			-- Add this in your lspconfig config function, after setting up servers
			-- vim.api.nvim_create_autocmd("BufWritePre", {
			--   pattern = "*.py",
			--   callback = function()
			--     vim.lsp.buf.format({ async = false })
			--   end,
			-- })

			-- set up diagnostics config
			require("diagnostics.config")
			require("diagnostics.virtual_text")
		end,
	},
}
