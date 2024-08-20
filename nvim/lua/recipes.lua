
local utils = require("utils")
local current_folder = utils.get_current_folder()


---@class recipes
---@field language_configurations table
---@field debug_adapters table
---@field debug_configurations table
---@field is_session_active function
local M = {}


------ sessions

M.is_session_active = function()
	local result =
		false
		or current_folder == "mtpl"
		or current_folder == "rlspr"
		or current_folder == "Tlob"
		or current_folder == "ue4cli"
		or current_folder == "dotfiles"
	return result
end


------ LSP setup

-- https://github.com/neovim/nvim-lspconfig/blob/master/doc/server_configurations.md
M.language_configurations = {
	-- ccls = {},
	-- rust_analyzer = {},
	-- bashls = {},
	-- tsserver = {},
	-- als = {},
	-- zls = {},
	harper_ls = {},
	csharp_ls = {},
	clangd = {
		single_file_support = true,
		cmd = { vim.fn.resolve(vim.fn.stdpath("data").."/mason/bin/clangd") },
	},
	pylsp = {},
	lua_ls = {
		settings = {
			Lua = {
				workspace = {
					checkThirdParty = false,
					library = vim.tbl_deep_extend('force', vim.api.nvim_get_runtime_file("", true), {
						"${3rd}/luv/library",
						"${3rd}/busted/library",
						"/usr/share/awesome/lib",
						"/usr/share/lua",
						-- "/usr/share/xmake",
					}),
				},
				diagnostics = {
					globals = {
						-- NOTE: these are all related to AwesomeWM
						"awesome",
						"awful",
						"client",
						"screen",
						"tag",
						"root",
						-- NOTE: neovim globals
						"vim",
					},
				},
				runtime = { version = 'LuaJIT' },
				completion = { callSnippet = "Replace", },
				telemetry = {
					enable = false,
				},
			},
		},
	},
}


-- TODO: make something that will look for those configurations automatically
-- TODO: try to make something wimilar with LLDB and windows VS debugger (its either WinDBG or VSDBG, I don't remember...)
-- https://github.com/mfussenegger/nvim-dap/discussions/869
local TLOB_CONFIGURATION = "DebugGame"
-- NOTE: the best experience out of them all
--       super fast and responsive, isn't noisy like the others
--       but it doesn't show the static/global values (only locals)
local gdb_tlob = {
	name = "gdb TlobEditor Linux "..TLOB_CONFIGURATION,
	type = "gdb",
	request = "launch",
	program = function()
		local postfix = (TLOB_CONFIGURATION ~= "Development") and "-Linux-"..TLOB_CONFIGURATION or ""
		local path = vim.env.HOME.."/UnrealEngine/Engine/Binaries/Linux/UnrealEditor"..postfix
		return vim.fn.resolve(path)
	end,
	cwd = vim.fn.resolve(vim.env.HOME.."/Tlob"),
	args = { vim.fn.resolve(vim.env.HOME.."/Tlob/Tlob.uproject"), },
	stopAtBeginningOfMainSubprogram = false,
}
-- NOTE: this one is super slow and doesn't even seems to load data formaters (or these might be broken)
local codelldb_tlob = {
	name = "codelldb TlobEditor Linux "..TLOB_CONFIGURATION,
	type = "codelldb",
	request = "launch",
	program = function()
		local postfix = (TLOB_CONFIGURATION ~= "Development") and "-Linux-"..TLOB_CONFIGURATION or ""
		local path = vim.env.HOME.."/UnrealEngine/Engine/Binaries/Linux/UnrealEditor"..postfix
		return vim.fn.resolve(path)
	end,
	cwd = vim.fn.resolve(vim.env.HOME.."/Tlob"),
	args = { vim.fn.resolve(vim.env.HOME.."/Tlob/Tlob.uproject"), },
	initCommands = { "command source ~/.lldbinit" },
	stopOnEntry = false,
}

local gdb_mtpl = {
	name = "gdb mtpl",
	type = "gdb",
	request = "launch",
	program = vim.fn.resolve(os.getenv("HOME").."/mtpl/bin/gcc/mtpl"),
	cwd = vim.fn.resolve(os.getenv("HOME").."/mtpl"),
	stopAtBeginningOfMainSubprogram = false,
}

local gdb_rlspr = {
	name = "gdb rlspr",
	type = "gdb",
	request = "launch",
	program = vim.fn.resolve(os.getenv("HOME").."/rlspr/bin/gcc/rlspr"),
	cwd = vim.fn.resolve(os.getenv("HOME").."/rlspr"),
	stopAtBeginningOfMainSubprogram = false,
}

local gdb_oneoff = {
	name = "gdb oneoff",
	type = "gdb",
	request = "launch",
	program = function()
		local potential_executable = Cached_executable or vim.fn.getcwd()..'/'
		Cached_executable = vim.fn.input('Path to executable: ', potential_executable, 'file')
		return Cached_executable
	end,
	cwd = '${workspaceFolder}',
	stopAtBeginningOfMainSubprogram = false,
}


local cppdbg_oneoff = {
	name = "cppdbg oneoff",
	type = "cppdbg",
	request = "launch",
	program = function()
		local potential_executable = Cached_executable or vim.fn.getcwd()..'/'
		Cached_executable = vim.fn.input('Path to executable: ', potential_executable, 'file')
		return Cached_executable
	end,
	cwd = '${workspaceFolder}',
	stopAtEntry = true,
}

------ DAP setup

-- https://github.com/mfussenegger/nvim-dap/wiki/Debug-Adapter-installation
M.debug_adapters = {
	["cppdbg"] = {
		id = 'cppdbg',
		type = 'executable',
		command = vim.fn.resolve(vim.fn.stdpath("data").."/mason/bin/OpenDebugAD7"),
	},
	-- WARN: using GDB on windows might be a problem
	-- https://github.com/mfussenegger/nvim-dap/issues/1227
	["gdb"] = {
		type = "executable",
		command = "gdb",
		args = { "-i", "dap", "--quiet" }
	},
	["codelldb"] = {
		type = 'server',
		port = "${port}",
		executable = {
			command = vim.fn.resolve(vim.fn.stdpath("data").."/mason/bin/codelldb"),
			args = {"--port", "${port}"},
			-- On windows you may have to uncomment this:
			-- detached = false,
		}
	},
}

-- https://github.com/mfussenegger/nvim-dap/wiki/Debug-Adapter-installation
M.debug_configurations = {
	["cpp"] = {
		false
		or (current_folder == "Tlob") and gdb_tlob
		or (current_folder == "Tlob") and codelldb_tlob
		or gdb_oneoff,
	},
	["c"] = {
		false
		-- or (current_folder == "mtpl") and gdb_mtpl
		-- or (current_folder == "rlspr") and gdb_rlspr
		-- or gdb_oneoff,
		or cppdbg_oneoff,
	},
}


return M
