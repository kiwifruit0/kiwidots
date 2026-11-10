return {
  "shaunsingh/nord.nvim",
  lazy = false,
  priority = 1000,
  config = function()
    require("config.desktop-theme").refresh(true)
  end,
}
