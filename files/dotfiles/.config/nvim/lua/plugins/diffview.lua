return {
    {
        'sindrets/diffview.nvim',
        event = 'VeryLazy',
        config = function()
            require('diffview').setup {}
            local function toggle_diffview(cmd)
                if require("diffview.lib").get_current_view() == nil then
                    vim.cmd(cmd)
                else
                    vim.cmd 'DiffviewClose'
                end
            end

            vim.keymap.set('n', '<leader>gd', function()
                toggle_diffview 'DiffviewOpen'
            end, { desc = 'git [d]iff index' })

            vim.keymap.set('n', '<leader>gD', function()
                toggle_diffview 'DiffviewOpen master..HEAD'
            end, { desc = 'git [D]iff HEAD' })

            vim.keymap.set('n', '<leader>gf', function()
                toggle_diffview 'DiffviewFileHistory %'
            end, { desc = 'git diff [f]ile' })
        end,
    },
}
