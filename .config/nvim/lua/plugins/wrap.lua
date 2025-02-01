return {
    {
        -- 'ZaiZu2/wrap.nvim',
        dir = '/Users/AB0383Q/Git/wrap.nvim',
        dev = true,
        opts = {
            line_width = 90,
            rules = {
                javascript = {
                    comment = {
                        { '//' },
                        { '/*', '*/' },
                    },
                },
            },
        },
        config = function(_, opts)
            require('wrap').setup(opts)
            vim.keymap.set(
                {'n','v'},
                '<leader>w',
                '<cmd>Wrap comment<CR>',
                { desc = '[w]rap comment' }
            )
            vim.keymap.set(
                {'n','v'},
                '<leader>W',
                '<cmd>Wrap block<CR>',
                { desc = '[W]rap block' }
            )
        end,
    },
}
