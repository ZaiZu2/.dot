return {
    {
        'lewis6991/gitsigns.nvim',
        opts = {
            signs = {
                add = { text = '▌' },
                change = { text = '▌' },
                delete = { text = '▌' },
                -- topdelete = { text = '▌' },
                -- changedelete = { text = '▌' },
                -- untracked = { text = '▌' },
            },
            signs_staged = {
                add = { text = '▓' },
                change = { text = '▓' },
                delete = { text = '▓' },
                -- topdelete = { text = '▓' },
                -- changedelete = { text = '▓' },
                -- untracked = { text = '▓' },
            },
            -- :help gitsigns
            signcolumn = true, -- Toggle with `:Gitsigns toggle_signs`
            numhl = true, -- Toggle with `:Gitsigns toggle_numhl`
            linehl = false, -- Toggle with `:Gitsigns toggle_linehl`
            word_diff = false, -- Toggle with `:Gitsigns toggle_word_diff`
            current_line_blame = true, -- Toggle with `:Gitsigns toggle_current_line_blame`
            on_attach = function(bufnr)
                local gitsigns = require 'gitsigns'

                local function map(mode, l, r, opts)
                    opts = opts or {}
                    opts.buffer = bufnr
                    vim.keymap.set(mode, l, r, opts)
                end

                -- Navigation
                map('n', ']h', function()
                    if vim.wo.diff then
                        vim.cmd.normal { ']h', bang = true }
                    else
                        gitsigns.nav_hunk 'next'
                    end
                end, { desc = 'Jump to next [g]it chunk' })

                map('n', '[g', function()
                    if vim.wo.diff then
                        vim.cmd.normal { '[g', bang = true }
                    else
                        gitsigns.nav_hunk 'prev'
                    end
                end, { desc = 'Jump to previous [g]it chunk' })

                -- Actions
                -- visual mode
                map('v', '<leader>gs', function()
                    gitsigns.stage_hunk { vim.fn.line '.', vim.fn.line 'v' }
                end, { desc = 'stage git hunk' })
                map('v', '<leader>gr', function()
                    gitsigns.reset_hunk { vim.fn.line '.', vim.fn.line 'v' }
                end, { desc = 'reset git hunk' })
                -- normal mode
                map('n', '<leader>gs', gitsigns.stage_hunk, { desc = 'git [s]tage hunk' })
                map('n', '<leader>gr', gitsigns.reset_hunk, { desc = 'git [r]eset hunk' })
                map('n', '<leader>gS', gitsigns.stage_buffer, { desc = 'git [S]tage buffer' })
                map('n', '<leader>gR', gitsigns.reset_buffer, { desc = 'git [R]eset buffer' })
                map('n', '<leader>gp', gitsigns.preview_hunk, { desc = 'git [p]review hunk' })
                map('n', '<leader>gb', gitsigns.blame_line, { desc = 'git [b]lame line' })
                -- Toggles
                map('n', '<leader>tb', gitsigns.toggle_current_line_blame, { desc = '[t]oggle git show [b]lame line' })
                map('n', '<leader>tD', gitsigns.preview_hunk_inline, { desc = '[t]oggle git show [D]eleted' })
            end,
        },
    },
}
