vim.keymap.set({ 'n', 'v' }, '<leader>ss', "<cmd>lua require('vscode').action('workbench.action.gotoSymbol')<CR>", { desc = '[s]earch [s]ymbols' })
vim.keymap.set(
  { 'n', 'v' },
  '<leader>sp',
  "<cmd>lua require('vscode').action('workbench.action.showAllSymbols')<CR>",
  { desc = '[s]earch symbols in [p]roject' }
)
vim.keymap.set({ 'n', 'v' }, '<leader>sf', "<cmd>lua require('vscode').action('workbench.action.quickOpen')<CR>", { desc = '[s]earch [f]iles' })
vim.keymap.set({ 'n', 'v' }, '<leader>sw', "<cmd>lua require('vscode').action('actions.find')<CR>", { desc = '[s]earch [w]ord' })
vim.keymap.set({ 'n', 'v' }, '<leader>sg', "<cmd>lua require('vscode').action('workbench.action.findInFiles')<CR>", { desc = '[s]earch [g]lobally' })
vim.keymap.set({ 'n', 'v' }, '<leader>q', "<cmd>lua require('vscode').action('editor.action.quickFix')<CR>", { desc = 'Open [q]uickFix' })
vim.keymap.set({ 'n', 'v' }, '<leader>z', "<cmd>lua require('vscode').action('workbench.action.toggleZenMode')<CR>", { desc = 'Toggle [z]en Mode' })

-- Window keymaps
vim.keymap.set({ 'n', 'v' }, '<leader>ge', "<cmd>lua require('vscode').action('workbench.view.explorer')<CR>", { desc = 'Focus on File [e]xplorer' })
vim.keymap.set({ 'n', 'v' }, '<leader>gs', "<cmd>lua require('vscode').action('workbench.view.scm')<CR>", { desc = 'Focus on [s]ource Control' })
vim.keymap.set({ 'n', 'v' }, '<leader>gd', "<cmd>lua require('vscode').action('workbench.view.debug')<CR>", { desc = 'Focus on [d]ebugger' })
vim.keymap.set(
  { 'n', 'v' },
  '<leader>gt',
  "<cmd>lua require('vscode').action('workbench.action.terminal.toggleTerminal')<CR>",
  { desc = 'Focus on [t]erminal' }
)
vim.keymap.set({ 'n', 'v' }, '<leader>gc', "<cmd>lua require('vscode').action('workbench.debug.action.toggleRepl')<CR>", { desc = 'Focus on Debug [c]onsole' })
vim.keymap.set({ 'n', 'v' }, '<leader>gk', "<cmd>lua require('vscode').action('workbench.view.testing.focus')<CR>", { desc = 'Focus on Testing' })
vim.keymap.set({ 'n', 'v' }, '<leader>gg', "<cmd>lua require('vscode').action('git-graph.view')<CR>", { desc = 'Focus on [g]it Graph' })
