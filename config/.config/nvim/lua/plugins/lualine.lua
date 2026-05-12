return {
  'nvim-lualine/lualine.nvim',
  dependencies = {
    'nvim-tree/nvim-web-devicons',
  },
  opts = {
    options = {
      icons_enabled = true,
      theme = 'nord',
      component_separators = { left = '|', right = '|' },
    },
    sections = {
      lualine_x = {
        {
          require('noice').api.status.mode.get,
          cond = require('noice').api.status.mode.has,
          color = { fg = '#ff9e64' },
        },
        'encoding',
        'filetype',
      },
    },
  },
}
