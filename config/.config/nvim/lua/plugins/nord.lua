return {
  'shaunsingh/nord.nvim',

  lazy = false,
  config = function()
    vim.cmd.colorscheme('nord')
    vim.g.nord_contrast = true
    vim.g.nord_disable_background = false
    vim.opt.cursorline = true
  end,
}
