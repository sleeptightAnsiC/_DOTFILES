
local cmds_group = vim.api.nvim_create_augroup("config_cmds", { clear = true })


vim.api.nvim_create_autocmd("TextYankPost", {
	desc = "Highlight when yanking ",
	group = cmds_group,
	callback = function() vim.highlight.on_yank() end,
})


vim.api.nvim_create_autocmd("TermOpen", {
	desc = "Manage terminal after opening",
	pattern = 'term://*',
	group = cmds_group,
	callback = function(event)
		vim.opt_local.number = false
		vim.opt_local.relativenumber = false
		vim.opt_local.signcolumn = "no"
		local current_buf = vim.api.nvim_get_current_buf()
		vim.cmd.startinsert()
		vim.cmd.nohlsearch()
	end,
})


if
	pcall(function()
		assert(vim.system({"xset", "--version"}):wait().code == 0)
		assert(vim.system({"xdotool", "--version"}):wait().code == 0)
	end)
then
	vim.api.nvim_create_autocmd("ModeChanged", {
		desc = "Ensure that capslock is turned OFF after changing Mode",
		group = cmds_group,
		callback = function()
			local result_xset = vim.system({"xset", "-q"}):wait()
			assert(result_xset.code == 0)
			local b_on = not not string.find(result_xset.stdout, "Caps Lock:   on")
			assert(b_on or string.find(result_xset.stdout, "Caps Lock:   off"))
			if b_on then
				local result_xdotool = vim.system({"xdotool", "key", "Caps_Lock"}):wait()
				assert(result_xdotool.code == 0)
				assert(result_xdotool.stdout == "")
			end
		end,
	})
else
	vim.api.nvim_create_autocmd("UIEnter", {
		desc = "Notify about missing xorg backend",
		group = cmds_group,
		callback = function()
			vim.notify(
				"Unable to setup automatic CAPSLOCK toggling",
				vim.log.levels.WARN,
				{ title = "cmds.lua" }
			)
		end,
	})
end

