return {
  "lervag/vimtex",
  lazy = false, -- The global inverse-search command must be available on startup.
  init = function()
    vim.g.vimtex_view_method = "zathura_simple" -- Avoid xdotool on Wayland.
    vim.g.vimtex_complete_enabled = 0 -- Blink uses Texlab's LSP completion.
  end,
}
