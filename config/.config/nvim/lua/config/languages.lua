-- Add a server here using its nvim-lspconfig name. Installation and activation
-- are derived from this table; empty options use upstream defaults.
return {
  servers = {
    bashls = {},
    clangd = {
      cmd = {
        "clangd",
        "--background-index",
        "--clang-tidy",
        "--completion-style=detailed",
        "--function-arg-placeholders=true",
        "--header-insertion=iwyu",
        "--query-driver=" .. vim.env.HOME .. "/.platformio/packages/toolchain-*/bin/*",
      },
    },
    jsonls = {
      filetypes = { "json", "jsonc", "vil" },
      -- .vil files contain JSON but retain their custom Neovim filetype.
      get_language_id = function(_, filetype)
        return filetype == "vil" and "json" or filetype
      end,
    },
    lua_ls = {
      settings = {
        Lua = {
          workspace = { checkThirdParty = false },
          telemetry = { enable = false },
          format = { enable = false }, -- Conform runs StyLua.
        },
      },
    },
    pyright = {
      settings = {
        pyright = { disableOrganizeImports = true },
        python = { analysis = { typeCheckingMode = "standard" } },
      },
    },
    ruff = {},
    texlab = {}, -- VimTeX handles compilation and PDF navigation.
    ts_ls = {},
  },

  -- Mason package names for formatters, linters, and existing debug adapters.
  tools = { "stylua", "clang-format", "prettier", "shfmt", "shellcheck", "codelldb", "debugpy" },

  formatters_by_ft = {
    lua = { "stylua" },
    python = { "ruff_organize_imports", "ruff_format" },
    c = { "clang-format" },
    cpp = { "clang-format" },
    objc = { "clang-format" },
    objcpp = { "clang-format" },
    cuda = { "clang-format" },
    cs = { "clang-format" },
    java = { "clang-format" },
    proto = { "clang-format" },
    sh = { "shfmt" },
    bash = { "shfmt" },
    json = { "prettier" },
    jsonc = { "prettier" },
    vil = { "prettier" },
    javascript = { "prettier" },
    javascriptreact = { "prettier" },
    typescript = { "prettier" },
    typescriptreact = { "prettier" },
    css = { "prettier" },
    scss = { "prettier" },
    html = { "prettier" },
    yaml = { "prettier" },
    markdown = { "prettier" },
  },
}
