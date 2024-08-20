
local utils = require("utils")
local recipes = require("recipes")

return {

	{
		-- FIXME: find replacement for this plugin or revrite it to lua!
		-- https://github.com/anuvyklack/hydra.nvim - hydra does not do exacly what I want
		-- https://github.com/smoka7/multicursors.nvim - might be fine but it uses damn hydra as dependency...
		"mg979/vim-visual-multi",
	},

	{
		'echasnovski/mini.bracketed',
		event = "UIEnter",
		version = '*',
		keys = {
			-- FIXME: this still does not work as it should, reimplement it yourself!
			{ mode="n", "<C-I>", function() require("mini.bracketed").jump("backward") end, noremap=true, desc="hover" },
		}, config = true,
	},

	{
		'echasnovski/mini.clue',
		event = "UIEnter",
		version = '*',
		config = function ()
			local miniclue = require('mini.clue')
			miniclue.setup({
				window = {
					config = {
						border = utils.BORDER_STYLE
					},
					scroll_down = '<C-n>',
					scroll_up = '<C-p>',
				},
				triggers = {
					{ mode = 'n', keys = '[' },
					{ mode = 'x', keys = '[' },
					{ mode = 'n', keys = ']' },
					{ mode = 'x', keys = ']' },
					{ mode = 'n', keys = '<Leader>' },
					{ mode = 'x', keys = '<Leader>' },
					{ mode = 'i', keys = '<C-x>' },
					{ mode = 'n', keys = 'g' },
					{ mode = 'x', keys = 'g' },
					{ mode = 'n', keys = "'" },
					{ mode = 'n', keys = '`' },
					{ mode = 'x', keys = "'" },
					{ mode = 'x', keys = '`' },
					{ mode = 'n', keys = '"' },
					{ mode = 'x', keys = '"' },
					{ mode = 'i', keys = '<C-r>' },
					{ mode = 'c', keys = '<C-r>' },
					{ mode = 'n', keys = '<C-w>' },
					{ mode = 'n', keys = 'z' },
					{ mode = 'x', keys = 'z' },
				},
				clues = {
					miniclue.gen_clues.builtin_completion(),
					miniclue.gen_clues.g(),
					miniclue.gen_clues.marks(),
					miniclue.gen_clues.registers(),
					miniclue.gen_clues.windows(),
					miniclue.gen_clues.z(),
				},
			})
		end,
	},

	{
		'echasnovski/mini.cursorword',
		event = "UIEnter",
		version = '*',
		config = true,
	},

	{
		'echasnovski/mini.move',
		event = "UIEnter",
		version = '*',
		opts = {
			mappings = {
				left = '<S-h>',
				right = '<S-l>',
				down = '<S-j>',
				up = '<S-k>',
			},
		},
	},

	{
		'echasnovski/mini.notify',
		event = "UIEnter",
		version = '*',
		opts = {
			lsp_progress = { duration_last = 100, },
			window = {
				config = { border = utils.BORDER_STYLE },
			},
		},
	},

	{
		-- WARN: https://github.com/glacambre/firenvim/blob/master/SECURITY.md
		"glacambre/firenvim",
		lazy = not vim.g.started_by_firenvim,
		build = function()
			require("lazy").load({ plugins = "firenvim", wait = true })
			vim.fn["firenvim#install"](0)
		end,
		config = function()
			vim.api.nvim_create_autocmd({'TextChanged', 'TextChangedI'}, {
				callback = function(e)
					if vim.g.timer_started == true then
						return
					end
					vim.g.timer_started = true
					vim.fn.timer_start(10000, function()
						vim.g.timer_started = false
						vim.cmd('silent write')
					end)
				end
			})
		end,
		init = function ()
			vim.g.firenvim_config = {
				globalSettings = { alt = "all" },
				localSettings = {
					[".*"] = {
						content  = "text",
						priority = 0,
						selector = "textarea",
						takeover = "never" -- always explicit takeover
					}
				}
			}
		end
	},

	{
		"lewis6991/hover.nvim",
		lazy = true,
		keys = {
			{mode="n", "K", function() require("hover").hover() end, noremap=true, desc="hover"},
		},
		opts = {
			init = function()
				require("hover.providers.lsp")
				require('hover.providers.gh')
				require('hover.providers.gh_user')
				require('hover.providers.jira')
				require('hover.providers.dap')
				require('hover.providers.fold_preview')
				require('hover.providers.diagnostic')
			end,
			preview_opts = { border = utils.BORDER_STYLE },
		},
	},

	{
		'neovim/nvim-lspconfig',
		lazy = true,
		dependencies = {
			{"SmiteshP/nvim-navbuddy", lazy = true},
		},
		config = function()
			require("nvim-navbuddy")
			local capabilities_nvim = vim.lsp.protocol.make_client_capabilities()
			local capabilities_cmp = require('cmp_nvim_lsp').default_capabilities()
			local capabilities_all = vim.tbl_deep_extend("force", capabilities_nvim, capabilities_cmp)
			local nvimlspconfig = require("lspconfig")
			local lsp_configurations = recipes.language_configurations
			for name, cfg in pairs(lsp_configurations) do
				-- HACK: table injection
				cfg.capabilities = capabilities_all
				nvimlspconfig[name].setup(cfg)
			end
		end,
	},

	{
		"andrewferrier/debugprint.nvim",
		-- NOTE: not possible to lazy load as it has lots of bindings, also it starts super fast
		lazy = false,
		config = true,
	},

	{
		"uga-rosa/ccc.nvim",
		lazy = true,
		cmd = {
			"CccPick",
			"CccConvert",
			"CccHighlighterEnable",
			"CccHighlighterDisable",
			"CccHighlighterToggle",
		},
		keys = {
			{mode="n", "<leader>ucp", "<cmd>CccPick<CR>", noremap=true, desc="[P]ick"},
			{mode="n", "<leader>ucc", "<cmd>CccConvert<CR>", noremap=true, desc="[C]onvert"},
			{mode="n", "<leader>uch", "<cmd>CccHighlighterToggle<CR>", noremap=true, desc="[H]ighlight toggle"},
		},
		opts = {
			highlighter = {
				auto_enable = false,
				lsp = true,
			},
			win_opts = { border = utils.BORDER_STYLE },
			preserve = true,
		},
	},

	{
		"SmiteshP/nvim-navbuddy",
		-- FIXME: pin pointed to my fork until upstream accepts PR
		-- https://github.com/SmiteshP/nvim-navbuddy/pull/100
		url = "https://github.com/sleeptightAnsiC/nvim-navbuddy.git",
		branch = "usercommand_global",
		lazy = true,
		dependencies = {
			{"SmiteshP/nvim-navic", lazy=true},
			{"MunifTanjim/nui.nvim", lazy=true},
			{"neovim/nvim-lspconfig", lazy=false},
			{"numToStr/Comment.nvim", lazy=true}, -- NOTE: alternative: https://github.com/echasnovski/mini.nvim/blob/main/readmes/mini-comment.md
			{"nvim-telescope/telescope.nvim", lazy=true},
		},
		cmd = { "Navbuddy" },
		keys = {
			{mode="n", "L", "<cmd>Navbuddy<CR>", desc="navigate LSP symbols"},
			{mode="n", "<leader>ln", "<cmd>Navbuddy<CR>", noremap=true, desc="[N]avigate"},
		},
		opts = {
			lsp = { auto_attach = true },
			window = {
				border = utils.BORDER_STYLE,
				size = {
					height = "40%",
					width = "95%",
				},
				position = {
					row = 2,
					col = "50%",
				},
			},
		},
	},

	{
		"miyakogi/conoline.vim",
		cond = utils.COLOR_SUPPORTED,
		config = function ()
			vim.g.conoline_auto_enable = 1
		end,
	},

	{
		"rcarriga/nvim-dap-ui",
		lazy = true,
		cmd = {
			"DapContinue", "DapInstall", "DapLoadLaunchJSON",
			"DapRestartFrame", "DapSetLogLevel", "DapShowLog",
			"DapStepInto", "DapStepOver", "DapTerminate",
			"DapToggleBreakpoint", "DapToggleRepl", "DapUninstall",
			"DapStepOut", "DapRunCurrentFile", "DapRunNvim",
		},
		keys = {
			{mode="n", "<leader>dc", function() require("dap").continue() end, desc="[C]ontinue" },
			{mode="n", "<leader>di", function() require("dap").step_into() end, desc="step [I]nto" },
			{mode="n", "<leader>dn", function() require("dap").step_over() end, desc="[N] step over" },
			{mode="n", "<leader>do", function() require("dap").step_out() end, desc="step [O]ut" },
			{mode="n", "<leader>db", function() require("dap").toggle_breakpoint() end, desc="[B]reakpoint toggle"},
			{mode="n", "<leader>de", function() require("dap").terminate() end, desc="[E]xit"},
			{mode="n", "<leader>dt", function() require('dapui').toggle() end, desc="[T]oggle UI"},
			{mode="n", "<leader>ds", function() require('dapui')._float_element_pretty("scopes") end, desc="[S]copes UI"},
			{mode="n", "<leader>df", function() require('dapui')._float_element_pretty("stacks") end, desc="[F]rames UI"},
			{mode="n", "<leader>dw", function() require('dapui')._float_element_pretty("watches") end, desc="[W]atches UI"},
			{mode="n", "<leader>dp", function() require('dapui')._float_element_pretty("breakpoints") end, desc="[P] breakpoints UI"},
			{mode="n", "<leader>dr", function() require('dapui')._float_element_pretty("repl") end, desc="[R]epl UI"},
			{mode="n", "<leader>du", function() require('dapui')._float_element_pretty("console") end, desc="[U] console UI"},
			{mode="n", "<leader>dv", function() require('dapui').eval() end, desc="[V] evaluate UI"},
		},
		dependencies = {
			{"mfussenegger/nvim-dap", lazy=true},
			{"nvim-neotest/nvim-nio", lazy=true},
			{"jbyuki/one-small-step-for-vimkind", lazy=true},
		},
		config = function()
			local dap = require('dap')
			local adapters_default = dap.adapters or {}
			local adapters_user = recipes.debug_adapters
			---@diagnostic disable inject-field
			dap.adapters = vim.tbl_deep_extend("force", vim.deepcopy(adapters_default), adapters_user)
			dap.adapters["nlua"] = {
				type = "server",
				host = "127.0.0.1",
				port = 8086,
			}
			local configurations_default = dap.configurations or {}
			local configurations_user = recipes.debug_configurations
			---@diagnostic disable inject-field
			dap.configurations = vim.tbl_deep_extend("force", vim.deepcopy(configurations_default), configurations_user)
			dapui = require("dapui")
			dapui.setup({
				icons = { expanded = "v", collapsed = ">", current_frame = ">" },
				floating = { border = utils.BORDER_STYLE, },
				controls = { enabled = false, },
				render = { indent = 2 },
				layouts = {
					-- TODO: maybe there is a way to have multiple configs,
					--       if not, I shall contribute this
					{
						elements = { "repl" },
						size = 0.2,
						position = "top",
					},
					-- NOTE: native gdb prints everything to repl window, we don't need a console for it
					-- {
					-- 	elements = { "console" },
					-- 	size = 0.2,
					-- 	position = "top",
					-- },
					{
						elements = { "stacks" },
						size = 0.2,
						position = "bottom",
					},
				},
			})
			dap.listeners.before.attach.dapui_config = dapui.open
			dap.listeners.before.launch.dapui_config = dapui.open
			-- FIXME: something shadows DAP signs. Redefinition fixes this but I don't like it...
			vim.fn.sign_define('DapBreakpoint', { text='B', texthl='DapBreakpointSymbol', linehl='', numhl='' })
			vim.fn.sign_define('DapBreakpointCondition', { text='C', texthl='DapBreakpointSymbol', linehl='', numhl='' })
			vim.fn.sign_define('DapBreakpointRejected', { text='R', texthl='DapBreakpointSymbol', linehl='', numhl= '' })
			vim.fn.sign_define('DapLogPoint', { text='L', texthl='DapStoppedSymbol', linehl='', numhl= '' })
			vim.fn.sign_define('DapStopped', { text='->', texthl='DapStoppedSymbol', linehl='', numhl= '' })
			-- https://github.com/mfussenegger/nvim-dap/wiki/Cookbook#run-the-current-buffer-script-with-cli-arguments-and-enter-into-debug-mode
			vim.api.nvim_create_user_command("DapRunCurrentFile", function(t)
				dap.run({
					type = vim.bo.filetype,
					request = "launch",
					name = "Launch script with custom arguments (adhoc)",
					program = "${file}",
					args = vim.split(vim.fn.expand(t.args), "\n"),
				})
			end, { nargs = '*' })
			-- neovim debugging
			vim.api.nvim_create_user_command("DapRunNvim", function(t)
				dapui.open()
				-- TODO: move some of the logic to trap.lua
				vim.cmd([[term nvim -c "lua vim.defer_fn(function() require('osv').launch({port = 8086}) end, 1500)"]])
				vim.defer_fn(function()
					dap.run({
						name = "Attach to Neovim instance",
						type = 'nlua',
						request = 'attach',
					})
				end, 2000)
				vim.notify(
					"debugging will start in 2 sec...",
					vim.log.levels.WARN,
					{ title = "new neovim instance started" }
				)
			end, { nargs = '*' })
			-- WARN: (dapui table injection) this wrapper makes it
			--       way easier to call float_element funtion from key bindings
			--       but yes, this is super duper nasty...
			dapui._float_element_pretty = function (name)
				dapui.float_element(name, {
					width = math.floor(vim.go.columns * 0.90),
					height = math.floor(vim.go.lines * 0.80),
					enter = true,
					position = "center",
				})
			end
		end,
	},

	{
		"iamcco/markdown-preview.nvim",
		lazy = true,
		cmd = { "MarkdownPreviewToggle", "MarkdownPreview", "MarkdownPreviewStop" },
		ft = { "markdown" },
		build = function()
			vim.fn["mkdp#util#install"]()
		end,
	},

	{
		"kevinhwang91/nvim-bqf",
		lazy = true,
		event = { "QuickFixCmdPre", },
		ft = { "qf" },
		cmd = { "BqfAutoToggle" },
		dependencies = {'nvim-treesitter/nvim-treesitter', lazy=true},
		config = function()
			require("bqf").setup({
				preview = {
					border = utils.BORDER_STYLE,
					show_scroll_bar = false,
					winblend = 0,
				},
			})
			-- fix wrong highlight for nvim-bqf floating preview with shadow border
			--     and prevent cursor line from displaying in preview
			-- TODO: this still is a bit broken
			assert(utils.BORDER_STYLE == "shadow", "This is probably will be broken again with different border style")
			local hl_nf = vim.api.nvim_get_hl(0, {name = "NormalFloat"})
			vim.api.nvim_set_hl(0, "BqfPreviewFloat", hl_nf)
			vim.api.nvim_set_hl(0, "BqfPreviewCursorLine", hl_nf)
			vim.api.nvim_set_hl(0, "BqfPreviewCursor", hl_nf)
		end,
	},

	{
		'Wansmer/treesj',
		dependencies = { 'nvim-treesitter/nvim-treesitter' },
		cmd = { "TSJToggle", "TSJSplit", "TSJJoin" },
		keys = {
			{mode="n", "<C-j>", "<cmd>TSJToggle<CR>", desc="text split/join"},
		},
		opts = {
			max_join_length = 2000,
			use_default_keymaps = false,
		},
	},

	{
		"kylechui/nvim-surround",
		event = "VeryLazy",
		config = true,
		version = "*",
	},

	{
		"shellRaining/hlchunk.nvim",
		-- TODO: possibly obsolete
		event = {"UIEnter"},
		opts = {
			chunk = {enable = false},
			line_num = {enable = false},
			blank = {enable = false},
			indent = {enable = true},
		},
	},

	{
		-- FIXME: for some reason, this plugin loads lots of things, like telescope
		"rmagatti/auto-session",
		config = true,
		cond = recipes.is_session_active(),
	},

	{
		'windwp/nvim-autopairs',
		lazy = true,
		event = "InsertEnter",
		config = true,
	},

	{
		"stevearc/oil.nvim",
		-- cannot lazy load as it won't work when opening nvim with directory as argument
		lazy = false,
		cmd = { "Oil", },
		keys = {
			{mode="n", "-", "<cmd>Oil<CR>", desc="explore"},
			{mode="n", "_", function () require("oil").open(vim.fn.getcwd()) end, desc="explore CWD"},
		},
		opts = {
			columns = {
				{ "permissions", highlight = nil},
				{ "size", highlight = "Special"},
				{ "mtime", highlight = nil},
				{ "type", highlight = "Special"},
			},
			skip_confirm_for_simple_edits = true,
			prompt_save_on_select_new_entry = false,
			constrain_cursor = "editable",
			experimental_watch_for_changes = true,
			keymaps = {
				["<C-v>"] = { "actions.select_vsplit", desc = "Open the entry in a vertical split" },
				["<C-s>"] = { "actions.select_split", opts = { horizontal = true }, desc = "Open the entry in a horizontal split" },
			},
			view_options = {
				show_hidden = true,
				natural_order = false,
			},
			float = { border = utils.BORDER_STYLE, },
			preview = { border = utils.BORDER_STYLE, },
			progress = { border = utils.BORDER_STYLE, },
			ssh = { border = utils.BORDER_STYLE, },
			keymaps_help = { border = utils.BORDER_STYLE, },
		},
	},

	{
		"tpope/vim-sleuth",
		lazy = true,
		event = { "BufReadPre" },
	},

	{
		"numToStr/Comment.nvim",
		event = { "UIEnter" },
		config = true,
		lazy = true,
	},

	{
		"lewis6991/gitsigns.nvim",
		lazy = true,
		event = { "UIEnter" },
		cmd = { "Gitsigns", },
		keys = {
			{mode="n", desc="git [D]iff", "<leader>ud",
				"<cmd>Gitsigns toggle_numhl<CR>"
				.."<cmd>Gitsigns toggle_linehl<CR>"
				.."<cmd>Gitsigns toggle_deleted<CR>"
				.."<cmd>Gitsigns toggle_word_diff<CR>"
			},
		},
		opts = {
			signs = {
				add = { text = '+' },
				change = { text = '~' },
				delete = { text = '-' },
				topdelete = { text = '-' },
				changedelete = { text = '~' },
				untracked  = { text = '?' },
			},
			current_line_blame_opts = {
				delay = 300,
				ignore_whitespace = true,
			},
			attach_to_untracked = true,
		},
	},

	{
		-- FIXME: make opening-into-split binding <C-s> so it will be consistent with everythig else
		"nvim-telescope/telescope.nvim",
		lazy = true,
		dependencies = {
			{"nvim-lua/plenary.nvim", lazy=true},
			{"nvim-telescope/telescope-ui-select.nvim", lazy=true},
			{"polirritmico/telescope-lazy-plugins.nvim", lazy=true},
			{"debugloop/telescope-undo.nvim", lazy=true},
		},
		cmd = { "Telescope", },
		keys = {
			{mode="n", "<leader>ft", "<cmd>Telescope<CR>", desc="[T]elescope" },
			{mode="n", "<leader>lw", "<cmd> Telescope lsp_dynamic_workspace_symbols <CR>", noremap=true, desc="[W]orkspace symbols"},
			{mode="n", "<leader>lf", "<cmd> Telescope lsp_references <CR>", noremap=true, desc="[F] references"},
			{mode="n", "<leader>li", "<cmd> Telescope lsp_implementations <CR>", noremap=true, desc="[I]mplementation"},
			{mode="n", "<leader>ld", "<cmd> Telescope lsp_definitions <CR>", noremap=true, desc="[D]efinition"},
			{mode="n", "<leader>lq", "<cmd> Telescope diagnostics <CR>", noremap=true, desc="[Q] Open diagnostic list"},
			{mode="n", "<leader>ff", "<cmd> Telescope find_files <CR>", desc="[F]iles" },
			{mode="n", "<leader>fw", "<cmd> Telescope grep_string <CR>", desc="current [W]ord in cwd" },
			{mode="n", "<leader>fg", "<cmd> Telescope live_grep <CR>", desc="[G]rep cwd" },
			{mode="n", "<leader>fd", "<cmd> Telescope diagnostics <CR>", desc="[D]iagnostics" },
			{mode="n", "<leader>fo", "<cmd> Telescope oldfiles <CR>", desc="[O]ld files" },
			{mode="n", "<leader>fb", "<cmd> Telescope buffers <CR>", desc="[B]uffers" },
			{mode="n", "<leader>fc", "<cmd> Telescope current_buffer_fuzzy_find <CR>", desc="grep [C]urrent buffer" },
			{mode="n", "<leader>fp", "<cmd> Telescope lazy_plugins <CR>", desc="[P]lugins" },
			{mode="n", "<leader>fu", "<cmd> Telescope undo <CR>", desc="[U]ndo tree (file changes)" },
			{mode="n", "<leader>fh", "<cmd> Telescope highlights <CR>", desc="[H]ighlights" },
			{
				mode="n",
				"<leader>fn",
				function()
					require("telescope.builtin").find_files({
						cwd = vim.fn.stdpath("config"),
					})
				end,
				desc="[N]eovim files",
			},
			{
				mode="n",
				"<leader>lD",
				function ()
					require("telescope.builtin").lsp_definitions({
						jump_type = "split",
						-- FIXME: this option does not seem to work
						-- https://github.com/nvim-telescope/telescope.nvim/issues/2690
						reuse_win = true,
					})
				end,
				noremap=true,
				desc="[D]efinition (split)",
			},
		},
		config = function()
			local telescope = require("telescope")
			telescope.setup({
				defaults = {
					-- WARN: increment each time you try and fail to implement alternative border
					--	STUPIDITY COUNTER: 3
					sorting_strategy = "ascending",
					layout_strategy = "flex",
					layout_config = {
						flex = { flip_columns = 150 },
						horizontal = { preview_width = { 0.55, max = 100, min = 30 } },
						vertical = { preview_cutoff = 20, preview_height = 0.5 },
						prompt_position = "top",
						height = {padding = utils.TERM_SUPPORTED and 0.1 or 0 },
						width = {padding = utils.TERM_SUPPORTED and 0.1 or 0 },
					},
					mappings = {
						n = {
							["<C-h>"] = "which_key",
							['<C-d>'] = require('telescope.actions').delete_buffer,
						},
						i = {
							["<C-h>"] = "which_key",
							['<C-d>'] = require('telescope.actions').delete_buffer,
						},
					}
				},
				extensions = {
					["ui-select"] = {
						require("telescope.themes").get_dropdown(),
					},
					["lazy_plugins"] = {
						lazy_spec_table = vim.fn.stdpath("config") .. "/lua/plugins.lua",
					},
				},
			})
			pcall(telescope.load_extension, "lazygit")
			pcall(telescope.load_extension, "ui-select")
			pcall(telescope.load_extension, "undo")
		end,
	},

	{
		"williamboman/mason.nvim",
		-- FIXME: If I want this to be lazy loaded I need to prepend path manually and fix few cases (but don't remember what was wrong)!
		lazy = false,
		keys = {
			{mode="n", "<leader>um", "<cmd>Mason<CR>", noremap=true, desc="[M]asn"},
		},
		build = ":MasonUpdate",
		cmd = {
			"Mason",
			"MasonUpdate",
			"MasonInstall",
			"MasonUninstall",
			"MasonUninstallAll",
			"MasonLog",
		},
		opts = {
			ui = {
				border = utils.BORDER_STYLE,
				width = 0.8,
				height = 0.8,
				icons = {
					package_installed = "OK ",
					package_pending = "... ",
					package_uninstalled = ""
				}
			}
		},
	},

	{
		"ellisonleao/gruvbox.nvim",
		-- WARN: colorschemes have to be loaded very early!!!
		lazy = false,
		priority = 1000,
		cond = function()
			if utils.COLOR_SUPPORTED then
				return true
			end
			vim.cmd.colorscheme(utils.COLORSCHEME_FALLBACK)
			return false
		end,
		config = function()
			require("gruvbox").setup({
				italic = {
					strings = false,
					emphasis = false,
					comments = false,
					operators = false,
					folds = false,
				},
			})
			vim.cmd.colorscheme("gruvbox")
			local COLORS = { "Red", "Aqua", "Blue", "Green", "Orange", "Purple", "Yellow" }
			-- fixes for sign collumn being too bright
			do
				local hl_gbg0 = vim.api.nvim_get_hl(0, {name = "GruvboxBg0"})
				vim.api.nvim_set_hl(0, "SignColumn", hl_gbg0)
				for _,color in pairs(COLORS) do
					local name = "Gruvbox"..color.."Sign"
					local hl_gcs = vim.api.nvim_get_hl(0, {name = name})
					hl_gcs.bg = hl_gbg0.fg
					vim.api.nvim_set_hl(0, name, hl_gcs)
				end
			end
			-- removes curly underlines (straight lines are easier to spot!)
			for _,color in pairs(COLORS) do
				local name = "Gruvbox"..color.."Underline"
				local hl_gcu = vim.api.nvim_get_hl(0, {name = name})
				hl_gcu.undercurl = false
				hl_gcu.underline = true
				vim.api.nvim_set_hl(0, name, hl_gcu)
			end
			-- fix for shadow border being too bright
			for _,postfix in pairs({ "", "Through"}) do
				local name = "FloatShadow"..postfix
				local hl_fs = vim.api.nvim_get_hl(0, {name = name})
				hl_fs.bg = "#000000"
				vim.api.nvim_set_hl(0, name, hl_fs)
			end
			-- change function highlight to cyan
			do
				local hl_gob = vim.api.nvim_get_hl(0, {name = "GruvboxOrangeBold"})
				hl_gob.fg = "#3f9a7d"
				vim.api.nvim_set_hl(0, "Function", hl_gob)
			end
			-- tweaks for DAP sing highlights
			do
				local hl_dbs = vim.api.nvim_get_hl(0, {name = "DapBreakpointSymbol"})
				local hl_dss = vim.api.nvim_get_hl(0, {name = "DapStoppedSymbol"})
				local hl_sc = vim.api.nvim_get_hl(0, {name = "SignColumn"})
				hl_dbs.bg = hl_sc.fg
				hl_dss.bg = hl_sc.fg
				vim.api.nvim_set_hl(0, "DapBreakpointSymbol", hl_dbs)
				vim.api.nvim_set_hl(0, "DapStoppedSymbol", hl_dss)
			end
		end,
	},

	{
		"folke/todo-comments.nvim",
		-- TODO: MINI has a replacement for this plugin
		lazy = true,
		event = "UIEnter",
		dependencies = {
			{ "nvim-lua/plenary.nvim", lazy=true },
		},
		opts = {
			signs = false,
			highlight = { after = "", },
		},
	},

	{
		"nvim-treesitter/nvim-treesitter",
		lazy = true,
		event = "UIEnter",
		cmd = {
			-- FIXME: some commands are missing
			"TSBufEnable",
			"TSBufDisable",
			"TSEnable",
			"TSDisable",
			"TSModuleInfo",
			"TSUpdateSync",
		},
		build = ":TSUpdate",
		dependencies = {
			{"nvim-treesitter/nvim-treesitter-textobjects", lazy=true },
		},
		config = function()
			local path_parsers = vim.fn.stdpath("data") .. "/treesitter_parsers"
			vim.opt.runtimepath:append(path_parsers)
			require("nvim-treesitter.configs").setup({
				parser_install_dir = path_parsers,
				auto_install = true,
				highlight = { enable = true },
				indent = { enable = true },
			})
		end,
	},

	{
		"L3MON4D3/LuaSnip",
		-- Snippet Engine
		-- TODO: learn how to quickly write snippets with this!
		-- NOTE: cmp is loading this plugin
		lazy=true,
		dependencies = {
			{"rafamadriz/friendly-snippets", lazy=true},
		},
		keys = {
			{mode="i", "<C-l>", desc="Snippet: next item", function()
				local luasnip = require("luasnip")
				if luasnip.expand_or_locally_jumpable() then
					luasnip.expand_or_jump()
				end
			end},
			{mode="i", "<C-h>", desc="Snippet: previous item", function()
				local luasnip = require("luasnip")
				if luasnip.expand_or_locally_jumpable(-1) then
					luasnip.expand_or_jump(-1)
				end
			end},
		},
		build = function()
			if vim.fn.executable("make") then
				return "make install_jsregexp"
			end
		end,
		config = function(_, opts)
			require("luasnip").config.setup(opts)
			require("luasnip.loaders.from_vscode").lazy_load()
		end,
	},


	{
		-- FIXME: this causes some kind of errors sometimes, one of them is the one bellow:
		-- https://github.com/hrsh7th/cmp-cmdline/issues/73
		"hrsh7th/nvim-cmp",
		lazy = true,
		event = { "InsertEnter", "CmdlineEnter" },
		keys = {
			{mode="i", "<C-a>", function() require("cmp").abort() end, desc="CMP: [A]bort"},
			{mode="i", "<C-n>", function() require("cmp").select_next_item() end, desc="CMP: select [N]next"},
			{mode="i", "<C-p>", function() require("cmp").select_prev_item() end, desc="CMP: select [P]revious"},
			{mode="i", "<C-y>", function() require("cmp").confirm({ select = true }) end, desc="CMP: [S]elect"},
			{mode="i", "<C-Space>", function() require("cmp").complete({}) end, desc="CMP: [C]omplete"},
		},
		dependencies = {
			{"neovim/nvim-lspconfig", lazy=true, },
			{"L3MON4D3/LuaSnip", lazy=true, },
			{"hrsh7th/cmp-nvim-lsp", lazy=true, },
			{"hrsh7th/cmp-buffer", lazy=true, },
			{"hrsh7th/cmp-path", lazy=true, },
			{"hrsh7th/cmp-cmdline", lazy=true, },
			{"hrsh7th/cmp-nvim-lua", lazy=true, },
			{"hrsh7th/cmp-emoji", lazy=true, },
			{"saadparwaiz1/cmp_luasnip", lazy=true, },
			{"ray-x/cmp-treesitter", lazy=true, },
		},
		config = function()
			local cmp = require("cmp")
			cmp.setup({
				snippet = {
					expand = function(args)
						require("luasnip").lsp_expand(args.body)
					end,
				},
				completion = { completeopt = "menu,menuone,noinsert" },
				sources = {
					{ name = "nvim_lsp" },
					{ name = "buffer" },
					{ name = "path" },
					{ name = "luasnip" },
					{ name = "nvim_lua" },
					{ name = 'treesitter' },
					{ name = 'emoji' },
					{ name = 'cmdline' },
				},
			})
			cmp.setup.cmdline('/', {
				mapping = cmp.mapping.preset.cmdline(),
				sources = {{ name = 'buffer' }}
			})
			cmp.setup.cmdline(':', {
				mapping = cmp.mapping.preset.cmdline(),
				sources = cmp.config.sources(
					{{ name = 'path' }},
					{{ name = 'cmdline' }}
				)
			})
		end,
	},

	{
		"folke/lazy.nvim",
		lazy = false,
		opts = {
			rocks = { enabled = false, },
			install = {
				colorscheme = { utils.COLORSCHEME_FALLBACK },
			},
			ui = {
				size = { width = 0.8, height = 0.8 },
				wrap = false,
				border = utils.BORDER_STYLE,
				backdrop = 100,
				icons = {
					cmd = "[cmd]",
					config = "[config]",
					event = "[event]",
					ft = "[ft]",
					init = "[init]",
					keys = "[key]",
					plugin = "[plugin]",
					runtime = "[runtime]",
					require = "[require]",
					source = "[source]",
					start = "[start]",
					task = "[task]",
					lazy = "zZz",
				},
				custom_keys = {
					["<C-o>"] = {
						function(plugin)
							local window_id = vim.api.nvim_get_current_win()
							vim.api.nvim_win_close(window_id, true)
						end,
						desc = "back out of Lazy",
					},
				},
			},
		},
	},

}

