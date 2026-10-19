return {
  "stevearc/conform.nvim",
  cmd = "ConformInfo",
  keys = {
    {
      "<leader>gf",
      function()
        require("conform").format({ async = true })
      end,
      mode = { "n", "x" },
      desc = "Format buffer or selection",
    },
  },
  opts = function()
    return {
      formatters_by_ft = require("config.languages").formatters_by_ft,
      default_format_opts = { lsp_format = "fallback" },
      notify_no_formatters = true,
      formatters = {
        ["clang-format"] = {
          -- Project .clang-format takes precedence; preserve the old style as a fallback.
          append_args = function(_, context)
            local config = vim.fs.find({ ".clang-format", "_clang-format" }, {
              path = context.dirname,
              upward = true,
              type = "file",
            })[1]
            if config then
              return {}
            end
            return {
              "--style={BasedOnStyle: LLVM, ColumnLimit: 80, BreakConstructorInitializers: BeforeColon, PackConstructorInitializers: Never}",
            }
          end,
        },
        prettier = {
          options = { ft_parsers = { vil = "json" } },
        },
      },
    }
  end,
}
