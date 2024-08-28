vim.keymap.set({ 'n', 'v' }, '<leader>ss', "<cmd>lua require('vscode').action('workbench.action.gotoSymbol')<CR>", { desc = '[S]earch [S]ymbols' })
vim.keymap.set(
  { 'n', 'v' },
  '<leader>sp',
  "<cmd>lua require('vscode').action('workbench.action.showAllSymbols')<CR>",
  { desc = '[S]earch symbols in [P]roject' }
)
vim.keymap.set({ 'n', 'v' }, '<leader>sf', "<cmd>lua require('vscode').action('workbench.action.quickOpen')<CR>", { desc = '[S]earch [F]iles' })
vim.keymap.set({ 'n', 'v' }, '<leader>sw', "<cmd>lua require('vscode').action('editor.action.startFindReplaceAction')<CR>", { desc = '[S]earch [W]ord' })
vim.keymap.set({ 'n', 'v' }, '<leader>sr', "<cmd>lua require('vscode').action('workbench.view.search.focus')<CR>", { desc = '[S]earch and [R]eplace globally' })
vim.keymap.set({ 'n', 'v' }, '<leader>q', "<cmd>lua require('vscode').action('editor.action.quickFix')<CR>", { desc = 'Open [Q]uickFix' })
vim.keymap.set({ 'n', 'v' }, '<leader>z', "<cmd>lua require('vscode').action('workbench.action.toggleZenMode')<CR>", { desc = 'Toggle [Z]en Mode' })

-- Window keymaps
-- vim.keymap.set({ 'n', 'v' }, '<leader>ge', "<cmd>lua require('vscode').action('workbench.files.action.focusOpenEditorsView')<CR>", { desc = 'Focus on File [E]xplorer' })
vim.keymap.set({ 'n', 'v' }, '<leader>ge', "<cmd>lua require('vscode').action('workbench.view.explorer')<CR>", { desc = 'Focus on File [E]xplorer' })
vim.keymap.set({ 'n', 'v' }, '<leader>gs', "<cmd>lua require('vscode').action('workbench.view.scm')<CR>", { desc = 'Focus on [S]ource Control' })
vim.keymap.set({ 'n', 'v' }, '<leader>gd', "<cmd>lua require('vscode').action('workbench.view.debug')<CR>", { desc = 'Focus on [D]ebugger' })
vim.keymap.set(
  { 'n', 'v' },
  '<leader>gt',
  "<cmd>lua require('vscode').action('workbench.action.terminal.toggleTerminal')<CR>",
  { desc = 'Focus on [T]erminal' }
)
vim.keymap.set({ 'n', 'v' }, '<leader>gc', "<cmd>lua require('vscode').action('workbench.debug.action.toggleRepl')<CR>", { desc = 'Focus on Debug [C]onsole' })
vim.keymap.set({ 'n', 'v' }, '<leader>gk', "<cmd>lua require('vscode').action('workbench.view.testing.focus')<CR>", { desc = 'Focus on Testing' })
vim.keymap.set({ 'n', 'v' }, '<leader>gg', "<cmd>lua require('vscode').action('git-graph.view')<CR>", { desc = 'Focus on [G]it Graph' })
