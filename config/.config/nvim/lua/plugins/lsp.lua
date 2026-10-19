return {
  {
    "mason-org/mason.nvim",
    opts = {},
  },
  {
    "neovim/nvim-lspconfig",
    lazy = false,
    dependencies = {
      "mason-org/mason.nvim",
      "mason-org/mason-lspconfig.nvim",
      "WhoIsSethDaniel/mason-tool-installer.nvim",
      "saghen/blink.cmp",
    },
    keys = {
      { "<leader>lm", "<cmd>Mason<cr>", desc = "Manage language tools" },
      { "<leader>li", "<cmd>checkhealth vim.lsp<cr>", desc = "LSP status" },
      { "<leader>lu", "<cmd>MasonToolsUpdate<cr>", desc = "Update language servers and tools" },
      { "<leader>lf", "<cmd>ConformInfo<cr>", desc = "Formatter status" },
    },
    config = function()
      local languages = require("config.languages")
      local servers = vim.tbl_keys(languages.servers)
      table.sort(servers)

      vim.api.nvim_create_autocmd("FileType", {
        group = vim.api.nvim_create_augroup("UserSourceHeader", { clear = true }),
        pattern = { "c", "cpp", "objc", "objcpp", "cuda" },
        callback = function(event)
          vim.keymap.set("n", "<leader>sh", require("config.source-header").switch, {
            buffer = event.buf,
            desc = "Switch source/header",
          })
        end,
      })

      vim.api.nvim_create_autocmd("LspAttach", {
        group = vim.api.nvim_create_augroup("UserLspAttach", { clear = true }),
        callback = function(event)
          local client = vim.lsp.get_client_by_id(event.data.client_id)
          if not client then
            return
          end
          if client.name == "ruff" then
            client.server_capabilities.hoverProvider = false
          end
          local function map(key, callback, desc, method)
            if not method or client:supports_method(method, event.buf) then
              vim.keymap.set("n", key, callback, { buffer = event.buf, desc = desc })
            end
          end
          map("gd", vim.lsp.buf.definition, "Go to definition", "textDocument/definition")
          map("gi", vim.lsp.buf.implementation, "Go to implementation", "textDocument/implementation")
          map("<leader>rn", vim.lsp.buf.rename, "Rename symbol", "textDocument/rename")
          map("<leader>ca", vim.lsp.buf.code_action, "Code action", "textDocument/codeAction")
          -- Neovim supplies K (hover), grr (references), and other gr* mappings.
        end,
      })

      for name, config in pairs(languages.servers) do
        vim.lsp.config(name, config)
      end
      -- Configure before enabling; only declared servers may auto-attach after installation.
      require("mason-lspconfig").setup({ automatic_enable = servers })
      vim.lsp.enable(servers)
      local tools = vim.list_extend(vim.deepcopy(servers), languages.tools)
      require("mason-tool-installer").setup({
        ensure_installed = tools,
        auto_update = false,
        run_on_start = true,
        start_delay = 1000,
        integrations = {
          ["mason-lspconfig"] = true,
          ["mason-null-ls"] = false,
          ["mason-nvim-dap"] = false,
        },
      })
    end,
  },
  {
    "folke/lazydev.nvim",
    ft = "lua",
    opts = {
      library = {
        { path = "${3rd}/luv/library", words = { "vim%.uv" } },
      },
    },
  },
}
