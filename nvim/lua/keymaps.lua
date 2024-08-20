
-- [[ navigation]]
vim.keymap.set("n", "<tab>", "<cmd>tabnext<CR>", { desc = "Move focus to the next Tab" })
vim.keymap.set("n", "<S-tab>", "<cmd>tabprevious<CR>", { desc = "Move focus to the previous Tab" })
vim.keymap.set("n", "<C-w>t", "<cmd>tabnew<CR><C-o>", { desc = "Create [T]ab" })

-- [[ LSP ]]
vim.keymap.set("n", "<leader>lr", vim.lsp.buf.rename, { desc = "[R]ename" })
vim.keymap.set("n", "<leader>ls", vim.lsp.buf.signature_help, { desc = "[S]ignature help" })
vim.keymap.set("n", "<leader>la", vim.lsp.buf.code_action, { desc = "code [A]ction" })
vim.keymap.set("n", "<leader>le", vim.diagnostic.open_float, { desc = "show [E]rror messages (use '<C-w>d' instead)" })
vim.keymap.set("n", "<leader>lci", vim.lsp.buf.incoming_calls, { desc = "[I]ncoming" })
vim.keymap.set("n", "<leader>lco", vim.lsp.buf.outgoing_calls, { desc = "[O]utgoing" })


-- [[ Terminal ]]
vim.keymap.set("n", "<leader>tb", "<cmd> terminal <CR>", { desc = "[B]uffer" })
vim.keymap.set("n", "<leader>tt", "<cmd> tabnew | terminal <CR>", { desc = "[T]ab" })
vim.keymap.set("n", "<leader>ts", "<cmd> split | terminal <CR>", { desc = "horizontal [S]lit" })
vim.keymap.set("n", "<leader>tv", "<cmd> vsplit | terminal <CR>", { desc = "[V]ertical slit" })

-- [[ Misc ]]
vim.keymap.set("n", "<Esc>", "<cmd>nohlsearch<CR>", { desc = "no highlight" })
vim.keymap.set("n", "<C-;>", "<cmd> edit ~/Notes/dummy.txt <CR>", { desc = "edit dummy note" })

