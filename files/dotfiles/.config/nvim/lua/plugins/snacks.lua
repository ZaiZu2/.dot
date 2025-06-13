return {
    {
        'folke/snacks.nvim',
        ---@type snacks.Config
        opts = {
            image = {
                enabled = true,
            },
            scroll = {
                animate = {
                    duration = { step = 5, total = 100 },
                    easing = 'linear',
                },
            },
        },
    },
}
