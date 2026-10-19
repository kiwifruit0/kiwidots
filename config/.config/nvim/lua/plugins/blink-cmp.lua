return {
  "saghen/blink.cmp",
  dependencies = {
    "rafamadriz/friendly-snippets",
    "zbirenbaum/copilot.lua",
    "fang2hou/blink-copilot",
    { "xzbdmw/colorful-menu.nvim", opts = {} },
    {
      "L3MON4D3/LuaSnip",
      version = "v2.*",
      build = "make install_jsregexp",
      dependencies = { "rafamadriz/friendly-snippets" },
      config = function()
        require("luasnip").config.setup({})
        require("luasnip.loaders.from_vscode").lazy_load()
        require("luasnip.loaders.from_lua").lazy_load()
      end,
    },
  },
  version = "1.*",
  opts = {
    sources = {
      default = { "lazydev", "lsp", "path", "snippets", "buffer", "copilot" },
      providers = {
        lazydev = {
          name = "LazyDev",
          module = "lazydev.integrations.blink",
          score_offset = 100,
        },
        copilot = {
          name = "copilot",
          module = "blink-copilot",
          enabled = function()
            local client = require("copilot.client")
            return not client.is_disabled() and client.buf_is_attached(0) or false
          end,
          score_offset = 0,
          async = true,
          opts = { max_completions = 3 },
        },
      },
    },
    keymap = {
      preset = "none",
      ["<C-f>"] = { "select_and_accept", "fallback" },
      ["<C-y>"] = { "show", "show_documentation", "hide_documentation", "fallback" },
      ["<C-p>"] = { "select_prev", "fallback_to_mappings" },
      ["<C-n>"] = { "select_next", "fallback_to_mappings" },
      ["<C-k>"] = { "select_prev", "fallback_to_mappings" },
      ["<C-j>"] = { "select_next", "fallback_to_mappings" },
      ["<C-e>"] = { "cancel", "fallback" },
      ["<Tab>"] = { "snippet_forward", "fallback" },
      ["<S-Tab>"] = { "snippet_backward", "fallback" },
      ["<C-l>"] = {
        function()
          local snippets = require("luasnip")
          if snippets.choice_active() then
            snippets.change_choice(1)
            return true
          end
        end,
        "fallback",
      },
    },
    cmdline = {
      keymap = { preset = "cmdline", ["<C-f>"] = { "select_and_accept", "fallback" } },
    },
    appearance = {
      nerd_font_variant = "mono",
      use_nvim_cmp_as_default = false,
    },
    completion = {
      list = { selection = { preselect = true, auto_insert = true } },
      documentation = { auto_show = true, window = { border = "rounded" } },
      menu = {
        border = "rounded",
        draw = {
          columns = { { "label" }, { "kind_icon", "kind" } },
          components = {
            label = {
              text = function(ctx)
                return require("colorful-menu").blink_components_text(ctx)
              end,
              highlight = function(ctx)
                return require("colorful-menu").blink_components_highlight(ctx)
              end,
            },
          },
        },
      },
    },
    fuzzy = { implementation = "prefer_rust_with_warning", sorts = { "exact", "score", "sort_text" } },
    snippets = { preset = "luasnip" },
    signature = { enabled = true, window = { border = "rounded" } },
  },
  config = function(_, opts)
    require("blink.cmp").setup(opts)

    local function match_hover_highlights()
      for group, target in pairs({
        BlinkCmpMenu = "NormalFloat",
        BlinkCmpMenuBorder = "FloatBorder",
        BlinkCmpDoc = "NormalFloat",
        BlinkCmpDocBorder = "FloatBorder",
        BlinkCmpDocSeparator = "FloatBorder",
        BlinkCmpSignatureHelp = "NormalFloat",
        BlinkCmpSignatureHelpBorder = "FloatBorder",
      }) do
        vim.api.nvim_set_hl(0, group, { link = target })
      end

      -- Text inherits the window background, including the selected row's highlight.
      local foreground = vim.api.nvim_get_hl(0, { name = "NormalFloat", link = false }).fg
      local muted = vim.api.nvim_get_hl(0, { name = "Comment", link = false }).fg
      vim.api.nvim_set_hl(0, "BlinkCmpLabel", { fg = foreground })
      vim.api.nvim_set_hl(0, "BlinkCmpLabelMatch", { bold = true })
      vim.api.nvim_set_hl(0, "BlinkCmpLabelDeprecated", { fg = muted, strikethrough = true })
      for _, group in ipairs({ "BlinkCmpLabelDetail", "BlinkCmpLabelDescription", "BlinkCmpSource" }) do
        vim.api.nvim_set_hl(0, group, { fg = muted })
      end
      vim.api.nvim_set_hl(0, "BlinkCmpKind", { fg = foreground })
      for _, kind in ipairs(require("blink.cmp.types").CompletionItemKind) do
        vim.api.nvim_set_hl(0, "BlinkCmpKind" .. kind, { link = "BlinkCmpKind" })
      end
    end

    match_hover_highlights()
    vim.api.nvim_create_autocmd("ColorScheme", {
      group = vim.api.nvim_create_augroup("UserBlinkHoverStyle", { clear = true }),
      callback = match_hover_highlights,
    })
  end,
}
