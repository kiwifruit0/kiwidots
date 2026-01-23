return {
  'brenoprata10/nvim-highlight-colors',
  config = function()
    require('nvim-highlight-colors').setup({})
    vim.opt.termguicolors = true
  end
}
