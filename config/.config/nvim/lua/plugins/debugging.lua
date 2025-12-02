return {
	"mfussenegger/nvim-dap",
	dependencies = {
		"rcarriga/nvim-dap-ui",
		"mfussenegger/nvim-dap",
		"nvim-neotest/nvim-nio",
		"mfussenegger/nvim-dap-python",
	},
	keys = {
		{
			"<leader>db",
			function()
				require("dap").toggle_breakpoint()
			end,
			desc = "Toggle breakpoint",
		},
		{
			"<leader>dc",
			function()
				require("dap").continue()
			end,
			desc = "Continue / Start debugging",
		},
		{
			"<F10>",
			function()
				require("dap").continue()
			end,
			desc = "Continue / Start debugging",
		},
		{
			"<leader>dn",
			function()
				require("dap").step_over()
			end,
			desc = "Step over",
		},
		{
			"<F11>",
			function()
				require("dap").step_over()
			end,
			desc = "Step over",
		},
		{
			"<leader>di",
			function()
				require("dap").step_into()
			end,
			desc = "Step into",
		},
		{
			"<F12>",
			function()
				require("dap").step_into()
			end,
			desc = "Step into",
		},
		{
			"<leader>do",
			function()
				require("dap").step_out()
			end,
			desc = "Step out",
		},
		{
			"<leader>dr",
			function()
				require("dap").restart()
			end,
			desc = "Restart session",
		},
		{
			"<leader>dq",
			function()
				require("dap").terminate()
			end,
			desc = "Stop debugging",
		},
		{
			"<leader>du",
			function()
				require("dapui").toggle()
			end,
			desc = "Toggle DAP UI",
		},
		{
			"<leader>dB",
			function()
				local condition = vim.fn.input("Breakpoint condition: ")
				require("dap").set_breakpoint(condition)
			end,
			desc = "Set conditional breakpoint",
		},
	},
	config = function()
		local dap, dapui = require("dap"), require("dapui")

		------------------------------
		-- language specific setup
		------------------------------
		require("dapui").setup({
			controls = {
				enabled = true,
			},
			force_buffers = true,
		})
		require("dap-python").setup("python3")

		dap.adapters.haskell = {
			type = "executable",
			command = "haskell-debug-adapter",
			args = { "--hackage-version=0.0.39.0" },
		}

		-- Haskell DAP configuration for plain GHCi
		dap.configurations.haskell = {
			{
				type = "haskell",
				request = "launch",
				name = "Debug with GHCi (manual)",
				workspace = "${workspaceFolder}",
				startup = "${file}",
				stopOnEntry = true, -- Stop immediately so you can manually control
				logFile = vim.fn.stdpath("cache") .. "/haskell-dap.log",
				logLevel = "WARNING",
				ghciEnv = vim.empty_dict(),
				ghciPrompt = "H>>= ",
				ghciInitialPrompt = "ghci> ",
				ghciCmd = "ghci-dap --interactive -i${workspaceFolder}",
			},
		}
		dap.adapters.codelldb = {
			type = "executable",
			command = "$HOME/.local/share/nvim/mason/bin/codelldb",
		}
		dap.configurations.cpp = {
			{
				name = "Launch file",
				type = "codelldb",
				request = "launch",
				program = function()
					return vim.fn.input("Path to executable: ", vim.fn.getcwd() .. "/", "file")
				end,
				cwd = "${workspaceFolder}",
				stopOnEntry = false,
			},
		}

		dap.configurations.c = dap.configurations.cpp
		dap.configurations.h = dap.configurations.cpp
		dap.configurations.rust = dap.configurations.cpp

		dap.listeners.before.attach.dapui_config = function()
			dapui.open()
		end
		dap.listeners.before.launch.dapui_config = function()
			dapui.open()
		end
		-- dap.listeners.before.event_terminated.dapui_config = function()
		--   dapui.close()
		-- end
		-- dap.listeners.before.event_exited.dapui_config = function()
		--   dapui.close()
		-- end
	end,
}
