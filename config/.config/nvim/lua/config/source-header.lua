local M = {}

local headers = { "hpp", "h", "hh", "hxx", "h++", "inc", "cuh" }
local sources = { "cpp", "cc", "cxx", "c++", "c", "m", "mm", "cu" }
local header_dirs = { "include", "inc" }
local source_dirs = { "src", "source" }

local function counterpart(path)
  local extension = vim.fn.fnamemodify(path, ":e"):lower()
  local is_header = vim.tbl_contains(headers, extension)
  if not is_header and not vim.tbl_contains(sources, extension) then
    return
  end

  local dir = vim.fs.dirname(path)
  local stem = vim.fn.fnamemodify(path, ":t:r")
  local root = vim.fs.root(path, { ".clangd", "compile_commands.json", "CMakeLists.txt", "Makefile", ".git" })
    or vim.fs.dirname(dir)
  local dirs = { dir }
  local from_dirs = is_header and header_dirs or source_dirs
  local to_dirs = is_header and source_dirs or header_dirs

  -- Preserve subdirectories for pairs such as src/audio/synth.cpp and include/audio/synth.hpp.
  for _, from in ipairs(from_dirs) do
    local prefix = vim.fs.joinpath(root, from) .. "/"
    if dir .. "/" == prefix or dir:sub(1, #prefix) == prefix then
      local relative = dir:sub(#prefix + 1)
      for _, to in ipairs(to_dirs) do
        dirs[#dirs + 1] = vim.fs.joinpath(root, to, relative)
      end
    end
  end
  dirs[#dirs + 1] = root
  for _, to in ipairs(to_dirs) do
    dirs[#dirs + 1] = vim.fs.joinpath(root, to)
  end

  for _, candidate_dir in ipairs(dirs) do
    for _, ext in ipairs(is_header and sources or headers) do
      local candidate = vim.fs.joinpath(candidate_dir, stem .. "." .. ext)
      if vim.fn.filereadable(candidate) == 1 then
        return candidate
      end
    end
  end
end

function M.switch()
  local bufnr = vim.api.nvim_get_current_buf()
  local target = counterpart(vim.api.nvim_buf_get_name(bufnr))
  if target then
    vim.cmd.edit(vim.fn.fnameescape(target))
    return
  end

  local client = vim.lsp.get_clients({ bufnr = bufnr, name = "clangd" })[1]
  if not client then
    vim.notify("No matching source/header file found; clangd is not attached", vim.log.levels.INFO)
    return
  end
  client:request("textDocument/switchSourceHeader", vim.lsp.util.make_text_document_params(bufnr), function(err, uri)
    if err then
      vim.notify(err.message, vim.log.levels.ERROR)
    elseif not uri or uri == "" then
      vim.notify("No matching source/header file found", vim.log.levels.INFO)
    elseif vim.api.nvim_get_current_buf() == bufnr then
      vim.cmd.edit(vim.fn.fnameescape(vim.uri_to_fname(uri)))
    end
  end, bufnr)
end

return M
