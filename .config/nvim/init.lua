-- Read `nvim.lua` from cwd, and save the result to `vim.g.custom`
-- `vim.g.custom` can be used to modify lua initialization
vim.g.custom = {}
local init_file = vim.fn.getcwd() .. '/nvim.lua'
if vim.fn.filereadable(init_file) == 1 then
  local ok, custom = pcall(dofile, init_file)
  if ok then
    if type(custom) == 'table' then
      vim.g.custom = custom
    else
      vim.notify('nvim.lua must return a table' .. custom, vim.log.levels.ERROR)
    end
  else
    vim.notify('Error loading `nvim.lua`: ' .. custom, vim.log.levels.ERROR)
  end
end

-- :help lua-guide
-- https://neovim.io/doc/user/lua-guide.html
-- :help mapleader
vim.g.mapleader = ' '
vim.g.maplocalleader = ' '
vim.g.have_nerd_font = true

-- :help vim.opt
-- :help option-list
vim.opt.number = true
vim.opt.relativenumber = true
vim.opt.cursorline = true
vim.opt.mouse = 'a'
vim.opt.showmode = false
vim.opt.clipboard = 'unnamedplus' -- :help 'clipboard'
vim.opt.breakindent = true
vim.opt.undofile = true
-- Case-insensitive searching UNLESS \C or one or more capital letters in the search term
vim.opt.ignorecase = true
vim.opt.smartcase = true
vim.opt.signcolumn = 'yes' -- Keep signcolumn on by default
vim.opt.updatetime = 250
vim.opt.timeoutlen = 1000
vim.opt.splitright = true
vim.opt.splitbelow = true
-- :help 'list'
-- :help 'listchars'
vim.opt.list = true
vim.opt.listchars = { tab = '» ', trail = '·', nbsp = '␣' }
vim.opt.inccommand = 'split' -- Preview substitutions live, as you type!
vim.opt.scrolloff = 10
vim.opt.hlsearch = true -- Set highlight on search, but clear on pressing <Esc> in normal mode

-- :help vim.keymap.set()
vim.keymap.set('t', '<Esc><Esc>', '<C-\\><C-n>', { desc = 'Exit terminal mode' })
vim.keymap.set('n', '<Esc>', '<cmd>nohlsearch<CR>') -- Deactive search highlights
vim.keymap.set('n', '[d', vim.diagnostic.goto_prev, { desc = 'Go to previous [d]iagnostic message' })
vim.keymap.set('n', ']d', vim.diagnostic.goto_next, { desc = 'Go to next [d]iagnostic message' })
vim.keymap.set('n', '<leader>e', vim.diagnostic.open_float, { desc = 'Show diagnostic [e]rror messages' })
vim.keymap.set('n', '<leader>q', vim.diagnostic.setloclist, { desc = 'Open diagnostic [q]uickfix list' })

vim.keymap.set('n', '<leader>gn', ':tabnew<CR>', { desc = '[n]ew tab' })
vim.keymap.set('n', '<leader>gN', ':tabclose<CR>', { desc = 'Close the current tab' })
vim.keymap.set('n', '<C-_>', '<C-w><h>', { desc = 'Split window horizontally' })
vim.keymap.set('n', '<C-|>', '<C-w><v>', { desc = 'Split window vertically' })

vim.diagnostic.config {
  virtual_text = {
    prefix = '■ ',
  },
  float = { border = 'rounded' },
}

