
local utils = require("utils")

vim.g.mapleader = " "
vim.g.maplocalleader = " "

vim.o.background = "dark"
vim.o.timeout = true
vim.o.timeoutlen = 500
vim.o.autoread = true

vim.opt.updatetime = 250
vim.opt.number = true
vim.opt.relativenumber = true
vim.opt.clipboard = "unnamedplus"
vim.opt.breakindent = true
vim.opt.undofile = true
vim.opt.ignorecase = true
vim.opt.smartcase = true
vim.opt.signcolumn = "auto"
vim.opt.splitright = true
vim.opt.splitbelow = true
vim.opt.list = true
vim.opt.listchars = {
	tab = utils.SEPARATOR_VERTICAL.."->",
	space = "·",
	trail = "~",
	nbsp = "␣",
}
vim.opt.inccommand = "split"
vim.opt.scrolloff = 5
vim.opt.sidescrolloff = 10
vim.opt.hlsearch = true
vim.opt.wrap = false

vim.diagnostic.config({
	virtual_text = false
})

