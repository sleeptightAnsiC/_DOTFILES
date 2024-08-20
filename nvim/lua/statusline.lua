--- MIT License Copyright (c) 2021-2024 Evgeni Chasnovski
--- MIT License Copyright (c) 2024 SleeptightAnsiC

--- This file has been creted based on Evgeni Chasnovski's implementation of statusline from mini.nvim
--- Although almost whole code has been changed and refactored, his work is still part of it
--- and, because of said reason, there's additional Copytight notice on the very first line.
--- https://github.com/echasnovski/mini.nvim/blob/19e1584124cda35388d4fdb911eab7124014e541/lua/mini/statusline.lua
--- https://github.com/echasnovski/mini.nvim/blob/19e1584124cda35388d4fdb911eab7124014e541/LICENSE


local M = {}


M.section_mode = function()
	local CTRL_V = vim.api.nvim_replace_termcodes("<C-V>", true, true, true)
	local CTRL_S = vim.api.nvim_replace_termcodes("<C-S>", true, true, true)
	local mode = vim.fn.mode()
	local len = #mode
	return
		false
		or (mode == CTRL_V) and ("^v ")
		or (mode == CTRL_S) and ("^s ")
		or (len == 1) and (" "..mode.." ")
		or (len == 2) and (" "..mode)
		or mode
end

M.section_tabs = function()
	local tabpages = vim.api.nvim_list_tabpages()
	if #tabpages < 2 then
		return ""
	end
	local current = vim.api.nvim_get_current_tabpage()
	local section = "| "
	for i,n in ipairs(tabpages) do
		local str = (n == current) and ("{"..i.."} ") or (i.." ")
		section = section..str
	end
	return section
end

M.section_wins = function()
	local tabpage = vim.api.nvim_get_current_tabpage()
	local wins = vim.api.nvim_tabpage_list_wins(tabpage)
	local currwin = vim.api.nvim_get_current_win()
	local section = "| "
	local count = 0
	for _,win in ipairs(wins) do
		local buf = vim.api.nvim_win_get_buf(win)
		local full = vim.api.nvim_buf_get_name(buf)
		if full ~= "" then
			local short = string.match(full, "^.+/(.+)$") or ""
			local final = (win == currwin) and ("{"..short.."} ") or (short.." ")
			section = section..final
			count = count + 1
		end
	end
	return (count >= 2) and section or ""
end

M.section_buf = function()
	return "| %<%F%m%r "
end

M.section_lsp = function()
	local msg = ""
	local buf_ft = vim.api.nvim_get_option_value("filetype", {scope = "local"})
	local clients = vim.lsp.get_clients()
	for _, client in ipairs(clients) do
		local filetypes = client.config.filetypes
		if filetypes and vim.fn.index(filetypes, buf_ft) ~= -1 then
			msg = msg..client.name.." "
		end
	end
	return (msg ~= "") and ("| "..msg) or ""
end

M.section_diagnostics = function()
	if not vim.diagnostic.is_enabled({ bufnr = 0 }) then
		return ""
	end
	local count = vim.diagnostic.count(0)
	local severity = vim.diagnostic.severity
	local t = {}
	DIAGNOSTIC_LEVELS = {
		{ name = "ERROR", sign = "E" },
		{ name = "WARN", sign = "W" },
		{ name = "INFO", sign = "I" },
		{ name = "HINT", sign = "H" },
	}
	for _, level in ipairs(DIAGNOSTIC_LEVELS) do
		local n = count[severity[level.name]] or 0
		if n > 0 then
			table.insert(t, level.sign..n.." ")
		end
	end
	return (#t ~= 0) and (table.concat(t, "")) or ""
end

M.section_git = function()
	local branch = vim.b.minigit_summary_string or vim.b.gitsigns_head
	local diff = vim.b.minidiff_summary_string or vim.b.gitsigns_status
	return branch and ("| "..branch.." "..diff.." ") or ""
end

M.section_location = function()
	return "| %l:%2v "
end

M.section_lines = function()
	local line = vim.api.nvim_buf_line_count(0)
	local sign = ''
	while line > 1000 do
		line = line/1000
		sign = sign.."k"
	end
	line = math.floor(line * 10)
	line = line/10
	return "| "..tostring(line)..sign.." "
end

M.GROUPS = {
	"%#ColorColumn#",
	M.section_mode,
	M.section_tabs,
	M.section_wins,
	M.section_buf,
	"%=",
	M.section_lsp,
	M.section_diagnostics,
	M.section_git,
	"%=",
	M.section_location,
	M.section_lines,
	"%>"
}

M.content_get = function()
	local content = ""
	local cols = vim.o.columns
	local lens = 0
	for _,gr in ipairs(M.GROUPS) do
		if type(gr) == "string" then
			content = content..gr
		elseif type(gr) == "function" then
			local str = gr()
			local len = #str
			if (len + lens < cols) then
				lens = lens + len
				content = content..str
			else
				local n = cols - lens
				for _=1,n do
					content = content.." "
				end
				break
			end
		end
	end
	return content
end

-- TODO: this does not refresh right after opening vertical split
M.content_update = vim.schedule_wrap(function()
	-- FIXME: the fact that there is no way of disabling uter shit!
	--    https://github.com/neovim/neovim/issues/22714
	--    https://github.com/neovim/neovim/discussions/29510
	-- vim.t.tabline = "%{%v:lua.statusline_content_get()%}"
	-- local currwin = vim.api.nvim_get_current_win()
	-- local winwidth = vim.api.nvim_win_get_width(currwin)
	-- local separator = ""
	-- for _=1, winwidth do
	-- 	separator = separator.."─"
	-- end
	-- vim.wo.statusline = "%#WinSeparator#"..separator
	vim.wo.statusline = "%{%v:lua.statusline_content_get()%}"
end)

M.setup = function()
	vim.opt.showmode = false
	vim.opt.ruler = false
	vim.opt.laststatus = 3
	vim.g.qf_disable_statusline = 1
	vim.opt.showtabline = 0
	-- WARN: this is in _G so it can be called from vimscript
	_G.statusline_content_get = M.content_get
	vim.api.nvim_create_autocmd(
		{
			"WinEnter",
			"BufWinEnter",
			"WinLeave",
			"WinNew",
		},
		{
			group = vim.api.nvim_create_augroup("statusline", {}),
			pattern = "*",
			callback = M.content_update,
			desc = "Ensure statusline content",
		}
	)
	M.content_update()
end


M.setup()

