-- Close the blame pane of the current tab, or open one for the current file.
local function toggle_blame()
    for _, win in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
        if vim.bo[vim.api.nvim_win_get_buf(win)].filetype == 'gitsigns-blame' then
            vim.api.nvim_win_close(win, true)
            return
        end
    end
    require('gitsigns').blame()
end

local signs = {
    add = { text = '▌' },
    change = { text = '▌' },
    delete = { text = '▌' },
    topdelete = { text = '▌' },
    changedelete = { text = '▌' },
    untracked = { text = '▌' },
}

return {
    {
        'lewis6991/gitsigns.nvim',
        init = function()
            -- The blame pane is not a buffer gitsigns attaches to, so on_attach doesn't map it.
            vim.api.nvim_create_autocmd('FileType', {
                pattern = 'gitsigns-blame',
                callback = function(args)
                    vim.keymap.set(
                        'n',
                        '<leader>gB',
                        toggle_blame,
                        { buffer = args.buf, desc = 'git [B]lame file (toggle)' }
                    )
                end,
            })
        end,
        opts = {
            signs = signs,
            signs_staged = signs,
            -- :help gitsigns
            signcolumn = true, -- Toggle with `:Gitsigns toggle_signs`
            numhl = true, -- Toggle with `:Gitsigns toggle_numhl`
            linehl = false, -- Toggle with `:Gitsigns toggle_linehl`
            word_diff = false, -- Toggle with `:Gitsigns toggle_word_diff`
            current_line_blame = true, -- Toggle with `:Gitsigns toggle_current_line_blame`
            -- Rest is derived from 'diffopt'; its linematch splits a changed hunk into interleaved -/+ lines.
            diff_opts = { linematch = false },
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
                        vim.cmd.normal { ']g', bang = true }
                    else
                        gitsigns.nav_hunk 'next'
                    end
                end, { desc = 'Jump to next git c[h]unk' })

                map('n', '[h', function()
                    if vim.wo.diff then
                        vim.cmd.normal { '[g', bang = true }
                    else
                        gitsigns.nav_hunk 'prev'
                    end
                end, { desc = 'Jump to previous git c[h]unk' })

                -- Actions
                -- visual mode
                map(
                    'v',
                    '<leader>gs',
                    function() gitsigns.stage_hunk { vim.fn.line '.', vim.fn.line 'v' } end,
                    { desc = 'stage git hunk' }
                )
                map(
                    'v',
                    '<leader>gr',
                    function() gitsigns.reset_hunk { vim.fn.line '.', vim.fn.line 'v' } end,
                    { desc = 'reset git hunk' }
                )
                -- normal mode
                map('n', '<leader>gs', gitsigns.stage_hunk, { desc = 'git [s]tage hunk' })
                map('n', '<leader>gr', gitsigns.reset_hunk, { desc = 'git [r]eset hunk' })
                -- get_hunks lists only unstaged hunks: stage them if any are left, else unstage the whole file.
                map('n', '<leader>gS', function()
                    if #(gitsigns.get_hunks(bufnr) or {}) > 0 then
                        gitsigns.stage_buffer()
                    else
                        gitsigns.reset_buffer_index()
                    end
                end, { desc = 'git [S]tage buffer (toggle)' })
                map('n', '<leader>gR', gitsigns.reset_buffer, { desc = 'git [R]eset buffer' })
                map('n', '<leader>gp', gitsigns.preview_hunk, { desc = 'git [p]review hunk' })
                map('n', '<leader>gb', gitsigns.blame_line, { desc = 'git [b]lame line' })
                map('n', '<leader>gB', toggle_blame, { desc = 'git [B]lame file (toggle)' })
                -- Toggles
                map('n', '<leader>tb', gitsigns.toggle_current_line_blame, { desc = '[t]oggle git show [b]lame line' })
                map('n', '<leader>tD', gitsigns.preview_hunk_inline, { desc = '[t]oggle git show [D]eleted' })
            end,
        },
    },
}
