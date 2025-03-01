return {
    {
        'ibhagwan/fzf-lua',
        dependencies = { 'echasnovski/mini.nvim' },
        opts = {},
        config = function()
            local fzflua = require 'fzf-lua'
            local actions = require('fzf-lua').actions
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
                        ['<F7>'] = 'toggle-preview-ts-ctx',
                        ['<F8>'] = 'preview-ts-ctx-dec',
                        ['<F9>'] = 'preview-ts-ctx-inc',
                        ['<S-Esc>'] = 'hide',
                        ['<C-d>'] = 'preview-page-down',
                        ['<C-u>'] = 'preview-page-up',
                        ['<C-e>'] = 'preview-down',
                        ['<C-y>'] = 'preview-up',
                    },
                    fzf = {
                        ['ctrl-u'] = 'unix-line-discard',
                        ['ctrl-f'] = 'half-page-down',
                        ['ctrl-b'] = 'half-page-up',
                        ['ctrl-a'] = 'toggle-all',
                        ['alt-g'] = 'first',
                        ['alt-G'] = 'last',
                    },
                    actions = {
                        files = {
                            ['enter'] = actions.file_edit_or_qf,
                            ['ctrl-s'] = actions.file_split,
                            ['ctrl-v'] = actions.file_vsplit,
                            ['ctrl-t'] = actions.file_tabedit,
                            ['ctrl-q'] = actions.file_sel_to_qf,
                            ['alt-i'] = { fn = actions.toggle_ignore, reuse = true, header = false },
                            ['alt-h'] = { fn = actions.toggle_hidden, reuse = true, header = false },
                            ['alt-f'] = { fn = actions.toggle_follow, reuse = true, header = false },
                        },
                    },
                },
            }

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
