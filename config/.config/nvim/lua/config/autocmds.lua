-- attach treesitter to buffers with installed parsers
vim.api.nvim_create_autocmd("FileType", {
	callback = function()
		local lang = vim.treesitter.language.get_lang(vim.bo.filetype)
		if not lang then
			return
		end
		-- check if parser is installed
		local parser_path = vim.api.nvim_get_runtime_file("parser/" .. lang .. ".so", false)
		if #parser_path == 0 then
			return
		end
		-- parser exists, start treesitter
		pcall(vim.treesitter.start)
	end,
})

-- set cwd to the directory passed to nvim (if any)
vim.api.nvim_create_autocmd("VimEnter", {
	callback = function()
		local arg = vim.fn.argv(0)
		if arg and vim.fn.isdirectory(arg) == 1 then
			vim.cmd.cd(arg)
		end
	end,
})

-- Remove padding when Neovim starts
vim.api.nvim_create_autocmd("VimEnter", {
	callback = function()
		os.execute("kitty @ set-spacing padding=0")
	end,
})

-- Restore padding when Neovim exits
vim.api.nvim_create_autocmd("VimLeave", {
	callback = function()
		os.execute("kitty @ set-spacing padding=10")
	end,
})