-- vim.api.nvim_create_autocmd({ 'TextChanged', 'InsertLeave' }, {
--   desc = 'Autosave files on any changes',
--   group = vim.api.nvim_create_augroup('auto-save', { clear = true }),
--   callback = function(ctx)
--     local debouce_time = 1000
--     local init_autosave, autosave_locked = pcall(vim.api.nvim_buf_get_var, ctx.buf, 'autosave_locked')
--
--     if (not init_autosave or not autosave_locked) and vim.bo.buftype == '' then
--       vim.cmd 'silent w'
--       vim.notify('Saved at ' .. os.date '%H:%M:%S')
--
--       vim.api.nvim_buf_set_var(ctx.buf, 'autosave_locked', true)
--       vim.defer_fn(function()
--         if vim.api.nvim_buf_is_valid(ctx.buf) then
--           vim.api.nvim_buf_set_var(ctx.buf, 'autosave_locked', false)
--         end
--       end, debouce_time)
--     end
--   end,
-- })
vim.api.nvim_create_autocmd({ 'TextChanged', 'InsertLeave' }, {
  desc = 'Autosave files on any changes',
  group = vim.api.nvim_create_augroup('auto-save', { clear = true }),
  callback = function(ctx)
    if not vim.bo.buftype == '' or not vim.bo.modified or vim.fn.findfile(ctx.file, '.') == '' then
      return
    end

    vim.cmd 'silent w'
  end,
})

-- Highlight when yanking (copying) text
-- :help lua-guide-autocommands
-- :help vim.highlight.on_yank()
vim.api.nvim_create_autocmd('TextYankPost', {
  desc = 'Highlight when yanking (copying) text',
  group = vim.api.nvim_create_augroup('highlight-yank', { clear = true }),
  callback = function()
    vim.highlight.on_yank()
  end,
})

local findAndReplace = function()
  local cword = vim.fn.expand '<cword>'
  local cmd_string = ':%s/' .. cword .. '//g<Left><Left>'
  return cmd_string
  -- vim.cmd 'normal! :'
  -- vim.api.nvim_feedkeys(cmd_string, 'm', true)
end
vim.keymap.set('n', '<leader>sr', findAndReplace, { desc = '[s]earch and [r]eplace' })

local findAndReplaceGlobally = function()
  if vim.fn.getwininfo(vim.fn.win_getid())[1].quickfix ~= 1 then
    print 'This function can only be used in a quickfix buffer.'
    return
  end

  local cword = vim.fn.expand '<cword>'
  local cmd_string = string.format('<cmd>cdo %%s/%s/', cword)
  vim.cmd 'normal! :'
  vim.api.nvim_feedkeys(cmd_string, 't', true)
end
vim.keymap.set('n', '<leader>sR', findAndReplaceGlobally, { desc = '[s]earch and [R]eplace globally' })

-- Install plugin manager - lazy.nvim
-- :help lazy.nvim.txt
-- :Lazy / :Lazy update
local lazypath = vim.fn.stdpath 'data' .. '/lazy/lazy.nvim'
if not vim.loop.fs_stat(lazypath) then
  local lazyrepo = 'https://github.com/folke/lazy.nvim.git'
  vim.fn.system { 'git', 'clone', '--filter=blob:none', '--branch=stable', lazyrepo, lazypath }
end ---@diagnostic disable-next-line: undefined-field
vim.opt.rtp:prepend(lazypath)

local selectPlugins = function()
  local plugins = {}

  -- load global plugins
  for _, module_name in ipairs { 'plugins.various', 'plugins.mini' } do
    local module = require(module_name)
    for _, plugin in ipairs(module) do
      table.insert(plugins, plugin)
    end
  end

  local module_names = {}
  local path
  if vim.g.vscode then
    -- vscode-specific plugins
    path = 'plugins.vscode.'
    module_names = {}
  else
    -- native-nvim specific plugins
    path = 'plugins.native.'
    module_names = {
      'theme',
      'lsp',
      'treesitter',
      'lint',
      'cmp',
      'autopairs',
      'indent_line',
      'debug',
      'neotest',
      'gitsigns',
      'neotree',
      'toggleterm',
      'copilot',
      'telescope',
      'neotree',
      'vim-tmux-navigator',
      'which-key',
      'neoscroll',
      'colorizer',
    }
  end

  for _, module_name in ipairs(module_names) do
    local module_path = path .. module_name
    for _, plugin in ipairs(require(module_path)) do
      table.insert(plugins, plugin)
    end
  end

  return plugins
end

require('lazy').setup(selectPlugins(), {})

if vim.g.vscode then
  require 'vscode_bindings'
end

require 'health'

-- vim: ts=2 sts=2 sw=2 et
