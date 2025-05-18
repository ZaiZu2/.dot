return {
    {
        -- Nvim color scheme
        'rebelot/kanagawa.nvim',
        priority = 1000, -- Make sure to load this before all the other start plugins.
        init = function()
            vim.cmd.colorscheme 'kanagawa-wave'
            vim.cmd.hi 'Comment gui=none'
        end,
    },
    -- {
    --     'nvim-zh/colorful-winsep.nvim',
    --     event = { 'WinLeave' },
    --     opts = {
    --         hi = { fg = '#C8C093' },
    --         symbols = { '━', '┃', '┏', '┓', '┗', '┛' },
    --         only_line_seq = false,
    --         smooth = false,
    --     },
    --     config = function(_, opts)
    --         vim.api.nvim_set_hl(0, 'WinSeparator', { fg = '#54546D' })
    --         require('colorful-winsep').setup(opts)
    --     end,
    -- },
}
