return {
    {
        'ibhagwan/fzf-lua',
        dependencies = { 'echasnovski/mini.nvim' },
        opts = {},
        config = function()
            local fzflua = require 'fzf-lua'
            -- local fullscreen_opts = {
            --     fullscreen = true,
            --     backdrop = 100,
            --     border = 'none',
            --     preview = { border = 'none', wrap = true },
            -- }

            fzflua.setup {

                keymap = { true },
                actions = { true },
                files = {
                    -- winopts = fullscreen_opts,
                    formatter = 'path.filename_first',
                },
                grep = {
                    -- winopts = fullscreen_opts
                },
            }

            vim.keymap.set('n', '<leader>sh', fzflua.helptags, { desc = '[s]earch [h]elp' })
            vim.keymap.set('n', '<leader>sk', fzflua.keymaps, { desc = '[s]earch [k]eymaps' })

            vim.keymap.set('n', '<leader>sf', fzflua.files, { desc = '[s]earch [f]iles' })

            vim.keymap.set('n', '<leader>sw', fzflua.grep_cword, { desc = '[s]earch current [w]ord' })

            vim.keymap.set('n', '<leader>sg', fzflua.live_grep, { desc = '[s]earch by [g]rep' })

            vim.keymap.set('n', '<leader>sd', fzflua.diagnostics_document, { desc = '[s]earch [d]iagnostics' })
            vim.keymap.set('n', '<leader>sp', fzflua.resume, { desc = '[s]earch [p]revious' })
            vim.keymap.set('n', '<leader>s.', fzflua.oldfiles, { desc = '[s]earch Recent Files ("." for repeat)' })
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
