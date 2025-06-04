return {
    {
        'rebelot/kanagawa.nvim',
        priority = 1000, -- Make sure to load this before all the other start plugins.
        init = function()
            vim.cmd.colorscheme 'kanagawa-wave'
            -- local colors = require('kanagawa.colors').setup()

            ---@diagnostic disable-next-line: missing-fields
            require('kanagawa').setup {
                overrides = function(colors)
                    return {
                        VertSplit = { fg = colors.palette.dragonGray2 },
                        WinSeparator = { fg = colors.palette.dragonGray2 },

                        BlinkCmpMenu = { fg = colors.palette.oldWhite, bg = colors.palette.sumiInk1 },
                        BlinkCmpMenuSelection = { bg = colors.palette.sumiInk5 },
                        BlinkCmpScrollBarThumb = { bg = colors.palette.sumiInk6 },
                        BlinkCmpScrollBarGutter = { bg = colors.palette.sumiInk4 },
                    }
                end,
            }
            vim.cmd.colorscheme 'kanagawa-wave'
            vim.cmd.hi 'Comment gui=none'
        end,
    },
}
