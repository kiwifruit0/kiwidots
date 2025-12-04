return {
  {
    'nvim-telescope/telescope.nvim',
    branch = 'master',
    dependencies = { 'nvim-lua/plenary.nvim' },
    keys = {
      { '<leader>ff', '<cmd>Telescope find_files<cr>', desc = 'Telescope find files' },
      { '<leader>fg', '<cmd>Telescope git_files<cr>', desc = 'Telescope find git files' },
      { '<leader>fs', '<cmd>Telescope live_grep<cr>', desc = 'Search within files' },
      { '<leader>fh', function()
        require('telescope.builtin').find_files({ hidden = true })
      end, desc = 'Telescope find hidden files' },
      { '<leader>ds', '<cmd>Telescope lsp_document_symbols<cr>', desc = 'Find document symbols' },
      { '<leader>ws', '<cmd>Telescope lsp_dynamic_workspace_symbols<cr>', desc = 'Find workspace symbols' },
      { '<leader>gr', '<cmd>Telescope lsp_references<cr>', desc = 'Find references' },
    },
  },
  {
    'nvim-telescope/telescope-ui-select.nvim',
    config = function()
      require('telescope').setup({
        extensions = {
          ['ui-select'] = {
            require('telescope.themes').get_dropdown {}
          }
        }
      })
      require('telescope').load_extension('ui-select')
    end
  }
}
