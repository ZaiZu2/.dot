vim.g.mapleader = ' '
vim.g.maplocalleader = ' '
vim.g.have_nerd_font = true

vim.opt.fillchars = { vert = '▕' }
vim.opt.textwidth = 90
vim.opt.shiftwidth = 2
vim.opt.expandtab = true
vim.opt.number = true
vim.opt.relativenumber = true
vim.opt.cursorline = true
vim.opt.mouse = 'a'
vim.opt.showmode = false
vim.opt.clipboard = 'unnamedplus' -- :help 'clipboard'
vim.opt.breakindent = true
vim.opt.undofile = true
vim.opt.ignorecase = true -- Case-insensitive searching UNLESS \C or one or more capital letters in the search term
vim.opt.smartcase = true
vim.opt.smartindent = false
vim.opt.signcolumn = 'yes' -- Keep signcolumn on by default
vim.opt.updatetime = 250
vim.opt.timeoutlen = 1000
vim.opt.splitright = true
vim.opt.splitbelow = true
vim.opt.list = true
vim.opt.listchars = { tab = '» ', trail = '·', nbsp = '␣' }
vim.opt.inccommand = 'split' -- Preview substitutions live, as you type!
vim.opt.scrolloff = 10
vim.opt.hlsearch = true -- Set highlight on search, but clear on pressing <Esc> in normal mode
vim.opt.formatoptions = 'cqn1jp' -- help 'format-comments'
vim.opt.diffopt = { 'internal', 'filler', 'closeoff', 'indent-heuristic', 'linematch:60', 'algorithm:histogram' }

vim.keymap.set('n', '<leader>Q', ':bp | sp | bn | bd<CR>', { desc = '[Q]uit current buffer' })
vim.keymap.set('t', '<Esc><Esc>', '<C-\\><C-n>', { desc = 'Exit terminal mode' })
vim.keymap.set('n', '<Esc>', '<cmd>nohlsearch<CR>') -- Deactive search highlights
vim.keymap.set('n', '[d', vim.diagnostic.goto_prev, { desc = 'Go to previous [d]iagnostic message' })
vim.keymap.set('n', ']d', vim.diagnostic.goto_next, { desc = 'Go to next [d]iagnostic message' })
vim.keymap.set('n', '<leader>e', vim.diagnostic.open_float, { desc = 'Show diagnostic [e]rror messages' })
vim.keymap.set('n', '<leader>q', vim.diagnostic.setloclist, { desc = 'Open diagnostic [q]uickfix list' })
vim.keymap.set('n', '<leader>m', ':messages<CR>', { desc = 'Open [m]essages' })

vim.keymap.set('n', '<C-_>', '<C-w><h>', { desc = 'Split window horizontally' })
vim.keymap.set('n', '<C-|>', '<C-w><v>', { desc = 'Split window vertically' })

vim.keymap.set('v', '<leader>x', ':lua<CR>', { desc = 'E[x]ecute selected Lua code' })
vim.keymap.set('n', '<leader>x', ':.lua<CR>', { desc = 'E[x]ecute Lua line' })
vim.keymap.set('n', '<leader>X', '<cmd>source %<CR>', { desc = 'E[X]ecute current file' })
vim.keymap.set('n', ',tn', function()
    require('mini.test').run()
end, { desc = 'mini.[t]est current file' })

local utils = require 'utils'
vim.keymap.set({ 'n', 'v' }, '<leader>sr', utils.find_and_replace, { desc = '[s]earch and [r]eplace' })
vim.keymap.set(
    { 'n', 'v' },
    '<leader>sR',
    utils.find_and_replace_globally,
    { desc = '[s]earch and [R]eplace globally' }
)

vim.diagnostic.config {
    virtual_text = {
        prefix = '■ ',
    },
}

vim.filetype.add {
    extension = {
        task = 'xml', -- ABSA specific .task files
        asql  = 'sql', -- ABSA specific .sql files
    },
}

package.path = package.path .. ';' .. vim.fn.stdpath 'config' .. '/lsp/?.lua'

-- :help lazy.nvim.txt
local lazypath = vim.fn.stdpath 'data' .. '/lazy/lazy.nvim'
---@diagnostic disable-next-line: undefined-field
if not vim.uv.fs_stat(lazypath) then
    local lazyrepo = 'https://github.com/folke/lazy.nvim.git'
    vim.fn.system {
        'git',
        'clone',
        '--filter=blob:none',
        '--branch=stable',
        lazyrepo,
        lazypath,
    }
end ---@diagnostic disable-next-line: undefined-field
vim.opt.rtp:prepend(lazypath)

require('lazy').setup('plugins', { change_detection = { notify = false } })
require 'autocmd'
require 'health'

-- vim: ts=2 sts=2 sw=2 et
