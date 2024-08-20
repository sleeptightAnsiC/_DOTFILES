local M = {}


M.TERM_SUPPORTED =
	false
	or os.getenv("OS") == "Windows_NT"
	or os.getenv("TERM_PROGRAM") == "WezTerm"
	-- HACK: 
	or (os.getenv("HOSTNAME") == "DEAL260624" and os.getenv("DE"))
	or not not vim.g.started_by_firenvim
M.COLOR_SUPPORTED =
	false
	or os.getenv("OS") == "Windows_NT"
	or os.getenv("TERM") == "xterm-256color"
	or not not vim.g.started_by_firenvim
M.NERD_FONT_ALLOWED = M.TERM_SUPPORTED
M.BORDER_STYLE = M.NERD_FONT_ALLOWED and "shadow" or "rounded"
M.SEPARATOR_VERTICAL = '│'
M.SEPARATOR_HORIZONTAL = '─'
M.COLORSCHEME_FALLBACK = "retrobox"

M.get_current_folder = function ()
	local cwd = vim.fn.getcwd()
	local folder =  string.match(cwd, "([^/]+)$")
	return folder
end

return M
