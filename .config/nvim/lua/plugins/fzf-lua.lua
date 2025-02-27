return {
    {
        'ibhagwan/fzf-lua',
        dependencies = { 'echasnovski/mini.nvim' },
        opts = {},
        config = function()
            local fzflua = require 'fzf-lua'
            fzflua.setup {
                keymap = {
                    builtin = {
                        ['<F1>'] = 'toggle-help',
                        ['<F2>'] = 'toggle-fullscreen',
                        -- Only valid with the 'builtin' previewer
                        ['<F3>'] = 'toggle-preview-wrap',
                        ['<F4>'] = 'toggle-preview',
                        ['<F5>'] = 'toggle-preview-ccw',
                        ['<F6>'] = 'toggle-preview-cw',
                        ['<C-d>'] = 'preview-page-down',
                        ['<C-u>'] = 'preview-page-up',
                        ['<S-left>'] = 'preview-page-reset',
                    },
                    fzf = {
                        ['ctrl-f'] = 'half-page-down',
                        ['ctrl-b'] = 'half-page-up',
                        ['ctrl-a'] = 'beginning-of-line',
                        ['ctrl-e'] = 'end-of-line',
                        ['alt-a'] = 'toggle-all',
                        -- Only valid with fzf previewers (bat/cat/git/etc)
                        ['f3'] = 'toggle-preview-wrap',
                        ['f4'] = 'toggle-preview',
                        ['ctrl-d'] = 'preview-page-down',
                        ['ctrl-u'] = 'preview-page-up',
                        ['ctrl-q'] = 'select-all+accept',
                    },
                },
            }

            -- local actions = require('fzf-lua').actions
            -- actions = {
            --     files = {
            --         ['ctrl-i'] = { actions.toggle_ignore },
            --         ['ctrl-h'] = { actions.toggle_hidden },
            --         ['ctrl-f'] = { actions.toggle_follow },
            --     },
            -- }

            vim.keymap.set('n', '<leader>sh', fzflua.helptags, { desc = '[s]earch [h]elp' })
            vim.keymap.set('n', '<leader>sk', fzflua.keymaps, { desc = '[s]earch [k]eymaps' })

            vim.keymap.set('n', '<leader>sf', fzflua.files, { desc = '[s]earch [f]iles' })

            vim.keymap.set('n', '<leader>sw', fzflua.grep_cword, { desc = '[s]earch current [w]ord' })

            vim.keymap.set('n', '<leader>sg', fzflua.live_grep, { desc = '[s]earch by [g]rep' })

            vim.keymap.set('n', '<leader>sd', fzflua.diagnostics_document, { desc = '[s]earch [d]iagnostics' })
            vim.keymap.set('n', '<leader>sp', fzflua.resume, { desc = '[s]earch [p]revious' })
            vim.keymap.set('n', '<leader>so', fzflua.oldfiles, { desc = '[s]earch Recent Files ("." for repeat)' })
            vim.keymap.set('n', '<leader><leader>', fzflua.buffers, { desc = 'search existing buffers' })
            vim.keymap.set('n', '<leader>s?', fzflua.builtin, { desc = '[s]earch by custom picker' })
            vim.keymap.set('n', '<leader>s/', fzflua.lgrep_curbuf, { desc = '[/] Fuzzily search in current buffer' })

            vim.keymap.set('n', '<leader>sn', function()
                fzflua.files {
                    cwd = vim.fn.stdpath 'config',
                }
            end, { desc = '[s]earch [n]eovim files' })
        end,
    },
}
