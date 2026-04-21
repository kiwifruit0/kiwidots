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
			{ "<leader>sh", "<cmd>LspClangdSwitchSourceHeader<CR>", desc = "Switch between source/header" },
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
				pyright = {
					settings = {
						pyright = {
							disableOrganizeImports = true, -- let Ruff handle imports
						},
						python = {
							analysis = {
								typeCheckingMode = "standard",
								-- remove the ignore = {"*"} unless you want pyright silent on types too
							},
						},
					},
				},
				ruff = {
					on_attach = function(client)
						client.server_capabilities.hoverProvider = false
					end,
				},
				hls = {},
				dartls = {
					filetypes = { "dart" },
					root_markers = { "pubspec.yaml", ".git" },
				},
			}

			-- clang config
			local home = os.getenv("HOME")
			local pio_toolchains = home .. "/.platformio/packages/toolchain-*/bin/*"

			pkgs.clangd = {
				cmd = {
					"clangd",
					"--background-index",
					"--clang-tidy",
					"--completion-style=detailed",
					"--function-arg-placeholders=true",
					"--cross-file-rename=true",
					"--header-insertion=never",
					"--compile-commands-dir=.",
					"--query-driver=" .. pio_toolchains,
				},
				filetypes = { "c", "cpp", "h", "hpp", "objc", "objcpp", "cuda" },
			}

			-- install servers in server list
			local mason_lspconfig_pkgs = {
				"bashls",
				"lua_ls",
				"pyright",
				"ruff",
				"hls",
				"clangd",
			}

			require("mason").setup()
			require("mason-lspconfig").setup({
				ensure_installed = mason_lspconfig_pkgs,
			})

			vim.lsp.config("*", {
				on_attach = function(client, bufnr)
					if client.name == "ruff" then
						client.server_capabilities.hoverProvider = false
					end
				end,
			})

			for name, cfg in pairs(pkgs) do
				cfg.capabilities = require("blink.cmp").get_lsp_capabilities(cfg.capabilities or {})
				vim.lsp.config(name, cfg)
				vim.lsp.enable(name)
			end

			-- set up diagnostics config
			require("diagnostics.config")
			require("diagnostics.virtual_text")
		end,
	},
}
