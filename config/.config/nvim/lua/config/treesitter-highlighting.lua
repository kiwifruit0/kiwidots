vim.api.nvim_create_autocmd('FileType', {
  callback = function()
    local lang = vim.treesitter.language.get_lang(vim.bo.filetype)
    if not lang then
      return
    end
    
    -- Check if parser is installed
    local parser_path = vim.api.nvim_get_runtime_file('parser/' .. lang .. '.so', false)
    if #parser_path == 0 then
      return
    end
    
    -- Parser exists, start treesitter
    pcall(vim.treesitter.start)
  end,
})


--vim.api.nvim_create_autocmd('FileType', {
--  pattern = {
--    'python',
--    'lua',
--    'vim',
--    'bash',
--    'sh',
--    'zsh',
--    'c',
--    'cpp',
--    'rust',
--    'go',
--    'javascript',
--    'typescript',
--    'html',
--    'css',
--    'json',
--    'yaml',
--    'toml',
--    'markdown',
--    'haskell',
--  },
--  callback = function()
--    vim.treesitter.start()
--  end,
--})
