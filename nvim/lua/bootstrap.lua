
assert(not vim.g.lazy_did_setup)

local lazy_plugins = require("plugins")
assert(lazy_plugins)


local lazy_path = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.loop.fs_stat(lazy_path) then
	assert(vim.system({"git", "--version"}):wait().code == 0)
	local lazy_link = "https://github.com/folke/lazy.nvim.git"
	vim.fn.system({ "git", "clone", "--filter=blob:none", "--branch=stable", lazy_link, lazy_path })
end
vim.opt.rtp:prepend(lazy_path)

local lazy_options = nil

for _, plugin in pairs(lazy_plugins) do
	if plugin[1] == "folke/lazy.nvim" then
		lazy_options = plugin.opts
		break
	end
end
assert(lazy_options)

local lazy = require("lazy")
lazy.setup(lazy_plugins, lazy_options)

vim.keymap.set("n", "<leader>up", "<cmd>Lazy<CR>", { desc = "lazy [P]ackage manager" })

